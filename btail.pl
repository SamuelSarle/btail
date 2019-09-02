#!/usr/bin/perl -wT
package main;

use strict;
use warnings;
use diagnostics;

my @f = map { s/[^\w\.\-\/]//; $_ } @ARGV;

foreach my $file (@f){
	open IN, "<", "$file" or warn "Couldn't open file!: $file\n";
	while(my $l = <IN>) {
		print $l;
	}
	close IN;
}
