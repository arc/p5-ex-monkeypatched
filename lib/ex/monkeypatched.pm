package ex::monkeypatched;

use strict;
use warnings;

use Sub::Name qw<subname>;
use Carp qw<croak>;

our $VERSION = '0.01';

sub import {
    my ($invocant, $target, %routines) = @_;
    eval "CORE::require $target; 1" or die $@;
    while (my ($name, $code) = each %routines) {
        croak qq[Can't monkey-patch: $target already has a method "$name"]
            if $target->can($name);
        _install_subroutine($target, $name, $code);
    }
}

sub _install_subroutine {
    my ($package, $name, $code) = @_;
    my $full_name = "$package\::$name";
    my $renamed_code = subname($full_name, $code);
    no strict qw<refs>;
    *$full_name = $renamed_code;
}

1;
__END__

=head1 NAME

ex::monkeypatched - Experimental API for safe monkey-patching

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it
under the terms of either the GNU General Public License version 2 or, at
your option, the Artistic License.

=cut
