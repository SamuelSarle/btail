#!/usr/bin/perl -w

package main;

use strict;
use warnings;
use feature qw(:all);

use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use Carp qw(carp croak confess);
use Getopt::Long;
use Time::Local;

local $| = 1;    # autoflush

my %options = (
	'lines'     => 0,
	'from_date' => '',
	'to_date'   => '',
	'days_ago'  => 0,
	'days'      => 0,
	'verbose'   => 0,
	'help'      => 0,
	'test'      => 0,
);

GetOptions(
	'lines=i'     => \$options{'lines'},
	'from_date=s' => \$options{'from_date'},
	'to_date=s'   => \$options{'to_date'},
	'days_ago=i'  => \$options{'days_ago'},
	'days=i'      => \$options{'days'},
	'verbose'     => \$options{'verbose'},
	'help'        => \$options{'help'},
	'test'        => \$options{'test'},
) or croak "Error in command line arguments";

main(@ARGV);

sub main {
	my @files = @_;

	(_usage() and exit) if $options{'help'};
	(_tests() and exit) if $options{'test'};

	my @f = grep { m/[\w\.\-\/]/ } @files;

	foreach my $file (@f) {
		open my $fh, "<", "$file" or my_carp("Couldn't open $file: $!") and next;
		binmode $fh, ':encoding(UTF-8)';

		my $range = get_range($fh, \%options);

		###
		#
		# Either make an iterator like this:
			my $it = make_btail_iterator($fh, $range);
			my $line;
			print $line while($line = $it->());
		#
		###
		#
		# Or just print file to STDOUT like this:
			#print_file($fh, $range);
		#
		###

		close $fh;
	}
}

sub bsearch_point {
	my $fh    = shift;
	my $point = shift;
	my $begin = shift;
	my $end   = shift;

	my ($middle, $line, $value);

	(defined $begin)
		or (seek $fh, 0, SEEK_SET
			and $begin = tell $fh);

	(defined $end)
		or (seek $fh, 0, SEEK_END
			and $end = tell $fh);

	seek $fh, $begin, SEEK_SET;

	my $offset = 10; #this seems to help align correctly, not sure why

	while($begin <= $end) {
		$middle = int(($begin + $end) / 2);

		seek $fh, ($middle-$offset), SEEK_SET;

		$value = parse_date(read_line($fh)) || confess "Couldn't parse line";

		if ($value < $point) {
			$begin = $middle + 1;
		} elsif ($value > $point) {
			$end = $middle - 1;
		} else {
			last;
		}

		($end <= 0)
			and my_carp("Hit beginning of file")
			and ($middle = $end)
			and last;
	}

	($middle < 0) #shouldn't happen
		and $middle = 0;

	return $middle;
}

sub read_line {
	my $fh = shift;

	<$fh>; #fix cursor
	my $line = <$fh>;

	chomp $line;
	return $line;
}

sub print_file {
	my $fh    = shift || confess "No filehandle";
	my $range = shift || confess "No range struct";

	seek $fh, $$range{from}, SEEK_SET;

	($$range{from} == 0)
		or <$fh>; #fix cursor

	my $line;
	my $count = 0;
	while($line = <$fh>) {
		print $line;

		if ($$range{to}) {
			last if (tell($fh) > $$range{to});
		} elsif ($$range{lines}) {
			last if $count >= $$range{lines};
			$count++;
		}
	}
}

sub make_btail_iterator {
	my $fh    = shift || confess "No filehandle";
	my $range = shift || confess "No range struct";

	seek $fh, $$range{from}, SEEK_SET;

	($$range{from} == 0)
		or <$fh>; #fix cursor

	my $count = 0;

	return sub {
		((defined $$range{to} && tell($fh) > $$range{to}) || (defined $$range{lines} && $count++ >= $$range{lines}))
			and return undef;

		my $line = <$fh>;

		return $line;
	}
}

sub get_range {
	my $fh      = shift || confess "No filehandle";
	my $options = shift || confess "No options";

	my %range;

	if ($$options{from_date}) {
		$range{from} = bsearch_point($fh, parse_date($$options{from_date}));
	} elsif ($$options{days_ago}) {
		$range{from} = bsearch_point($fh, days_ago($$options{days_ago}));
	}

	(!defined $range{from} || $range{from} < 0)
		and croak "Start of range invalid";

	if ($$options{to_date}) {
		$range{to} = bsearch_point($fh, parse_date($$options{to_date}));
	} elsif ($$options{days}) {
		$range{to} = bsearch_point($fh, days_frwd($$options{days}, parse_date($$options{from_date})), $range{from});
	}

	if ($$options{lines}) {
		$range{lines} = $$options{lines}
	}

	(defined $range{to} && $range{to} < $range{from})
		and croak "End of range invalid";

	return \%range;
}

sub parse_date {
	my $string = shift || return 0;
	my $epoch;

	my %months = qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);

	($string =~
		m{
			^
			(?<year>\d{4,})
			[ / : \\ \s ]
			(?<mon>0[1-9]|1[0-2])
			[ / : \\ \s ]
			(?<day>[0-2][0-9]|3[01])
			(?:
			[ / : \\ \s ]
			(?<hour>[01][0-9]|2[0-3])
			[ / : \\ \s ]
			(?<min>[0-5][0-9])
			[ / : \\ \s ]
			(?<sec>[0-5][0-9])
			)?
			$
		}xx
	or $string =~
		m{
			^
			(?<day>[0-2][0-9]|3[01])
			[ / : \\ \s ]
			(?<mon>0[1-9]|1[0-2])
			[ / : \\ \s ]
			(?<year>\d{4,})
			(?:
			[ / : \\ \s ]
			(?<hour>[01][0-9]|2[0-3])
			[ / : \\ \s ]
			(?<min>[0-5][0-9])
			[ / : \\ \s ]
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

sub days_back {
	my $d = shift || 0;
	my $p = shift || time();
	return ($p - ($d*24*60*60));
}

sub days_frwd {
	my $d = shift || 0;
	my $p = shift || 0;
	return ($p + ($d*24*60*60));
}

sub _usage {
	say <<EOF;
usage: btail [--from_date | --days_ago] [--to_date | --days] [file ...]

Start point for printing:
--from_date Define start as a date string
--days_ago  Define start as n days ago from today

End point for printing:
--to_date   Define end of print as a date string
--days      Days forward from start of print

--lines     Print maximum of n lines

Other:
--verbose   More verbosity
--help      Print this message
--test      Run tests
EOF
}

sub my_carp {
	my $m = shift || '';
	($options{verbose}
		and carp "$m")
}

sub _tests {
	_test_parse_date();
	_test_days_back_frwd();
	say "Tests pass.";
}

sub _test_parse_date {
	for (0..50) {
		my $epoch = int rand 1e9;

		my ($sec, $min, $hour, $day, $mon, $year, undef, undef, undef) = (localtime $epoch);

		my $string_one = scalar localtime $epoch;

		my $string_two = sprintf("%04d/%02d/%02d %02d:%02d:%02d",
						$year+1900, $mon+1, $day, $hour, $min, $sec);

		my $string_three = sprintf("%02d/%02d/%04d %02d:%02d:%02d",
						$day, $mon+1, $year+1900, $hour, $min, $sec);


		for ($string_one, $string_two, $string_three) {
			($epoch == parse_date($_))
				or confess "Error in parse_date; $epoch, $_";
		}
	}
}

sub _test_days_back_frwd {
	my ($now, $last, $days, $new);
	$last = $now = time();
	for (0..50) {
		$days = int rand 1e5;

		my $back = days_back($days, $now);
		my $frwd = days_frwd($days, $back);

		($back == ($now-$days*24*60*60) && $frwd == $now)
			or confess "Error in days_back, days_frwd; $now, $back, $frwd";
	}

	((days_back(0, $now) == $now)
		and (days_frwd(0, $now) == $now))
		or confess "Error in days_back, days_frwd; zero days doesn't equal today";
}

__END__
