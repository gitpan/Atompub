#line 1
package PPI::Document::File;

#line 18

use strict;
use Carp          ();
use Params::Util  qw{_STRING _INSTANCE};
use PPI::Document ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Document';
}





#####################################################################
# Constructor and Accessors

#line 50

sub new {
	my $class    = shift;
	my $filename = _STRING(shift);
	unless ( defined $filename ) {
		# Perl::Critic got a complaint about not handling a file
		# named "0".
		return $class->_error("Did not provide a file name to load");
	}

	# Load the Document
	my $self = $class->SUPER::new( $filename, @_ ) or return undef;

	# Unlike a normal inheritance situation, due to our need to stay
	# compatible with caching magic, this actually returns a regular
	# anonymous document. We need to rebless if
	if ( _INSTANCE($self, 'PPI::Document') ) {
		bless $self, 'PPI::Document::File';
	} else {
		die "PPI::Document::File SUPER call returned an object of the wrong type";
	}

	# Save the filename
	$self->{filename} = $filename;

	$self;
}

#line 84

sub filename {
	$_[0]->{filename};
}

#line 110

sub save {
	my $self = shift;

	# Save to where?
	my $filename = shift;
	unless ( defined $filename ) {
		$filename = $self->filename;
	}

	# Hand off to main save method
	$self->SUPER::save( $filename, @_ );
}

1;

#line 152
