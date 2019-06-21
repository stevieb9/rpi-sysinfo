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

    print "$temp\n";

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

=head1 EXPORT_OK

=head1 FUNCTIONS/METHODS

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
