# https://rt.cpan.org/Public/Bug/Display.html?id=52572

use strict;
use warnings;

use Test::More;
if (eval "require XML::Simple; XML::Simple->import(qw(XMLin)); 1;") {
    plan tests => 4;
}
else {
    plan skip_all => "Need XML::Simple";
}

use Encode           qw( encode );
use HTTP::Headers    qw( );
use HTTP::Response   qw( );
use PerlIO::encoding qw( );

sub check {
    my ($file, $test) = @_;
    if (!eval {
	my $x = XMLin($file, keep_root => 1);
	my $name = $x->{root};
	is($name, "\x{C9}ric", $test);
	1;
    }) {
	fail($test)
	    or diag("died with $@");
    }
}

{
    my $builder = Test::More->builder;
    local $PerlIO::encoding::fallback = Encode::PERLQQ();
    binmode $builder->output,         ":encoding(US-ASCII)";
    binmode $builder->failure_output, ":encoding(US-ASCII)";
    binmode $builder->todo_output,    ":encoding(US-ASCII)";
}

for my $enc (qw( UTF-8 UTF-16le )) {
    my $file = encode($enc,
	($enc =~ /^UTF-/ ? "\x{FEFF}" : "") .
	qq{<?xml version="1.0" encoding="$enc"?>\n} .
	qq{<root>\x{C9}ric</root>\n}
    );

    check($file, "$enc direct");

    my $headers = HTTP::Headers->new(Content_Type => "application/xml");
    my $response = HTTP::Response->new(200, "OK", $headers, $file);

    check($response->decoded_content(), "$enc from response");
}
