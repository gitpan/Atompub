#line 1
package PPI::Normal;

#line 35

use strict;
use Carp                      ();
use List::MoreUtils           ();
use PPI::Util                 '_Document';
use PPI::Document::Normalized ();

use vars qw{$VERSION %LAYER};
BEGIN {
	$VERSION = '1.215';

	# Registered function store
	%LAYER = (
		1 => [],
		2 => [],
	);
}





#####################################################################
# Configuration

#line 75

sub register {
	my $class = shift;
	while ( @_ ) {
		# Check the function
		my $function = shift;
		SCOPE: {
			no strict 'refs';
			defined $function and defined &{"$function"}
				or Carp::croak("Bad function name provided to PPI::Normal");
		}

		# Has it already been added?
		if ( List::MoreUtils::any { $_ eq $function } ) {
			return 1;
		}

		# Check the layer to add it to
		my $layer = shift;
		defined $layer and $layer =~ /^(?:1|2)$/
			or Carp::croak("Bad layer provided to PPI::Normal");

		# Add to the layer data store
		push @{ $LAYER{$layer} }, $function;
	}

	1;
}

# With the registration mechanism in place, load in the main set of
# normalization methods to initialize the store.
use PPI::Normal::Standard;





#####################################################################
# Constructor and Accessors

#line 157

sub new {
	my $class = shift;
	my $layer = @_ ?
		(defined $_[0] and ! ref $_[0] and $_[0] =~ /^[12]$/) ? shift : return undef
		: 1;

	# Create the object
	my $object = bless {
		layer => $layer,
		}, $class;

	$object;
}

#line 179

sub layer { $_[0]->{layer} }





#####################################################################
# Main Methods

#line 241

sub process {
	my $self = ref $_[0] ? shift : shift->new;

	# PPI::Normal objects are reusable, but not re-entrant
	return undef if $self->{Document};

	# Get or create the document
	$self->{Document} = _Document(shift) or return undef;

	# Work out what functions we need to call
	my @functions = ();
	foreach ( 1 .. $self->layer ) {
		push @functions, @{ $LAYER{$_} };
	}

	# Execute each function
	foreach my $function ( @functions ) {
		no strict 'refs';
		&{"$function"}( $self->{Document} );
	}

	# Create the normalized Document object
	my $Normalized = PPI::Document::Normalized->new(
		Document  => $self->{Document},
		version   => $VERSION,
		functions => \@functions,
	) or return undef;

	# Done, clean up
	delete $self->{Document};
	return $Normalized;
}

1;

#line 332
