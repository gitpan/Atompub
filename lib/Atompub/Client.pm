package Atompub::Client;

use warnings;
use strict;
use URI::Escape;
use HTTP::Status;
use DateTime;
use Digest::SHA1 qw( sha1 );
use MIME::Base64 qw( encode_base64 );
use File::Slurp;
use XML::Atom::Entry;
use XML::Atom::Service;
use Atompub;
use base qw( XML::Atom::Client );

my $ENTRY_TYPE = 'application/atom+xml;type=entry';

sub init {
    my $client = shift;
    $client->SUPER::init(@_);
    $client->{ua}->agent( 'Atompub::Client/' . Atompub->VERSION );
    $client;
}

sub proxy {
    my $client = shift;
    $client->{ua}->proxy( [ 'http', 'https' ], shift );
}

sub slug {
    my $client = shift;
    if ( @_ ) {
	$client->{ua}->default_header( Slug => uri_escape $_[0] );
    }
    else {
	uri_unescape $client->{ua}->default_header('Slug');
    }
}

## Cache the collection information described in the Service Docment
sub _info {
    my $client = shift;
    my ( $coll ) = @_;

    my $href = $coll->href;

    my $info = {
	title     => $coll->title,
	href      => $href,
	accept    => [ map { split /[\s,]+/ } $coll->accept ],
    };

    my @cats;
    for my $cats ( $coll->categories ) {
	$cats = $client->getCategories( $cats->href ) if $cats->href;

	my @cat = map { term => $_->term, scheme => $_->scheme },
	              $cats->category;

	push @cats, {
	    fixed    => ( $cats->fixed || 'no' ),
	    scheme   => $cats->scheme,
	    category => \@cat,
	};
    }

    $info->{categories} = \@cats;

    return ( $href, $info );
}

sub getService {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    my $req = HTTP::Request->new( GET => $uri );

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line . "\n" . $res->content )
	unless is_success $res->code;
    
    my $serv = XML::Atom::Service->new( \$res->content )
	|| return $client->errorr( XML::Atom::Service->errstr );

    for my $work ( $serv->workspace ) {
	for my $coll ( $work->collection ) {
	    my ( $href, $info ) = $client->_info($coll);
	    $client->{info}{$href} = $info;
	}
    }

    return $serv;
}

sub getCategories {
    my $client = shift;
    my( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    my $req = HTTP::Request->new(GET => $uri);

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line . "\n" . $res->content )
	unless is_success $res->code;

    my $cats = XML::Atom::Categories->new( \$res->content )
	|| return $client->error( XML::Atom::Categories->errstr );

    return $cats;
}

sub getFeed {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    my $req = HTTP::Request->new( GET => $uri );

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line . "\n" . $res->content )
	unless is_success( $res->code );

    my $feed = XML::Atom::Feed->new( \$res->content )
	|| return $client->error( XML::Atom::Feed->errstr );

    return $feed;
}

sub getEntry {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    my $req = HTTP::Request->new( GET => $uri );
    my $etag = $client->{cache}{$uri}{etag};
    $req->header( 'If-None-Match' => $etag ) if $etag;

    my $res = $client->make_request( $req );

    my $entry;
    if ( is_success( $res->code ) ) {
	$entry = XML::Atom::Entry->new( \$res->content )
	    || return $client->error( XML::Atom::Entry->errstr );
	$client->{cache}{$uri} = {
	    etag => ( $res->header('ETag') || undef ),
	    body => $entry,
	};
    }
    elsif ( $res->code == RC_NOT_MODIFIED ) {
	$entry = $client->{cache}{$uri}{body};
    }
    else {
	return $client->error( $res->status_line . "\n" . $res->content );
    }

    return $entry;
}

sub getMedia {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    my $req = HTTP::Request->new( GET => $uri );
    my $etag = $client->{cache}{$uri}{etag};
    $req->header( 'If-None-Match' => $etag ) if $etag;

    my $res = $client->make_request( $req );

    my $media;
    my $content_type;
    if ( is_success( $res->code ) ) {
	$client->{cache}{$uri} = {
	    etag         => ( $res->header('ETag') || undef ),
	    body         => ( $media        = $res->content ),
	    content_type => ( $content_type = $res->header('Content-Type') ),
	};
    }
    elsif ( $res->code == RC_NOT_MODIFIED ) {
	$media        = $client->{cache}{$uri}{body};
	$content_type = $client->{cache}{$uri}{content_type};
    }
    else {
	return $client->error( $res->status_line . "\n" . $res->content );
    }

    return wantarray ? ( $media, $res->headers ) : $media;
}

sub createEntry {
    my $client = shift;
    my ( $uri, $entry ) = @_;

    return $client->error('No URI')   unless $uri;
    return $client->error('No Entry') unless $entry;

    if ( ! UNIVERSAL::isa( $entry, 'XML::Atom::Entry' ) ) {
	$entry = XML::Atom::Entry->new($entry)
	    || return $client->error( XML::Atom::Entry->errstr );
    }

    my $info = $client->{info}{$uri};

    my $content_type = $ENTRY_TYPE;

    return $client->error('Unsupported media type')
	if $info && ! _is_acceptable_media_type( $info, $content_type );

    return $client->error('Forbidden category')
	if $info && ! _is_allowed_category( $info, $entry->category );

    my $req = HTTP::Request->new( POST => $uri );
    $req->content_type( $content_type );

    my $xml = $entry->as_xml;
    XML::Atom::Client::_utf8_off($xml);
    $req->content_length( length $xml );
    $req->content($xml);

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line )
	unless $res->code == RC_CREATED;
    
    return $client->error('No Locaiton') unless $res->header('Location');

    warn 'No Content-Locaiton' unless $res->header('Content-Location');

    return wantarray ? ( undef, $res->headers ) : $res->header('Location')
	unless $res->content;

    $entry = XML::Atom::Entry->new( \$res->content )
	|| return $client->error( XML::Atom::Entry->errstr );

    $client->{cache}{ $res->header('Location') } = {
	etag => ( $res->header('ETag') || undef ),
	body => $entry,
    };

    return wantarray ? ( $entry, $res->headers ) : $res->header('Location');
}

sub createMedia {
    my $client = shift;
    my ( $uri, $stream, $content_type ) = @_;

    return $client->error('No URI')          unless $uri;
    return $client->error('No stream')       unless $stream;
    return $client->error('No Content-Type') unless $content_type;

    my $info = $client->{info}{$uri};

    return $client->error('Unsupported media type')
	if $info && ! _is_acceptable_media_type( $info, $content_type );

    my $headers = HTTP::Headers->new( 'Content-Type' => $content_type );

    my $media = ref $stream ? $$stream : read_file( $stream, binmode => ':raw' )
	|| return $client->error('No media');

    my $req = HTTP::Request->new( POST => $uri, $headers, $media );

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line )
	unless $res->code == RC_CREATED;

    return $client->error('No Locaiton') unless $res->header('Location');

    warn 'No Content-Locaiton' unless $res->header('Content-Location');

    return wantarray ? ( undef, $res->headers ) : $res->header('Location')
	unless $res->content;

    my $entry = XML::Atom::Entry->new( \$res->content )
	|| return $client->error( XML::Atom::Entry->errstr );

    $client->{cache}{ $res->header('Location') } = {
	etag => ( $res->header('ETag') || undef ),
	body => $entry,
    };

    return wantarray ? ( $entry, $res->headers ) : $res->header('Location');
}

sub editEntry {
    my $client = shift;
    my ( $uri, $entry ) = @_;

    return $client->error('No URI')   unless $uri;
    return $client->error('No Entry') unless $entry;

    if ( ! UNIVERSAL::isa( $entry, 'XML::Atom::Entry' ) ) {
	$entry = XML::Atom::Entry->new($entry)
	    || return $client->error( XML::Atom::Entry->errstr );
    }

    my $req = HTTP::Request->new( PUT => $uri );
    my $etag = $client->{cache}{$uri}{etag};
    $req->header( 'If-Match' => $etag ) if $etag;
    $req->content_type($ENTRY_TYPE);

    my $xml = $entry->as_xml;
    XML::Atom::Client::_utf8_off($xml);
    $req->content_length( length $xml );
    $req->content($xml);

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line . "\n" . $res->content )
	unless is_success( $res->code );

    return $entry unless $res->content;

    $entry = XML::Atom::Entry->new( \$res->content )
	|| return $client->error( XML::Atom::Entry->errstr );

    $client->{cache}{$uri} = {
	etag => ( $res->header('ETag') || undef ),
	body => $entry,
    };

    return $entry;
}

sub editMedia {
    my $client = shift;
    my ( $uri, $stream, $content_type ) = @_;

    return $client->error('No URI')          unless $uri;
    return $client->error('No stream')       unless $stream;
    return $client->error('No Content-Type') unless $content_type;

    ## XXX check whether content_type is acceptable?

    my $headers = HTTP::Headers->new;
    my $etag = $client->{cache}{$uri}{etag};
    $headers->header( 'If-Match' => $etag ) if $etag;
    $headers->header( 'Content-Type' => $content_type );

    my $media = ref $stream ? $$stream : read_file( $stream, binmode => ':raw' )
	|| return $client->error('No media');

    my $req = HTTP::Request->new( PUT => $uri, $headers, $media );

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line . "\n" . $res->content )
	unless is_success( $res->code );

    return wantarray ? ( $media, $res->headers ) : $media unless $res->content;

    $client->{cache}{$uri} = {
	etag => ( $res->header('ETag') || undef ),
	body => ( $media = $res->content ),
    };

    return wantarray ? ( $media, $res->headers ) : $media;
}

sub deleteEntry {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    my $req = HTTP::Request->new( DELETE => $uri );
    my $etag = $client->{cache}{$uri}{etag};
    $req->header( 'If-Match' => $etag ) if $etag;

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line . "\n" . $res->content )
	unless is_success( $res->code );

    return 1;
}

sub deleteMedia {
    my $client = shift;
    my ( $uri ) = @_;

    return $client->error('No URI') unless $uri;

    my $headers = HTTP::Headers->new;
    my $etag = $client->{cache}{$uri}{etag};
    $headers->header( 'If-Match' => $etag ) if $etag;

    my $req = HTTP::Request->new( DELETE => $uri, $headers );

    my $res = $client->make_request( $req );

    return $client->error( $res->status_line . "\n" . $res->content )
	unless is_success( $res->code );

    return 1;
}

*retrieveCategories = \&getCategories;
*retrieveService    = \&getService;
*retrieveFeed       = \&getFeed;
*retrieveEntry      = \&getEntry;

*postEntry = \&createEntry;
*postMedia = \&createMedia;

*putEntry    = \&editEntry;
*putMedia    = \&editMedia;
*updateEntry = \&editEntry;
*updateMedia = \&editMedia;

sub munge_request {
    my $client = shift;
    my ( $req ) = @_;

    $req->header(
	Accept => 'application/atom+xml, application/atomsvc+xml, application/atomcat+xml, */*',
    );

    return unless $client->username;

    my $nonce = sha1( sha1( time . {} . rand() . $$ ) );
    my $now = DateTime->now->iso8601 . 'Z';

    my $wsse = sprintf(
        qq(UsernameToken Username="%s", PasswordDigest="%s", Nonce="%s", Created="%s"),
	( $client->username || '' ),
        encode_base64( sha1( $nonce . $now . ( $client->password || '' ) ), '' ),
        encode_base64( $nonce, '' ),
        $now,
    );

    $req->header('X-WSSE' => $wsse );
    $req->header( Authorization => 'WSSE profile="UsernameToken"' );
}

sub _is_acceptable_media_type {
    my ( $info, $content_type ) = @_;

    ## XXX @accepts MUST be set as entry-type when called from Client to PUT Media Link Entry
    my @accepts = @{ $info->{accept} };
    @accepts = qw( application/atom+xml;type=entry ) unless @accepts;

    for my $accept ( @accepts ) {
        next unless length $accept;

        ## XXX check only substring before '*' or ';'
        my ( $regex ) = split /[*;]/, $accept;
        $regex = quotemeta $regex;
        return 1 if $content_type =~ /^$regex/;
    }

    return 0;
}

sub _is_allowed_category {
    my ( $info, @cat ) = @_;

    for my $cats ( @{ $info->{categories} } ) {
        return 1 unless $cats->{fixed} eq 'yes';

        for my $cat ( @cat ) {
            my $match
                = grep { my $scheme = $_->{scheme} || $cats->{scheme};
                         $_->{term} eq $cat->term && $scheme eq $cat->scheme }
                      @{ $cats->{category} };
            return 0 unless $match;
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

Atompub::Client - A client for the Atom Publishing Protocol


=head1 SYNOPSIS

    use Atompub::Client;

    ## Constructs client objects

    my $client = Atompub::Client->new;
    $client->username('Melody');
    $client->password('Nelson');
    #$client->proxy( $proxy_uri );


    ## Get Service Document

    my $service = $client->getService( $service_uri );
    my @workspaces = $service->workspaces;
    my @collections = $workspaces[0]->collections;


    ## CRUD Entry Resource

    ## Assuming that the 0-th collection supports Entry Resource
    my $collection_uri = $collections[0]->href;

    my $entry = XML::Atom::Entry->new;
    $entry->title('New Post');
    $entry->content('Content of my post.');

    my $edit_uri = $client->createEntry( $collection_uri, $entry );

    my $entry = $client->getEntry( $edit_uri );

    my $entry = $client->EditEntry( $edit_uri, $entry );

    $client->DeleteEntry( $edit_uri );

    my $feed = $client->getFeed( $collection_uri );
    my @entries = $feed->entries;


    ## CRUD Media Resource

    ## Assuming that the 1-st collection supports Media Resource
    my $collection_uri = $collections[1]->href;

    my ( $entry, $headers )
        = $client->createMedia( $collection_uri, 'sample.png', 'image/png' );

    my $edit_uri = $headers->header('Location');
    my ( $edit_media_uri )
        = map { $_->href } grep { $_->rel eq 'edit-media' } $entry->link;
    
    my ( $binary, $headers ) = $client->getMedia( $edit_media_uri );

    my ( $binary, $headers )
        = $client->EditMedia( $edit_media_uri, 'sample.jpg', 'image/jpeg' );

    $client->DeleteEntry( $edit_media_uri );


=head1 DESCRIPTION

B<Atompub::Client> implements a client for the Atom Publishing Protocol 
described at L<http://www.ietf.org/internet-drafts/draft-ietf-atompub-protocol-17.txt>.

The client supports following features:

=over 7

=item * Authentication

B<Atompub::Client> supports the Basic and WSSE Authentication described at 
L<http://www.intertwingly.net/wiki/pie/DifferentlyAbledClients>.

=item * Service Document

B<Atompub::Client> understands Service Document, 
in which information of collections are described,
such as URIs, acceptable media types, and allowable categories.

=item * Media and Entry Resource

Media Resource as well as Entry Resource are supported.
You can create and edit binary resources such as image and video
by using B<Atompub::Client>.

=item * I<Slug> header

The client can specify I<Slug> header when creating resources,
which may be used as part of the resource URI.

=item * Media type check

B<Atompub::Client> automatically checks media types of the resources 
before creating and editing them to a collection.
Acceptable media types are shown in I<app:accept> elements of the Service Document.

=item * Category check

B<Atompub::Client> automatically checks categories of the Entry Resource 
before creating and editing them to a collection.
Allowable categories are shown in I<app:categories> elements of the Service Document.

=item * Cache control

On-memory cache mechanizm is implemented in B<Atompub::Client>, 
which is controlled by I<ETag> header.

=back

This module was tested in InteropTokyo2007
L<http://intertwingly.net/wiki/pie/July2007InteropTokyo>, 
and interoperated with other implementations.


=head1 METHODS

=head2 Atompub::Client->new([ %options ])

Creates a new Atompub client object.
The options are same as B<LWP::UserAgent>.


=head2 $client->username([ $username ])

If called with an argument, sets the username for login to $username.

Returns the current username that will be used when logging in to the 
Atompub server.


=head2 $client->password([ $password ])

If called with an argument, sets the password for login to $password.

Returns the current password that will be used when logging in to the 
Atompub server.


=head2 $client->proxy([ $proxy_uri ])

If called with an argument, sets URI of proxy server.

Returns the current URI of the proxy server.


=head2 $client->slug([ $slug ])

If called with an argument, sets I<Slug> header which may be used as 
part of the resource URI.
$slug must not be escaped.

Returns the current I<Slug> header.


=head2 $client->getService( $service_uri )

Retrieves the Service Document at URI $service_uri.

Returns an B<XML::Atom::Service> object representing the Service 
Document returned from the server.

Returns false on error.


=head2 $client->retrieveService( $service_uri )

An alias for getService.


=head2 $client->getCategories( $category_uri )

Retrieves the Category Document at URI $category_uri.

Returns an B<XML::Atom::Categories> object representing the Category
Document returned from the server.

Returns false on error.


=head2 $client->retrieveCategories( $category_uri )

An alias for getCategories.


=head2 $client->createEntry( $collection_uri, $entry )

Creates a new entry in the collection at URI $collection_uri.
$entry must be an B<XML::Atom::Entry> object.

If called in scalar context, returns a Location header.

     my $location = $client->createEntry( $collection_uri, $entry );

If called in list context, returns an B<XML::Atom::Entry> object and an 
B<HTTP::Headers> object.

     my ( $entry, $headers )
         = $client->createEntry( $collection_uri, $entry );
     my $location = $headers->header('Location');

Returns false on error.


=head2 $client->postEntry( $collection_uri, $entry )

An alias for createEntry.


=head2 $client->createMedia( $collection_uri, $media, $media_type )

Creates a new Media Resource and Media Link Entry in the collection
at URI $collection_uri.

If $media is a reference to a scalar, it is treated as the binary.
If a scalar, treated as a file containing the Media Resource.

$media_type is the media type of the Media Resource, such as 'image/png'.

If called in scalar context, returns a Location header.

     my $location
         = $client->createMedia( $collection_uri, $media, $media_type );

If called in list context, returns an B<XML::Atom::Entry> object of the 
Media Link Entry and an B<HTTP::Headers> object.

     my ( $entry, $headers )
         = $client->createMedia( $collection_uri, $media, $media_type );
     my $location = $headers->header('Location');

Returns false on error.


=head2 $client->postMedia( $collection_uri, $media, $media_type )

An alias for createMedia.


=head2 $client->getEntry( $edit_uri )

Retrieves an entry with the given URI $edit_uri.

Returns an B<XML::Atom::Entry> object.
If the server returns 304, returns a cache of the Media Resource.

Returns false on error.


=head2 $client->retrieveEntry( $edit_uri )

An alias for getEntry.


=head2 $client->getMedia( $edit_uri )

Retrieves Media Resource with the given URI $edit_uri.

If called in scalar context, returns binary of the Media Resource.

     my $media = $client->getMedia( $edit_uri );

If called in list context, returns binary of Media Resource and an
B<HTTP::Headers> object. 
If the server returns 304, returns a cache of the Media Resource.

     my ( $entry, $headers ) = $client->getMedia( $edit_uri );
     my $media_type = $headers->header('Content-Type');

Returns false on error.


=head2 $client->retrieveMedia( $edit_uri )

An alias for getMedia.


=head2 $client->editEntry( $edit_uri, $entry )

Updates the entry at URI $edit_uri with the entry $entry, which must be
an B<XML::Atom::Entry> object.

Returns an B<XML::Atom::Entry> object.
If the server returns no content with successful status code, the
requested entry is returned.

Returns false on error.


=head2 $client->putEntry( $edit_uri, $entry )

An alias for editEntry.


=head2 $client->updateEntry( $edit_uri, $entry )

An alias for updateEntry.


=head2 $client->editMedia( $edit_uri, $media, $media_type )

Updates the Media Resource at URI $edit_uri with the $media.

If $media is a reference to a scalar, it is treated as the binary.
If a scalar, treated as a file containing the Media Resource.

$media_type is the media type of the Media Resource, such as 'image/png'.

If called in scalar context, returns a Media Resource.

     my $media
         = $client->editMedia( $edit_uri, $media, $media_type );

If called in list context, returns a Media Resource and an B<HTTP::Headers> 
object.

     my ( $media, $headers )
         = $client->createMedia( $edit_uri, $media, $media_type );
     my $media_type = $headers->header('Content-Type');

If the server returns no content with successful status code, the
requested entry is returned.

Returns false on error.


=head2 $client->putMedia( $edit_uri, $media, $media_type )

An alias for editMedia.


=head2 $client->updateMedia( $edit_uri, $media, $media_type )

An alias for updateMedia.


=head2 $client->deleteEntry( $edit_uri );

Deletes the entry at URI $edit_uri.

Returns true on success, false otherwise.


=head2 $client->deleteMedia( $edit_uri );

Deletes the Media Resource at URI $edit_uri, and related Media Link Entry.

Returns true on success, false otherwise.


=head2 $client->getFeed( $collection_uri )

Retrieves a feed from the collection at URI $collection_uri.

Returns an B<XML::Atom::Feed> object representing the feed returned 
from the server.

Returns false on error.


=head2 $client->retrieveFeed( $collection_uri )

An alias for getFeed.


=head2 $client->_info( $collection )

=head2 $client->munge_request( $req )

=head2 $client->init


=head1 SEE ALSO

L<XML::Atom>
L<XML::Atom::Service>
L<Atompub::Server>


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
