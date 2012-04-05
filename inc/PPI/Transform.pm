#line 1
package PPI::Transform;

#line 16

use strict;
use Carp          ();
use List::Util    ();
use PPI::Document ();
use Params::Util  qw{_INSTANCE _CLASS _CODE _SCALAR0};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.215';
}





#####################################################################
# Apply Handler Registration

my %HANDLER = ();
my @ORDER   = ();

# Yes, you can use this yourself.
# I'm just leaving it undocumented for now.
sub register_apply_handler {
	my $class   = shift;
	my $handler = _CLASS(shift) or Carp::croak("Invalid PPI::Transform->register_apply_handler param");
	my $get     = _CODE(shift)  or Carp::croak("Invalid PPI::Transform->register_apply_handler param");
	my $set     = _CODE(shift)  or Carp::croak("Invalid PPI::Transform->register_apply_handler param");
	if ( $HANDLER{$handler} ) {
		Carp::croak("PPI::Transform->apply handler '$handler' already exists");
	}

	# Register the handler
	$HANDLER{$handler} = [ $get, $set ];
	unshift @ORDER, $handler;
}

# Register the default handlers
__PACKAGE__->register_apply_handler( 'SCALAR', \&_SCALAR_get, \&_SCALAR_set );
__PACKAGE__->register_apply_handler( 'PPI::Document', sub { $_[0] }, sub { 1 } );





#####################################################################
# Constructor

#line 85

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

#line 113

sub document {
	my $class = shift;
	die "$class does not implement the required ->document method";
}

#line 136

sub apply {
	my $self = _SELF(shift);
	my $it   = defined $_[0] ? shift : return undef;

	# Try to find an apply handler
	my $class = _SCALAR0($it) ? 'SCALAR'
		: List::Util::first { _INSTANCE($it, $_) } @ORDER
		or return undef;
	my $handler = $HANDLER{$class}
		or die("->apply handler for $class missing! Panic");

	# Get, change, set
	my $Document = _INSTANCE($handler->[0]->($it), 'PPI::Document')
		or Carp::croak("->apply handler for $class failed to get a PPI::Document");
	$self->document( $Document ) or return undef;
	$handler->[1]->($it, $Document)
		or Carp::croak("->apply handler for $class failed to save the changed document");
	1;		
}

#line 174

sub file {
	my $self = _SELF(shift);

	# Where do we read from and write to
	my $input  = defined $_[0] ? shift : return undef;
	my $output = @_ ? defined $_[0] ? "$_[0]" : undef : $input or return undef;

	# Process the file
	my $Document = PPI::Document->new( "$input" ) or return undef;
	$self->document( $Document )                  or return undef;
	$Document->save( $output );
}





#####################################################################
# Apply Hander Methods

sub _SCALAR_get {
	PPI::Document->new( $_[0] );
}

sub _SCALAR_set {
	my $it = shift;
	$$it = $_[0]->serialize;
	1;
}





#####################################################################
# Support Functions

sub _SELF {
	return shift if ref $_[0];
	my $self = $_[0]->new or Carp::croak(
		"Failed to auto-instantiate new $_[0] object"
	);
	$self;
}

1;

#line 243
