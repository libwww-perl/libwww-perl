#!/local/bin/perl -w

require URI::URL;
use URI::Escape;  # imports uri_escape() and uri_unescape()

package URI::URL::_generic;

use Carp;

# _expect()
#
# Handy low-level object method tester. See test code at end.
#
sub _expect {
    my($self, $method, $expect, @args) = @_;
    my $result = $self->$method(@args);
    $expect = 'UNDEF' unless defined $expect;
    $result = 'UNDEF' unless defined $result;
    return 1 if $expect eq $result;
    warn "'$self'->$method(@args) = '$result' " .
                "(expected '$expect')\n";
    $self->print_on('STDERR');
    confess "Test Failed";
}


package main;

$| = 1;

print "1..6\n";  # for Test::Harness

# Do basic tests first.
# Dies if an error has been detected, prints "ok" otherwise.

print "Self tests for URI::URL version $URI::URL::VERSION...\n";

&scheme_parse_test;
print "ok 1\n";

&parts_test;
print "ok 2\n";

&escape_test;
print "ok 3\n";

&newlocal_test;
print "ok 4\n";

&absolute_test;
print "ok 5\n";

URI::URL::strict(0);
$u = new URI::URL "myscheme:something";
print $u->as_string, " works after URI::URL::strict(0)\n";
$u = undef;
print "ok 6\n";

print "URI::URL version $URI::URL::VERSION ok\n";
exit 0;




#####################################################################
#
# scheme_parse_test()
#
# test parsing and retrieval methods

sub scheme_parse_test {

    print "scheme_parse_test:\n";

    $tests = {
        'hTTp://web1.net/a/b/c/welcome#intro'
        => {    'scheme'=>'http', 'host'=>'web1.net', 'port'=>80,
                'path'=>'a/b/c/welcome', 'frag'=>'intro',
                'query'=>undef,
                'as_string'=>'http://web1.net/a/b/c/welcome#intro',
                'full_path' => '/a/b/c/welcome' },

        'http://web:1/a?query+text'
        => {    'scheme'=>'http', 'host'=>'web', 'port'=>1,
                'path'=>'a', 'frag'=>undef, 'query'=>'query text' },

        'http://web.net/'
        => {    'scheme'=>'http', 'host'=>'web.net', 'port'=>80,
                'path'=>'', 'frag'=>undef, 'query'=>undef,
                'full_path' => '/',
                'as_string' => 'http://web.net/' },

        'http://web.net'
        => {    'scheme'=>'http', 'host'=>'web.net', 'port'=>80,
                'path'=>'', 'frag'=>undef, 'query'=>undef,
                'full_path' => '/',
                'as_string' => 'http://web.net/' },

        'ftp://usr:pswd@web:1234/a/b;type=i'
        => {    'host'=>'web', 'port'=>1234, 'path'=>'a/b',
                'user'=>'usr', 'password'=>'pswd',
                'params'=>'type=i',
                'as_string'=>'ftp://usr:pswd@web:1234/a/b;type=i' },

        'ftp://host/a/b'
        => {    'host'=>'host', 'port'=>21, 'path'=>'a/b',
                'user'=>'anonymous',
                'as_string'=>'ftp://host/a/b' },

        'file://host/fseg/fs?g/fseg'
        # don't escape ? for file: scheme
        => {    'host'=>'host', 'path'=>'fseg/fs?g/fseg',
                'as_string'=>'file://host/fseg/fs?g/fseg' },

        'gopher://host'
        => {     'gtype'=>'1', 'as_string' => 'gopher://host/', },

        'gopher://gopher/2a_selector'
        => {    'gtype'=>'2', 'selector'=>'a_selector',
                'as_string' => 'gopher://gopher/2a_selector', },

        'mailto:libwww-perl@ics.uci.edu'
        => {    'encoded822addr'=>'libwww-perl@ics.uci.edu',
                'as_string'     => 'mailto:libwww-perl@ics.uci.edu', },

        'news:*'                 
        => {    'grouppart'=>'*' },
        'news:comp.lang.perl' 
        => {    'group'=>'comp.lang.perl' },
        'news:perl-faq/module-list-1-794455075@ig.co.uk'
        => {    'article'=>
                    'perl-faq/module-list-1-794455075@ig.co.uk' },

        'nntp://news.com/comp.lang.perl/42'
        => {    'group'=>'comp.lang.perl', 'digits'=>42 },

        'telnet://usr:pswd@web:12345/'
        => {    'user'=>'usr', 'password'=>'pswd' },

        'wais://web.net/db'       
        => { 'database'=>'db' },
        'wais://web.net/db?query' 
        => { 'database'=>'db', 'query'=>'query' },
        'wais://usr:pswd@web.net/db/wt/wp'
        => {    'database'=>'db', 'wtype'=>'wt', 'wpath'=>'wp',
                'password'=>'pswd' },
    };

    foreach $url_str (sort keys %$tests ){
        print "Testing '$url_str'\n";
        my $url = new URI::URL $url_str;
        my $tests = $tests->{$url_str};
        while( ($method, $exp) = each %$tests ){
            $exp = 'UNDEF' unless defined $exp;
	    $url->_expect($method, $exp);
        }
    }
}


#####################################################################
#
# parts_test()          (calls netloc_test test)
#
# Test individual component part access functions
#
sub parts_test {
    print "parts_test:\n";

    # test storage part access/edit methods (netloc, user, password,
    # host and port are tested by &netloc_test)

    $url = new URI::URL 'file://web/orig/path';
    $url->scheme('http');
    $url->path('1info');
    # $url->query('key+word');  was wrong, + is 'escaped' form
    $url->query('key words');
    $url->frag('this');
    $url->_expect('as_string', 'http://web/1info?key+words#this');

    &netloc_test;
    &port_test;
                  
    $url->query(undef);
    $url->_expect('query', undef);

    $url = new URI::URL 'gopher://gopher/';
    $url->port(33);
    $url->gtype("3");
    $url->selector("sel");
    $url->_expect('as_string', 'gopher://gopher:33/3%09sel');
    
}

#
# netloc_test()
#
# Test automatic netloc synchronisation
#
sub netloc_test {
    print "netloc_test:\n";

    my $url = new URI::URL 'ftp://anonymous:p%61ss@hst:12345';
    $url->_expect('user', 'anonymous');
    $url->_expect('password', 'pass');
    $url->_expect('host', 'hst');
    $url->_expect('port', 12345);
    $url->_expect('netloc', 'anonymous:pass@hst:12345');

    $url->user('nemo');
    $url->password('p2');
    $url->host('hst2');
    $url->port(2);
    $url->_expect('netloc', 'nemo:p2@hst2:2');

    $url->user(undef);
    $url->password(undef);
    $url->port(undef);
    $url->_expect('netloc', 'hst2');
}

#
# port_test()
#
# Test port behaviour
#
sub port_test {
    print "port_test:\n";

    $url = URI::URL->new('http://foo/root/dir/');
    my $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq
        'http://foo/root/dir/';

    $url->port(8001);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 8001;
    die "Wrong string" unless $url->as_string eq 
        'http://foo:8001/root/dir/';

    $url->port(80);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq 
        'http://foo/root/dir/';

    $url->port(8001);
    $url->port(undef);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq 
        'http://foo/root/dir/';
}


#####################################################################
#
# escape_test()
#
# escaping functions

sub escape_test {
    print "escape_test:\n";

    # supply escaped URL
    $url = new URI::URL 'http://web/this%20has%20spaces';
    # check component is unescaped
    $url->_expect('path', 'this has spaces');

    # modify the unescaped form
    $url->path('this ALSO has spaces');
    # check whole url is escaped
    $url->_expect('as_string',
                  'http://web/this%20ALSO%20has%20spaces');

    # now make 'A' an unsafe character :-)
    $url->unsafe('A\x00-\x20"#%;<>?\x7F-\xFF');
    $url->_expect('as_string',
                  'http://web/this%20%41LSO%20has%20spaces');

    $url = new URI::URL uri_escape('http://web/try %?#" those');
    $url->_expect('as_string', 
                  'http://web/try%20%25%3F%23%22%20those');

    my $all = pack('c*',0..255);
    my $esc = uri_escape($all);
    my $new = uri_unescape($esc);
    die "uri_escape->uri_unescape mismatch" unless $all eq $new;

    # test escaping uses uppercase (preferred by rfc1837)

    $url = new URI::URL 'file://h/';
    $url->path(chr(0x7F));
    $url->_expect('as_string', 'file://h/%7F');

    # reserved characters differ per scheme

    ## XXX is this '?' allowed to be unescaped
    $url = new URI::URL 'file://h/test?ing';
    $url->_expect('path', 'test?ing');

    $url = new URI::URL 'file://h/';
    $url->path('question?mark');
    $url->_expect('as_string', 'file://h/question?mark');

    # need more tests here
}


#####################################################################
#
# newlocal_test()
#

sub newlocal_test {
    print "newlocal_test:\n";
 
    my $savedir =`/bin/pwd`;  # we don't use Cwd.pm because we want to check
                              # that it get require'd corretly by URL.pm
    chomp $savedir;
    
    # cwd
    chdir('/tmp') or die $!;
    my $dir = `/bin/pwd`;
    chomp $dir;
    $url = newlocal URI::URL;
    $url->_expect('as_string', "file:$dir/");

    # absolute dir
    chdir('/') or die $!;
    $url = newlocal URI::URL '/usr/';
    $url->_expect('as_string', 'file:/usr/');

    # absolute file
    $url = newlocal URI::URL '/vmunix';
    $url->_expect('as_string', 'file:/vmunix');

    # relative file
    chdir('/tmp') or die $!;
    $dir = `/bin/pwd`;
    chomp $dir;
    $url = newlocal URI::URL 'foo';
    $url->_expect('as_string', "file:$dir/foo");

    # relative dir
    chdir('/tmp') or die $!;
    $dir = `/bin/pwd`;
    chomp $dir;
    $url = newlocal URI::URL 'bar/';
    $url->_expect('as_string', "file:$dir/bar/");

    # 0
    chdir('/') or die $!;
    $url = newlocal URI::URL '0';
    $url->_expect('as_string', 'file:/0');

    chdir($savedir) or die $!;
}


#####################################################################
#
# absolute_test()
#
sub absolute_test {

    print "Test relative/absolute URI::URL parsing:\n";

    # Tests from draft-ietf-uri-relative-url-06.txt
    # Copied verbatim from the draft, parsed below

    @URI::URL::g::ISA = qw(URI::URL::_generic); # for these tests

    my $base = 'http://a/b/c/d;p?q#f';

    $absolute_tests = <<EOM;
5.1.  Normal Examples

      g:h        = <URL:g:h>
      g          = <URL:http://a/b/c/g>
      ./g        = <URL:http://a/b/c/g>
      g/         = <URL:http://a/b/c/g/>
      /g         = <URL:http://a/g>
      //g        = <URL:http://g>
      ?y         = <URL:http://a/b/c/d;p?y>
      g?y        = <URL:http://a/b/c/g?y>
      g?y/./x    = <URL:http://a/b/c/g?y/./x>
      #s         = <URL:http://a/b/c/d;p?q#s>
      g#s        = <URL:http://a/b/c/g#s>
      g#s/./x    = <URL:http://a/b/c/g#s/./x>
      g?y#s      = <URL:http://a/b/c/g?y#s>
      ;x         = <URL:http://a/b/c/d;x>
      g;x        = <URL:http://a/b/c/g;x>
      g;x?y#s    = <URL:http://a/b/c/g;x?y#s>
      .          = <URL:http://a/b/c/>
      ./         = <URL:http://a/b/c/>
      ..         = <URL:http://a/b/>
      ../        = <URL:http://a/b/>
      ../g       = <URL:http://a/b/g>
      ../..      = <URL:http://a/>
      ../../     = <URL:http://a/>
      ../../g    = <URL:http://a/g>

5.2.  Abnormal Examples

   Although the following abnormal examples are unlikely to occur
   in normal practice, all URL parsers should be capable of resolving
   them consistently.  Each example uses the same base as above.

   An empty reference resolves to the complete base URL:

      <>         = <URL:http://a/b/c/d;p?q#f>

   Parsers must be careful in handling the case where there are more
   relative path ".." segments than there are hierarchical levels in
   the base URL's path.  Note that the ".." syntax cannot be used to
   change the <net_loc> of a URL.

     ../../../g = <URL:http://a/../g>
     ../../../../g = <URL:http://a/../../g>

   Similarly, parsers must avoid treating "." and ".." as special
   when they are not complete components of a relative path.

      /./g       = <URL:http://a/./g>
      /../g      = <URL:http://a/../g>
      g.         = <URL:http://a/b/c/g.>
      .g         = <URL:http://a/b/c/.g>
      g..        = <URL:http://a/b/c/g..>
      ..g        = <URL:http://a/b/c/..g>

   Less likely are cases where the relative URL uses unnecessary or
   nonsensical forms of the "." and ".." complete path segments.

      ./../g     = <URL:http://a/b/g>
      ./g/.      = <URL:http://a/b/c/g/>
      g/./h      = <URL:http://a/b/c/g/h>
      g/../h     = <URL:http://a/b/c/h>

   Finally, some older parsers allow the scheme name to be present in
   a relative URL if it is the same as the base URL scheme.  This is
   considered to be a loophole in prior specifications of partial
   URLs [1] and should be avoided by future parsers.

      http:g     = <URL:http:g>
      http:      = <URL:http:>
EOM
    # convert text to list like
    # @absolute_tests = ( ['g:h' => 'g:h'], ...)

    for $line (split("\n", $absolute_tests)) {
        next unless $line =~ /^\s{6}/;
        if ($line =~ /^\s+(\S+)\s*=\s*<URL:([^>]*)>/) {
            my($rel, $abs) = ($1, $2);
            $rel = '' if $rel eq '<>';
            push(@absolute_tests, [$rel, $abs]);
        }
        else {
            warn "illegal line '$line'";
        }
    }

    # add some extra ones for good measure

    push(@absolute_tests, ['x/y//../z' => 'http://a/b/c/x/y/z'],
                          ['1'         => 'http://a/b/c/1'    ],
                          ['0'         => 'http://a/b/c/0'    ],
                          ['/0'        => 'http://a/0'        ],
        );

    print "  Relative    +  Base  =>  Expected Absolute URL\n";
    print "================================================\n";
    for $test (@absolute_tests) {
        my($rel, $abs) = @$test;
        my $abs_url = new URI::URL $abs;
        my $abs_str = $abs_url->as_string;

        printf("  %-10s  +  $base  =>  $abs\n", $rel);
        my $u   = new URI::URL $rel, $base;
        my $got = $u->abs;
        $got->_expect('as_string', $abs_str);
    }

    # bug found and fixed in 1.9 by "J.E. Fritz" <FRITZ@gems.vcu.edu>

    my $base = new URI::URL 'http://host/directory/file';
    my $relative = new URI::URL 'file', $base;
    my $result = $relative->abs;

    my ($a, $b) = ($base->path, $result->path);
        die "'$a' and '$b' should be the same" unless $a eq $b;

    # Counter the expectation of least surprise,
    # section 6 of the draft says the URL should
    # be canonicalised, rather than making a simple
    # substitution of the last component.
    # Better doublecheck someone hasn't "fixed this bug" :-)

    my $base = new URI::URL 'http://host/dir1/../dir2/file';
    my $relative = new URI::URL 'file', $base;
    my $result = $relative->abs;
    die 'URL not canonicalised' unless $result eq 'http://host/dir2/file';

    print "absolute test ok\n";
}
