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

date_add             ::= date_term
                       | date_add op_plusminus duration_term
op_plusminus         ::= [+-]

date_term            ::= date_literal
#                       | date_variable
                       | '(' date_expr ')'                            action=>date_parenthesis

date_literal         ::= [\d][\d][\d][\d] '-' [\d][\d] '-' [\d][\d]   action=>datelit_isodate
                       | 'now'                                        action=>datelit_special
                       | 'today'                                      action=>datelit_special
                       | 'yesterday'                                  action=>datelit_special
                       | 'tommorow'                                   action=>datelit_special

duration_term        ::= duration_literal
#                       | duration_variable
#                       | '(' duration_expr ')'

duration_literal     ::= nat_duration_literal
                       | iso_duration_literal

unit_year              ~ 'year' | 'years' | 'y'
unit_month             ~ 'month' | 'months' | 'mon' | 'mons'
unit_week              ~ 'week' | 'weeks' | 'w'
unit_day               ~ 'day' | 'days' | 'd'
unit_hour              ~ 'hour' | 'hours' | 'h'
unit_minute            ~ 'minute' | 'minutes' | 'min' | 'mins'
unit_second            ~ 'second' | 'seconds' | 'sec' | 'secs' | 's'

ndl_year               ~ num ws_opt unit_year
ndl_year_opt           ~ num ws_opt unit_year
ndl_year_opt           ~

ndl_month              ~ num ws_opt unit_month
ndl_month_opt          ~ num ws_opt unit_month
ndl_month_opt          ~

ndl_week               ~ num ws_opt unit_week
ndl_week_opt           ~ num ws_opt unit_week
ndl_week_opt           ~

ndl_day                ~ num ws_opt unit_day
ndl_day_opt            ~ num ws_opt unit_day
ndl_day_opt            ~

ndl_hour               ~ num ws_opt unit_hour
ndl_hour_opt           ~ num ws_opt unit_hour
ndl_hour_opt           ~

ndl_minute             ~ num ws_opt unit_minute
ndl_minute_opt         ~ num ws_opt unit_minute
ndl_minute_opt         ~

ndl_second             ~ num ws_opt unit_second
ndl_second_opt         ~ num ws_opt unit_second
ndl_second_opt         ~

# need at least one element specified. XXX not happy with this
nat_duration_literal ::= ndl_year     ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month     ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week     ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day     ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour     ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute     ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second

idl_year_opt           ~ posnum 'Y'
idl_year_opt           ~
idl_month_opt          ~ posnum 'M'
idl_month_opt          ~
idl_week_opt           ~ posnum 'W'
idl_week_opt           ~
idl_day_opt            ~ posnum 'D'
idl_day_opt            ~
idl_hour_opt           ~ posnum 'H'
idl_hour_opt           ~
idl_minute_opt         ~ posnum 'M'
idl_minute_opt         ~
idl_second_opt         ~ posnum 'S'
idl_second_opt         ~

# also need at least one element specified like in nat_duration_literal?
iso_duration_literal ::= 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt 'T' idl_hour_opt idl_minute_opt idl_second_opt

sign                   ~ [+-]
digits                 ~ [\d]+
num                    ~ digits
                       | sign digits
                       | digits '.' digits
                       | sign digits '.' digits
posnum                 ~ digits
                       | digits '.' digits
# TODO: support exponent notation 1.2e3?

:discard               ~ ws
ws                     ~ [\s]+
ws_opt                 ~ [\s]*

_
        actions => {
            datelit_now => sub {
            },
            datelit_today => sub {
                my $hash = shift;
            },
            datelit_tommorow => sub {
            },
            datelit_yesterday => sub {
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
