use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

my $sys = RPi::SysInfo->new;

is ref $sys, 'RPi::SysInfo', "object is of proper class";

like $sys->mem_percent, qr/^\d+\.\d+$/, "mem_percent() method return ok";
like mem_percent, qr/^\d+\.\d+$/, "mem_percent() function return ok";

done_testing();