#!/usr/bin/perl -w

package main;

use strict;
use warnings;
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use Carp qw(carp croak confess);
use Getopt::Long;
use Time::Local;

use feature qw(:all);

local $, = "\n"; # TMP list seperator
local $| = 1;    # autoflush

my %options = (
	'lines'     => 0,
	'from_date' => '',
	'to_date'   => '',
	'days_ago'  => 0,
	'days'      => 0,
	'quiet'     => 1,
	'help'      => 0,
	'test'      => 0,
);

GetOptions(
	'lines=i'     => \$options{'lines'},
	'from_date=s' => \$options{'from_date'},
	'to_date=s'   => \$options{'to_date'},
	'days_ago=i'  => \$options{'days_ago'},
	'days=i'      => \$options{'days'},
	'verbose!'    => \$options{'quiet'},
	'help'        => \$options{'help'},
	'test'        => \$options{'test'},
) or croak "Error in command line arguments";

0 and do {
	use Data::Dumper;
	print Dumper \%options;
	parse_date($options{'from_date'});
	parse_date("Wed Jan 19 02:11:34 2000");
	exit;
};

main(@ARGV);

sub main {
	(usage() and exit) if $options{'help'};
	(tests() and exit) if $options{'test'};

	my @files = @_;

	my @f = map { s/[^\w\.\-\/]//g; $_ } @files;

	foreach my $file (@f) {
		open my $fh, "<", "$file" or carp "Couldn't open $file: $!" and next;
		binmode $fh, ':encoding(UTF-8)';
		my $print_from = bsearch_point($fh, 999734);

		print_file($fh, $print_from);

		close $fh;
	}
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

		$value = int $line or confess "Couldn't parse line";

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

	my %months = qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);

	($string =~
		m{
			^
			(?<year>\d{4,})
			[ / : \\ \s ]?
			(?<mon>0[1-9]|1[0-2])
			[ / : \\ \s ]?
			(?<day>[0-2][0-9]|3[01])
			(?:
			[ / : \\ \s ]?
			(?<hour>[01][0-9]|2[0-3])
			[ / : \\ \s ]?
			(?<min>[0-5][0-9])
			[ / : \\ \s ]?
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
			[\s0]?(?<day>[1-9]|[1-2][0-9]|3[01])
			\s
			((?<hour>[01][0-9]|2[0-3])
			:(?<min>[0-5][0-9])
			:(?<sec>[0-5][0-9]))
			\s
			(?<year>\d{4,})
			$
		}xx
	);
	my ($year, $mon, $day, $hour, $min, $sec) =
			($+{year},
			(defined $+{mname} ? $months{$+{mname}}:$+{mon}),
			$+{day},
			$+{hour},
			$+{min},
			$+{sec});

	$epoch = timelocal($sec||0,
						$min||0,
						$hour||0,
						$day||0,
						($mon>0?$mon-1:0), # should never be <=0
						$year||0
		) or confess "Failed to convert date";

	return $epoch;
}

sub usage {
	confess "usage() not implemented";
}

sub tests {
	test_parse_date();
	say "Tests pass.";
}

sub test_parse_date {
	for (0..250) {
		my $epoch = int rand 1e9;

		my ($sec, $min, $hour, $day, $mon, $year, undef, undef, undef) = (localtime $epoch);

		my $string_one = sprintf("%04d/%02d/%02d %02d:%02d:%02d",
						$year+1900, $mon+1, $day, $hour, $min, $sec);

		my $string_two = scalar localtime $epoch;

		($epoch == parse_date($string_one)
		and ($epoch == parse_date($string_two)))
			or confess "Fix your parse_date";
	}
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

