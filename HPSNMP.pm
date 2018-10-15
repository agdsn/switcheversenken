package HPSNMP;

use 5.008004;
use strict;
use warnings;
use Net::SNMP;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HPSNMP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	&get_maclist_from_switch
	&get_ether_ports
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	&get_maclist_from_switch
	&get_ether_ports
	&write_MACs
	&mac2decmac
	&decmac2mac
	&set_alarm
	&get_alarm
	&set_learnmode
	&get_learnmode
	&set_enabled
	&get_enabled
	&get_up
	&set_portalias
	&get_portalias
	&get_switch_vlan
	&add_switch_vlans
	&del_switch_vlans
	&set_vlan_name
	&get_ut_mask_hash
	&get_t_mask_hash
	&get_vlan_mask
	&set_vlan_mask
	&port_to_vlan
	&set_port
	&cdp_neighbor
	&reset_intrusionflag
	&reauth_radius_port
	&add_macaddress
	&del_macaddress
	&get_address_limit
);

our $VERSION = '0.01';
our $SNMP_VERSION = 'snmpv2c';
our $DOMAIN_SUFFIX = 'net.fem.tu-ilmenau.de';		# sollte Managment-Domain sein (net.fem.tu-ilmenau.de)
our $COMMUNITY_STRING = 'public';
our $COMMUNITY_READ_STRING = 'public';			# sollte für get-Anfragen benutzt werden
our $DEBUG = 0;

our %mib = (
	ifType =>					'.1.3.6.1.2.1.2.2.1.3.',						# für Ethernet Port Anzahl
	ifAdminStatus =>			'.1.3.6.1.2.1.2.2.1.7.',						# Port an(1) oder aus(2)
	ifOperStatus =>			'.1.3.6.1.2.1.2.2.1.8.',						# Port up(1) oder down(2)	
	hpSwitchPortAdminStatus =>	'.1.3.6.1.4.1.11.2.14.11.5.1.7.1.3.1.1.4.',		# wie ifAdminStatus
	hpSecCfgStatus =>			'.1.3.6.1.4.1.11.2.14.2.10.4.1.4.1.',			# MAC hinzufuegen siehe HP-ICF-GENERIC-RPTR::hpSecCfgStatus
	hpSecPtAddressLimit =>	'.1.3.6.1.4.1.11.2.14.2.10.3.1.3.1.',				# Adress Limit siehe    HP-ICF-GENERIC-RPTR::hpSecPtAddressLimit
	hpSecPtLearnMode =>		'.1.3.6.1.4.1.11.2.14.2.10.3.1.4.1.',				# LearnMode HP-ICF-GENERIC-RPTR::hpSecPtLearnMode
	hpSecPtAlarmEnable =>		'.1.3.6.1.4.1.11.2.14.2.10.3.1.6.1.',			# HP-ICF-GENERIC-RPTR::hpSecPtAlarmEnable
# 	hpSecPtIntrusionFlag =>	'.1.3.6.1.4.1.11.2.14.2.10.3.1.7.1.17.1.',			# Setzt/Lesen des Port Securty-Flags (0 nicht gesetzt, 1 gesetzt) HP-ICF-GENERIC-RPTR::hpSecPtIntrusionFlag.1.10
	hpSecPtIntrusionFlag => '.1.3.6.1.4.1.11.2.14.2.10.3.1.7.1.',
	hpSwitchPortEtherMode =>	'.1.3.6.1.4.1.11.2.14.11.5.1.7.1.3.1.1.5.',		# Half or Full Duplex
	hpSwitchPortFastEtherMode => '.1.3.6.1.4.1.11.2.14.11.5.1.7.1.3.1.1.10.',	# half-duplex-10Mbits(1),half-duplex-100Mbits(2),full-duplex-10Mbits(3),full-duplex-100Mbits(4),auto-neg(5),full-duplex-1000Mbits(6),auto-10Mbits(7),auto-100Mbits(8),auto-1000Mbits(9)
	dot1qVlanStaticName => 		'.1.3.6.1.2.1.17.7.1.4.3.1.1.',					# VLAN Name .1.1.[VLAN] = STRING
	dot1qVlanStaticRowStatus => '.1.3.6.1.2.1.17.7.1.4.3.1.5.',					# VLAN auf Switch hinzufügen oder löschen; dot1qVlanStaticRowStatus.[VLANID] (1 - active 2 - notInService 3 - notReady 4 - createAndGo 5 - createAndWait 6 - destroy )
	dot1qVlanStaticUntaggedPorts => '.1.3.6.1.2.1.17.7.1.4.3.1.4.',				# Untagged VLAN an Ports definieren; dot1qVlanStaticUntaggedPorts.[VLANID] = [BITMASKE] (BITMASKE von vorn nach hinten entspricht der Portbelegung MSB = Port 1)
	dot1qVlanStaticEgressPorts   => '.1.3.6.1.2.1.17.7.1.4.3.1.2.',				# Tagged VLANs an Ports definieren; dot1qVlanStaticEgressPorts.[VLANID] = [BITMASKE] (BITMASKE von vorn nach hinten entspricht der Portbelegung MSB = Port 1)
	dot1qVlanForbiddenEgressPorts => '.1.3.6.1.2.1.17.7.1.4.3.1.3.',			# Forbidden VLANs an Ports definieren; dot1qVlanForbiddenEgressPorts.[VLANID] = [BITMASKE] (BITMASKE von vorn nach hinten entspricht der Portbelegung MSB = Port 1)
	# Status-Abfragen
	hpicfSensorIndex =>		'.1.3.6.1.4.1.11.2.14.11.1.2.6.1.1.1',
	hpicfSensorStatus =>		'.1.3.6.1.4.1.11.2.14.11.1.2.6.1.4.1',
	hpicfSensorWarnings =>	'.1.3.6.1.4.1.11.2.14.11.1.2.6.1.5.1',
	hpicfSensorFailures =>	'.1.3.6.1.4.1.11.2.14.11.1.2.6.1.6.1',
	# Sonstige Daten
	sysDescr =>				'.1.3.6.1.2.1.1.1.0',								# System Beschreibung (Firmware, Geraete-Type uvm.)
	ifAlias =>				'.1.3.6.1.2.1.31.1.1.1.18.',						# interface name
	cdpCacheDeviceId =>		'.1.3.6.1.4.1.9.9.23.1.2.1.1.6.',					# (walk) System IDs der Nachbarn
	dot1dBaseNumPorts =>	'.1.3.6.1.2.1.17.1.2.0',							# die Anzahl der vorhandenen Ports
	hpRadiusReauth => '.1.3.6.1.4.1.11.2.14.11.5.1.19.2.1.1.4.', 	# Setzen von 1 fuehrt zu einem Radius-Reauth des Ports
);

sub get_maclist_from_switch {
	my ($switch_name, $port_nr) = @_;
	my @MACs = ();
	my $mac_table_oid = "";
	my $extracted_result = "";
	
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community  => $COMMUNITY_READ_STRING, -port => shift || 161 );
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
#	my $result = $session->get_next_request( -varbindlist => [$hpSecCfgStatus.$port_nr]);
	my $result = $session->get_next_request( -varbindlist => [$mib{'hpSecCfgStatus'}.$port_nr]);
	if(!defined($result)) {
		print "failed to get existing MACs: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	}
	
	$extracted_result = each %$result;
	$mac_table_oid = $mib{hpSecCfgStatus}.$port_nr;
	
	unless($extracted_result =~ /$mac_table_oid/) { # Wir sind nicht (mehr) in dem Zweig mit den MACs -> Keine MACs vorhanden.
		$session->close;
		return @MACs;
	}
	push(@MACs, substr( $extracted_result, length($mib{hpSecCfgStatus}.$port_nr)));
	while(defined($result)) {
		$result = $session->get_next_request( -varbindlist => [$extracted_result]);
		if(!defined($result)) {
			print "failed to get existing MACs: $error" if $DEBUG >= 1;
			$session->close;
			return 1;
		}
		$extracted_result= each %$result;
		if($extracted_result =~ /$mac_table_oid/) {		# Wir sind nicht (mehr) in dem Zweig mit den MACs -> Keine (weiteren) MACs vorhanden.
			push(@MACs, substr( $extracted_result, length($mib{hpSecCfgStatus}.$port_nr)));
		} else {
			undef $result;
		}
	}
	$session->close;
	# style ".0.14.123.241.215.2"
	return @MACs;
}

sub get_ether_ports {
	my ($switch_name, undef) = @_;
	my $port_count = 0;
# $extracted_result is just temp-crap
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community  => $COMMUNITY_STRING, -port => shift || 161 );
	if(!defined($session)) {
		print "failed to open Session: $error";
		return 1;
	}
	my $result = $session->get_next_request( -varbindlist => [$mib{ifType}.$port_count]);
	if(!defined($result)) {
		print "failed to get Etherports: $error";
		$session->close;
		return 1;
	}
	my ($extracted_result, $value) = each %$result; 
	$port_count++ if $value == 6;	# 6 ist der Port Type (ether)
	while(defined($result)) {
		$result = $session->get_next_request( -varbindlist => [$extracted_result]);
		if(!defined($result)) {
			print "failed to get Etherports: $error";
			$session->close;
			return 1;
		}
		($extracted_result, $value) = each %$result;
		if($extracted_result =~ /$mib{ifType}/) {
			#print "$extracted_result \t $value\n";
			$port_count++ if $value == 6;
		} else {
			undef $result;
		}
	}
	$session->close;
	return $port_count;
}


sub get_address_limit {
	my ($switch_name, $port_nr, undef) = @_;
	undef @_;

	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_READ_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "get_address_limit: failed to open Session: $error / $switch_name\n";
		return 1;
	}
	# AdressLimit lesen
	my $result = $session->get_request( -varbindlist => [$mib{hpSecPtAddressLimit}.$port_nr]);
	if(!defined($result)) {
		print "failed to read Address-Limit: $error / $switch_name\n";
		$session->close;
		return 1;
	}
	my ( undef, $value) = each %$result;
	$session->close;
	return $value;
}


sub add_macaddress {
	my ($switch_name, $port_nr, $Mac_Address) = @_;
	undef @_;

	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
	
	# AdressLimit lesen
	my $result = $session->get_request( -varbindlist => [$mib{hpSecPtAddressLimit}.$port_nr]);
	if(!defined($result)) {
		print "failed to read Address-Limit: $error";
		$session->close;
		return 1;
	}
	my ( undef, $value) = each %$result;
	$value++;

	# AdressLimit setzen
	$result = $session->set_request( -varbindlist => [$mib{hpSecPtAddressLimit}.$port_nr, INTEGER, $value]);
	if(!defined($result)) {
		print "failed to change Address-Limit: $error";
		$session->close;
		return 1;
	}
	
	$result = $session->set_request( -varbindlist => [$mib{hpSecCfgStatus}.$port_nr.$Mac_Address, INTEGER, '4']);  # add
	if(!defined($result)) {
		print "failed to add new MAC: $error\n";
		print $mib{hpSecCfgStatus}.$port_nr.$Mac_Address,"\n";
	} 
	$session->close;
	return 0;
}

sub del_macaddress {
	my ($switch_name, $port_nr, $Mac_Address) = @_;
	undef @_;

	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
		
	my $result = $session->set_request( -varbindlist => [$mib{hpSecCfgStatus}.$port_nr.$Mac_Address, INTEGER, '6']);  # add
	if(!defined($result)) {
		print "failed to del new MAC: $error\n";
		print $mib{hpSecCfgStatus}.$port_nr.$Mac_Address,"\n";
	}

	# AdressLimit lesen
	$result = $session->get_request( -varbindlist => [$mib{hpSecPtAddressLimit}.$port_nr]);
	if(!defined($result)) {
		print "failed to read Address-Limit: $error";
		$session->close;
		return 1;
	}
	my ( undef, $value) = each %$result;
	return 2 if $value eq "1";
	$value--;
	# AdressLimit setzen
	$result = $session->set_request( -varbindlist => [$mib{hpSecPtAddressLimit}.$port_nr, INTEGER, $value]);
	if(!defined($result)) {
		print "failed to decrease Address-Limit: $error you try value $value\n";
		$session->close;
		return 1;
	}
 
	$session->close;
	return 0;
}

sub write_MACs {
	my ($switch_name, $port_nr, @Mac_Address) = @_;

	undef @_;
	#print "MACs fuer ", $self->{'switch_name'}," @ Port ", $self->{'port_nr'},"\n";

	my @old_macs = get_maclist_from_switch($switch_name, $port_nr);
	
	my @add_macs = (); #homework
	my %temp_seen = (); #homework
	foreach my $item (@old_macs) { del_macaddress($switch_name, $port_nr, $item); } #homework
	
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
#		print "failed. $error\n";
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
	
	# AdressLimit setzen
	my $result = $session->set_request( -varbindlist => [$mib{hpSecPtAddressLimit}.$port_nr, INTEGER, $#Mac_Address+1]);
	if(!defined($result)) {
		print "failed to change Address-Limit: $error";
		$session->close;
		return 1;
	}
	print "change Address-Limit at $port_nr to $#Mac_Address" if $DEBUG >= 1;
	
	# Neue MACs dazu ...
	foreach my $nmac (@Mac_Address) {
		undef $result;
		$nmac = mac2decmac($nmac);
		$result = $session->set_request( -varbindlist => [$mib{hpSecCfgStatus}.$port_nr.$nmac , INTEGER, '6']);  # del
		if(!defined($result)) {
			print "failed to del new MAC: $error\n";
			print $mib{hpSecCfgStatus}.$port_nr.$nmac,"\n";
		} 
		undef $result;
		$result = $session->set_request( -varbindlist => [$mib{hpSecCfgStatus}.$port_nr.$nmac , INTEGER, '4']);  # add
		if(!defined($result)) {
			print "failed to add new MAC: $error\n";
			print $mib{hpSecCfgStatus}.$port_nr.$nmac,"\n";
		} 
#		$session->close;
	}
	$session->close;
}

sub mac2decmac {
	my ($MAC, undef) = @_;
	my @MAC_pat = split("-",$MAC);
	my $mac_string = "";
	foreach my $item (@MAC_pat) {
		$mac_string = $mac_string.".".unpack("C3", pack("H2",$item));
	}
	return $mac_string;
}
sub decmac2mac {
	my ($decMAC, undef) = @_;
	$decMAC =~ s/^[.]//;
	my @MAC_pat = split(/[.]/,$decMAC);
	my $mac_string = "";
	foreach my $item (@MAC_pat) {
		$mac_string = $mac_string."-".unpack("H*", pack("C*", $item));
	}
	$mac_string =~ s/^[-]//;
	return $mac_string;
}

# $Alarm (1 - disable) (2 - sendTrap) (3 - sendTrapAndDisablePort)
sub set_alarm {
	my ($switch_name, $port_nr, $Alarm) = @_;

	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
#		print "failed. $error\n";
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}

	# Alarm
	my $result = $session->set_request( -varbindlist => [$mib{hpSecPtAlarmEnable}.$port_nr, INTEGER, $Alarm]);
	if(!defined($result)) {
		print "failed to change Port-Alarm: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	} else {
		print "change Port-Alarm at $port_nr to $Alarm" if $DEBUG >= 1;
		$session->close;
		return 0;
	}
}

sub get_alarm {
	my ($switch_name, $port_nr) = @_;
	undef @_;
	
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error"  if $DEBUG >= 1;
		return 1;
	}
	
	# Alarm
	my $result = $session->get_request( -varbindlist => [$mib{hpSecPtAlarmEnable}.$port_nr]);
	if(!defined($result)) {
		print "failed to get PtAlarmEnable: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	}
	my ( undef, $value) = each %$result;
	$session->close;
	return $value;
}

# $port_sec (1 - learnContinuous) (2 - learnFirstN) (3 - learnFirstNConditionally) (4 - configureSpecific)
sub set_learnmode {
	my ($switch_name, $port_nr, $port_sec) = @_;
	undef @_;
	
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
#		print "failed. $error\n";
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}

	# LearnMode setzen
	my $result = $session->set_request( -varbindlist => [$mib{hpSecPtLearnMode}.$port_nr, INTEGER, $port_sec]);
	if(!defined($result)) {
		print "failed to change Port-Security: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	} else {
		print "change Port-Security at $port_nr to $port_sec" if $DEBUG >= 1;
		$session->close;
		return 0;
	}
}

sub get_learnmode {
	my ($switch_name, $port_nr) = @_;
	undef @_;
	
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
	
	# LearnMode abfragen 
	my $result = $session->get_request( -varbindlist => [$mib{hpSecPtLearnMode}.$port_nr]);
	if(!defined($result)) {
		print "failed to get PtLearnMode: $error" if $DEBUG >= 1;
		$session->close;
		return 1;		#FEHLER
	}
	my ( undef, $value) = each %$result;
	$session->close;
	return $value;
}

# $enable (1 - up) (2 - down) (3 - testing)
sub set_enabled {
	my ($switch_name, $port_nr, $enabled) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
	# Status setzen
	my $result = $session->set_request( -varbindlist => [$mib{ifAdminStatus}.$port_nr, INTEGER, $enabled]);
	if(!defined($result)) {
		print "failed to change Port-Status: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	} else {
		print "change Port-Status $port_nr to $enabled" if $DEBUG >= 1;
		$session->close;
		return 0;
	}
}

sub reset_intrusionflag {
	my ($switch_name, $port_nr) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
	# Flag reset 
	my $result = $session->set_request( -varbindlist => [$mib{hpSecPtIntrusionFlag}.$port_nr, INTEGER, 2]);
	if(!defined($result)) {
		print "failed to change Intrusionflag: $error \n";
		$session->close;
		return 1;
	}
	$session->close;
	return 0;
}

sub reauth_radius_port {
	my ($switch_name, $port_nr) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
	# reauth
	my $result = $session->set_request( -varbindlist => [$mib{hpRadiusReauth}.$port_nr, INTEGER, 1]);
	if(!defined($result)) {
		print "failed to initiate reauth: ". $session->error() ." \n";
		$session->close;
		return 1;
	}
	$session->close;
	return 0;
}

sub get_enabled {
	my ($switch_name, $port_nr) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_READ_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}

	# Status setzen
	my $result = $session->get_request( -varbindlist => [$mib{ifAdminStatus}.$port_nr]);
	if(!defined($result)) {
		print "failed to change Port-Status: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	}
	my ( undef, $value) = each %$result;
	$session->close;
	return $value;
}

sub get_up {
	my ($switch_name, $port_nr) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_READ_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}

	# Status setzen
	my $result = $session->get_request( -varbindlist => [$mib{ifOperStatus}.$port_nr]);
	if(!defined($result)) {
		print "failed to change Port-Status: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	}
	my ( undef, $value) = each %$result;
	$session->close;
	return $value;
}

sub set_portalias {
	my ($switch_name, $port_nr, $alias) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}
	# Status setzen
	my $result = $session->set_request( -varbindlist => [$mib{ifAlias}.$port_nr, OCTET_STRING, $alias]);
	if(!defined($result)) {
		print "failed to change Port-Status: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	} else {
		print "change Port-Alias $port_nr to $alias" if $DEBUG >= 1;
		$session->close;
		return 0;
	}
}

sub get_portalias {
	my ($switch_name, $port_nr) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_READ_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to open Session: $error" if $DEBUG >= 1;
		return 1;
	}

	# Status setzen
	my $result = $session->get_request( -varbindlist => [$mib{ifAlias}.$port_nr]);
	if(!defined($result)) {
		print "failed to get Port-Alias: $error" if $DEBUG >= 1;
		$session->close;
		return 1;
	}
	my ( undef, $value) = each %$result;
	$session->close;
	return $value;
}

sub get_switch_vlan {
	my ($switch_name) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to get vlans: $error" if $DEBUG >= 1;
		return 1;
	}
	my @VLANs = ();
	my $result = $session->get_next_request( -varbindlist => [$mib{dot1qVlanStaticRowStatus}]);
	if(!defined($result)) {
#		print "failed to get VLANs(dot1qVlanStaticRowStatus): $error" if $DEBUG >= 1;
		$session->close;
		return 1;		#FEHLER
	}
	my ($vlan_table_oid, $value) = each %$result;
	push(@VLANs, substr($vlan_table_oid, length($mib{dot1qVlanStaticRowStatus}))) if $value == 1;
	while(defined($result)) {
		$result = $session->get_next_request( -varbindlist => [$vlan_table_oid]);
		if(!defined($result)) {
#			print "failed to get VLANs(dot1qVlanStaticRowStatus): $error" if $DEBUG >= 1;
			$session->close;
			return 1;		#FEHLER
		}
		($vlan_table_oid, $value) = each %$result;
		push(@VLANs, substr($vlan_table_oid, length($mib{dot1qVlanStaticRowStatus}))) if $value == 1;
		unless($vlan_table_oid =~ /$mib{dot1qVlanStaticRowStatus}/) {
			undef $result;
		}
	}
	$session->close;
	return @VLANs;
}

sub add_switch_vlans {
	my ($switch_name, $vlan) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to add vlans: $error" if $DEBUG >= 1;
		return 1;
	}
	my $result = $session->set_request( -varbindlist => [$mib{dot1qVlanStaticRowStatus}.$vlan, INTEGER, 4]);
	if(!defined($result)) {
		print "failed to add VLANs(dot1qVlanStaticRowStatus): $error" if $DEBUG >= 1;
		$session->close;
		return 1;		#FEHLER
	}
	$session->close;
	return 0;
}

sub del_switch_vlans {
	my ($switch_name, $vlan) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to add vlans: $error" if $DEBUG >= 1;
		return 1;
	}
	my $result = $session->set_request( -varbindlist => [$mib{dot1qVlanStaticRowStatus}.$vlan, INTEGER, 6]);
	if(!defined($result)) {
		print "failed to add VLANs(dot1qVlanStaticRowStatus): $error" if $DEBUG >= 1;
		$session->close;
		return 1;		#FEHLER
	}
#	my ($k, $value) = each %$result; # $k is just temp-crap
#	my ($vlan_table_oid, $value) = each %$result;
	$session->close;
	return 0;
}

sub set_vlan_name {
	my ($switch_name, $vlan, $Name) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch_name, -community => $COMMUNITY_STRING, -port => shift || 161);
	if(!defined($session)) {
		print "failed to set/change vlan name: $error" if $DEBUG >= 1;
		return 1;
	}
	my $result = $session->set_request( -varbindlist => [$mib{dot1qVlanStaticName}.$vlan, OCTET_STRING, $Name]);
	if(!defined($result)) {
		print "failed to set/change VLAN Name(dot1qVlanStaticName): $error" if $DEBUG >= 1;
		$session->close;
		return 1;		#FEHLER
	}
	$session->close;
	return 0;
}

sub get_ut_mask_hash {
	my ($switch, undef) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch, -community => $COMMUNITY_STRING, -translate => 0x0, -port => shift || 161);
	if(!defined($session)) {
		print "failed to get untagged vlan hash: $error" if $DEBUG >= 1;
		return 1;
	}
	my %VLANs = ();
	my $result = $session->get_next_request( -varbindlist => [$mib{dot1qVlanStaticUntaggedPorts}]);
	if(!defined($result)) {
		print "failed to get untagged VLANs(dot1qVlanStaticUntaggedPorts): $error" if $DEBUG >= 1;
		$session->close;
		return 1;		#FEHLER
	}
	my ($untagged_port_oid, $value) = each %$result;
	$VLANs{substr($untagged_port_oid, length($mib{dot1qVlanStaticUntaggedPorts}))} = unpack("H*", $value);
	while(defined($result)) {
		$result = $session->get_next_request( -varbindlist => [$untagged_port_oid]);
		if(!defined($result)) {
			print "failed to get untagged VLANs(dot1qVlanStaticUntaggedPorts): $error" if $DEBUG >= 1;
			$session->close;
			return 1;		#FEHLER
		}
		($untagged_port_oid, $value) = each %$result;
		if($untagged_port_oid =~ /$mib{dot1qVlanStaticUntaggedPorts}/) {
			#print "$k \t \"$value\" \t\t ", unpack("H*", $value) , "\n";
			$VLANs{substr($untagged_port_oid, length($mib{dot1qVlanStaticUntaggedPorts}))} = unpack("H*", $value);
		} else {
			undef $result;
		}
	}
	$session->close;
	return %VLANs;
}

sub get_t_mask_hash {
	my ($switch, undef) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch, -community => $COMMUNITY_STRING, -translate => 0x0, -port => shift || 161);
	if(!defined($session)) {
		print "failed to get tagged vlan hash: $error" if $DEBUG >= 1;
		return 1;
	}
	my %VLANs = ();
	my $result = $session->get_next_request( -varbindlist => [$mib{dot1qVlanStaticEgressPorts}]);
	if(!defined($result)) {
		print "failed to get untagged VLANs(dot1qVlanStaticEgressPorts): $error" if $DEBUG >= 1;
		$session->close;
		return 1;		#FEHLER
	}
	my ($tagged_port_oid, $value) = each %$result;
	$VLANs{substr($tagged_port_oid, length($mib{dot1qVlanStaticEgressPorts}))} = unpack("H*", $value);
	while(defined($result)) {
		$result = $session->get_next_request( -varbindlist => [$tagged_port_oid]);
		if(!defined($result)) {
			print "failed to get tagged VLANs(dot1qVlanStaticEgressPorts): $error" if $DEBUG >= 1;
			$session->close;
			return 1;		#FEHLER
		}
		($tagged_port_oid, $value) = each %$result;
		if($tagged_port_oid =~ /$mib{dot1qVlanStaticEgressPorts}/) {
			#print "$k \t \"$value\" \t\t ", unpack("H*", $value) , "\n";
			$VLANs{substr($tagged_port_oid, length($mib{dot1qVlanStaticEgressPorts}))} = unpack("H*", $value);
		} else {
			undef $result;
		}
	}
	$session->close;
	return %VLANs;
}

# $mode (untagged, tagged, forbidden)
sub get_vlan_mask {
	my ($switch, $vlan, $mode) = @_;
	undef @_;
	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch, -community => $COMMUNITY_STRING, -translate => 0x0, -port => shift || 161);
	if(!defined($session)) {
		print "failed to get untagged vlan hash: $error";
		return -1;
	}
	my $result;
	$result = $session->get_request( -varbindlist => [$mib{dot1qVlanStaticUntaggedPorts}.$vlan]) if $mode eq "untagged";
	$result = $session->get_request( -varbindlist => [$mib{dot1qVlanStaticEgressPorts}.$vlan]) if $mode eq "tagged"; 
	$result = $session->get_request( -varbindlist => [$mib{dot1qVlanForbiddenEgressPorts}.$vlan]) if $mode eq "forbidden";
	#return -1 if ($mode ne "forbidden") and ($mode ne "untagged") and ($mode ne "tagged");
	if(!defined($result)) {
		print "failed to get untagged VLANs(dot1qVlanStaticUntaggedPorts): $error";
		$session->close;
		return -1;		#FEHLER
	}
	my (undef, $value) = each %$result;
	$session->close;
#	return $value;
	return unpack("H*", $value)
}

sub set_vlan_mask {
	my ($switch, $vlan, $mode, $mask) = @_;
	undef @_;

# ToDo: hier koennte man checken ob die maske die richtige Länge hat 
#		in dem man noch eine mal mit get_vlan_mask den Switch abfragt.

	my ($session, $error) = Net::SNMP->session(-version => $SNMP_VERSION, -hostname => $switch, -community => $COMMUNITY_STRING, -translate => 0x0, -port => shift || 161);
	if(!defined($session)) {
		print "failed to set untagged vlan hash: ". $session->error() ." \n";
		return 1;
	}
	my $result;
	$result = $session->set_request( -varbindlist => [$mib{dot1qVlanStaticUntaggedPorts}.$vlan, OCTET_STRING, pack("H*",$mask)]) if $mode eq "untagged";
	$result = $session->set_request( -varbindlist => [$mib{dot1qVlanStaticEgressPorts}.$vlan, OCTET_STRING, pack("H*",$mask)]) if $mode eq "tagged"; 
	$result = $session->set_request( -varbindlist => [$mib{dot1qVlanForbiddenEgressPorts}.$vlan, OCTET_STRING, pack("H*",$mask)]) if $mode eq "forbidden";
	if(!defined($result)) {
		print "failed to set untagged VLANs(dot1qVlanStaticUntaggedPorts): " . $session->error() . "\n";
		$session->close;
		return 1;		#FEHLER
	}
	my (undef, $value) = each %$result;
	$session->close;
	return $value;
}

sub port_to_vlan {
	my ($switch, $PORT, $VLAN, $mode) = @_;
	undef @_;
	my $hexports = HPSNMP::get_vlan_mask($switch, $VLAN, "tagged");
	my $mask = HPSNMP::set_port($PORT,$hexports,"or");
	HPSNMP::set_vlan_mask($switch, $VLAN, "tagged", $mask);
	return 0 if $mode ne "untagged";
	my @vlans = HPSNMP::get_switch_vlan($switch);
	foreach my $vlan (@vlans) {
		my $uhexports = HPSNMP::get_vlan_mask($switch, $vlan, "untagged");
		if( HPSNMP::set_port($PORT,$uhexports,"and") != 0 ) {
			#print "Port $PORT has " , $vlan," untagged\n";
			my $ut_mask = HPSNMP::set_port($PORT,$uhexports,"xor");
			HPSNMP::set_vlan_mask($switch, $vlan, "untagged", $ut_mask);
			my $hex_ports = HPSNMP::get_vlan_mask($switch, $vlan, "tagged");
			my $mask_t = HPSNMP::set_port($PORT,$hex_ports,"xor");
			HPSNMP::set_vlan_mask($switch, $vlan, "tagged", $mask_t);
#			break;
		}
	}
	my $ut_hex_ports = HPSNMP::get_vlan_mask($switch,$VLAN, "untagged");
	my $umask_t = HPSNMP::set_port($PORT,$ut_hex_ports,"or");
	HPSNMP::set_vlan_mask($switch, $VLAN, "untagged", $umask_t);
	return 0;
}

sub set_port {
	my ($portnr, $hexports, $op) = @_;
	#return $hexports if $hexports == -1;
	my $port = '';
	for(my $count=1; $count <= length($hexports)*4; $count++) {
		$port = $port.'0';
	}
	substr($port, $portnr-1,1) = '1' if $portnr <= length($hexports)*4;
	print "Bitmask length: ",length($hexports),"\n" if $DEBUG >= 7;
	return unpack("H".length($hexports),pack("B".length($hexports)*4, $port | unpack("B".length($hexports)*4, pack("H*", $hexports)))) if $op eq "or";
	return unpack("H".length($hexports),pack("B".length($hexports)*4, $port ^ unpack("B".length($hexports)*4, pack("H*", $hexports)))) if $op eq "xor";
	return unpack("H".length($hexports),pack("B".length($hexports)*4, $port & unpack("B".length($hexports)*4, pack("H*", $hexports)))) if $op eq "and";
}

sub cdp_neighbor {
        my ($switch_name, $port, undef) = @_;
        undef @_;
        my ($session, $error) = Net::SNMP->session( -version => $SNMP_VERSION,  -hostname   => $switch_name, -community  => $COMMUNITY_READ_STRING, -port => shift || 161 );
        if(!defined($session)) {
                print "failed to open Session: $error \n";
                return 1;
        }
        my $result = $session->get_next_request( -varbindlist => [$mib{cdpCacheDeviceId}.$port]);
        my $request = '';
	my $value = '';
	( $request, $value) = each %$result;
        $session->close;
        ($value, undef) = split(/\(/,$value);
        $request =~ s/$mib{cdpCacheDeviceId}//g;
        ($request, undef) = split(/\./,$request);
#	print $request, " ", $value,"\n";
        $value = "no neighbor" if $request ne $port;
        return $value;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HPSNMP - Perl extension for HP ProCurve Switch management (2500, 2600, 2800, 4100gl)

=head1 SYNOPSIS

  use HPSNMP;
  @maclist = get_maclist_from_switch("switch.foo.bar",$port_number);

  set_ut_vlans($switch, $vlan, $mask);
Prototype:
  set_t_vlans($switch, $vlan, set_port($port, get_vlan_mask($switch, $vlan, $mode)));


=head1 DESCRIPTION

 get_maclist_from_switch(switch, portnumber)
 get_ether_ports(switch)
 write_MACs(switch, portnumber, mac-list)
 set_alarm(switch, portnumber, alarm)
 get_alarm()
 set_learnmode()
 get_learnmode()
 set_enabled()
 get_enabled()
 get_up()
 set_portalias()
	set Interface Name
 get_portalias()
 get_switch_vlan(switch)
 get all vlan and return a ARRAY
 add_switch_vlans()
 del_switch_vlans()
 set_vlan_name(switch, vlan, name) 
	set Namestring of VLAN
 get_ut_mask_hash(switch) 
	gets a Hash vlan => bitmask
 get_t_mask_hash(switch) 
	gets a Hash vlan => bitmask
 get_vlan_mask(switch, vlan, mode)
	gets bitmask by vlan and mode. possible modes are tagged, untagged or forbidden
 set_vlan_mask(switch, vlan, mode, mask)
	sets bitmask by vlan and mode. possible modes are tagged, untagged or forbidden
	Bitte beachten: - es MUSS mindestens ein Port tagged anliegen
			- es MUSS der Port erst tagged anliegen bevor er untagged anliegen kann
			- es darf nur ein Port untagged anliegen
			- 
 port_to_vlan(switch, port, vlan, [tagged, untagged])
	push port to vlan
 set_port(portnummer, mask, operation)
	manipuliert die Bitmaske. possible operations and, or, xor
 cdp_neighbors(switch, port)
	get the neighbors by port
 		
=head2 EXPORT

 get_maclist_from_switch
 get_ether_ports
 write_MACs
 mac2decmac
 set_alarm
 get_alarm
 set_learnmode
 get_learnmode
 set_enabled
 get_enabled
 get_up
 set_portalias
 get_portalias
 get_switch_vlan
 add_switch_vlans
 del_switch_vlans
 set_vlan_name
 get_ut_mask_hash
 get_t_mask_hash
 get_vlan_mask
 set_vlan_mask
 port_to_vlan
et_port
 cdp_neighbor
 
=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Volker M. Henze, E<lt>volker.henze@stud.tu-ilmenau.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Volker M. Henze

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
