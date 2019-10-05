#!/usr/bin/perl -w

package main;

use strict;
use warnings;
#use diagnostics;
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use Carp qw(carp croak confess);

use v5.28;

use feature qw(:all);

local $, = "\n"; # TMP list seperator
local $| = 1; #autoflush

my @f = map { s/[^\w\.\-\/]//g; $_ } @ARGV;

foreach my $file (@f) {
	open my $fh, "<", "$file" or carp "Couldn't open $file: $!\n";
	binmode $fh, ':encoding(UTF-8)';
	my $print_from = bsearch_point($fh, 999734);

	print_file($fh, $print_from);

	close $fh;
}

sub bsearch_point {
	my $fh = shift;
	my $point = shift;
	my $begin = shift || 0;
	my $end = shift || 0;

	my ($middle, $line, $value);

	seek $fh, 0, SEEK_SET;
	$begin = tell $fh;

	seek $fh, 0, SEEK_END;
	$end = tell $fh;

	seek $fh, 0, SEEK_SET;
	while($begin <= $end) {
		$middle = int(($begin + $end) / 2);

		seek $fh, $middle, SEEK_SET;
		$line = read_line($fh);

		$value = int $line or confess "Couldn't read line";

		if ($value < $point) {
			$begin = $middle + 1;
		} elsif ($value > $point) {
			$end = $middle - 1;
		} else {
			last;
		}

		($end <= 0)
			and carp "Hit beginning of file"
			and ($middle = $end)
			and last;
	}

	($middle < 0) #shouldn't happen
		and $middle = 0;

	return $middle;
}

sub read_line {
	my $fh = shift;

	# TODO do we need to go backwards ?
	<$fh>; #fix cursor
	my $line = <$fh>;

	chomp $line;
	return $line;
}

sub print_file {
	my $fh = shift|| return;
	my $print_from = shift || 0;

	seek $fh, $print_from, SEEK_SET;

	($print_from == 0)
		or <$fh>; #fix cursor

	my $line;

	print $line while($line = <$fh>);
}

__END__

999713
999719
999721
999725
999734
999735
999737
999749
999755
999764
999775
999801
999805
999815
999816
999826
999830
999833
999840
999846
999849
999871
999889
999891
999892
999902
999914
999928
999945
999946
999971
999986
999995

