package RPi::SysInfo;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RPi::SysInfo', $VERSION);

use Exporter qw(import);

our @EXPORT_OK = qw(
    core_temp
    cpu_percent
    mem_percent
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

sub new {
    return bless {}, shift;
}
sub core_temp {
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

    return $temp;
}
sub cpu_percent {
    return _format(cpuPercent());
}
sub mem_percent {
    return _format(memPercent());
}
sub _format {
    croak "_format() requires a float/double sent in\n" if ! defined $_[0];
    return sprintf("%.2f", $_[0]);
}
1;
__END__

=head1 NAME

RPi::SysInfo - Retrieve system information from a Raspberry Pi

=head1 DESCRIPTION

Fetch live-time and other system information from a Raspberry Pi.

Most functions will work equally as well on most Unix/Linux systems.

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

=head1 PRIVATE FUNCTIONS/METHODS

=head2 _format($float)

Formats a float/double value to two decimal places.

Parameters:

    $float

Mandatory, Float/Double: The number to format.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of RPi::SysInfo
