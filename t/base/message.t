require HTTP::Request;
require HTTP::Response;

print "1..5\n";

$req = new HTTP::Request 'GET', "http://www.oslonett.no/";
$req->header(
	"if-modified-since" => "Thu, 03 Feb 1994 00:00:00 GMT",
	"mime-version"      => "1.0");

$str = $req->as_string;

print $str;

print "ok 1\n" if $str =~ /^GET/m;

print "ok 2\n" if $req->header("MIME-Version") eq "1.0";

$req->content("gisle");
$req->add_content(" aas");
$req->add_content(\ " old interface");

if ($req->content eq "gisle aas old interface") {
    print "ok 3\n";
}


$res = new HTTP::Response 200, "This message";

$html = $res->error_as_HTML;
print $html;

if ($html =~ /<head>/i && $html =~ /This message/) {
	print "ok 4\n";
}


if ($res->is_success) {
	print "ok 5\n";
}
