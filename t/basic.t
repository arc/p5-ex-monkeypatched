#! /usr/bin/perl

use strict;
use warnings;

use File::Spec::Functions qw<splitpath catdir catpath>;

use lib do {
    my ($vol, $dir, undef) = splitpath(__FILE__);
    catpath($vol, catdir($dir, 'lib'), '');
};

use Test::More 0.88;
use Test::Exception;

{
    no_class_ok('Monkey::A');
    require_ok('Monkey::PatchA');
    my $obj = new_ok('Monkey::A', [], 'monkey-patched version');
    can_ok($obj, qw<meth_a monkey_a1 monkey_a2>);
}

{
    no_class_ok('Monkey::B');
    throws_ok { require Monkey::PatchB }
        qr/^Can't monkey-patch: Monkey::B already has a method "\w+"/,
        'Correctly refuse to override a statically-defined method';
}

{
    no_class_ok('Monkey::C');
    throws_ok { require Monkey::PatchC }
        qr/^Can't monkey-patch: Monkey::C already has a method "heritable"/,
        'Correctly refuse to override an inherited method';
}

{
    no_class_ok('Monkey::D');
    require_ok('Monkey::PatchD');
    can_ok('Monkey::D', qw<monkey_d>);
    throws_ok { 'Monkey::D'->new }
        qr/^Can't locate object method "new" via package "Monkey::D"/,
        '-norequire option does not load target package';
    require_ok('Monkey::D');
    my $obj = new_ok('Monkey::D', [], 'monkey-patched version');
    can_ok($obj, qw<meth_d monkey_d>);
}

throws_ok { ex::monkeypatched->import('Monkey::False', f => sub {}) }
    qr{^Monkey/False\.pm did not return a true value},
    'Exception propagated from require for false module';

throws_ok { ex::monkeypatched->import('Monkey::Invalid', f => sub {}) }
    qr{^syntax error at .*Monkey/Invalid\.pm line },
    'Exception propagated from require for invalid module';

throws_ok { eval q{use ex::monkeypatched 'Monkey::Q1', 'meth'; 1} or die $@ }
    qr{^Usage: use ex::monkeypatched \$class => %methods},
    'Argument validation: missing method body';

done_testing();

sub no_class_ok {
    my ($class, $msg) = @_;
    throws_ok { my $obj = $class->new }
        qr/^Can't locate object method "new" via package "\Q$class\E"/,
        $msg || "no class $class exists";
}
