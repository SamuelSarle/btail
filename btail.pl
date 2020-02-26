#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Carp qw(croak);

use File::Basename qw(dirname);
use Cwd  qw(abs_path);

use lib dirname(abs_path $0) . '/lib';
use Btail::Btail qw(make_btail_iterator);

local $| = 1;    # autoflush

my %options = (
	'lines'     => 0,
	'from_date' => '',
	'to_date'   => '',
	'days_ago'  => 0,
	'days'      => 0,
	'help'      => 0,
);

GetOptions(
	'lines=i'     => \$options{'lines'},
	'from_date=s' => \$options{'from_date'},
	'to_date=s'   => \$options{'to_date'},
	'days_ago=i'  => \$options{'days_ago'},
	'days=i'      => \$options{'days'},
	'help'        => \$options{'help'},
) or croak "Error in command line arguments";

main(@ARGV);

sub main {
	my @files = @_;

	(_usage() and exit) if $options{'help'};

	foreach my $file (@files) {
		my $it = make_btail_iterator($file, \%options);
		my $line;
		print $line while($line = $it->());
	}
}

sub _usage {
	print <<EOF;
usage: btail [--from_date | --days_ago] [--to_date | --days] [file ...]

Start point for printing:
--from_date Define start as a date string
--days_ago  Define start as n days ago from today

End point for printing:
--to_date   Define end as a date string
--days      Days forward from start of print

--lines     Print maximum of n lines

Other:
--help      Print this message
EOF
}

__END__
