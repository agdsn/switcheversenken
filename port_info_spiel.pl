#!/usr/bin/perl

# ruft Status enabled/disabled und up/down der Switche ab (muss nur einmal ganz am Anfang aufgerufen werden und nochmal kurz vor dem Spiel)

use HPSNMP;

#use strict;
use DBI;


#my ($switch1, $switch2, $switch3, $switch4, $switch5, $switch6, undef) = @ARGV;

$switch[1] = "192.168.1.1";
$switch[2] = "192.168.1.2";
#$switch[2] = $switch2.".fem.tu-ilmenau.de";
#$switch[1] = "141.24.55.222";
#$switch[3] = "192.168.1.3";
#$switch[4] = "192.168.1.4";
#$switch[5] = "192.168.1.5";
#$switch[6] = "192.168.1.6";



$port = 1;

my %helfer = ('a' => 1, 'b' => 65, 'c' => 129, 'd' => 72, 'e' => 96, 'f' => 120, 'g' => 144);

if ($port =~ /([a-g])([0-9]+)/i)
{
    $port = $helfer{lc($1)} + $2;
}

$port_alt = $port;

$a = 2;

#my $switch = HPSNMPv2->new();
#my $enabled = get_enabled($switch, $port);
#print "Port ",$port," ist enabled.\n" if $enabled == 1;
#print "Port ",$port," ist disabled.\n" if $enabled == 2;
#$port = $port + 1;

while ($a < 3) {
  my $dbargs = {AutoCommit => 0, PrintError => 1};
  my $dbh = DBI->connect("dbi:SQLite:dbname=schiffe.db", "", "", $dbargs);


#  for(my $z = 1; $z <= 2; $z++){
#
#    $port = $port_alt;
#
#    for my $k("a","b","c"){                                                                                                                                                                                                                   
#	$port = $k;                                                                                                                                                                                                                           
#	print $port,"\n";                                                                                                                                                                                                                     
#	$port = 1 if $port eq "a";                                                                                                                                                                                                            
#	$port = 65 if $port eq "b";                                                                                                                                                                                                           
#	$port = 129 if $port eq "c";                                                                                                                                                                                                          
#	print $port,"\n";
#	for(my $i = 1; $i <= 24; $i++) {
#    	    my $enabled = get_enabled($switch[$z], $port);
#    	    #$dbh->do("UPDATE switche SET enabled='1', up='0' WHERE switch='$z' AND port='$port';") if $enabled == 1;
#    	    #$dbh->do("UPDATE switche SET enabled='0', up='0' WHERE switch='$z' AND port='$port';") if $enabled == 2;
#    	    $dbh->do("INSERT INTO switche (switch,port,enabled,up) VALUES ($z,$port,'1','0');") if $enabled == 1;
#    	    $dbh->do("INSERT INTO switche (switch,port,enabled,up) VALUES ($z,$port,'0','0');") if $enabled == 2;
#    	    #print "1" if $enabled == 1;
#    	    #print "0" if $enabled == 2;
#    	    $port = $port + 1;
#	}
#    }
#
#    #print "\n";
# }

  for(my $z = 1; $z <= 2; $z++){
    $port = $port_alt;

    for my $k("a","b","c"){
	$port = $k;
	print $port,"\n";
	$port = 1 if $port eq "a";
	$port = 65 if $port eq "b";
	$port = 129 if $port eq "c";
	print $port,"\n";

	for(my $i = 1; $i <= 24; $i++) {
	    
    	    my $up = get_up($switch[$z], $port);
#	    print "Port ",$port," ist up.\n" if $up == 1;
#	    print "Port ",$port," ist down.\n" if $up == 2;
      		$dbh->do("UPDATE switche SET up='1' WHERE switch='$z' AND port='$port';") if $up == 1;
  		$dbh->do("UPDATE switche SET up='0' WHERE switch='$z' AND port='$port';") if $up == 2;
    	    #print "1" if $up == 1;
    	    #print "0" if $up == 2;
        $port = $port + 1;
	}
    }

    #print "\n";
  }

print "done\n";

  if ($dbh->err()) { die "$DBI::errstr\n"; }
  $dbh->commit();
  $dbh->disconnect();
}