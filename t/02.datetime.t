use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 11;

use Atompub::DateTime qw( datetime );

my $dt = datetime;

like $dt->epoch, qr{^\d+$};
like $dt->iso,   qr{^20\d\d-\d\d-\d\d \d\d:\d\d:\d\d$};
like $dt->isoz,  qr{^20\d\d-\d\d-\d\d \d\d:\d\d:\d\dZ$};
like $dt->w3c,   qr{^20\d\d-\d\d-\d\dT\d\d:\d\d:\d\d[-+]\d\d:\d\d$};
like $dt->w3cz,  qr{^20\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$};
like $dt->str,   qr{^[a-z]{3},\s+\d{1,2}\s+[a-z]{3}\s+20\d\d\s+\d\d:\d\d:\d\d\s+GMT$}i;

is "$dt", $dt->w3c;
is 0+$dt, $dt->epoch;

my $dt2 = datetime( $dt );

ok $dt = $dt2;

$dt2 = datetime( $dt->epoch + 1 );

ok $dt  < $dt2;
ok $dt != $dt2;
