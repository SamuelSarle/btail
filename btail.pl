#!/usr/bin/perl -w

package main;

use strict;
use warnings;
#use diagnostics;
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);

use v5.28;

use feature qw(:all);

local $, = "\n";
local $| = 1;

my @f = map { s/[^\w\.\-\/]//g; $_ } @ARGV;

foreach my $file (@f) {
	bsearch_point(999734, $file);
}

sub bsearch_point {
	my $point = shift;
	my $file = shift;
	my $begin = shift || 0;
	my $end = shift || 0;

	my ($middle, $line, $value);

	open my $IN, "<", "$file" or warn "Couldn't open file!: $file\n";
	binmode $IN, ':encoding(UTF-8)';

	die "Value not in range!: $file\n" if not value_in_range($point, $IN);

	seek $IN, 0, SEEK_SET;
	$begin = tell $IN;

	seek $IN, 0, SEEK_END;
	$end = tell $IN;

	seek $IN, 0, SEEK_SET;
	my $count = 1;
	while($begin <= $end) {
		$middle = int(($begin + $end) / 2);
		seek $IN, $middle, SEEK_SET;
		$line = read_line($IN);
		$value = int $line || 0;
		if ($value < $point) {
			$begin = $middle + 1;
		} elsif ($value > $point) {
			$end = $middle - 1;
		} else {
			last;
		}
		sleep 0.1;
		say $count++;
	}
	<$IN>;
	print $_ while (<$IN>);

	close $IN;
}

sub read_line {
	my $fh = shift;

	<$fh>; #need to fix cursor to begin of line # TODO go backwards ?
	my $line = <$fh>;

	chomp $line;
	return $line;
}

sub value_in_range {
	my $point = shift;
	my $file_h = shift;
	my ($first, $last);

	$first = int <$file_h>;
	while(<$file_h>) { # TODO remove requirement to read whole file
		$last = int $_;
	}
	return ($point >= $first && $point <= $last)
}

sub print_file { # TODO
	my (@files) = @_ || die;
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

