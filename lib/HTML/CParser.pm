package HTML::CParser;

# $Id: CParser.pm,v 1.1 1996/10/07 11:38:14 aas Exp $

# This parser is modifies the HTML::Parser by collecting together all
# text segments before calling ctext.  Subclasses should override:
#
#   cdeclaration
#   cstart
#   cend
#   ctext
#
# instead of the same methods without the "c"-prefix.  I am not sure this
# module should go into the distribution yet. Perhaps something that also
# get rid of all the non-essential whitespace.

require HTML::Parser;
@ISA=qw(HTML::Parser);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{'_text'} = '';
    $self;
}

sub declaration
{
    my $self = shift;
    $self->_col_out;
    $self->cdeclaration(@_);
}


sub start
{
    my $self = shift;
    $self->_col_out;
    $self->cstart(@_);
}

sub end
{
    my $self = shift;
    $self->_col_out;
    $self->cend(@_);
}

sub text
{
    my($self, $text) = @_;
    $self->{'_text'} .= $text;
}

sub _col_out
{
    my($self) = @_;
    if (length $self->{'_text'}) {
	$self->ctext($self->{'_text'});
	$self->{'_text'} = '';
    }
}

sub eof
{
    my $self = shift;
    $self->SUPER::eof;
    $self->_col_out;
    $self;
}


#--------

sub cdeclaration  {}
sub cstart        {}
sub cend          {}
sub ctext         {}


1;
