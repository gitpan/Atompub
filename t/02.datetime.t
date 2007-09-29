use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 11;

# current time is "Mon Jan 01 10:00:00 2007" in your timezone
BEGIN {
    use HTTP::Date qw( str2time );
    *CORE::GLOBAL::time = sub { str2time '2007-01-01 10:00:00' };
}

use Atompub::DateTime qw( datetime );
use Time::Local;

sub tz {
    my $now = time;
    my $diff = timegm( localtime( $now ) ) - timegm( gmtime( $now ) );
    sprintf "%+03d:%02d", int( $diff / 3600 ), int( ( $diff % 3600 ) / 60 );
}

my $dt = datetime;

is $dt->epoch, 1167613200;
is $dt->iso,   '2007-01-01 10:00:00';
is $dt->w3c,   '2007-01-01T10:00:00' . tz();

like $dt->isoz, qr{^20\d\d-\d\d-\d\d \d\d:\d\d:\d\dZ$};
like $dt->w3cz, qr{^20\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$};
like $dt->str,  qr{^[a-z]{3},\s+\d{1,2}\s+[a-z]{3}\s+20\d\d\s+\d\d:\d\d:\d\d\s+GMT$}i;

is "$dt", $dt->w3c;
is 0+$dt, $dt->epoch;

my $dt2 = datetime( $dt );

ok $dt = $dt2;

$dt2 = datetime( $dt->epoch + 1 );

ok $dt  < $dt2;
ok $dt != $dt2;
