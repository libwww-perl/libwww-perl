package HTML::Parser;

# $Id: Parser.pm,v 2.6 1997/02/21 09:32:14 aas Exp $

=head1 NAME

HTML::Parser - SGML parser class

=head1 SYNOPSIS

 require HTML::Parser;
 $p = HTML::Parser->new;  # should really a be subclass
 $p->parse($chunk1);
 $p->parse($chunk2);
 #...
 $p->eof;                 # signal end of document

 # Parse directly from file
 $p->parse_file("foo.html");
 # or
 open(F, "foo.html") || die;
 $p->parse_file(\*F);

=head1 DESCRIPTION

The C<HTML::Parser> will tokenize a HTML document when the $p->parse()
method is called.  The document to parse can be supplied in arbitrary
chunks.  Call $p->eof() the end of the document to flush any remaining
text.  The return value from parse() is a reference to the parser
object.

The $p->parse_file() method can be called to parse text from a file.
The argument can be a filename or an already opened file handle. The
return value from parse_file() is a reference to the parser object.

In order to make the parser do anything interesting, you must make a
subclass where you override one or more of the following methods as
appropriate:

=over 4

=item $self->declaration($decl)

This method is called when a I<markup declaration> has been
recognized.  For typical HTML documents, the only declaration you are
likely to find is <!DOCTYPE ...>.  The initial "<!" and ending ">" is
not part of the string passed as argument.  Comments are removed and
entities have B<not> been expanded yet.

=item $self->start($tag, $attr, $attrseq, $origtext)

This method is called when a complete start tag has been recognized.
The first argument is the tag name (in lower case) and the second
argument is a reference to a hash that contain all attributes found
within the start tag.  The attribute keys are converted to lower case.
Entities found in the attribute values are already expanded.  The
third argument is a reference to an array with the lower case
attribute keys in the original order.  The fourth argument is the
original HTML text.


=item $self->end($tag)

This method is called when an end tag has been recognized.  The
argument is the lower case tag name.

=item $self->text($text)

This method is called when plain text in the document is recognized.
The text is passed on unmodified and might contain multiple lines.
Note that for efficiency reasons entities in the text are B<not>
expanded.  You should call HTML::Entities::decode($text) before you
process the text any further.

=item $self->comment($comment)

This method is called as comments are recognized.  The leading and
trailing "--" sequences have been stripped off the comment text.

=back

The default implementation of these methods does nothing, I<i.e.,> the
tokens are just ignored.

There is really nothing in the basic parser that is HTML specific, so
it is likely that the parser can parse many kinds of SGML documents,
but SGML has many obscure features (not implemented by this module)
that prevent us from renaming this module as C<SGML::Parse>.

=head1 BUGS

You can instruct the parser to parse comments the way Netscape does it
by calling the netscape_buggy_comment() method with a TRUE argument.
This means that comments will always be terminated by the first
occurence of "-->".

=head1 SEE ALSO

L<HTML::TreeBuilder>, L<HTML::HeadParser>, L<HTML::Entities>

=head1 COPYRIGHT

Copyright 1996 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut


use strict;

use HTML::Entities ();
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);


sub new
{
    my $class = shift;
    my $self = bless { '_buf'              => '',
		       '_netscape_comment' => 0,
		     }, $class;
    $self;
}

# How does Netscape do it: It parse <xmp> in the depreceated 'literal'
# mode, i.e. no tags are recognized until a </xmp> is found.
# 
# <listing> is parsed like <pre>, i.e. tags are recognized.  <listing>
# are presentend in smaller font than <pre>
#
# Netscape does not parse this comment correctly (it terminates the comment
# too early):
#
#    <! -- comment -- --> more comment -->
#
# Netscape does not allow space after the initial "<" in the start tag.
# Like this "<a href='gisle'>"
#
# Netscape ignore '<!--' and '-->' within the <SCRIPT> tag.  This is used
# as a trick to make non-script-aware browsers ignore the scripts.


sub eof
{
    shift->parse(undef);
}


sub parse
{
    my $self = shift;
    my $buf = \ $self->{'_buf'};
    unless (defined $_[0]) {
	# signals EOF (assume rest is plain text)
	$self->text($$buf) if length $$buf;
	$$buf = '';
	return $self;
    }
    $$buf .= $_[0];

    # Parse html text in $$buf.  The strategy is to remove complete
    # tokens from the beginning of $$buf until we can't deside whether
    # it is a token or not, or the $$buf is empty.
    while (1) {  # the loop will end by returning when text is parsed
	# First we try to pull off any plain text (anything before a "<" char)
	if ($$buf =~ s|^([^<]+)||) {
	    unless (length $$buf) {
		my $text = $1;
		# At the end of the buffer, we should not parse white space
		# but leave it for parsing on the next round.
		if ($text =~ s|(\s+)$||) {
		    $$buf = $1;
                # Same treatment for chopped up entites.
		} elsif ($text =~ s/(&(?:(?:\#\d*)?|\w*))$//) {
		    $$buf = $1;
		};
		$self->text($text);
		return $self;
	    } else {
		$self->text($1);
	    }
	# Netscapes buggy comments are easy to handle
	} elsif ($self->{'_netscape_comment'} && $$buf =~ m|^(<!--)|) {
	    if ($$buf =~ s|^<!--(.*?)-->||s) {
		$self->comment($1);
	    } else {
		return $self;  # must wait until we see the end of it
	    }
	# Then, markup declarations (usually either <!DOCTYPE...> or a comment)
	} elsif ($$buf =~ s|^(<!)||) {
	    my $eaten = $1;
	    my $text = '';
	    my @com = ();  # keeps comments until we have seen the end
	    # Eat text and beginning of comment
	    while ($$buf =~ s|^(([^>]*?)--)||) {
		$eaten .= $1;
		$text .= $2;
		# Look for end of comment
		if ($$buf =~ s|^((.*?)--)||s) {
		    $eaten .= $1;
		    push(@com, $2);
		} else {
		    # Need more data to get all comment text.
		    $$buf = $eaten . $$buf;
		    return $self;
		}
	    }
	    # Can we finish the tag
	    if ($$buf =~ s|^([^>]*)>||) {
		$text .= $1;
		$self->declaration($text) if $text =~ /\S/;
		# then tell about all the comments we found
		for (@com) { $self->comment($_); }
	    } else {
		$$buf = $eaten . $$buf;  # must start with it all next time
		return $self;
	    }
        # Should we look for 'processing instructions' <? ...> ??
	#} elsif ($$buf =~ s|<\?||) {
	    # ...
	# Then, look for a end tag
	} elsif ($$buf =~ s|^</||) {
	    # end tag
	    if ($$buf =~ s|^([a-zA-Z][a-zA-Z0-9\.\-]*)\s*>||) {
		$self->end(lc($1));
	    } elsif ($$buf =~ m|^[a-zA-Z]*[a-zA-Z0-9\.\-]*\s*$|) {
		$$buf = "</" . $$buf;  # need more data to be sure
		return $self;
	    } else {
		# it is plain text after all
		$self->text("</");
	    }
	# Then, finally we look for a start tag
	} elsif ($$buf =~ s|^<||) {
	    # start tag
	    my $eaten = '<';

	    # This first thing we must find is a tag name.  RFC1866 says:
	    #   A name consists of a letter followed by letters,
	    #   digits, periods, or hyphens. The length of a name is
	    #   limited to 72 characters by the `NAMELEN' parameter in
	    #   the SGML declaration for HTML, 9.5, "SGML Declaration
	    #   for HTML".  In a start-tag, the element name must
	    #   immediately follow the tag open delimiter `<'.
	    if ($$buf =~ s|^(([a-zA-Z][a-zA-Z0-9\.\-]*)\s*)||) {
		$eaten .= $1;
		my $tag = lc $2;
		my %attr;
		my @attrseq;

		# Then we would like to find some attributes
                #
                # Arrgh!! Since stupid Netscape violates RCF1866 by
                # using "_" in attribute names (like "ADD_DATE") of
                # their bookmarks.html, we allow this too.
		while ($$buf =~ s|^(([a-zA-Z][a-zA-Z0-9\.\-_]*)\s*)||) {
		    $eaten .= $1;
		    my $attr = lc $2;
		    my $val;
		    # The attribute might take an optional value (first we
		    # check for an unquoted value)
		    if ($$buf =~ s|(^=\s*([^\"\'>\s][^>\s]*)\s*)||) {
			$eaten .= $1;
			$val = $2;
			HTML::Entities::decode($val);
		    # or quoted by " or '
		    } elsif ($$buf =~ s|(^=\s*([\"\'])(.*?)\2\s*)||s) {
			$eaten .= $1;
			$val = $3;
			HTML::Entities::decode($val);
                    # truncated just after the '=' or inside the attribute
		    } elsif ($$buf =~ m|^(=\s*)$| or
			     $$buf =~ m|^(=\s*[\"\'].*)|s) {
			$$buf = "$eaten$1";
			return $self;
		    } else {
			# assume attribute with implicit value
			$val = $attr;
		    }
		    $attr{$attr} = $val;
		    push(@attrseq, $attr);
		}

		# At the end there should be a closing ">"
		if ($$buf =~ s|^>||) {
		    $self->start($tag, \%attr, \@attrseq, "$eaten>");
		} elsif (length $$buf) {
		    # Not a conforming start tag, regard it as normal text
		    $self->text($eaten);
		} else {
		    $$buf = $eaten;  # need more data to know
		    return $self;
		}

	    } elsif (length $$buf) {
		$self->text($eaten);
	    } else {
		$$buf = $eaten . $$buf;  # need more data to parse
		return $self;
	    }

	} elsif (length $$buf) {
	    die; # This should never happen
	} else {
	    # The buffer is empty now
	    return $self;
	}
    }
    $self;
}

sub netscape_buggy_comment
{
    my $self = shift;
    my $old = $self->{'_netscape_comment'};
    $self->{'_netscape_comment'} = shift if @_;
    return $old;
}

sub parse_file
{
    my($self, $file) = @_;
    no strict 'refs';  # so that a symbol ref as $file works
    local(*F);
    unless (ref($file) || $file =~ /^\*[\w:]+$/) {
	# Assume $file is a filename
	open(F, $file) || die "Can't open $file: $!";
	$file = \*F;
    }
    my $chunk = '';
    while(read($file, $chunk, 2048)) {
	$self->parse($chunk);
    }
    close($file);
    $self->eof;
}

sub text
{
    # my($self, $text) = @_;
}

sub declaration
{
    # my($self, $decl) = @_;
}

sub comment
{
    # my($self, $comment) = @_;
}

sub start
{
    my($self, $tag, $attr, $attrseq, $origtext) = @_;
    # $attr is reference to a HASH, $attrseq is reference to an ARRAY
}

sub end
{
    my($self, $tag) = @_;
}

1;
