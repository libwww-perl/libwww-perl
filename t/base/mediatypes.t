use LWP::MediaTypes;

require URI::URL;

$url1 = new URI::URL 'http://www/foo/test.gif?search+x#frag';
$url2 = new URI::URL 'http:test';

$file = "/etc/passwd";
-r $file or $file = "./README";

@tests =
(
 ["/this.dir/file.html" => "text/html",],
 ["test.gif.htm"        => "text/html",],
 ["test.txt.gz"         => "text/plain", "gzip"],
 ["gif.foo"             => "application/octet-stream",],
 ["lwp-0.03.tar.Z"      => "application/x-tar", "compress"],
 [$file		        => "text/plain",],
 ["/random/file"        => "application/octet-stream",],
 ["/dev/null"	        => "text/plain",],
 [$url1	        	=> "image/gif",],
 [$url2	        	=> "application/octet-stream",],
 ["x.ppm.Z.UU"		=> "image/x-portable-pixmap","compress","x-uuencode",],
);

$notests = @tests;
print "1..$notests\n";

if (-f "$ENV{HOME}/.mime.types") {
   warn "
The MediaTypes test might fail because you have a private ~/.mime.types file
If you get a failed test, try to move it away while testing.
";
}


$testno = 1;
for (@tests) {
    ($file, $expectedtype, @expectedEnc) = @$_;
    $type1 = guess_media_type($file);
    ($type, @enc) = guess_media_type($file);
    if ($type1 ne $type) {
       print "guess_media_type does not return same content-type in scalar and array conext.\n";
	next;
    }
    $type = "undef" unless defined $type;
    if ($type eq $expectedtype and "@enc" eq "@expectedEnc") {
	print "ok $testno\n";
    } else {
	print "expected '$expectedtype' for '$file', got '$type'\n";
	print "encoding: expected: '@expectedEnc', got '@enc'\n"
	  if @expectedEnc || @enc;
	print "nok ok $testno\n";
    }
    $testno++;
}

@imgSuffix = media_suffix('image/*');
print "Image suffixes: @imgSuffix\n";
