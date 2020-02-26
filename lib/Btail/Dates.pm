package Btail::Dates;

use strict;
use warnings;

use Carp qw(confess);
use Time::Local;
use Exporter qw(import);

our @EXPORT_OK = qw(parse_date days_back days_frwd);

sub parse_date {
	my $string = shift || return 0;
	my $epoch;

	my %months = qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);

	($string =~
		m{
			^
			(?<year>\d{4,})
			[ / : \\ \s \-]
			(?<mon>0[1-9]|1[0-2])
			[ / : \\ \s \-]
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
			[ / : \\ \s \-]
			(?<mon>0[1-9]|1[0-2])
			[ / : \\ \s \-]
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
