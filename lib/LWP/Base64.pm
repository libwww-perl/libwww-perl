#!/usr/local/bin/perl
#
# $Id: Base64.pm,v 1.2 1995/06/12 18:16:57 aas Exp $
#

#####################################################################

package LWP::Base64;

=head1 NAME

LWP::Base64 - Base 64 encoding/decoding routines
              for HTTP Basic Authentication

=head1 SYNOPSIS

 use LWP::Base64 qw(Base64encode Base64decode);
 
 $encoded = Base64encode('Aladdin:open sesame');

 $decoded = Base64decode($encoded);

=head1 DESCRIPTION

This package provides function to encode and decode strings into
Base64 encoding specified in RFC 1521 section 5.2, and used by HTTP
1.0 Basic Authentication.

=head1 AUTHORS

Martijn Koster <m.koster@nexor.co.ukl> and Joerg Reichelt
<j.reichelt@nexor.co.uk>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF THE AUTHORS HAVE BEEN ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE. 

=head1 BUGS

Didn't someone else write one of these?

This is basically C code; can clever use of pack/unpack not
reduce this code?

No performance analysis done on this at all. The index in 
Base64decode_aux might be faster with a hash table or 
indexable array.

Doesn't honour the "The output stream (encoded bytes) must be
represented in lines of no more than 76 characters each" yet,
as I'm not at all sure what WWW servers expect...

=head1 FUNCTIONS

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(Base64encode Base64decode);

$Version = '$Revision: 1.2 $';
($Version) = $Version =~ /(\d+\.\d+)/;

@Base64CharacterSet  = ('A'..'Z', 'a'..'z', 0..9, '+', '/');
$Base64CharacterString = join('', @Base64CharacterSet);

=head2 Base64encode()

Encode a string using Base64.

=cut

sub Base64encode {
    my $str = shift;
    $str =~ s/(.{1,3})/_Base64encode_aux($1)/ge;    
#   $str =~ s/(.{76})/$1\n/g; # rfc 1521 dictates maximum of 76 chars
    $str;
}

# _Base64encode_aux()
#
# Private helper function for Base64encode.
#
# Takes a string of three characters, and encodes
# it into four characters by taking 6 bits at a
# time, and using a dictionary @chars
#
sub _Base64encode_aux {
    my $threes = shift;
    @threes = split('', $threes);

    # can have 1, 2, or three characters,
    # missing characters are undefined.

    my $result = '';

    $unpacked[0] = (unpack('C', $threes[0]))[0];

    my $s0 = ($unpacked[0] & 0xfc) >> 2;
    $result .= $Base64CharacterSet[$s0];

    my $s1 = ($unpacked[0] & 0x03) << 4;

    if(! defined $threes[1]) {
        $result .= $Base64CharacterSet[$s1] . '==';
    }
    else {
        $unpacked[1] = (unpack('C', $threes[1]))[0];

        my $s2 = ($unpacked[1] & 0xf0) >> 4;
        my $s3 = ($unpacked[1] & 0x0f) << 2;

        $result .= $Base64CharacterSet[$s1 | $s2];

        if(!defined $threes[2]) {
            $result .= $Base64CharacterSet[$s3] . '=';
        }
        else {
            $unpacked[2] = (unpack('C', $threes[2]))[0];

            my $s4 = ($unpacked[2] & 0xc0) >> 6;
            my $s5 = ($unpacked[2] & 0x3f);

            $result .= $Base64CharacterSet[$s3 | $s4];
            $result .= $Base64CharacterSet[$s5];
        }
    }

    $result;
}

=head2 Base64decode()

Decode a string encoded using Base64.
Whitespace in the string is ignored.
The routine will die on illegal characters.

=cut

sub Base64decode {
    my $str = shift;
    $str =~ s/\s+//g;
    $str =~ s/(.{2,4})/_Base64decode_aux($1)/ge;
    $str;
}

sub _Base64decode_aux {
    my $encoded = shift;
    my $result = '';
    my @encoded = split('', $encoded);

    my $i0 = index($Base64CharacterString, $encoded[0]);
    my $i1 = index($Base64CharacterString, $encoded[1]);

    my $error = 'Error in Base64 encoding';

    die "$error: invalid character '$encoded[0]'" if ($i0 < 0);
    die "$error: invalid character '$encoded[1]'" if ($i1 < 0);

    my $v0 = $i0 << 2 | ($i1 & 0x30) >> 4;
    $result .= pack('C', $v0);

    if(! defined $encoded[2] || $encoded[2] eq '=') {
        if($i1 & 0xf) {
            die "$error: bits set in remaining part of 2nd character";
        }
    }
    else {
        my $i2 = index($Base64CharacterString, $encoded[2]);

        die "$error: invalid character '$encoded[2]'" if ($i2 < 0);

        my $v1 = ($i1 & 0x0f) << 4 | ($i2 & 0x3c) >> 2;
        $result .= pack('C', $v1);

        if(! defined $encoded[3] || $encoded[3] eq '=') {
            if($i2 & 0x03) {
                die "$error: bits set in remaining part of 3rd character";
            }
        }
        else {
            my $i3 = index($Base64CharacterString, $encoded[3]);

            die "$error: invalid character '$encoded[3]'" if ($i3 < 0);

            my $v2 = ($i2 & 0x03) << 6 | $i3;
            $result .= pack('C', $v2);
        }
    }

    $result;
}


#####################################################################
#
# S E L F   T E S T   S E C T I O N
#
#####################################################################
#
# If we're not use'd or require'd execute self-test.
# Handy for regression testing and as a quick reference :)
#
# Test is kept behind __END__ so it doesn't take uptime
# and memory  unless explicitly required. If you're working
# on the code you might find it easier to comment out the
# eval and __END__ so that error line numbers make more sense.

package main;

eval join('',<DATA>) || die $@ unless caller();

1;

__END__

&encode_test;
&decode_test;
print "LWP::Base64 ", $LWP::Base64::Version, " ok\n";

sub encode_test {

    print "encode test\n";

    my @encode_tests = (
        ['a'   => 'YQ=='],
        ['aa'  => 'YWE='], 
        ['aaa' => 'YWFh'],

        ['aaa' => 'YWFh'],
        ['aaa' => 'YWFh'],
        ['aaa' => 'YWFh'],

                 # from HTTP spec
        ['Aladdin:open sesame' => 'QWxhZGRpbjpvcGVuIHNlc2FtZQ=='],

        ['a' x 100 => 'YWFh' x 33 . 'YQ=='],
    );

    my $testno = 1;
    for $test (@encode_tests) {
        my($plain, $expected) = ($$test[0], $$test[1]);

        my $encoded = &LWP::Base64::Base64encode($plain);
        if ($encoded ne $expected) {
            die "test $testno ($plain): expected $expected, got $encoded\n";
        }
        my $decoded = &LWP::Base64::Base64decode($encoded);
        if ($decoded ne $plain) {
            die "test $testno ($plain): expected $expected, got $encoded\n";
        }

        print "  test $testno ok\n";
        $testno++;
    }
}

sub decode_test {

    print "decode test:\n";

    my @decode_tests = (
        ['YWE='   => 'aa'],
        [' YWE='  => 'aa'],
        ['Y WE='  => 'aa'],
        ['YWE= '  => 'aa'],
        ['Y W E=' => 'aa'],
    );

    my $testno = 1;
    for $test (@decode_tests) {
        my($encoded, $expected) = ($$test[0], $$test[1]);

        my $decoded = &LWP::Base64::Base64decode($encoded);
        if ($decoded ne $expected) {
            die "test $testno ($encoded): expected $expected, got $decoded\n";
        }
        print "  test $testno ok\n";
        $testno++;
    }
}
