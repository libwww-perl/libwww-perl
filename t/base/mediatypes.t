use LWP::MediaTypes;

require URI::URL;

$url1 = new URI::URL 'http://www/foo/test.gif?search+x#frag';
$url2 = new URI::URL 'http:test';

@tests =
(
 ["/this.dir/file.html" => "text/html",],
 ["test.gif.htm"        => "text/html",],
 ["test.txt.gz"         => "text/plain", "gzip"],
 ["gif.foo"             => "application/octet-stream",],
 ["lwp-0.03.tar.Z"      => "application/x-tar", "compress"],
 ["/etc/passwd"         => "text/plain",],
 ["/random/file"        => "application/octet-stream",],
 ["/dev/null"	        => "text/plain",],
 [$url1	        	=> "image/gif",],
 [$url2	        	=> "application/octet-stream",],
 ["x.ppm.Z.UU"		=> "image/x-portable-pixmap","compress","x-uuencode",],
);

$notests = @tests;
print "1..$notests\n";

$testno = 1;
for (@tests) {
    ($file, $expectedtype, @expectedEnc) = @$_;
    $type1 = guessMediaType($file);
    ($type, @enc) = guessMediaType($file);
    if ($type1 ne $type) {
       print "guessMediaType does not return same content-type in scalar and array conext.\n";
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

@imgSuffix = mediaSuffix('image/*');
print "Image suffixes: @imgSuffix\n";
