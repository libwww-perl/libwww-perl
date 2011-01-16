package LWP::Protocol::https;

use strict;

use vars qw(@ISA);
require LWP::Protocol::http;
@ISA = qw(LWP::Protocol::http);

sub socket_type
{
    return "https";
}

sub _check_sock
{
    my($self, $req, $sock) = @_;
    if ($sock->can("verify_hostname")) {
	if (!$sock->verify_hostname($req->uri->host, "www")) {
	    my $subject = $sock->peer_certificate("subject");
	    die "SSL-peer fails verification [subject=$subject]\n";
	}
	else {
	    $req->{ssl_sock_verified}++;
	}
    }
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
    if (!$res->request->{ssl_sock_verified}) {
	if(! eval { $sock->get_peer_verify }) {
	    my $msg = "Peer certificate not verified";
	    $msg .= " [$@]" if $@;
	    $res->header("Client-SSL-Warning" => $msg);
	}
    }
    $res->header("Client-SSL-Socket-Class" => $Net::HTTPS::SSL_SOCKET_CLASS);
}

#-----------------------------------------------------------
package LWP::Protocol::https::Socket;

use vars qw(@ISA);
require Net::HTTPS;
@ISA = qw(Net::HTTPS LWP::Protocol::http::SocketMethods);

1;
