package Btail::Btail;

use strict;
use warnings;

use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use Carp qw(croak confess);
use Time::Local;
use Exporter qw(import);

use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/';

use Btail::Dates qw(parse_date days_back days_frwd);

our @EXPORT_OK = qw(make_btail_iterator);

sub make_btail_iterator {
	my $file    = shift || croak "No filename";
	my $options = shift || croak "No options struct";

	open my $fh, "<", "$file" or croak "Couldn't open $file: $!";
	binmode $fh, ':encoding(UTF-8)';

	my $range = get_range($fh, $options);

	seek $fh, $$range{from}, SEEK_SET;

	($$range{from} == 0)
		or <$fh>; #fix cursor

	my $count = 0;

	return sub {
		if ((defined $$range{to}
				&& tell($fh) > $$range{to})
				|| (defined $$range{lines}
				&& $count++ >= $$range{lines})) {
			close $fh;
		} elsif (fileno $fh) {
			my $line = <$fh>;
			return $line if defined $line;
			close $fh;
		}
		return undef;
	}
}

sub bsearch_point {
	my $fh    = shift;
	my $point = shift;
	my $begin = shift;
	my $end   = shift;

	my ($middle, $value);

	(defined $begin)
		or (seek $fh, 0, SEEK_SET
			and $begin = tell $fh);

	(defined $end)
		or (seek $fh, 0, SEEK_END
			and $end = tell $fh);

	$middle = int(($begin + $end) / 2);

	my $offset = 10; #this seems to help align correctly, not sure why
	seek $fh, ($middle-$offset), SEEK_SET;

	$value = parse_date(read_line($fh)) || confess "Couldn't parse line";

	if ($begin >= $end || $value == $point) {
		return $middle;
	} elsif ($value < $point) {
		return bsearch_point($fh, $point, $middle+1, $end);
	} elsif ($value > $point) {
		return bsearch_point($fh, $point, $begin, $middle-1);
	}
}

sub read_line {
	my $fh = shift;

	<$fh>; #fix cursor
	my $line = <$fh>;

	chomp $line;
	return $line;
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
		and croak "Start of range invalid: before 0";

	if ($$options{to_date}) {
		$range{to} = bsearch_point($fh, parse_date($$options{to_date}));
	} elsif ($$options{days}) {
		$range{to} = bsearch_point($fh, days_frwd($$options{days}, parse_date($$options{from_date})), $range{from});
	}

	if ($$options{lines}) {
		$range{lines} = $$options{lines}
	}

	(defined $range{to} && $range{to} < $range{from})
		and croak "End of range invalid: before start of range";

	return \%range;
}

__END__
