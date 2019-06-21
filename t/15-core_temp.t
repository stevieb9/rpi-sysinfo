use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $sys = RPi::SysInfo->new;

like $sys->core_temp, qr/^\d+\.\d+$/, "core_temp() method return ok";
like core_temp(), qr/^\d+\.\d+$/, "core_temp() function return ok";

done_testing();