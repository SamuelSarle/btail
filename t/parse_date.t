use strict;
use warnings;

use Test::Simple tests => 30;

use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

use Btail::Dates qw(parse_date);

for (1..10) {
	my $epoch = int rand 1e9;

	my ($sec, $min, $hour, $day, $mon, $year, undef, undef, undef) = (localtime $epoch);

	my $string_one = scalar localtime $epoch;

	my $string_two = sprintf("%04d/%02d/%02d %02d:%02d:%02d",
					$year+1900, $mon+1, $day, $hour, $min, $sec);

	my $string_three = sprintf("%02d/%02d/%04d %02d:%02d:%02d",
					$day, $mon+1, $year+1900, $hour, $min, $sec);

	for ($string_one, $string_two, $string_three) {
		ok( $epoch == parse_date($_) );
	}
}
