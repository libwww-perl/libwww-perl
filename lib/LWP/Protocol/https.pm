package LWP::Protocol::https;

use strict;

use vars qw(@ISA);
require LWP::Protocol::http;
@ISA = qw(LWP::Protocol::http);

sub socket_type
{
    return "https";
}

sub _extra_sock_opts
{
    my $self = shift;
    my %ssl_opts = %{$self->{ua}{ssl_opts} || {}};
    unless (exists $ssl_opts{SSL_verify_mode}) {
	$ssl_opts{SSL_verify_mode} = 1;
    }
    if (delete $ssl_opts{verify_hostname}) {
	$ssl_opts{SSL_verify_mode} ||= 1;
	$ssl_opts{SSL_verifycn_scheme} = 'www';
    }
    if ($ssl_opts{SSL_verify_mode}) {
	unless (exists $ssl_opts{SSL_ca_file} || exists $ssl_opts{SSL_ca_path}) {
	    require Mozilla::CA;
	    $ssl_opts{SSL_ca_file} = Mozilla::CA::SSL_ca_file();
	}
    }
    $self->{ssl_opts} = \%ssl_opts;
    return (%ssl_opts, $self->SUPER::_extra_sock_opts);
}

sub _check_sock
{
    my($self, $req, $sock) = @_;
    my $check = $req->header("If-SSL-Cert-Subject");
    if (defined $check) {
	my $cert = $sock->get_peer_certificate ||
	    die "Missing SSL certificate";
	my $subject = $cert->subject_name;
	die "Bad SSL certificate subject: '$subject' !~ /$check/"
	    unless $subject =~ /$check/;
	$req->remove_header("If-SSL-Cert-Subject");  # don't pass it on
    }
}

sub _get_sock_info
{
    my $self = shift;
    $self->SUPER::_get_sock_info(@_);
    my($res, $sock) = @_;
    $res->header("Client-SSL-Cipher" => $sock->get_cipher);
    my $cert = $sock->get_peer_certificate;
    if ($cert) {
	$res->header("Client-SSL-Cert-Subject" => $cert->subject_name);
	$res->header("Client-SSL-Cert-Issuer" => $cert->issuer_name);
    }
    if (!$self->{ssl_opts}{SSL_verify_mode}) {
	$res->push_header("Client-SSL-Warning" => "Peer certificate not verified");
    }
    elsif (!$self->{ssl_opts}{SSL_verifycn_scheme}) {
	$res->push_header("Client-SSL-Warning" => "Peer hostname match with certificate not verified");
    }
    $res->header("Client-SSL-Socket-Class" => $Net::HTTPS::SSL_SOCKET_CLASS);
}

#-----------------------------------------------------------
package LWP::Protocol::https::Socket;

use vars qw(@ISA);
require Net::HTTPS;
@ISA = qw(Net::HTTPS LWP::Protocol::http::SocketMethods);

1;
