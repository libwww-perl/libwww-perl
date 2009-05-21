#perl -w

use Test;
plan tests => 52;

use HTTP::Request::Common;

$r = GET 'http://www.sn.no/';
print $r->as_string;

ok($r->method, "GET");
ok($r->uri, "http://www.sn.no/");

$r = HEAD "http://www.sn.no/",
     If_Match => 'abc',
     From => 'aas@sn.no';
print $r->as_string;

ok($r->method, "HEAD");
ok($r->uri->eq("http://www.sn.no"));

ok($r->header('If-Match'), "abc");
ok($r->header("from"), "aas\@sn.no");

$r = PUT "http://www.sn.no",
     Content => 'foo';
print $r->as_string, "\n";

ok($r->method, "PUT");
ok($r->uri->host, "www.sn.no");

ok(!defined($r->header("Content")));

ok(${$r->content_ref}, "foo");
ok($r->content, "foo");
ok($r->content_length, 3);

#--- Test POST requests ---

$r = POST "http://www.sn.no", [foo => 'bar;baz',
                               baz => [qw(a b c)],
                               foo => 'zoo=&',
                               "space " => " + ",
                              ],
                              bar => 'foo';
print $r->as_string, "\n";

ok($r->method, "POST");
ok($r->content_type, "application/x-www-form-urlencoded");
ok($r->content_length, 58);
ok($r->header("bar"), "foo");
ok($r->content, "foo=bar%3Bbaz&baz=a&baz=b&baz=c&foo=zoo%3D%26&space+=+%2B+");

$r = POST "mailto:gisle\@aas.no",
     Subject => "Heisan",
     Content_Type => "text/plain",
     Content => "Howdy\n";
#print $r->as_string;

ok($r->method, "POST");
ok($r->header("Subject"), "Heisan");
ok($r->content, "Howdy\n");
ok($r->content_type, "text/plain");

#
# POST for File upload
#
$file = "test-$$";
open(FILE, ">$file") or die "Can't create $file: $!";
print FILE "foo\nbar\nbaz\n";
close(FILE);

$r = POST 'http://www.perl.org/survey.cgi',
       Content_Type => 'form-data',
       Content      => [ name  => 'Gisle Aas',
                         email => 'gisle@aas.no',
                         gender => 'm',
                         born   => '1964',
                         file   => [$file],
                       ];
#print $r->as_string;

unlink($file) or warn "Can't unlink $file: $!";

ok($r->method, "POST");
ok($r->uri->path, "/survey.cgi");
ok($r->content_type, "multipart/form-data");
ok($r->header(Content_type) =~ /boundary="?([^"]+)"?/);
$boundary = $1;

$c = $r->content;
$c =~ s/\r//g;
@c = split(/--\Q$boundary/, $c);
print "$c[5]\n";

ok(@c == 7 and $c[6] =~ /^--\n/);  # 5 parts + header & trailer

ok($c[2] =~ /^Content-Disposition:\s*form-data;\s*name="email"/m);
ok($c[2] =~ /^gisle\@aas.no$/m);

ok($c[5] =~ /^Content-Disposition:\s*form-data;\s*name="file";\s*filename="$file"/m);
ok($c[5] =~ /^Content-Type:\s*text\/plain$/m);
ok($c[5] =~ /^foo\nbar\nbaz/m);

$r = POST 'http://www.perl.org/survey.cgi',
      [ file => [ undef, "xxy\"", Content_type => "text/html", Content => "<h1>Hello, world!</h1>" ]],
      Content_type => 'multipart/form-data';
print $r->as_string;

ok($r->content =~ /^--\S+\015\012Content-Disposition:\s*form-data;\s*name="file";\s*filename="xxy\\"/m);
ok($r->content =~ /^Content-Type: text\/html/m);
ok($r->content =~ /^<h1>Hello, world/m);

$r = POST 'http://www.perl.org/survey.cgi',
      Content_type => 'multipart/form-data',
      Content => [ file => [ undef, undef, Content => "foo"]];
#print $r->as_string;

ok($r->content !~ /filename=/);


# The POST routine can now also take a hash reference.
my %hash = (foo => 42, bar => 24);
$r = POST 'http://www.perl.org/survey.cgi', \%hash;
#print $r->as_string, "\n";
ok($r->content =~ /foo=42/);
ok($r->content =~ /bar=24/);
ok($r->content_type, "application/x-www-form-urlencoded");
ok($r->content_length, 13);

 
#
# POST for File upload
#
use HTTP::Request::Common qw($DYNAMIC_FILE_UPLOAD);

$file = "test-$$";
open(FILE, ">$file") or die "Can't create $file: $!";
for (1..1000) {
   print FILE "a" .. "z";
}
close(FILE);

$DYNAMIC_FILE_UPLOAD++;
$r = POST 'http://www.perl.org/survey.cgi',
       Content_Type => 'form-data',
       Content      => [ name  => 'Gisle Aas',
                         email => 'gisle@aas.no',
                         gender => 'm',
                         born   => '1964',
                         file   => [$file],
                       ];
print $r->as_string, "\n";

ok($r->method, "POST");
ok($r->uri->path, "/survey.cgi");
ok($r->content_type, "multipart/form-data");
ok($r->header(Content_type) =~ /boundary="?([^"]+)"?/);
$boundary = $1;
ok(ref($r->content), "CODE");

ok(length($boundary) > 10);

$code = $r->content;
my $chunk;
my @chunks;
while (defined($chunk = &$code) && length $chunk) {
   push(@chunks, $chunk);
}

unlink($file) or warn "Can't unlink $file: $!";

$_ = join("", @chunks);

print int(@chunks), " chunks, total size is ", length($_), " bytes\n";

# should be close to expected size and number of chunks
ok(abs(@chunks - 15 < 3));
ok(abs(length($_) - 26589) < 20);

$r = POST 'http://www.example.com';
ok($r->as_string, <<EOT);
POST http://www.example.com
Content-Length: 0
Content-Type: application/x-www-form-urlencoded

EOT

$r = POST 'http://www.example.com', Content_Type => 'form-data', Content => [];
ok($r->as_string, <<EOT);
POST http://www.example.com
Content-Length: 0
Content-Type: multipart/form-data; boundary=none

EOT

$r = POST 'http://www.example.com', Content_Type => 'form-data';
#print $r->as_string;
ok($r->as_string, <<EOT);
POST http://www.example.com
Content-Length: 0
Content-Type: multipart/form-data

EOT

$r = HTTP::Request::Common::DELETE 'http://www.example.com';
ok($r->method, "DELETE");

$r = HTTP::Request::Common::PUT 'http://www.example.com',
    'Content-Type' => 'application/octet-steam',
    'Content' => 'foobarbaz',
    'Content-Length' => 12;   # a slight lie
ok($r->header('Content-Length'), 12);
