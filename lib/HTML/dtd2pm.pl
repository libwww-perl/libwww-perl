#!/local/bin/perl -w

# This is a crude hack to parse the HTML DTDs in order to generate
# a HTML parser in perl.  The output is a perl structure that describe
# the same releationships as the DTD.  This script in known to work
# on the HTML 3.2 of Tuesday 23-Apr-96, but it might need some
# tweaks if that DTD use more sophisticated SGML features.
#
# Author: Gisle Aas
#
# $Id: dtd2pm.pl,v 1.2 1996/05/26 10:33:38 aas Exp $
#
# Disclaimer: I am not an SGML expert and don't really understand how
# to read those damn DTDs.

$VERBOSE = 0;

undef($/);
$DTD = "HTML3.2.dtd";

open(DTD, $DTD) or die "Can't open $DTD: $!";
$_ = <DTD>;
close(DTD);
$| = 1;

($intro) = /<!\s*--(.*?)--\s*>/s;

#print $_;

while (s/^\s*<!//) {
   if (s/^(\[.*?\])>//s) {  # ignore <![......]> constructs
	#print "Skip: <!$1>\n";
        next;
   }

   s/^([^>]*)>//;
   $c = $1;
   while (1) {
      $c =~ s/--.*?--//gs;  # remove comments
      if ($c =~ /--/) {
          # we really did read to little
          s/([^>]*)>//;
          $c .= $1
      } else {
          last;
      }
   }

   $c =~ s/^\s+//;
   $c =~ s/\s+$//;
   next unless length $c;  # only comments

   #$c =~ s/\s+/ /g;

   print "C: $c\n" if $VERBOSE;
   while (s/^\s*([^\s<]+)//) {
      print "T: $1\n" if $VERBOSE;
   }

   if ($c =~ /^ENTITY\s+(%\s*)?(\S+)\s+(.*)/is) {
       my($percent, $key, $val) = ($1, lc($2), $3);
       if ($percent) {
          $key = "%$key";
       } else {
          $key = "&$key";
          $val =~ s/CDATA\s+//;
       }
       $val =~ s/^"//s;
       $val =~ s/"$//s;
       $val =~ s/(%[\w\.\-]+);?/$entity{lc $1} || $1/eg;

       $entity{$key} = $val;
       #print "E: $key => $val\n";
   } else {
       # Expand entities
       $c =~ s/(%[\w\.\-]+);?/$entity{lc $1} || $1/eg;
       #print "C: $c\n"
       if ($c =~ /^ELEMENT\s+\(([^\)]+)\)\s+([-O])\s+([-O])\s+(.*)/is) {
          my($elems, $start, $stop, $content) = (lc $1, $2, $3, lc $4);
	  for ($elems, $content) {
	      s/\s+//g;
	  }
          $content =~ s/(\#pcdata)\b/\U$1/g;
          for $elem (split(/\|/, $elems)) {
             $element{$elem} = [$start, $stop, $content];
          }
       } elsif ($c =~ /^ELEMENT\s+(\S+)\s+([-O])\s+([-O])\s+(.*)/is) {
          my($elem, $start, $stop, $content) = (lc $1, $2, $3, lc $4);
          $content =~ s/\s+//g;
          $content =~ s/(\#pcdata)\b/\U$1/g;
	  $element{$elem} =  [$start, $stop, $content];

       } elsif ($c =~ s/^ATTLIST\s+\(([^\)]+)\)\s+//) {
          my $elems = lc $1;
	  $elems =~ s/\s+//g;
          my $attrs = parse_attrs($c);
          for $elem (split(/\|/, $elems)) {
	      $attr{$elem} = $attrs;
          }
       } elsif ($c =~ s/^ATTLIST\s+(\S+)\s+//) {
          $attr{lc $1} = parse_attrs($c);
       } else {
          print STDERR "?: $c\n";
       }
   }
}

# is there anything left?
s/^\s+//;
print STDERR "?: ", substr($_, 0, 200), "\n" if length $_;


# At this point, we have initialized the %element, %attr arrays.
# Their content is as described here:
#
#  %element = ( tag => [ $start, $end, $content ],
#               ...
#             );
#
#  %attr    = ( tag => {
#                         attr => [ $values, $default ],
#                         ...
#                      },
#               ...
#             );
#
# The %entity hash is also available, but should not be of much use
# now.


# Dump result to stdout so that it is useful to a perl program.

print "##### Do not edit!!  Auto-generated from $DTD\n\n";

print "package HTML::DTD;  # <!DOCTYPE HTML PUBLIC \"$entity{'%html.version'}\">\n\n";
$intro =~ s/^[ \t]*/\# /gm;
print "$intro\n\n";


my @all_tags = sort keys %element;
my @empty = ();
my @optional_end_tag = ();
my @optional_start_tag = ();
for (@all_tags) {
   push(@empty, $_) if $element{$_}[2] eq 'empty';
   push(@optional_end_tag, $_) if $element{$_}[2] ne 'empty' and
                                  $element{$_}[1] ne '-';
   push(@optional_start_tag, $_) if $element{$_}[0] ne '-';
}

print "\@all_tags = qw(@all_tags);\n";
print "\@empty = qw(@empty);\n";
print "\@optional_end_tag = qw(@optional_end_tag);\n";
print "\@optional_start_tag = qw(@optional_start_tag);\n";
print <<'EOT';


# The %elem hash is indexed by lowercase tag identifiers.  Each element is
# an anonymouse hash with the following values:
#
#    'content': Describes the content that can be present within this
#               element.  This value is missing if the element should
#               always be empty.
#
#    'optend':  True if the end tag for this element is optional
#
#    'attr':    A hash that describes the attributes of this element.
#               Each element in this hash is a anonymous array with
#               two values: allowed values; default value
#    
EOT

print "\n%elem = (\n";

@boolean_attr = ();

for (@all_tags) {
   my $e = $_;
   $e = "'$e'" if $e eq 'tr' || $e eq 'link' || $e eq 'sub';  # these are perl keywords
   printf "%-4s => {\n", $e;
   print "\t  content => '$element{$_}[2]',\n" if $element{$_}[2] ne 'empty';
   print "\t  optend => 1,\n" if $element{$_}[1] ne '-';
   if (exists $attr{$_}) {
       print "\t  attr => {\n";
       for $a (sort keys %{$attr{$_}}) {
	   my @a = @{$attr{$_}{$a}};
	   print "\t\t\t$a => [", join(",", map {qq("$_")} @a), "],\n";
	   push(@boolean_attr, "$_\t=> '$a'") if $a eq $attr{$_}{$a}[0];
       }
       print "\t\t  },\n";
   }
   print "\t},\n";
}

print ");\n";

print "\n\n\%boolean_attr = (\n";
for (@boolean_attr) {
    print " $_,\n";
}
print ");\n";

print "\n1;\n";


exit;
#-----------------------------------------------------------------------

sub parse_attrs  # Parse the <!ATTLIST elem ...> content
{
    my $a = shift;
    my %a = ();
    #print "---$a---\n";
    while ($a =~ /\S/) {
	$a =~ s/^\s*(\S+)\s*//;
	my $key = $1;
	my ($val, $default);
	if ($a =~ s/^\(([^\)]+)\)//) {
	    $val = $1;
            $val =~ s/\s+//g;
	} elsif ($a =~ s/^(\S+)//) {
	    $val = $1;
	} else {
	    die "Missing values";
	}
        $val = lc($val) unless $val =~ /^[A-Z]+$/;
        $val =~ s/^"(.*)"$/$1/;
	
        $a =~ s/^\s+//;
        if ($a =~ s/^(\#FIXED\s+\'[^\']+\')//) {
	    $default = $1;
	} elsif ($a =~ s/^(\S+)//) {
	    $default = $1;
	} else {
	    die "Missing default";
	}
	$default = lc($default) unless $default =~ /^[\#\"]/;
        $default =~ s/^"(.*)"$/$1/;

	$a{$key} = [$val, $default];
    }
    \%a;
}
