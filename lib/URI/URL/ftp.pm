package URI::URL::ftp;
require URI::URL::file;
@ISA = qw(URI::URL::file);

sub default_port { 21 }

sub user
{
    my($self, @val) = @_;
    my $old = $self->URI::URL::_generic::user(@val);
    defined $old ? $old : "anonymous";
}

BEGIN {
    $whoami = undef;
    $fqdn   = undef;
}

sub password
{
    my($self, @val) = @_;
    my $old = $self->URI::URL::_generic::password(@val);
    unless (defined $old) {
	# anonymous ftp login password
	unless (defined $fqdn) {
	    require Sys::Hostname;
	    $fqdn = Sys::Hostname::hostname();
	}
	unless (defined $whoami) {
	    $whoami = $ENV{USER} || $ENV{LOGNAME} || `whoami`;
	    chomp $whoami;
	}
	$old = "$whoami\@$fqdn";
    }
    $old;
}
