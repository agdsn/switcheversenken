#!/usr/bin/perl

# setzt Port auf einem Switch auf den jeweils anderen Status enabled oder disabled

use HPSNMP;

#use strict;

my ($switch, $port, $enabled, undef) = @ARGV;

$switch = "192.168.1.".$switch;


if ($enabled == 1){
  set_enabled($switch, $port, 2);
}
elsif ($enabled == 0) {
  set_enabled($switch, $port, 1);
}
