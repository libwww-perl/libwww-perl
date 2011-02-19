#!perl -w

use strict;
use Test;
plan tests => 14;

use HTTP::Config;

sub j { join("|", @_) }

my $conf = HTTP::Config->new;
ok($conf->empty);
$conf->add_item(42);
ok(!$conf->empty);
ok(j($conf->matching_items("http://www.example.com/foo")), 42);
ok(j($conf->remove_items), 42);
ok($conf->matching_items("http://www.example.com/foo"), 0);

$conf = HTTP::Config->new;

$conf->add_item("always");
$conf->add_item("GET", m_method => ["GET", "HEAD"]);
$conf->add_item("POST", m_method => "POST");
$conf->add_item(".com", m_domain => ".com");
$conf->add_item("secure", m_secure => 1);
$conf->add_item("not secure", m_secure => 0);
$conf->add_item("slash", m_host_port => "www.example.com:80", m_path_prefix => "/");
$conf->add_item("u:p", m_host_port => "www.example.com:80", m_path_prefix => "/foo");
$conf->add_item("success", m_code => "2xx");

use HTTP::Request;
my $request = HTTP::Request->new(HEAD => "http://www.example.com/foo/bar");
$request->header("User-Agent" => "Moz/1.0");

ok(j($conf->matching_items($request)), "u:p|slash|.com|GET|not secure|always");

$request->method("HEAD");
$request->uri->scheme("https");

ok(j($conf->matching_items($request)), ".com|GET|secure|always");

ok(j($conf->matching_items("http://activestate.com")), ".com|not secure|always");

use HTTP::Response;
my $response = HTTP::Response->new(200 => "OK");
$response->content_type("text/plain");
$response->content("Hello, world!\n");
$response->request($request);

ok(j($conf->matching_items($response)), ".com|success|GET|secure|always");

$conf->remove_items(m_secure => 1);
$conf->remove_items(m_domain => ".com");
ok(j($conf->matching_items($response)), "success|GET|always");

$conf->remove_items;  # start fresh
ok(j($conf->matching_items($response)), "");

$conf->add_item("any", "m_media_type" => "*/*");
$conf->add_item("text", m_media_type => "text/*");
$conf->add_item("html", m_media_type => "html");
$conf->add_item("HTML", m_media_type => "text/html");
$conf->add_item("xhtml", m_media_type => "xhtml");

ok(j($conf->matching_items($response)), "text|any");

$response->content_type("application/xhtml+xml");
ok(j($conf->matching_items($response)), "xhtml|html|any");

$response->content_type("text/html");
ok(j($conf->matching_items($response)), "HTML|html|text|any");
