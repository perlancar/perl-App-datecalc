package App::datecalc;

use 5.010001;
use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use MarpaX::Simple qw(gen_parser);
use Scalar::Util qw(blessed);

# VERSION
# DATE

# XXX there should already be an existing module that does this
sub __fmtduriso {
    my $dur = shift;
    my $res = join(
        '',
        "P",
        ($dur->years  ? $dur->years  . "Y" :  ""),
        ($dur->months ? $dur->months . "M" :  ""),
        ($dur->weeks  ? $dur->weeks  . "W" :  ""),
        ($dur->days   ? $dur->days   . "D" :  ""),
    );
    if ($dur->hours || $dur->minutes || $dur->seconds) {
        $res .= join(
            '',
            'T',
            ($dur->hours   ? $dur->hours   . "H" : ""),
            ($dur->minutes ? $dur->minutes . "M" : ""),
            ($dur->seconds ? $dur->seconds . "S" : ""),
        );
    }

    $res = "P0Y" if $res eq 'P';

    $res;
}

sub new {
    state $parser = gen_parser(
        grammar => <<'_',
:default             ::= action=>::first
lexeme default         = latm=>1
:start               ::= answer

answer               ::= date_expr
                       | dur_expr
#                      | num_expr

date_expr            ::= date_sub_date

date_sub_date        ::= date_add_dur
                       | date_sub_date ('-') date_sub_date                action=>date_sub_date

date_add_dur         ::= date_term
                       | date_add_dur op_plusminus dur_term               action=>date_add_dur

date_term            ::= date_literal
#                       | date_variable
                       | ('(') date_expr (')')                            action=>date_parenthesis

year                   ~ [\d][\d][\d][\d]
mon2                   ~ [\d][\d]
day                    ~ [\d][\d]
date_literal         ::= year ('-') mon2 ('-') day                        action=>datelit_isodate
                       | 'now'                                            action=>datelit_special
                       | 'today'                                          action=>datelit_special
                       | 'yesterday'                                      action=>datelit_special
                       | 'tomorrow'                                       action=>datelit_special

dur_expr             ::= dur_add_dur

dur_add_dur          ::= dur_mult_num
                       | dur_add_dur op_plusminus dur_add_dur             action=>dur_add_dur

dur_mult_num         ::= dur_term
                       | dur_mult_num op_multdiv

dur_term             ::= dur_literal
#                       | dur_variable
                       | '(' dur_expr ')'

dur_literal          ::= nat_dur_literal
                       | iso_dur_literal

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
nat_dur_literal      ::= nat_dur_literal0                                 action=>durlit_nat
nat_dur_literal0       ~ ndl_year     ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month     ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week     ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day     ndl_hour_opt ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour     ndl_minute_opt ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute     ndl_second_opt
                       | ndl_year_opt ndl_month_opt ndl_week_opt ndl_day_opt ndl_hour_opt ndl_minute_opt ndl_second

idl_year               ~ posnum 'Y'
idl_year_opt           ~ posnum 'Y'
idl_year_opt           ~

idl_month              ~ posnum 'M'
idl_month_opt          ~ posnum 'M'
idl_month_opt          ~

idl_week               ~ posnum 'W'
idl_week_opt           ~ posnum 'W'
idl_week_opt           ~

idl_day                ~ posnum 'D'
idl_day_opt            ~ posnum 'D'
idl_day_opt            ~

idl_hour               ~ posnum 'H'
idl_hour_opt           ~ posnum 'H'
idl_hour_opt           ~

idl_minute             ~ posnum 'M'
idl_minute_opt         ~ posnum 'M'
idl_minute_opt         ~

idl_second             ~ posnum 'S'
idl_second_opt         ~ posnum 'S'
idl_second_opt         ~

# also need at least one element specified like in nat_dur_literal
iso_dur_literal      ::= iso_dur_literal0                                 action=>durlit_iso
iso_dur_literal0       ~ 'P' idl_year     idl_month_opt idl_week_opt idl_day_opt
                       | 'P' idl_year_opt idl_month     idl_week_opt idl_day_opt
                       | 'P' idl_year_opt idl_month_opt idl_week     idl_day_opt
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt 'T' idl_hour     idl_minute_opt idl_second_opt
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt 'T' idl_hour_opt idl_minute     idl_second_opt
                       | 'P' idl_year_opt idl_month_opt idl_week_opt idl_day_opt 'T' idl_hour_opt idl_minute_opt idl_second

sign                   ~ [+-]
digits                 ~ [\d]+
num                    ~ digits
                       | sign digits
                       | digits '.' digits
                       | sign digits '.' digits
posnum                 ~ digits
                       | digits '.' digits

op_plusminus           ~ [+-]
op_multdiv             ~ [*/]

:discard               ~ ws
ws                     ~ [\s]+
ws_opt                 ~ [\s]*

_
        actions => {
            date_parenthesis => sub {
                my $h = shift;
            },
            datelit_isodate => sub {
                my $h = shift;
                DateTime->new(year=>$_[0], month=>$_[1], day=>$_[2]);
            },
            date_sub_date => sub {
                my $h = shift;
                $_[0]->subtract_datetime($_[1]);
            },
            datelit_special => sub {
                my $h = shift;
                if ($_[0] eq 'now') {
                    DateTime->now;
                } elsif ($_[0] eq 'today') {
                    DateTime->today;
                } elsif ($_[0] eq 'yesterday') {
                    DateTime->today->subtract(days => 1);
                } elsif ($_[0] eq 'tomorrow') {
                    DateTime->today->add(days => 1);
                } else {
                    die "BUG: Unknown date literal '$_[0]'";
                }
            },
            date_add_dur => sub {
                my $h = shift;
                dd \@_;
                if ($_[1] eq '+') {
                    $_[0] + $_[2];
                } else {
                    $_[0] - $_[2];
                }
            },
            dur_add_dur => sub {
                my $h = shift;
                dd \@_;
            },
        },
        trace_terminals => $ENV{DEBUG},
        trace_values => $ENV{DEBUG},
    );

    bless {parser=>$parser}, shift;
}

sub eval {
    my ($self, $str) = @_;
    my $res = $self->{parser}->($str);

    if (blessed($res) && $res->isa('DateTime::Duration')) {
        __fmtduriso($res);
    } elsif (blessed($res) && $res->isa('DateTime')) {
        $res->ymd;
    } else {
        "$res";
    }
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

Currently supported calculations:

=over

=item * date literals

 2014-05-19
 now
 today
 tomorrow

=item * duration literals, either in ISO 8601 format or natural syntax

 P3M2D
 3 months 2 days

=item * date addition/subtraction with a duration

 2014-05-19 - 2 days
 2014-05-19 + P29W

=item * date subtraction with another date

 2014-05-19 - 2013-12-25

=item * (NOT YET) duration addition/subtraction with another duration

=item * (NOT YET) duration multiplication/division with a number

 P2D * 2

=item * (NOT YET) extract elements from date

 year(2014-05-20)
 month(2014-05-20)
 day(2014-05-20)

=item * (NOT YET) extract elements from duration

=back


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
