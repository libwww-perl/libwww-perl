#!/local/bin/perl -w

use MIME::QuotedPrint;

$x73 = "x" x 73;

@tests =
  (
   # plain ascii should not be encoded
   ["quoted printable"  =>
    "quoted printable"],

   # 8-bit chars should be encoded
   ["våre kjære norske tegn bør æres" =>
    "v=E5re kj=E6re norske tegn b=F8r =E6res"],

   # trailing space should be encoded
   ["  " => "=20=20"],
   ["\tt\t" => "\tt=09"],
   ["test  \ntest\n\t \t \n" => "test=20=20\ntest\n=09=20=09=20\n"],

   # "=" is special an should be decoded
   ["=\n" => "=3D\n"],
   ["\0\xff" => "=00=FF"],

   # Very long lines should be broken (not more than 76 chars
   ["The Quoted-Printable encoding is intended to represent data that largly consists of octets that correspond to printable characters in the ASCII character set." =>
    "The Quoted-Printable encoding is intended to represent data that largly cons=
ists of octets that correspond to printable characters in the ASCII characte=
r set."
    ],

   # Not allowed to break =XX escapes using soft line break
   ["$x73=a" => "$x73=3D=\na"],
   ["$x73 =a" => "$x73 =\n=3Da"],
   ["$x73  =a" => "$x73 =\n =3Da"],
   ["$x73=" => "$x73=3D"],
   ["$x73 =" => "$x73 =\n=3D"],
   ["$x73  =" => "$x73 =\n =3D"],
);

$notests = @tests;
print "1..$notests\n";

$testno = 0;
for (@tests) {
    $testno++;
    ($plain, $encoded) = @$_;
    $x = encode_qp($plain);
    if ($x ne $encoded) {
	print "Encode test failed\n";
	print "Got:      '$x'\n";
	print "Expected: '$encoded'\n";
	print "not ok $testno\n";
	next;
    }
    $x = decode_qp($encoded);
    if ($x ne $plain) {
	print "Decode test failed\n";
	print "Got:      '$x'\n";
	print "Expected: '$plain'\n";
	print "not ok $testno\n";
	next;
    }
    print "ok $testno\n";
}
