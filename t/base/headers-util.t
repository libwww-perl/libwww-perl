use strict;
use HTTP::Headers::Util qw(split_header_words join_header_words);

my @tests = (

   ["foo"                     => "foo"],
   ["foo=bar"                 => "foo=bar"],
   ["   foo   "               => "foo"],
   ["foo="                    => 'foo=""'],
   ["foo=bar bar=baz"         => "foo=bar; bar=baz"],
   ["foo=bar;bar=baz"         => "foo=bar; bar=baz"],
   ['foo bar baz'             => "foo; bar; baz"],
   ['foo="\"" bar="\\\\"'     => 'foo="\""; bar="\\\\"'],
   ['foo,,,bar'               => 'foo, bar'],
   ['foo=bar,bar=baz'         => 'foo=bar, bar=baz'],

   ['text/html; charset=iso-8859-1' =>
    'text/html; charset="iso-8859-1"'],

   ['foo="bar"; port="80,81"; discard, bar=baz' =>
    'foo=bar; port="80,81"; discard, bar=baz'],

   ['Basic realm="\"foo\\\\bar\""' =>
    'Basic; realm="\"foo\\\\bar\""'],
);

print "1.." .  @tests . "\n";

my $testno = 1;

for (@tests) {
   my($arg, $expect) = @$_;
   my @arg = ref($arg) ? @$arg : $arg;

   my $res = join_header_words(split_header_words(@arg));
   if ($res ne $expect) {
       print "\nUnexpected result: '$res'\n";
       print "         Expected: '$expect'\n";
       print "  when parsing '", join(", ", @arg), "'\n";
       eval {
	   require Data::Dumper;
           my @p = split_header_words(@arg);
           print Data::Dumper::Dumper(\@p);
       };
       print "not ";
   }
   print "ok ", $testno++, "\n";
}
