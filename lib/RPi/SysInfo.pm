package RPi::SysInfo;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '1.01';

require XSLoader;
XSLoader::load('RPi::SysInfo', $VERSION);

use Exporter qw(import);

our @EXPORT_OK = qw(
    core_temp
    cpu_percent
    mem_percent
    gpio_info
    raspi_config
    network_info
    file_system
    pi_details
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

sub new {
    return bless {}, shift;
}
sub core_temp {
    shift if $_[0] && $_[0] =~ /RPi::/;

    my ($degree) = @_;

    $degree //= 'c';

    local $SIG{__WARN__} = sub {
        my $warning = shift;
        if ($warning !~ /Can't exec "vcgencmd"/){
            warn $warning;
        }
    };

    my $temp = `vcgencmd measure_temp`;

    if (! defined $temp){
        croak "issue executing the core temp command, can't continue...\n";
    }

    $temp =~ s/(temp=)//;
    $temp =~ s/'.*//;

    if ($degree eq 'f' || $degree eq 'F'){
        $temp = ($temp * 1.8) + 32;
    }

    chomp $temp;
    return $temp;
}
sub cpu_percent {
    return _format(cpuPercent());
}
sub gpio_info {
    shift if $_[0] && $_[0] =~ /RPi::/;

    my ($pins) = @_;

    $pins = ! defined $pins
        ? ''
        : join ",", @$pins;

    # raspi-gpio was removed from current Raspberry Pi OS in favour of pinctrl,
    # and never existed for the Pi 5 / RP1. Prefer pinctrl, falling back to
    # raspi-gpio on older systems that still ship it. Both accept the same
    # "get [pin[,pin...]]" invocation.

    my $tool = _gpio_tool();

    return '' if ! defined $tool;

    my $info = `$tool get $pins`;
    $info = '' if ! defined $info;

    chomp $info;
    return $info;
}
sub mem_percent {
    return _format(memPercent());
}
sub network_info {
    my $netinfo = `ifconfig`;
    chomp $netinfo;
    return $netinfo;
}
sub raspi_config {
    my $config = `vcgencmd get_config int`;
    $config .= `vcgencmd get_config str`;

    # config.txt moved from /boot to /boot/firmware on Bookworm and later (the
    # old path now holds only a "this file has moved" stub), so resolve the
    # real location before appending the user's non-comment directives.

    my $config_file = _config_file();

    if (defined $config_file){
        $config .= `grep -E -v '^\\s*(#|^\$)' $config_file`;
    }

    chomp $config;
    return $config;
}
sub file_system {
    my $fs_info = `df` . "\n";
    $fs_info .= `cat /proc/swaps`;
    return $fs_info;
}
sub pi_details {

    my $details;

    $details = "\n"
             . `cat /sys/firmware/devicetree/base/model`
             . "\n\n"
             . `cat /etc/os-release | head -4`
             . "\n"
             . `uname -a`
             . "\n"
             . `cat /proc/cpuinfo | tail -3`
             . "Throttled flag  : " . `vcgencmd get_throttled`
             . "Camera          : " . `vcgencmd get_camera`;

    return $details;
}
sub _config_file {
    # Locate the active config.txt. Bookworm and later moved it to
    # /boot/firmware/config.txt; older systems keep it at /boot/config.txt.

    for my $file ('/boot/firmware/config.txt', '/boot/config.txt'){
        return $file if -f $file;
    }

    return undef;
}
sub _format {
    croak "_format() requires a float/double sent in\n" if ! defined $_[0];
    return sprintf("%.2f", $_[0]);
}
sub _gpio_tool {
    # Locate a GPIO query tool on PATH. pinctrl is the current Raspberry Pi OS
    # utility; raspi-gpio is the legacy one kept here as a fallback.

    for my $tool (qw(pinctrl raspi-gpio)){
        for my $dir (split /:/, $ENV{PATH} // ''){
            return $tool if -x "$dir/$tool";
        }
    }

    return undef;
}
1;
__END__

=head1 NAME

RPi::SysInfo - Retrieve hardware system information from a Raspberry Pi

=head1 DESCRIPTION

Fetch live-time and other system information from a Raspberry Pi.

Most functions will work equally as well on Unix/Linux systems.

=head1 SYNOPSIS

    # Object Oriented

    use RPi::SysInfo;

    my $sys = RPi::SysInfo->new;
    say $sys->cpu_percent;
    say $sys->mem_percent;
    say $sys->core_temp;

    # Functional

    use RPi::SysInfo qw(:all);

    say cpu_percent();
    say mem_percent();
    say core_temp();

=head1 EXPORT_OK

Functions are not exported by default. You can load them each by name:

    cpu_percent
    mem_percent
    core_temp
    gpio_info
    raspi_config
    network_info
    file_system
    pi_details

...or use the C<:all> tag to bring them all in at once.

=head1 FUNCTIONS/METHODS

=head2 new

Instantiates and returns a new L<RPi::SysInfo> object.

Takes no parameters.

=head2 cpu_percent

Returns the percentage of current CPU usage.

Takes no parameters.

Return: Two decimal floating point number.

=head2 mem_percent

Returns the percentage of physical RAM currently in use.

Takes no parameters.

Return: Two decimal floating point number.

=head2 core_temp($scale)

Returns the core CPU temperature of the system.

Parameters:

    $scale

Optional, String: By default we return the temperature in Celcius. Simply send
in the letter C<f> to get the result returned in Fahrenheit.

Return: Two decimal place floating point number.

=head2 gpio_info([$pins])

Fetches the current configuration and status of one or many GPIO pins.

Parameters:

    $pins

Optional, Aref of Integers: By default, we'll return the information for all
GPIO pins on the system. Send in an aref of pin numbers and well fetch the data
for only those pins (eg: C<gpio_info[1]> or C<gpio_info([2, 4, 6, 8])>).

The data is collected with C<pinctrl> (the current Raspberry Pi OS GPIO tool,
and the only one available on the Pi 5 / RP1), falling back to the legacy
C<raspi-gpio> on older systems that still ship it. If neither tool is present,
an empty string is returned.

Return: Single string containing all of the data requested.

=head2 raspi_config

Feteches the directive names and values the Pi is configured with. This includes
the live C<vcgencmd get_config> values plus the non-comment directives from the
active C<config.txt> (C</boot/firmware/config.txt> on Bookworm and later,
falling back to C</boot/config.txt>).

Takes no parameters.

Return: String, the contents of the current configuration.

=head2 file_system

Fetches and returns various file system information as a string.

=head2 network_info

Fetches and returns the Pi's network configuration details as a string.

=head2 pi_details

Fetches and returns various information about the Pi, including the OS info,
along with several hardware platform details as a string.

=head1 PRIVATE FUNCTIONS/METHODS

=head2 _config_file

Returns the path to the active C<config.txt>, preferring the Bookworm-and-later
C</boot/firmware/config.txt> and falling back to the legacy C</boot/config.txt>.
Returns C<undef> if neither exists.

=head2 _format($float)

Formats a float/double value to two decimal places.

Parameters:

    $float

Mandatory, Float/Double: The number to format.

=head2 _gpio_tool

Returns the name of the GPIO query tool found on C<PATH>: C<pinctrl> by
preference, else the legacy C<raspi-gpio>. Returns C<undef> if neither is
installed.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
