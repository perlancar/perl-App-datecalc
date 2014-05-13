package App::datecalc;

use 5.010001;
use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use MarpaX::Simple qw(gen_parser);

# VERSION
# DATE

sub new {
    state $parser = gen_parser(
        grammar => <<'_',
:default             ::= action=>::first
:start               ::= answer

answer               ::= date_expr
#                      | duration_expr
#                      | numeric_expr

date_expr            ::= date_add

date_add             ::= date_literal
                       | date_add op_plusminus duration_term
op_plusminus         ::= [+-]

date_term            ::= date_literal
                       | '(' date_expr ')'                      action=>date_parenthesis

date_literal         ::= [\d][\d][\d][\d]-[\d][\d]-[\d][\d]     action=>dlit_isodate
                       | 'now'                                  action=>dlit_special
                       | 'today'                                action=>dlit_special
                       | 'yesterday'                            action=>dlit_special
                       | 'tommorow'                             action=>dlit_special

duration_literal     ::= nat_duration_literal
                       | iso_duration_literal

unit_year              ~ 'year' | 'years' | 'y'
unit_month             ~ 'month' | 'months' | 'mon' | 'mons'
unit_week              ~ 'week' | 'weeks' | 'w'
unit_day               ~ 'day' | 'days' | 'd'
unit_hour              ~ 'hour' | 'hours' | 'h'
unit_minute            ~ 'minute' | 'minutes' | 'min' | 'mins'
unit_second            ~ 'second' | 'seconds' | 'sec' | 'secs' | 's'

ndl_year               ~ num (opt_ws) unit_year
ndl_month              ~ num (opt_ws) unit_month
ndl_week               ~ num (opt_ws) unit_week
ndl_day                ~ num (opt_ws) unit_day
ndl_hour               ~ num (opt_ws) unit_hour
ndl_minute             ~ num (opt_ws) unit_minute
ndl_second             ~ num (opt_ws) unit_second

nat_duration         ::=

sign                   ~ [+-]
digits                 ~ [\d]+
num                    ~ digits
                       | sign digits
                       | digits '.' digits
                       | sign digits '.' digits
# TODO: support exponent notation 1.2e3

:discard               ~ ws
ws                     ~ [\s]+
opt_ws                 ~ [\s]*

_
        actions => {
            today => sub {
                my $hash = shift;

            },
            tommorow => sub {
            },
            tommorow => sub {
            },
        },
    );

    bless {parser=>$parser}, shift;
}

sub eval {
    my ($self, $str) = @_;
    $self->{parser}->($str);
}

1;
#ABSTRACT: Date arithmetics

=head1 SYNOPSIS

 use App::datecalc;
 my $calc = App::datecalc->new;
 say $calc->eval('2014-05-13 + 2 days'); # -> 2014-05-15


=head1 DESCRIPTION

B<This is an early release. More features and documentation will follow in
subsequent releases.>

This module provides a date calculator. You can write date literals in ISO 8601
format (though not all format is supported), e.g. C<2014-05-13>. Date duration
can be specified using the natural syntax e.g. C<2 days 13 hours> or using the
ISO 8601 format e.g. C<P2DT13H>.


=head1 TODO

Support date+time literal.

Support time literal (but can we represent it in DateTime?).

Function to extract elements, e.g. hour(dt), month(dt).

Support more special date literals: {last,next} {week,month,year,...}, etc.

Comparison (date1 < date2, d1 <=> d2, ...).

Variable assignment?

Numeric calculations, so the tool is usable too for some simple arithmetics,
e.g. hour(dt)*2.


=head1 SEE ALSO

L<DateTime> and L<DateTime::Format::ISO8601>, the backend modules used to do the
actual date calculation.

L<Marpa::R2> is used to generate the parser.

L<Date::Calc> another date module on CPAN. No relation except the similarity of
name.

L<http://en.wikipedia.org/wiki/ISO_8601> for more information about the ISO 8601
format.
