#
# PFLog.pm
# NetPacket::PFLog
#
# Decodes OpenBSD's pflog(4) packets

package NetPacket::PFLog;
BEGIN {
  $NetPacket::PFLog::VERSION = '0.43.2';
}
# ABSTRACT: Assembling and disassembling OpenBSD's Packet Filter log header.

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use NetPacket;
use Socket;

BEGIN {
	@ISA = qw(Exporter NetPacket);

	@EXPORT = qw(
	);

	@EXPORT_OK = qw(
		pflog_strip
		DLT_PFLOG
		PFLOG_HDRLEN
	);

	%EXPORT_TAGS = (
		ALL         => [@EXPORT, @EXPORT_OK],
		strip       => [qw(pflog_strip)],
		DLT			=> [qw(DLT_PFLOG)],
	);
}

#  data link type for pflog in the pcap dump
use constant DLT_PFLOG => 117;

#  maximum size of the header (in bytes) in the pcap dump
use constant PFLOG_HDRLEN => 64;

#  packet filter constants (src/sys/net/pfvar.h)
my %PF_DIR = (
	1 => "in",
	2 => "out"
);
my %PF_ACTION = (
	0 => "pass",
	1 => "block",
	2 => "scrub"
);
my %PF_REASON = (
	0 => "match",
	1 => "bad-offset",
	2 => "fragment",
	3 => "short",
	4 => "normalize",
	5 => "memory",
	6 => "bad-timestamp",
	7 => "congestion",
	8 => "ip-options",
	9 => "proto-cksum",
	10 => "state-mismatch",
	11 => "state-insert",
	12 => "state-limit",
	13 => "src-limit",
	14 => "syn-proxy"
);

#  decode(packet, parent_packet, additional_data)
#  create a new NetPacket::PFLog object. decode the pflog header
#  from 'packet' and assign each field to the object.
#  return the NetPacket::PFLog object.
sub decode {
	my $class = shift;
	my ($pkt, $parent, @rest) = @_;
	my $self = {};

	$self->{_parent} = $parent;
	$self->{_frame} = $pkt;

	# based on pfloghdr struct in:
	# [OpenBSD]/src/sys/net/if_pflog.h r1.14
	if (defined $pkt) {
		my ($len, $af, $action, $reason, $ifname, $ruleset, $rulenr, 
			$subrulenr, $uid, $pid, $rule_uid, $rule_pid, $dir,
			$pad, $data) =
			unpack("CCCCa16a16NNLlLlCa3a*", $pkt);
	
		#  strip trailing NULs
		$ifname =~ s/\W//g;
		$ruleset =~ s/\W//g;

		$self->{len} = $len;
		$self->{af} = $af;
		$self->{action} = $PF_ACTION{$action};
		$self->{reason} = $PF_REASON{$reason};
		$self->{ifname} = $ifname;
		$self->{ruleset} = $ruleset;
		$self->{rulenr} = $rulenr;
		$self->{subrulenr} = $subrulenr;
		$self->{uid} = $uid;
		$self->{pid} = $pid;
		$self->{rule_uid} = $rule_uid;
		$self->{rule_pid} = $rule_pid;
		$self->{dir} = $PF_DIR{$dir};
		$self->{pad} = $pad;

		$self->{data} = $data;
	}

	bless ($self, $class);
	return $self;
}

# make an alias
undef &pflog_strip;
*pflog_strip = \&strip;

# strip header from packet and return the data contained in it
sub strip {
	my ($pkt, @rest) = @_;

	my $pflog_obj = NetPacket::PFLog->decode($pkt);
	return $pflog_obj->{data};
}   

#  encode(ip_pkt)
#  re-encapsulate an already decapsulated pflog packet
sub encode {
	my $class = shift;
	my $self = shift;
	my $ip = $_[0];

	#  convert these items back into the integers from whence they came
	my %rev_DIR = reverse %PF_DIR;
	my %rev_ACTION = reverse %PF_ACTION;
	my %rev_REASON = reverse %PF_REASON;

	my $dir = $rev_DIR{$self->{dir}};
	my $action = $rev_ACTION{$self->{action}};
	my $reason = $rev_REASON{$self->{reason}};

	# based on pfloghdr struct in:
	# [OpenBSD]/src/sys/net/if_pflog.h r1.14
	my $packet = pack("CCCCa16a16NNLlLlCa3a*", 
		$self->{len}, $self->{af}, $action, $reason, $self->{ifname}, 
		$self->{ruleset}, $self->{rulenr}, $self->{subrulenr},
		$self->{uid}, $self->{pid}, $self->{rule_uid}, $self->{rule_pid},
		$dir, $self->{pad}, $ip);

	return $packet;
}

1;



=pod

=head1 NAME

NetPacket::PFLog - Assembling and disassembling OpenBSD's Packet Filter log header.

=head1 VERSION

version 0.43.2

=head1 SYNOPSIS

  use NetPacket::PFLog;

  $pfl_obj = NetPacket::PFLog->decode($raw_pkt);
  $pfl_pkt = NetPacket::PFLog->encode();
  $pfl_data = NetPacket::PFLog::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::PFLog> provides a set of routines for assembling and
disassembling the header attached to packets logged by OpenBSD's
Packet Filter.  

=head2 Methods

=over

=item C<NetPacket::PFLog-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input. It
is the responsibility of the programmer to ensure valid packet data is
passed to this method.

=item C<NetPacket::PFLog-E<gt>encode()>

Return a PFLog packet encoded with the instance data specified.

=back

=head2 Functions

=over

=item C<NetPacket::PFLog::strip([RAW PACKET])>

Return the actual packet logged by Packet Filter that the PFLog header
is describing. This data is suitable to be used as input for other
C<NetPacket::*> modules.

This function is equivalent to creating an object using the
C<decode()> constructor and returning the C<data> field of that
object.

=back

=head2 Instance data

The instance data for the C<NetPacket::PFLog> object consists of
the following fields:

=over

=item len

The length of the pflog header.

=item af

The Address Family which denotes if the packet is IPv4 or IPv6.

=item action

The action (block, pass, or scrub) that was taken on the packet.

=item reason

The reason that the action was taken.

=item ifname

The name of the interface the packet was passing through.

=item ruleset

The name of the subruleset that the matching rule is a member of. If
the value is empty, the matching rule is in the main ruleset.

=item rulenr

The rule number that the packet matched.

=item subrulenr

The rule number in the subruleset that the packet matched. The value
will be 2^32-1 if the packet matched in the main ruleset only.

=item uid

The uid of the local process that generated the packet that was logged, if
applicable.

=item pid

The pid of the local process that generated the packet that was logged, if
applicable.

=item rule_uid

The uid of the process that inserted the rule that caused the packet to be
logged.

=item rule_pid

The pid of the process that inserted the rule that caused the packet to be
logged.

=item dir

The direction the packet was travelling through the interface.

=item pad

Padding data.

=item data

The actual IPv4 or IPv6 packet that was logged by Packet Filter.

=back

=head2 Exports

=over

=item default

none

=item exportable

Data Link Type:

  DLT_PFLOG

Strip function:

  pflog_strip

=item tags

The following tags can be used to export certain items:

=over

=item C<:DLT>

DLT_PFLOG

=item C<:strip>

The function C<pflog_strip>

=item C<:ALL>

All the above exportable items

=back

=back

=head1 EXAMPLE

The following prints the action, direction, interface name, and
reason:

  #!/usr/bin/perl -w

  use strict;
  use Net::PcapUtils;
  use NetPacket::PFLog;

  sub process_pkt {
      my ($user, $hdr, $pkt) = @_;

      my $pfl_obj = NetPacket::PFLog->decode($pkt);
      print("$pfl_obj->{action} $pfl_obj->{dir} ");
      print("on $pfl_obj->{ifname} ($pfl_obj->{reason})\n");
  }

  Net::PcapUtils::loop(\&process_pkt, FILTER => 'ip or ip6');

=head1 COPYRIGHT

Copyright (c) 2003-2009 Joel Knight <knight.joel@gmail.com>

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Joel Knight E<lt>knight.joel@gmail.comE<gt>

=cut


__END__


