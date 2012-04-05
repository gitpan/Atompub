#line 1
package PPI::Find;

#line 72

use strict;
use Params::Util qw{_INSTANCE};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.215';
}





#####################################################################
# Constructor

#line 98

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my $wanted = ref $_[0] eq 'CODE' ? shift : return undef;

	# Create the object
	my $self = bless {
		wanted => $wanted,
	}, $class;

	$self;
}

#line 124

sub clone {
	my $self = ref $_[0] ? shift
		: die "->clone can only be called as an object method";
	my $class = ref $self;

	# Create the object
	my $clone = bless {
		wanted => $self->{wanted},
	}, $class;

	$clone;
}





####################################################################
# Search Execution Methods

#line 170

sub in {
	my $self    = shift;
	my $Element = shift;
	my %params  = @_;
	delete $self->{errstr};
 
	# Are we already acting as an iterator
	if ( $self->{in} ) {
		return $self->_error('->in called while another search is in progress', %params);
	}

	# Get the root element for the search
	unless ( _INSTANCE($Element, 'PPI::Element') ) {
		return $self->_error('->in was not passed a PPI::Element object', %params);
	}

	# Prepare the search
	$self->{in}      = $Element;
	$self->{matches} = [];

	# Execute the search
	eval {
		$self->_execute;
	};
	if ( $@ ) {
		my $errstr = $@;
		$errstr =~ s/\s+at\s+line\s+.+$//;
		return $self->_error("Error while searching: $errstr", %params);
	}

	# Clean up and return
	delete $self->{in};
	if ( $params{array_ref} ) {
		if ( @{$self->{matches}} ) {
			return delete $self->{matches};
		}
		delete $self->{matches};
		return '';
	}

	# Return as a list
	my $matches = delete $self->{matches};
	@$matches;
}

#line 230

sub start {
	my $self    = shift;
	my $Element = shift;
	delete $self->{errstr};

	# Are we already acting as an iterator
	if ( $self->{in} ) {
		return $self->_error('->in called while another search is in progress');
	}

	# Get the root element for the search
	unless ( _INSTANCE($Element, 'PPI::Element') ) {
		return $self->_error('->in was not passed a PPI::Element object');
	}

	# Prepare the search
	$self->{in}      = $Element;
	$self->{matches} = [];

	# Execute the search
	eval {
		$self->_execute;
	};
	if ( $@ ) {
		my $errstr = $@;
		$errstr =~ s/\s+at\s+line\s+.+$//;
		$self->_error("Error while searching: $errstr");
		return undef;
	}

	1;
}

#line 274

sub match {
	my $self = shift;
	return undef unless $self->{matches};

	# Fetch and return the next match
	my $match = shift @{$self->{matches}};
	return $match if $match;

	$self->finish;
	undef;
}

#line 305

sub finish {
	my $self = shift;
	delete $self->{in};
	delete $self->{matches};
	delete $self->{errstr};
	1;
}





#####################################################################
# Support Methods and Error Handling

sub _execute {
	my $self   = shift;
	my $wanted = $self->{wanted};
	my @queue  = ( $self->{in} );

	# Pull entries off the queue and hand them off to the wanted function
	while ( my $Element = shift @queue ) {
		my $rv = &$wanted( $Element, $self->{in} );

		# Add to the matches if returns true
		push @{$self->{matches}}, $Element if $rv;

		# Continue and don't descend if it returned undef
		# or if it doesn't have children
		next unless defined $rv;
		next unless $Element->isa('PPI::Node');

		# Add the children to the head of the queue
		if ( $Element->isa('PPI::Structure') ) {
			unshift @queue, $Element->finish if $Element->finish;
			unshift @queue, $Element->children;
			unshift @queue, $Element->start if $Element->start;
		} else {
			unshift @queue, $Element->children;
		}
	}

	1;
}

#line 361

sub errstr {
	shift->{errstr};
}

sub _error {
	my $self = shift;
	$self->{errstr} = shift;
	my %params = @_;
	$params{array_ref} ? undef : ();
}

1;

#line 400
