use LWP::Base64 qw(Base64encode Base64decode);

print "1..13\n";

$testno = 1;

&encodeTest;
&decodeTest;

print "LWP::Base64 ", $LWP::Base64::VERSION, " tested ok\n";

sub encodeTest
{
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

    for $test (@encode_tests) {
        my($plain, $expected) = ($$test[0], $$test[1]);

        my $encoded = Base64encode($plain);
        if ($encoded ne $expected) {
            die "test $testno ($plain): expected $expected, got $encoded\n";
        }
        my $decoded = Base64decode($encoded);
        if ($decoded ne $plain) {
            die "test $testno ($plain): expected $expected, got $encoded\n";
        }

        print "ok $testno\n";
        $testno++;
    }
}

sub decodeTest
{
    print "decode test:\n";

    my @decode_tests = (
        ['YWE='   => 'aa'],
        [' YWE='  => 'aa'],
        ['Y WE='  => 'aa'],
        ['YWE= '  => 'aa'],
        ['Y W E=' => 'aa'],
    );

    for $test (@decode_tests) {
        my($encoded, $expected) = ($$test[0], $$test[1]);

        my $decoded = Base64decode($encoded);
        if ($decoded ne $expected) {
            die "test $testno ($encoded): expected $expected, got $decoded\n";
        }
        print "ok $testno\n";
        $testno++;
    }
}
