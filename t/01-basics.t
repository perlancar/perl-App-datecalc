#!perl

use 5.010;
use strict;
use warnings;

use App::datecalc;
use Test::Exception;
use Test::More 0.98;

my $calc = App::datecalc->new;

subtest 'date literals' => sub {
    is($calc->eval('2014-05-20'), '2014-05-20', 'YYYY-MM-DD');
    dies_ok { $calc->eval('2014-02-29') } 'invalid YYYY-MM-DD -> dies';

    like($calc->eval('today'), qr/^\d{4}-\d{2}-\d{2}$/, 'today');
    like($calc->eval('yesterday'), qr/^\d{4}-\d{2}-\d{2}$/, 'yesterday');
    like($calc->eval('tomorrow'), qr/^\d{4}-\d{2}-\d{2}$/, 'tomorrow');
};

subtest 'duration literals' => sub {
    dies_ok { $calc->eval('P2H') } 'invalid ISO -> dies';
    dies_ok { $calc->eval('2 days 2 week') } 'invalid natural -> dies';

    is($calc->eval('P2D'), 'P2D', 'ISO 1');
    is($calc->eval('P10DT1H2M'), 'P1W3DT1H2M', 'ISO 2');

    is($calc->eval('3 weeks'), 'P3W', 'natural 1');
    is($calc->eval('2d10h'), 'P2DT10H', 'natural 2');
};

subtest 'datetime literals' => sub {
    # currently we don't show time
    like($calc->eval('now'), qr/^\d{4}-\d{2}-\d{2}$/, 'now');
};

subtest 'date addition/subtraction with duration' => sub {
    is($calc->eval('2014-05-20 + 20d'), '2014-06-09');
    is($calc->eval('2014-05-20 - P20D'), '2014-04-30');
};

subtest 'date subtraction with date' => sub {
    is($calc->eval('2014-05-20 - 2014-03-03'), 'P2M2W3D');
};

subtest 'duration addition/subtraction with duration' => sub {
    is($calc->eval('P1D + 30 mins 45s'), 'P1DT30M45S');
};

subtest 'duration multiplication/division with number' => sub {
    is($calc->eval('P1D * 2'), 'P2D');
    is($calc->eval('P2D / 2'), 'P1D');
    is($calc->eval('2 * P5D'), 'P1W3D');
};

DONE_TESTING:
done_testing;
