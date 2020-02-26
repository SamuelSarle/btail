use strict;
use warnings;

use Test::Simple tests => 31;

use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

use Btail::Dates qw(days_back days_frwd);

my ($now, $last, $days, $new);
$last = $now = time();
for (1..30) {
	$days = int rand 1e5;

	my $back = days_back($days, $now);
	my $frwd = days_frwd($days, $back);

	ok ($back == ($now-$days*24*60*60) && $frwd == $now);
}

ok ((days_back(0, $now) == $now) and (days_frwd(0, $now) == $now));

