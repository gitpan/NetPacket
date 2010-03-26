#
# NetPacket::ICMP -Decode and encode ICMP (Internet Control Message
# Protocol) packets.

package NetPacket::ICMP;


use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);


our $VERSION = '0.42.0';

BEGIN {
    @ISA = qw(Exporter NetPacket);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)

    @EXPORT = qw(
    );

# Other items we are prepared to export if requested

    @EXPORT_OK = qw(icmp_strip
                    ICMP_ECHOREPLY ICMP_UNREACH ICMP_SOURCEQUENCH
                    ICMP_REDIRECT ICMP_ECHO ICMP_ROUTERADVERT
                    ICMP_ROUTERSOLICIT ICMP_TIMXCEED ICMP_PARAMPROB
                    ICMP_TSTAMP ICMP_TSTAMPREPLY ICMP_IREQ ICMP_IREQREPLY
                    ICMP_MASKREQ ICMP_MASKREPLY
    );

# Tags:

    %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
    types       => [qw(ICMP_ECHOREPLY ICMP_UNREACH ICMP_SOURCEQUENCH
                       ICMP_REDIRECT ICMP_ECHO ICMP_ROUTERADVERT 
                       ICMP_ROUTERSOLICIT ICMP_TIMXCEED ICMP_PARAMPROB
                       ICMP_TSTAMP ICMP_TSTAMPREPLY ICMP_IREQ ICMP_IREQREPLY
                       ICMP_MASKREQ ICMP_MASKREPLY)],
    strip       => [qw(icmp_strip)],
);

}

# ICMP Types

use constant ICMP_ECHOREPLY       => 0;
use constant ICMP_UNREACH         => 3;
use constant ICMP_SOURCEQUENCH    => 4;
use constant ICMP_REDIRECT        => 5;
use constant ICMP_ECHO            => 8;
use constant ICMP_ROUTERADVERT    => 9;
use constant ICMP_ROUTERSOLICIT   => 10;
use constant ICMP_TIMXCEED        => 11;
use constant ICMP_PARAMPROB       => 12;
use constant ICMP_TSTAMP          => 13;
use constant ICMP_TSTAMPREPLY     => 14;
use constant ICMP_IREQ            => 15;
use constant ICMP_IREQREPLY       => 16;
use constant ICMP_MASKREQ         => 17;
use constant ICMP_MASKREPLY       => 18;

#
# Decode the packet
#

sub decode {
    my $class = shift;
    my($pkt, $parent, @rest) = @_;
    my $self = {};

    # Class fields

    $self->{_parent} = $parent;
    $self->{_frame} = $pkt;

    # Decode ICMP packet

    if (defined($pkt)) {

	($self->{type}, $self->{code}, $self->{cksum}, $self->{data}) =
	    unpack("CCna*", $pkt);
    }

    # Return a blessed object

    bless($self, $class);
    return $self;
}

#
# Strip a packet of its header and return the data
#

undef &icmp_strip;
*icmpstrip = \&strip;

sub strip {
    my ($pkt, @rest) = @_;

    my $icmp_obj = decode($pkt);
    return $icmp_obj->{data};
}

#
# Encode a packet
#

sub encode {
    my $self = shift;
    my ($ip) = @_;
    my ($packet);
    
    # Checksum the packet
    $self->checksum();

    # Put the packet together
    $packet = pack("CCna*", $self->{type}, $self->{code}, 
                $self->{cksum}, $self->{data});

    return($packet); 
}

#
# Calculate ICMP checksum

sub checksum {
    my $self = shift;
    my ($ip) = @_;
    my ($packet,$zero);

    # Put the packet together for checksumming
    $zero = 0;
    $packet = pack("CCna*", $self->{type}, $self->{code},
                $zero, $self->{data});

    $self->{cksum} = NetPacket::htons(NetPacket::in_cksum($packet));
}


#
# Module initialisation
#

1;

# autoloaded methods go after the END token (&& pod) below

__END__

=head1 NAME

C<NetPacket::ICMP> - Assemble and disassemble ICMP (Internet Control
Message Protocol) packets. 

=head1 SYNOPSIS

  use NetPacket::ICMP;

  $icmp_obj = NetPacket::ICMP->decode($raw_pkt);
  $icmp_pkt = NetPacket::ICMP->encode();
  $icmp_data = NetPacket::ICMP::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::ICMP> provides a set of routines for assembling and
disassembling packets using ICMP (Internet Control Message Protocol). 

=head2 Methods

=over

=item C<NetPacket::ICMP-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input.
It is the responsibility of the programmer to ensure valid packet data
is passed to this method.

=item C<NetPacket::ICMP-E<gt>encode()>

Return an ICMP packet encoded with the instance data specified. 

=back

=head2 Functions

=over

=item C<NetPacket::ICMP::strip([RAW PACKET])>

Return the encapsulated data (or payload) contained in the ICMP
packet.

=back

=head2 Instance data

The instance data for the C<NetPacket::ICMP> object consists of
the following fields.

=over

=item type

The ICMP message type of this packet.

=item code

The ICMP message code of this packet.

=item cksum

The checksum for this packet.

=item data

The encapsulated data (payload) for this packet.

=back

=head2 Exports

=over

=item default

none

=item exportable

Icmp message types: 
    ICMP_ECHOREPLY ICMP_UNREACH ICMP_SOURCEQUENCH
    ICMP_REDIRECT ICMP_ECHO ICMP_ROUTERADVERT
    ICMP_ROUTERSOLICIT ICMP_TIMXCEED ICMP_PARAMPROB
    ICMP_TSTAMP ICMP_TSTAMPREPLY ICMP_IREQ ICMP_IREQREPLY
    ICMP_MASKREQ ICMP_MASKREPLY


=item tags

The following tags group together related exportable items.

=over

=item C<:strip>

Import the strip function C<icmp_strip>.

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 EXAMPLE

=head1 TODO

=over

=item Create constants

=item Write example

=back

=head1 COPYRIGHT

This is free software; you can redistribute it and/or modify it 
under the same terms as the Perl 5 programming language system itself.

Copyright (c) 2001 Tim Potter and Stephanie Wehner.

Copyright (c) 1995,1996,1997,1998,1999 ANU and CSIRO on behalf of 
the participants in the CRC for Advanced Computational Systems
('ACSys').


=head1 AUTHOR

Tim Potter E<lt>tpot@samba.orgE<gt>

Stephanie Wehner E<lt>atrak@itsx.comE<gt>

=cut

# any real autoloaded methods go after this line