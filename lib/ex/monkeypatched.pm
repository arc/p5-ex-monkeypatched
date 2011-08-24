package ex::monkeypatched;

use strict;
use warnings;

use Sub::Name qw<subname>;
use Carp qw<croak>;

our $VERSION = '0.01';

sub import {
    my $invocant = shift;
    if (@_) {
        my ($target, %routines) = @_;
        croak qq[Invalid class name "$target"]
            if $target !~ /\A (?!\d) \w+ (?: :: \w+ )* \z/xms;
        eval "CORE::require $target; 1" or die $@;
        $invocant->inject($target => %routines);
    }
}

sub inject {
    my ($invocant, $target, %routines) = @_;
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

=head1 SYNOPSIS

    use ex::monkeypatched 'Third::Party::Class' => (
        clunk => sub { ... },
        eth   => sub { ... },
    );

=head1 BACKGROUND

The term "monkey patching" describes injecting additional methods into a
class whose implementation you don't control.  If done without care, this is
dangerous; the problematic case arises when:

=over 4

=item *

You add a method to a class;

=item *

A newer version of the monkey-patched class adds another method I<of the
same name>

=item *

And uses that new method in some other part of its own implementation.

=back

C<ex::monkeypatched> lets you do this sort of monkey-patching safely: before
it injects a method into the target class, it checks whether the class
already has a method of the same name.  If it finds such a method, it throws
an exception (at compile-time with respect to the code that does the
injection).

See L<http://aaroncrane.co.uk/talks/monkey_patching_subclassing/> for more
details.

=head1 DESCRIPTION

C<ex::monkeypatched> injects methods when you C<use> it.  Your C<use> call
should supply the name of a class to patch, and a hash from method names to
code references implementing those methods.  The class to be patched will be
loaded automatically before any patching is done (thus ensuring that all its
base classes are also loaded).

Alternatively, you can inject methods after a class has already been loaded,
using the C<inject> method:

    use ex::monkeypatched;

    ex::monkeypatched->inject('Third::Party::Class' => (
        clunk => sub { ... },
        eth   => sub { ... },
    );

Calling C<inject> like this does not load the class in question, so
C<ex::monkeypatched> is unable to guarantee that all the target class's
methods have been loaded at the point the new methods are injected.

The C<ex::> prefix on the name of this module indicates that its API is
still considered experimental.  However, the underlying code has been in use
in production for an extended period, and seems to be reliable.

=head1 CAVEATS

If the class you're monkeying around in uses C<AUTOLOAD> to implement some
of its methods, and doesn't also implement its own C<can> method to
accurately report which method names are autoloaded, C<ex::monkeypatched>
will incorrectly assume that an autoloaded method does not exist.  The
solution is to fix the broken class; implementing C<AUTOLOAD> but not C<can>
is always an error.

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it
under the terms of either the GNU General Public License version 2 or, at
your option, the Artistic License.

=cut
