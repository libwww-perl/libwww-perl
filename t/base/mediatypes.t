#!perl -w

use Test;

use LWP::MediaTypes;

require URI::URL;

$url1 = new URI::URL 'http://www/foo/test.gif?search+x#frag';
$url2 = new URI::URL 'http:test';

my $pwd if $^O eq "MacOS";

unless ($^O eq "MacOS") {
    $file = "/etc/passwd";
    -r $file or $file = "./README";
}
else {
    require Mac::Files;
    $pwd = `pwd`;
    chomp($pwd);
    my $dir = Mac::Files::FindFolder(Mac::Files::kOnSystemDisk(),
	                             Mac::Files::kDesktopFolderType());
    chdir($dir);
    $file = "README";
    open(README,">$file") or die "Unable to open $file";
    print README "This is a dummy file for LWP testing purposes\n";
    close README;
    open(README,">/dev/null") or die "Unable to open /dev/null";
    print README "This is a dummy file for LWP testing purposes\n";
    close README;
}

@tests =
(
 ["/this.dir/file.html" => "text/html",],
 ["test.gif.htm"        => "text/html",],
 ["test.txt.gz"         => "text/plain", "gzip"],
 ["gif.foo"             => "application/octet-stream",],
 ["lwp-0.03.tar.Z"      => "application/x-tar", "compress"],
 [$file		        => "text/plain",],
 ["/random/file"        => "application/octet-stream",],
 [($^O eq 'VMS'? "nl:" : "/dev/null") => "text/plain",],
 [$url1	        	=> "image/gif",],
 [$url2	        	=> "application/octet-stream",],
 ["x.ppm.Z.UU"		=> "image/x-portable-pixmap","compress","x-uuencode",],
);

plan tests => @tests * 3 + 6;

if ($ENV{HOME} and -f "$ENV{HOME}/.mime.types") {
   warn "
The MediaTypes test might fail because you have a private ~/.mime.types file
If you get a failed test, try to move it away while testing.
";
}


for (@tests) {
    ($file, $expectedtype, @expectedEnc) = @$_;
    $type1 = guess_media_type($file);
    ($type, @enc) = guess_media_type($file);
    ok($type1, $type);
    ok($type, $expectedtype);
    ok("@enc", "@expectedEnc");
}

@imgSuffix = media_suffix('image/*');
print "# Image suffixes: @imgSuffix\n";
ok(grep $_ eq "gif", @imgSuffix);

@audioSuffix = media_suffix('AUDIO/*');
print "# Audio suffixes: @audioSuffix\n";
ok(grep $_ eq 'oga', @audioSuffix);
ok(media_suffix('audio/OGG'), 'oga');

require HTTP::Response;
$r = new HTTP::Response 200, "Document follows";
$r->title("file.tar.gz.uu");
guess_media_type($r->title, $r);
#print $r->as_string;

ok($r->content_type, "application/x-tar");

@enc = $r->header("Content-Encoding");
ok("@enc", "gzip x-uuencode");

#
use LWP::MediaTypes qw(add_type add_encoding);
add_type("x-world/x-vrml", qw(wrl vrml));
add_encoding("x-gzip" => "gz");
add_encoding(rot13 => "r13");

@x = guess_media_type("foo.vrml.r13.gz");
#print "@x\n";
ok("@x", "x-world/x-vrml rot13 x-gzip");

#print LWP::MediaTypes::_dump();

if($^O eq "MacOS") {
    unlink "README";
    unlink "/dev/null";
    chdir($pwd);
}

