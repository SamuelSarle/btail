#!/usr/bin/perl -w

package main;

use strict;
use warnings;
#use diagnostics;
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use Carp qw(carp croak confess);
use Getopt::Long;
use Time::Local;

use v5.28;

use feature qw(:all);

my %options = (
	'lines'     => 0,
	'from_date' => '',
	'to_date'   => '',
	'days_ago'  => 0,
	'days'      => 0,
	'quiet'     => 1,
);

GetOptions(
	'lines=i'     => \$options{'lines'},
	'from_date=s' => \$options{'from_date'},
	'to_date=s'   => \$options{'to_date'},
	'days_ago=i'  => \$options{'days_ago'},
	'days=i'      => \$options{'days'},
	'verbose!'    => \$options{'quiet'},
) or croak "Error in command line arguments";

{
	use Data::Dumper;
	print Dumper \%options;
	parse_date($options{'from_date'});
	exit;
}

local $, = "\n"; # TMP list seperator
local $| = 1; #autoflush

my @f = map { s/[^\w\.\-\/]//g; $_ } @ARGV;

foreach my $file (@f) {
	open my $fh, "<", "$file" or carp "Couldn't open $file: $!" and next;
	binmode $fh, ':encoding(UTF-8)';
	my $print_from = bsearch_point($fh, 999734);

	print_file($fh, $print_from);

	close $fh;
}

sub bsearch_point {
	my $fh    = shift;
	my $point = shift;
	my $begin = shift || 0;
	my $end   = shift || 0;

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

sub parse_date {
	my $string = shift || return 0;
	my $epoch;

	my %months = qw(Jan 0 Feb 1 Mar 2 Apr 3 May 4 Jun 5 Jul 6 Aug 7 Sep 8 Oct 9 Nov 10 Dec 11);

	#my ($year, $mon, $day, $hour, $min, $sec) = (0,0,0,0,0,0,0);
	($string =~
		m{
			^
			(?<year>\d{4,})
			[ / : \\ ]?
			(?<mon>[0-9]|1[0-2])
			[ / : \\ ]?
			(?<day>[0-2][0-9]|3[01])
			(?:
			[ / : \\ ]?
			(?<hour>[01][0-9]|2[0-3])
			[ / : \\ ]?
			(?<min>[0-5][0-9])
			[ / : \\ ]?
			(?<sec>[0-5][0-9])
			)?
			$
		}xx
	or $string =~
		m{
			^
			(?:[A-Z][a-z]{2})       #Mon, Tue, Wed..
			\s
			(?<mname>[A-Z][a-z]{2}) #Jan, Feb, Mar..
			\s
			[\s0]?(?<mon>[1-9]|[1-2][0-9]|3[01])\s #month day
			((?<hour>[01][0-9]|2[0-3])
			:(?<min>[0-5][0-9])
			:(?<sec>[0-5][0-9]))
			\s
			(?<year>\d{4,})
			$
		}xx
	);
	$+{mon} = $months{$+{mname}} if (defined $+{mname});

	$epoch = timelocal($+{sec}||0,
						$+{min}||0,
						$+{hour}||0,
						$+{day}||0,
						($+{mon}>0?$+{mon}-1:0),
						$+{year}||0
					);
	say $epoch;

	return $epoch;
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

