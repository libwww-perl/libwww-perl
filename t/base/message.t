print "1..17\n";

require HTTP::Request;
require HTTP::Response;

$req = new HTTP::Request 'GET', "http://www.sn.no/";
$req->header(
	"if-modified-since" => "Thu, 03 Feb 1994 00:00:00 GMT",
	"mime-version"      => "1.0");

$str = $req->as_string;

print $str;

$str =~ /^GET/m || print "not ";
print "ok 1\n";

$req->header("MIME-Version") eq "1.0" || print "not ";
print "ok 2\n";

$req->content("gisle");
$req->add_content(" aas");
$req->add_content(\ " old interface");

$req->content eq "gisle aas old interface" || print "not ";
print "ok 3\n";

$req->if_modified_since == 760233600 || print "not ";
print "ok 4\n";

$time = time;

$req->date($time);
$timestr = gmtime($time);
($month) = ($timestr =~ /^\S+\s+(\S+)/);  # extract month;

print "These should represent the same time:\n\t", $req->header('Date'), "\n\t$timestr\n";

$req->header('Date') =~ /\Q$month/ || print "not ";
print "ok 5\n";

$req->authorization_basic("gisle", "passwd");
$auth = $req->header("Authorization");

print "$auth\n";
$auth =~ /Z2lzbGU6cGFzc3dk/ || print "not ";
print "ok 6\n";

($user, $pass) = $req->authorization_basic;
($user eq "gisle" && $pass eq "passwd") || print "not ";
print "ok 7\n";

# Check the response
$res = new HTTP::Response 200, "This message";

$html = $res->error_as_HTML;
print $html;

($html =~ /<head>/i && $html =~ /This message/) || print "not ";
print "ok 8\n";

$res->is_success || print "not ";
print "ok 9\n";

$res->content_type("text/html;version=3.0");
$res->content("<html>...</html>\n");

$res2 = $res->clone;

print $res2->as_string;

$res2->header("cOntent-TYPE") eq "text/html;version=3.0" || print "not ";
print "ok 10\n";

$res2->code == 200 || print "not ";
print "ok 11\n";

$res2->content =~ />\.\.\.</ || print "not ";
print "ok 12\n";

# Check the base method:

$res = new HTTP::Response 200, "This message";
$res->request($req);
$res->content_type("image/gif");

$res->base eq "http://www.sn.no/" || print "not ";
print "ok 13\n";

$res->header('Base', 'http://www.sn.no/xxx/');

$res->base eq "http://www.sn.no/xxx/" || print "not ";
print "ok 14\n";

$res->content_type("text/plain");
$res->content('<head><basE
href="file:/"><title>xxx</title></head>..............</html>');
$res->remove_header("base");

# Since the Content-Type isn't html, we should not look inside
$res->base eq "http://www.sn.no/" || print "not ";
print "ok 15\n";

$res->content_type("text/html");

$res->base eq "file:/" || print "not ";
print "ok 16\n";

$res->content("<head><title>Foo</title><h1>Foo</h1>
Some text
");

# This was an error in the B11 release.  If $1 was set before calling
# base(), then we would return it's value.
"2" =~ /(\d)/;   # set $1 to "2"

$res->base eq "http://www.sn.no/" || print "not ";
print "ok 17\n";
