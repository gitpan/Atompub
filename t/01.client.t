use strict;
use warnings;
use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 20;
use DateTime;
use Atompub::Client;

my $SERVICE = 'http://teahut.sakura.ne.jp:3000/service';
my $USER = 'foo';
my $PASS = 'foo';

$XML::Atom::DefaultVersion = '1.0';
$XML::Atom::Service::DefaultNamespace = 'http://www.w3.org/2007/app';


## Retrieve Service

my $client = Atompub::Client->new;
$client->username( $USER );
$client->password( $PASS );

my $service = $client->getService( $SERVICE );
isa_ok $service, 'XML::Atom::Service';

my @collections = $service->workspace->collection;


## Create Entry Resource

my $entry = XML::Atom::Entry->new;
$entry->title('Entry 1');

$entry->updated( DateTime->now->iso8601 . 'Z' );

$entry->id('tag:teahut.sakura.ne.jp,2007:1');

$entry->content('<span>This is an entry 1</span>');

my $category = XML::Atom::Category->new;
$category->term('animal');
$category->scheme('http://example.com/cats/big3');
$entry->add_category($category);

$client->slug('Entry 1');
is $client->slug, 'Entry 1';


my $href = $collections[0]->href;
( $entry, my $headers ) = $client->createEntry( $href, $entry );
isa_ok $entry, 'XML::Atom::Entry';
isa_ok $headers, 'HTTP::Headers';


## Retrieve Feed

my $feed = $client->getFeed( $href );
isa_ok $feed, 'XML::Atom::Feed';


## Retrieve Entry Resource

$href = $headers->header('Location');
$entry = $client->getEntry( $href ); ## 304
isa_ok $entry, 'XML::Atom::Entry';


## Edit Entry Resource

$entry->title('Entry 1, ver.2');

$entry = $client->editEntry( $href, $entry );
isa_ok $entry, 'XML::Atom::Entry';

is $entry->title, 'Entry 1, ver.2';


## Delete Entry Resource

ok $client->deleteEntry($href);


## Create Media Resource

$href = $collections[1]->href;

ok ! $client->createMedia( $href, 't/samples/media1.gif', 'text/plain' );
like $client->errstr, qr/Unsupported media type/;

$client->slug('Media 1');
( $entry, $headers )
    = $client->createMedia( $href, 't/samples/media1.gif', 'image/gif' );
isa_ok $entry, 'XML::Atom::Entry';
isa_ok $headers, 'HTTP::Headers';


## Retrieve Feed of Media Link Entries

$feed = $client->getFeed( $href );
isa_ok $feed, 'XML::Atom::Feed';


## Retrieve Media Link Entry

$href = $headers->header('Location');
$entry = $client->getEntry( $href ); ## 304
isa_ok $entry, 'XML::Atom::Entry';


## Edit Media Link Entry

$entry->title('Media 1, ver. 2');

$entry = $client->editEntry( $href, $entry );
isa_ok $entry, 'XML::Atom::Entry';

is $entry->title, 'Media 1, ver. 2';


## Delete Media Link Entry

#ok $client->deleteEntry( $href );


## Retrieve Media Resource

( $href ) = map { $_->href } grep { $_->rel eq 'edit-media' } $entry->link;

ok $client->getMedia( $href );


## Edit Media resource

ok $client->editMedia( $href, 't/samples/media2.png', 'image/png' );


## Delete Media Resource

ok $client->deleteMedia( $href );
