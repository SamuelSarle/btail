#!/usr/bin/perl -w

package main;

use strict;
use warnings;
#use diagnostics;
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);

use feature qw(:all);

local $, = "\n";
local $| = 1;

my @f = map { s/[^\w\.\-\/]//g; $_ } @ARGV;

foreach my $file (@f) {
	bsearch_point(99275, $file);
}

sub bsearch_point {
	my $point = shift;
	my $file = shift;
	my ($begin, $end, $middle, $line, $value);

	open my $IN, "<", "$file" or warn "Couldn't open file!: $file\n";

	die "Value not in range!: $file\n" if not value_in_range($point, $IN);

	seek $IN, 0, SEEK_SET;
	$begin = tell $IN;

	seek $IN, 0, SEEK_END;
	$end = tell $IN;

	$middle = int($begin+$end / 2);

	seek $IN, 0, SEEK_SET;
	while($begin <= $end) {
		$middle = $begin + int(($end - $begin) / 2);
		say "begin $begin";
		say "middle $middle";
		say "end $end";
		#say "value $value";
		$line = read_line($IN);
		say "line $line";
		$value = int $line;
		say "value $value";
		if ($point > $value) {
			say "POINT MORE THAN VALUE; SEEKED TO $middle";
			#$begin = $middle + 1;
			seek $IN, $middle+1, SEEK_SET;
			$begin = tell $IN;
		} elsif ($point < $value) {
			say "POINT LESS THAN VALUE; SEEKED TO $middle";
			#$end = $middle - 1;
			seek $IN, $middle-1, SEEK_SET;
			$end = tell $IN;
		} else {
			say "VALUE AND POINT ARE SAME";
			die "Found match at :$begin:$middle:$end;\n";
		}
		sleep 5;
		say <<EOF;

--------------------------------------------------------------------------------
EOF
	}

	close $IN;
}

sub read_line {
	my $fh = shift;

	my $cur = tell $fh;
	<$fh>;
	my $line = readline $fh;
	$cur = tell $fh;

	seek $fh, $cur, SEEK_SET;

	chomp $line;
	return $line;
}

sub value_in_range {
	my $point = shift;
	my $file_h = shift;
	my ($first, $last);

	$first = int <$file_h>;
	while(<$file_h>) {
		$last = int $_;
	}
	return ($point >= $first && $point <= $last)
}

sub print_file {
	my (@files) = @_ || die;
}

__END__

99071
99130
99275
99388
99456
99557
99616
99677
99954
99958
