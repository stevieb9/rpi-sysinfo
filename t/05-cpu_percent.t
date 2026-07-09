use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

# cpuPercent() reads /proc/stat, which is Linux-wide, not Pi-specific, so this
# runs on any Linux host (not just a Pi board).
if ($^O ne 'linux'){
    plan skip_all => "cpuPercent() reads /proc/stat (Linux only)";
}

my $sys = RPi::SysInfo->new;

is ref $sys, 'RPi::SysInfo', "object is of proper class";

like $sys->cpu_percent, qr/^\d+\.\d+$/, "cpu_percent() method return ok";

sleep 1;

like cpu_percent, qr/^\d+\.\d+$/, "cpu_percent() function return ok";

done_testing();