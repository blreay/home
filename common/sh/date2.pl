#!/usr/local/bin/perl

use Time::HiRes;
 
#$datestring = localtime();
#print "Local date and time $datestring\n";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
($s, $usec) = Time::HiRes::gettimeofday();
#print "$s  $usec\n";
#printf("%02d %02d\n", $s % 60, (($s-$s%60)/60)%60);
printf("%04d%02d%02d %02d:%02d:%02d.%03d\n", $year+1900, $mon+1, $mday+1, $hour, $min, $sec, $usec/1000); 
#printf("%04d%02d%02d %02d:%02d:%02d.%03d\n", $year+1900, $mon+1, $mday+1, $hour, (($s-$s%60)/60)%60, $s%60, $usec/1000);
printf("%04d%02d%02d %02d:%02d:%02d.%03d\n", $year+1900, $mon+1, $mday+1, $hour, (($s-$s%60)/60)%60, $s%60, $usec/1000);
