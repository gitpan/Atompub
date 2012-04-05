#line 1
package PPI::Statement::Include;

#line 45

use strict;
use PPI::Statement                 ();
use PPI::Statement::Include::Perl6 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

#line 88

sub type {
	my $self    = shift;
	my $keyword = $self->schild(0) or return undef;
	$keyword->isa('PPI::Token::Word') and $keyword->content;
}

#line 121

sub module {
	my $self = shift;
	my $module = $self->schild(1) or return undef;
	$module->isa('PPI::Token::Word') and $module->content;
}

#line 161

sub module_version {
	my $self     = shift;
	my $argument = $self->schild(3);
	if ( $argument and $argument->isa('PPI::Token::Operator') ) {
		return undef;
	}

	my $version = $self->schild(2) or return undef;
	return undef unless $version->isa('PPI::Token::Number');

	return $version;
}

#line 198

sub pragma {
	my $self   = shift;
	my $module = $self->module or return '';
	$module =~ /^[a-z][a-z\d]*$/ ? $module : '';
}

#line 262

sub version {
	my $self    = shift;
	my $version = $self->schild(1) or return undef;
	$version->isa('PPI::Token::Number') ? $version->content : '';
}

#line 317

sub version_literal {
	my $self    = shift;
	my $version = $self->schild(1) or return undef;
	$version->isa('PPI::Token::Number') ? $version->literal : '';
}

#line 435

sub arguments {
	my $self = shift;
	my @args = $self->schildren;

	# Remove the "use", "no" or "require"
	shift @args;

	# Remove the statement terminator
	if (
		$args[-1]->isa('PPI::Token::Structure')
		and
		$args[-1]->content eq ';'
	) {
		pop @args;
	}

	# Remove the module or perl version.
	shift @args;  

	return unless @args;

	if ( $args[0]->isa('PPI::Token::Number') ) {
		my $after = $args[1] or return;
		$after->isa('PPI::Token::Operator') or shift @args;
	}

	return @args;
}

1;

#line 492
