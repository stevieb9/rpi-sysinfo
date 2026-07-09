use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

# memPercent() reads /proc/meminfo, which is Linux-wide, not Pi-specific, so
# this runs on any Linux host (not just a Pi board).
if ($^O ne 'linux'){
    plan skip_all => "memPercent() reads /proc/meminfo (Linux only)";
}

my $sys = RPi::SysInfo->new;

is ref $sys, 'RPi::SysInfo', "object is of proper class";

like $sys->mem_percent, qr/^\d+\.\d+$/, "mem_percent() method return ok";

sleep 1;

like mem_percent, qr/^\d+\.\d+$/, "mem_percent() function return ok";

done_testing();