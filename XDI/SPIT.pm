# XDI::SPIT.pm
#
# $Id: SPIT.pm,v 1.3 2004/06/04 08:18:20 eekim Exp $
#
# Copyright (c) Blue Oxen Associates 2004.  All rights reserved.
#
# See COPYING for licensing terms.

package XDI::SPIT;

use strict;
use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;
use XRI;
use XRI::Descriptor;

our $VERSION = '1.0';

### constructor

sub new {
    bless {}, shift;
}

### methods

sub resolveBroker {
    my $self = shift;
    my $ename = shift;

    my $xri = XRI->new($ename);
    my $xml = $xri->resolveToAuthorityXML;
    if ($xml) {
        my $xriDescriptor = XRI::Descriptor->new($xml);
        my @localAccess = $xriDescriptor->getLocalAccess;
        my $idBroker = ${$localAccess[0]->uris}[0];
        my $enumber = $xriDescriptor->getMappings->[0];
        return $idBroker, $enumber;
    }
    else {
        return 0;
    }
}

sub getAuthUrl {
    my $self = shift;
    my ($idBroker, $ename, $returnUrl) = @_;

    # FIXME: Use enumber instead?
    return "$idBroker?xri_cmd=auth&xri_ename=" . uri_escape($ename) .
        '&xri_rtn=' . uri_escape($returnUrl);
}

sub validateSession {
    my $self = shift;
    my ($idBroker, $ename, $xsid) = @_;

    return &_xriCmd($idBroker, $ename, $xsid, "verify");
}

sub logout {
    my $self = shift;
    my ($idBroker, $ename, $xsid) = @_;

    return &_xriCmd($idBroker, $ename, $xsid, "logout");
}

### private methods

sub _xriCmd {
    my ($idBroker, $ename, $xsid, $cmd) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Identity Commons SPIT/$VERSION");

    my $request = HTTP::Request->new(GET=>"$idBroker?xri_cmd=$cmd&xri_ename="
                                     . uri_escape($ename) .
                                     '&xri_xsid=' . uri_escape($xsid));
    my $response = $ua->request($request);
    if ($response->is_success) {
        ($response->content =~ /true/) ? return 1 : return 0;
    }
    else {  # FIXME: should parse status code
        return 0;
    }
}

1;
__END__

=head1 NAME

XDI::SPIT - XDI Service Provider Interface Toolkit

=head1 SYNOPSIS

  use XDI::SPIT;

  my $ename = '@pw*eekim';
  my $rtnUrl = 'http://www.blueoxen.org/?';

  my $spit = new XDI::SPIT;
  my ($idBroker, $enumber) = $spit->resolveBroker($ename);

  my $redirectUrl = $spit->getAuthUrl($idBroker, $ename, $rtnUrl);
      # Use this to redirect to identity broker login screen

=head1 DESCRIPTION

Perl library for Service Providers to authenticate and synchronize
data with data brokers.

=head1 METHODS

=head2 new

Constructor.

=head2 resolveBroker($ename)

Resolves the XRI e-name.  Returns the identity broker and e-number
corresponding to an e-name.

=head2 getAuthUrl($idBroker, $ename, $returnUrl)

Returns the redirection URL for sending the user to the identity
broker for login.  Send the following HTTP header to redirect:

  Location: $redirectUrl\n\n

where $redirectUrl is the result of getAuthUrl().

=head2 validateSession($idBroker, $ename, $xsid)

Validates with $idBroker that user $ename is indeed logged in.  $xsid
is passed by the identity broker when it redirects to the return URL
(specified in &getAuthUrl).  Returns 1 or 0.

=head2 logout($idBroker, $ename, $xsid)

Logs out of a sessions with the identity broker.  Returns 1 or 0.

=head1 SEE ALSO

L<XRI>.

More information is available at the Identity Commons Wiki:

  http://wiki.idcommons.net/moin.cgi/FrontPage

and especially the following pages:

  http://wiki.idcommons.net/moin.cgi/SSO

  http://wiki.idcommons.net/moin.cgi/SPIT

=head1 AUTHOR

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Blue Oxen Associates 2004.  All rights reserved.

See COPYING for licensing terms.

=cut
