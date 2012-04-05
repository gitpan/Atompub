#line 1
package PPI::Transform::UpdateCopyright;

#line 28

use strict;
use Params::Util   qw{_STRING};
use PPI::Transform ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.215';
}





#####################################################################
# Constructor and Accessors

#line 61

sub new {
	my $self = shift->SUPER::new(@_);

	# Must provide a name
	unless ( defined _STRING($self->name) ) {
		PPI::Exception->throw("Did not provide a valid name param");
	}

	return $self;
}

#line 81

sub name {
	$_[0]->{name};
}





#####################################################################
# Transform

sub document {
	my $self     = shift;
	my $document = _INSTANCE(shift, 'PPI::Document') or return undef;

	# Find things to transform
	my $name     = quotemeta $self->name;
	my $regexp   = qr/\bcopyright\b.*$name/m;
	my $elements = $document->find( sub {
		$_[1]->isa('PPI::Token::Pod') or return '';
		$_[1]->content =~ $regexp     or return '';
		return 1;
	} );
	return undef unless defined $elements;
	return 0 unless $elements;

	# Try to transform any elements
	my $changes = 0;
	my $change  = sub {
		my $copyright = shift;
		my $thisyear  = (localtime time)[5] + 1900;
		my @year      = $copyright =~ m/(\d{4})/g;

		if ( @year == 1 ) {
			# Handle the single year format
			if ( $year[0] == $thisyear ) {
				# No change
				return $copyright;
			} else {
				# Convert from single year to multiple year
				$changes++;
				$copyright =~ s/(\d{4})/$1 - $thisyear/;
				return $copyright;
			}
		}

		if ( @year == 2 ) {
			# Handle the range format
			if ( $year[1] == $thisyear ) {
				# No change
				return $copyright;
			} else {
				# Change the second year to the current one
				$changes++;
				$copyright =~ s/$year[1]/$thisyear/;
				return $copyright;
			}
		}

		# huh?
		die "Invalid or unknown copyright line '$copyright'";
	};

	# Attempt to transform each element
	my $pattern = qr/\b(copyright.*\d)({4}(?:\s*-\s*\d{4})?)(.*$name)/mi;
	foreach my $element ( @$elements ) {
		$element =~ s/$pattern/$1 . $change->($2) . $2/eg;
	}

	return $changes;
}

1;

#line 182
