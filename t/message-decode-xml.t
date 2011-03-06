# https://rt.cpan.org/Public/Bug/Display.html?id=52572

use strict;
use warnings;

use Test::More;
plan tests => 2;

use Encode           qw( encode );
use HTTP::Headers    qw( );
use HTTP::Response   qw( );
use PerlIO::encoding qw( );

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

    my $headers = HTTP::Headers->new(Content_Type => "application/xml");
    my $response = HTTP::Response->new(200, "OK", $headers, $file);

    is($response->decoded_content, qq(<?xml version="1.0"?>\n<root>\x{c9}ric</root>\n), $enc);
}
