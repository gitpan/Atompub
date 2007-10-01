package Atompub::Client;

use warnings;
use strict;

use Atompub;
use Atompub::DateTime qw( datetime );
use Atompub::MediaType qw( media_type );
use Atompub::Util qw( is_acceptable_media_type is_allowed_category );
use Digest::SHA1 qw( sha1 );
use File::Slurp;
use HTTP::Status;
use MIME::Base64 qw( encode_base64 );
use NEXT;
use URI::Escape;
use XML::Atom::Entry;
use XML::Atom::Service;

use base qw( XML::Atom::Client Class::Accessor::Lvalue::Fast );

my @ATTRS = qw( request response resource );

__PACKAGE__->mk_accessors( @ATTRS, qw( ua info cache ) );

*req = \&request;
*res = \&response;
*rc  = \&resource;

sub init {
    my $client = shift;
    $client->NEXT::init(@_);
    $client->ua->agent( 'Atompub::Client/' . Atompub->VERSION );
    $client->info  = Atompub::Client::Info->instance;
    $client->cache = Atompub::Client::Cache->instance;
    $client;
}

sub proxy {
    my $client = shift;
    $client->ua->proxy( [ 'http', 'https' ], $_[0] );
}

sub getService {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    $client->_get_service( { uri => $uri } ) || return;

    return $client->rc;
}

sub getCategories {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    $client->_get_categories( { uri => $uri } ) || return;

    return $client->rc;
}

sub getFeed {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    $client->_get_feed( { uri => $uri } ) || return;

    return $client->rc;
}

sub createEntry {
    my $client = shift;
    my ( $uri, $entry, $slug ) = @_;

    return $client->error('No URI')   unless $uri;
    return $client->error('No Entry') unless $entry;

    if ( ! UNIVERSAL::isa( $entry, 'XML::Atom::Entry' ) ) {
	$entry = XML::Atom::Entry->new($entry)
	    || return $client->error( XML::Atom::Entry->errstr );
    }

    my $headers = HTTP::Headers->new;
    $headers->content_type( media_type('entry') );
    $headers->slug( uri_escape uri_unescape $slug ) if defined $slug;

    $client->_create_resource( { uri     => $uri,
				 rc      => $entry,
				 headers => $headers } ) || return;

    return $client->res->location;
}

sub createMedia {
    my $client = shift;
    my ( $uri, $stream, $content_type, $slug ) = @_;

    return $client->error('No URI')          unless $uri;
    return $client->error('No stream')       unless $stream;
    return $client->error('No Content-Type') unless $content_type;

    my $media
	= ref $stream ? $$stream
	:               read_file( $stream, binmode => ':raw', err_mode => 'carp' )
	    || return $client->error('No media');

    my $headers = HTTP::Headers->new;
    $headers->content_type( $content_type );
    $headers->slug( uri_escape uri_unescape $slug ) if defined $slug;

    $client->_create_resource( { uri     => $uri, 
				 rc      => \$media, 
				 headers => $headers } ) || return;

    return $client->res->location;
}

sub getEntry {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    $client->_get_resource( { uri => $uri } ) || return;

    return $client->error('Response is not Atom Entry')
	unless UNIVERSAL::isa( $client->rc, 'XML::Atom::Entry' );

    return $client->rc;
}

sub getMedia {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    $client->_get_resource( { uri => $uri } ) || return;

    return $client->error('Response is not Media Resource')
	if UNIVERSAL::isa( $client->rc, 'XML::Atom::Entry' );

    return wantarray ? ( $client->rc, $client->res->content_type ) : $client->rc;
}

sub updateEntry {
    my $client = shift;
    my ( $uri, $entry ) = @_;

    return $client->error('No URI')   unless $uri;
    return $client->error('No Entry') unless $entry;

    if ( ! UNIVERSAL::isa( $entry, 'XML::Atom::Entry' ) ) {
	$entry = XML::Atom::Entry->new($entry)
	    || return $client->error( XML::Atom::Entry->errstr );
    }

    my $headers = HTTP::Headers->new;
    $headers->content_type( media_type('entry') );

    return $client->_update_resource( { uri     => $uri,
					rc      => $entry,
					headers => $headers } );
}

sub updateMedia {
    my $client = shift;
    my ( $uri, $stream, $content_type ) = @_;

    return $client->error('No URI')          unless $uri;
    return $client->error('No stream')       unless $stream;
    return $client->error('No Content-Type') unless $content_type;

    my $media
	= ref $stream ? $$stream
	:               read_file( $stream, binmode => ':raw', err_mode => 'carp' )
	    || return $client->error('No media resource');

    my $headers = HTTP::Headers->new;
    $headers->content_type( $content_type );

    return $client->_update_resource( { uri     => $uri,
					rc     => \$media,
					headers => $headers } );
}

sub deleteEntry {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    return $client->_delete_resource( { uri => $uri } );
}

*deleteMedia = \&deleteEntry;

sub _get_service {
    my $client = shift;
    my ( $args ) = @_;

    my $uri = $args->{uri};

    $client->_clear;

    return $client->error('No URI') unless $uri;

    $client->req = HTTP::Request->new( GET => $uri );

    $client->res = $client->make_request( $client->req );

    return $client->error( join "\n", $client->res->status_line, $client->res->content )
	unless is_success $client->res->code;

    warn 'Bad Content-Type: ' . $client->res->content_type
	unless media_type( $client->res->content_type )->is_a('service');

    $client->rc = XML::Atom::Service->new( \$client->res->content )
	|| return $client->error( XML::Atom::Service->errstr );

    for my $work ( $client->rc->workspaces ) {
	$client->info->put( $_->href, $_ ) for $work->collections;
    }

    return $client;
}

sub _get_categories {
    my $client = shift;
    my ( $args ) = @_;

    my $uri = $args->{uri};

    $client->_clear;

    return $client->error('No URI') unless $uri;

    $client->req = HTTP::Request->new( GET => $uri );

    $client->res = $client->make_request( $client->req );

    return $client->error( join "\n", $client->res->status_line, $client->res->content )
	unless is_success $client->res->code;

    warn 'Bad Content-Type: ' . $client->res->content_type
	unless media_type( $client->res->content_type )->is_a('categories');

    $client->rc = XML::Atom::Categories->new( \$client->res->content )
	|| return $client->error( XML::Atom::Categories->errstr );

    return $client;
}

sub _get_feed {
    my $client = shift;
    my ( $args ) = @_;

    my $uri = $args->{uri};

    $client->_clear;

    return $client->error('No URI') unless $uri;

    $client->req = HTTP::Request->new( GET => $uri );

    $client->res = $client->make_request( $client->req );

    return $client->error( join "\n", $client->res->status_line, $client->res->content )
	unless is_success $client->res->code;

    warn 'Bad Content-Type: ' . $client->res->content_type
	unless media_type( $client->res->content_type )->is_a('feed');

    $client->rc = XML::Atom::Feed->new( \$client->res->content )
	|| return $client->error( XML::Atom::Feed->errstr );

    return $client;
}

sub _create_resource {
    my $client = shift;
    my ( $args ) = @_;

    my $uri     = $args->{uri};
    my $rc      = $args->{resource} || $args->{rc};
    my $headers = $args->{headers};

    $client->_clear;

    return $client->error('No URI')      unless $uri;
    return $client->error('No resource') unless $rc;
    return $client->error('No headers')  unless $headers;

    my $content_type = $headers->content_type;

    my $info = $client->info->get( $uri );

    return $client->error("Unsupported media type: $content_type")
	unless is_acceptable_media_type( $info, $content_type );

    my $content;
    if ( UNIVERSAL::isa( $rc, 'XML::Atom::Entry' ) ) {
	my $entry = $rc;

	return $client->error('Forbidden category')
	    unless is_allowed_category( $info, $entry->category );

	$content = $entry->as_xml;
	XML::Atom::Client::_utf8_off( $content );
	$headers->content_type( media_type('entry') );
	$headers->content_length( length $content );
    }
    elsif ( UNIVERSAL::isa( $rc, 'SCALAR' ) ) {
	$content = $$rc;
    }

    $client->req = HTTP::Request->new( POST => $uri, $headers, $content );

    $client->res = $client->make_request( $client->req );

    return $client->error( join "\n", $client->res->status_line, $client->res->content )
	unless is_success $client->res->code;

    warn 'Bad status code: ' . $client->res->code
	unless $client->res->code == RC_CREATED;
    
    return $client->error('No Locaiton') unless $client->res->location;

#    warn 'No Content-Locaiton' unless $client->res->content_location;

    return $client unless $client->res->content;

    warn 'Bad Content-Type: ' . $client->res->content_type
	unless media_type( $client->res->content_type )->is_a('entry');

    $client->rc = XML::Atom::Entry->new( \$client->res->content )
	|| return $client->error( XML::Atom::Entry->errstr );

    my $last_modified = $client->res->last_modified;
    my $etag          = $client->res->etag;

    $client->cache->put( $client->res->location,
			 {  rc            => $client->rc,
			    last_modified => $last_modified,
			    etag          => $etag           } );

    return $client;
}

sub _get_resource {
    my $client = shift;
    my ( $args ) = @_;

    my $uri = $args->{uri};

    $client->_clear;

    return $client->error('No URI') unless $uri;

    my $headers = HTTP::Headers->new;

    my $cache = $client->cache->get( $uri );
    if ( $cache ) {
	$headers->if_modified_since( datetime( $cache->last_modified )->epoch )
	    if $cache->last_modified;
	$headers->if_none_match( $cache->etag ) if defined $cache->etag;
    }

    $client->req = HTTP::Request->new( GET => $uri, $headers );

    $client->res = $client->make_request( $client->req );

    if ( is_success $client->res->code ) {
	if ( media_type( $client->res->content_type )->is_a('entry') ) {
	    $client->rc = XML::Atom::Entry->new( \$client->res->content )
		|| return $client->error( XML::Atom::Entry->errstr );
	}
	else {
	    $client->rc = $client->res->content;
	}

	my $last_modified = $client->res->last_modified;
	my $etag          = $client->res->etag;

	$client->cache->put( $uri, 
			     {  rc            => $client->rc,
				last_modified => $last_modified,
				etag          => $etag           } );
    }
    elsif ( $client->res->code == RC_NOT_MODIFIED ) {
	$client->rc = $cache->rc;
    }
    else {
	return $client->error( join "\n", $client->res->status_line, $client->res->content );
    }

    return $client;
}

sub _update_resource {
    my $client = shift;
    my ( $args ) = @_;

    my $uri     = $args->{uri};
    my $rc      = $args->{resource} || $args->{rc};
    my $headers = $args->{headers};

    $client->_clear;

    return $client->error('No URI')      unless $uri;
    return $client->error('No resource') unless $rc;
    return $client->error('No headers')  unless $headers;

    my $content;
    if ( UNIVERSAL::isa( $rc, 'XML::Atom::Entry' ) ) {
	my $entry = $rc;

	$content = $entry->as_xml;
	XML::Atom::Client::_utf8_off( $content );
	$headers->content_type( media_type('entry') );
	$headers->content_length( length $content );
    }
    elsif ( UNIVERSAL::isa( $rc, 'SCALAR' ) ) {
	$content = $$rc;
    }

    if ( my $cache = $client->cache->get( $uri ) ) {
	$headers->if_unmodified_since( datetime( $cache->last_modified )->epoch )
	    if $cache->last_modified;
	$headers->if_match( $cache->etag ) if defined $cache->etag;
    }

    $client->req = HTTP::Request->new( PUT => $uri, $headers, $content );

    $client->res = $client->make_request( $client->req );

    return $client->error( join "\n", $client->res->status_line, $client->res->content )
	unless is_success $client->res->code;

    return $client unless $client->res->content;

    if ( media_type( $client->res->content_type )->is_a('entry') ) {
	$client->rc = XML::Atom::Entry->new( \$client->res->content )
	    || return $client->error( XML::Atom::Entry->errstr );
    }
    else {
	$client->rc = $client->res->content;
    }

    my $last_modified = $client->res->last_modified;
    my $etag          = $client->res->etag;

    $client->cache->put( $uri, 
			 {  rc            => $client->rc,
			    last_modified => $last_modified,
			    etag          => $etag           } );

    return $client;
}

sub _delete_resource {
    my $client = shift;
    my ( $args ) = @_;

    my $uri = $args->{uri};

    $client->_clear;

    return $client->error('No URI') unless $uri;

    my $headers = HTTP::Headers->new;

# If-Match nor If-Unmodified-Since header is not required on DELETE
#    if ( my $cache = $client->cache->get( $uri ) ) {
#	$headers->if_unmodified_since( datetime( $cache->last_modified )->epoch )
#	    if $cache->last_modified;
#	$headers->if_match( $cache->etag ) if defined $cache->etag;
#    }

    $client->req = HTTP::Request->new( DELETE => $uri, $headers );

    $client->res = $client->make_request( $client->req );

    return $client->error( join "\n", $client->res->status_line, $client->res->content )
	unless is_success $client->res->code;

    return $client;
}

sub _clear {
    my $client = shift;
    $client->error('');
    $client->{$_} = undef for @ATTRS;
}

sub munge_request {
    my $client = shift;
    my ( $req ) = @_;

    $req->accept( join ',', media_type('entry')->without_parameters,
		            media_type('service'), media_type('categories'), '*/*'  );

    return unless $client->username;

    my $nonce = sha1( sha1( time . {} . rand() . $$ ) );
    my $now = datetime->w3cz;

    my $wsse = sprintf(
        qq{UsernameToken Username="%s", PasswordDigest="%s", Nonce="%s", Created="%s"},
	( $client->username || '' ),
        encode_base64( sha1( $nonce . $now . ( $client->password || '' ) ), '' ),
        encode_base64( $nonce, '' ),
        $now,
    );

    $req->header('X-WSSE' => $wsse );
    $req->authorization( 'WSSE profile="UsernameToken"' );
}

sub slug {
    warn '$client->slug is DEPRECATED, and see $client->createEntry and $client->createMedia';
    my $client = shift;
    if ( @_ ) {
	$client->ua->default_header( Slug => uri_escape uri_unescape $_[0] );
    }
    else {
	uri_unescape $client->ua->default_header('Slug');
    }
}

my %OBSOLETED = ( retrieveService    => 'getService',
		  retrieveCategories => 'getCategories',
		  retrieveFeed       => 'getFeed',
		  postEntry          => 'createEntry',
		  postMedia          => 'createMedia',
		  retrieveEntry      => 'getEntry',
		  retrieveMedia      => 'getMedia',
		  editEntry          => 'updateEntry',
		  putEntry           => 'updateEntry',
		  editMedia          => 'updateMedia',
		  putMedia           => 'updateMedia', );

while ( my ( $obs, $new ) = each %OBSOLETED ) {
    no strict 'refs'; ## no critic
    *{$obs} = sub {
	warn "\$client->$obs is DEPRECATED, and see \$client->$new";
	shift->$new(@_);
    };
}

package Atompub::Client::Info;

my $Info;

sub instance {
    my $class = shift;
    $Info ||= bless { info => {} }, $class;
    $Info;
}

sub put {
    my $self = shift;
    my ( $uri, @args ) = @_;
    return unless $uri;
    if ( @args ) {
	$self->{info}{$uri} = $self->_clone_collection( @args );
    }
    else {
	delete $self->{info}{$uri};
    }
}

sub get {
    my $self = shift;
    my ( $uri ) = @_;
    return unless $uri;
    return $self->{info}{$uri};
}

sub _get_categories {
    my $self = shift;
    my ( $client, $href ) = @_;
    return unless $client;
    return $client->getCategories( $href );
}

sub _clone_collection {
    my $self = shift;
    my ( $coll_arg, $client ) = @_;

    return unless UNIVERSAL::isa( $coll_arg, 'XML::Atom::Collection' );
    
    my $coll = XML::Atom::Collection->new;

    $coll->title( $coll_arg->title );
    $coll->href( $coll_arg->href );

    $coll->accept( $coll_arg->accepts ) if $coll_arg->accept;

    my @cats = grep { defined $_ }
                map {   $_->href ? $self->_get_categories( $client, $_->href )
		      :            $self->_clone_categories($_) }
                    $coll_arg->categories;

    $coll->categories( @cats );

    return $coll;
}

sub _clone_categories {
    my $self = shift;
    my ( $cats_arg ) = @_;

    my $cats = XML::Atom::Categories->new;
    $cats->fixed( $cats_arg->fixed ) if $cats_arg->fixed;
    $cats->scheme( $cats_arg->scheme ) if $cats_arg->scheme;

    my @cat = map { my $cat = XML::Atom::Category->new;
		    $cat->term( $_->term );
		    $cat->scheme( $_->scheme ) if $_->scheme;
		    $cat->label( $_->label ) if $_->label;
		    $cat }
                  $cats_arg->category;
    $cats->category( @cat );

    return $cats;
}

package Atompub::Client::Cache;

my $Cache;

sub instance {
    my $class = shift;
    $Cache ||= bless { cache => {} }, $class;
    $Cache;
}

sub put {
    my $self = shift;
    my ( $uri, @args ) = @_;
    return unless $uri;
    if ( @args ) {
	$self->{cache}{$uri} = Atompub::Client::Cache::Resource->new( @args );
    }
    else {
	delete $self->{cache}{$uri};
    }
}

sub get {
    my $self = shift;
    my ( $uri ) = @_;
    return unless $uri;
    return $self->{cache}{$uri};
}

package Atompub::Client::Cache::Resource;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw( resource last_modified etag ) );

*rc = \&resource;

sub new {
    my $class = shift;
    my ( $args ) = @_;

    my $rc = $args->{resource} || $args->{rc} || return;

    bless {
	resource      => $rc,
	last_modified => $args->{last_modified},
	etag          => $args->{etag},
    }, $class;
}

1;
__END__

=head1 NAME

Atompub::Client - A client for the Atom Publishing Protocol


=head1 COMPATIBILITY ISSUES

L<Atompub::Client> has B<changed return values of the following methods> since v0.1.0.

=over 4

=item * $client->createEntry in list context

=item * $client->createMedia in list context

=item * $client->getMedia in list context

=item * $client->updateEntry

=item * $client->updateMedia

=back

L<Atompub::Client> B<made some methods obsolete> in v0.1.0.

See L<METHODS> and L<OBSOLETED METHODS> in details.


=head1 SYNOPSIS

    use Atompub::Client;

    my $client = Atompub::Client->new;
    $client->username('Melody');
    $client->password('Nelson');
    #$client->proxy( $proxy_uri );

    # Get a Service Document
    my $service = $client->getService( $service_uri );

    my @workspaces = $service->workspaces;
    my @collections = $workspaces[0]->collections;

    # CRUD an Entry Resource; assuming that the 0-th collection supports 
    # Entry Resources
    my $collection_uri = $collections[0]->href;

    my $name = 'New Post';

    my $entry = XML::Atom::Entry->new;
    $entry->title( $name );
    $entry->content('Content of my post.');

    my $edit_uri
        = $client->createEntry( $collection_uri, $entry, $name );

    my $feed = $client->getFeed( $collection_uri );
    my @entries = $feed->entries;

    $entry = $client->getEntry( $edit_uri );

    $client->updateEntry( $edit_uri, $entry );

    $client->deleteEntry( $edit_uri );

    # CRUD a Media Resource; assuming that the 1-st collection supports 
    # Media Resources
    my $collection_uri = $collections[1]->href;

    my $name = 'My Photo';

    my $edit_uri
        = $client->createMedia( $collection_uri, 'sample1.png',
                                'image/png', $name );

    # Get a href attribute of an "edit-media" link
    my $edit_media_uri = $client->resource->edit_media_link;
    
    my $binary = $client->getMedia( $edit_media_uri );

    $client->updateMedia( $edit_media_uri, 'sample2.png', 'image/png' );

    $client->deleteEntry( $edit_media_uri );

    # Access to the requested HTTP::Request object
    my $request  = $client->request;

    # Access to the received HTTP::Response object
    my $response = $client->response;

    # Access to the received resource (XML::Atom object or binary data)
    my $resource = $client->resource;


=head1 DESCRIPTION

L<Atompub::Client> implements a client for the Atom Publishing Protocol 
described at L<http://www.ietf.org/internet-drafts/draft-ietf-atompub-protocol-17.txt>.

The client supports the following features:

=over 4

=item * Authentication

L<Atompub::Client> supports the Basic and WSSE Authentication described in
L<http://www.intertwingly.net/wiki/pie/DifferentlyAbledClients>.

=item * Service Document

L<Atompub::Client> understands Service Documents, 
in which information of collections are described,
such as URIs, acceptable media types, and allowable categories.

=item * Media Resource support

Media Resources (binary data) as well as Entry Resources are supported.
You can create and edit Media Resources such as image and video
by using L<Atompub::Client>.

=item * Media type check

L<Atompub::Client> checks media types of resources
before creating and editing them to the collection.
Acceptable media types are shown in I<app:accept> elements in the Service Document.

=item * Category check

L<Atompub::Client> checks categories in Entry Resources
before creating and editing them to the collection.
Allowable categories are shown in I<app:categories> elements in the Service Document.

=item * Cache controll and versioning

On-memory cache and versioning, which are controlled by I<ETag> and I<Last-Modified> header,
are implemented in L<Atompub::Client>.

=item * Naming resources by I<Slug> header

The client can specify I<Slug> header when creating a resource,
which may be used as part of the resource URI.

=back


=head1 METHODS

=head2 Atompub::Client->new([ %options ])

Creates a new Atompub client object.
The options are same as L<LWP::UserAgent>.


=head2 $client->getService( $service_uri )

Retrieves a Service Document at URI $service_uri.

Returns an L<XML::Atom::Service> object on success, false otherwise.


=head2 $client->getCategories( $category_uri )

Retrieves a Category Document at URI $category_uri.

Returns an L<XML::Atom::Categories> object on success, false otherwise.


=head2 $client->getFeed( $collection_uri )

Retrieves a Feed Document from the collection at URI $collection_uri.

Returns an L<XML::Atom::Feed> object, false otherwise.


=head2 $client->createEntry( $collection_uri, $entry, [ $slug ] )

Creates a new entry in the collection at URI $collection_uri.

$entry must be an L<XML::Atom::Entry> object.

If $slug is provided, it is set in I<Slug> header and may be used 
as part of the resource URI.

Returns a I<Location> header, which contains a URI of the newly created resource,
or false on error.


=head2 $client->createMedia( $collection_uri, $media, $media_type, [ $slug ] )

Creates a new Media Resource and a Media Link Entry in the collection
at URI $collection_uri.

If $media is a reference to a scalar, it is treated as the binary.
If a scalar, treated as a file containing the Media Resource.

$media_type is the media type of the Media Resource, such as 'image/png'.

$slug is set in the I<Slug> header, and may be used as part of
the resource URI.

Returns a I<Location> header, which contains a URI of the newly created resource,
or false on error.


=head2 $client->getEntry( $edit_uri )

Retrieves an Entry Document with the given URI $edit_uri.

Returns an L<XML::Atom::Entry> object on success, false otherwise.
If the server returns 304 (Not Modified), returns a cache of the Media Resource.


=head2 $client->getMedia( $edit_uri )

Retrieves a Media Resource with the given URI $edit_uri.

Returns binary data of the Media Resource on success, false otherwise.
If the server returns 304 (Not Modified), returns a cache of the Media Resource.


=head2 $client->updateEntry( $edit_uri, $entry )

Updates the Entry Document at URI $edit_uri with the new Entry Document $entry, 
which must be an L<XML::Atom::Entry> object.

Returns true on success, false otherwise.


=head2 $client->updateMedia( $edit_uri, $media, $media_type )

Updates the Media Resource at URI $edit_uri with the $media.

If $media is a reference to a scalar, it is treated as the binary.
If a scalar, treated as a file containing the Media Resource.

$media_type is the media type of the Media Resource, such as 'image/png'.

Returns true on success, false otherwise.


=head2 $client->deleteEntry( $edit_uri )

Deletes the Entry Document at URI $edit_uri.

Returns true on success, false otherwise.


=head2 $client->deleteMedia( $edit_uri )

Deletes the Media Resource at URI $edit_uri and related Media Link Entry.

Returns true on success, false otherwise.


=head1 Accessors

=head2 $client->username([ $username ])

If called with an argument, sets the username for login to $username.

Returns the current username that will be used when logging in to the 
Atompub server.


=head2 $client->password([ $password ])

If called with an argument, sets the password for login to $password.

Returns the current password that will be used when logging in to the 
Atompub server.


=head2 $client->proxy([ $proxy_uri ])

If called with an argument, sets URI of proxy server like 'http://proxy.example.com:8080'.

Returns the current URI of the proxy server.


=head2 $client->resource

=head2 $client->rc

An accessor for Entry or Media Resource, which was retrieved in the previous action.


=head2 $client->request

=head2 $client->req

An accessor for an L<HTTP::Request> object, which was used in the previous action.


=head2 $client->response

=head2 $client->res

An accessor for an L<HTTP::Response> object, which was used in the previous action.


=head1 OBSOLETED METHODS

=head2 $client->slug([ $slug ])

This method is DEPRECATED, and see $client->createEntry and $client->createMedia.

=head2 $client->retrieveService( $service_uri )

This method is DEPRECATED, and see $client->getService.

=head2 $client->retrieveCategories( $category_uri )

This method is DEPRECATED, and see $client->getCategories.

=head2 $client->retrieveFeed( $collection_uri )

This method is DEPRECATED, and see $client->getFeed.

=head2 $client->postEntry( $collection_uri, $entry )

This method is DEPRECATED, and see $client->createEntry.

=head2 $client->postMedia( $collection_uri, $media, $media_type )

This method is DEPRECATED, and see $client->createMedia.

=head2 $client->retrieveEntry( $edit_uri )

This method is DEPRECATED, and see $client->getEntry.

=head2 $client->retrieveMedia( $edit_uri )

This method is DEPRECATED, and see $client->getMedia.

=head2 $client->editEntry( $edit_uri, $entry )

This method is DEPRECATED, and see $client->updatedEntry.

=head2 $client->putEntry( $edit_uri, $entry )

This method is DEPRECATED, and see $client->updatedEntry.

=head2 $client->editMedia( $edit_uri, $media, $media_type )

This method is DEPRECATED, and see $client->updatedMedia.

=head2 $client->putMedia( $edit_uri, $media, $media_type )

This method is DEPRECATED, and see $client->updatedMedia.


=head1 INTERNAL INTERFACES

=head2 $client->init

=head2 $client->ua

Accessor to the UserAgent.

=head2 $client->info

An accessor to information of Collections described in a Service Document.

=head2 $client->cache

An accessor to the resource cache.

=head2 $client->munge_request( $req )

=head2 $client->_clear

=head2 $client->_get_service( $args )

=head2 $client->_get_categories( $args )

=head2 $client->_get_feed( $args )

=head2 $client->_create_resource( $args )

=head2 $client->_get_resource( $args )

=head2 $client->_update_resource( $args )

=head2 $client->_delete_resource( $args )


=head1 ERROR HANDLING

Methods return C<undef> on error, and the error message can be retrieved
using the I<errstr> method.


=head1 SEE ALSO

L<XML::Atom>
L<XML::Atom::Service>
L<Atompub>


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
