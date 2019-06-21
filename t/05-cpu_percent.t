use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

my $sys = RPi::SysInfo->new;

is ref $sys, 'RPi::SysInfo', "object is of proper class";

like $sys->cpu_percent, qr/^\d+\.\d+$/, "cpu_percent() method return ok";
like cpu_percent, qr/^\d+\.\d+$/, "cpu_percent() function return ok";

done_testing();