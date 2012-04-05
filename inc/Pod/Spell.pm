#line 1

require 5;
package Pod::Spell;    # Time-stamp: "2001-10-27 00:05:01 MDT"
use strict;
use vars qw(@ISA $VERSION);
$VERSION = '1.01';
use Pod::Parser ();
@ISA = ('Pod::Parser');

use constant MAXWORDLENGTH => 50; # max length of a word

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }
use Pod::Wordlist ();
use Pod::Escapes ('e2char');
use Text::Wrap ('wrap');
 # We don't need a very new version of Text::Wrap, altho they are nicer.
$Text::Wrap::huge = 'overflow';

use integer;
use locale;    # so our uc/lc works right
use Carp;

#==========================================================================
#
#  Override some methods
#

sub new {
  my $x = shift;
  my $new = $x->SUPER::new(@_);
  $new->{'spell_stopwords'} = { };
  @{ $new->{'spell_stopwords'} }{ keys %Pod::Wordlist::Wordlist } = ();
  $new->{'region'} = [];
  return $new;
}

sub verbatim { return ''; } # totally ignore verbatim sections

#----------------------------------------------------------------------

sub _get_stopwords_from {
  my $stopwords = $_[0]{'spell_stopwords'};

  my $word;
  while($_[1] =~ m<(\S+)>g) {
    $word = $1;
    if($word =~ m/^!(.+)/s) {  # "!word" deletes from the stopword list
      delete $stopwords->{$1};
      DEBUG and print "Unlearning stopword $1\n";
    } else {
      $stopwords->{$1} = 1;
      DEBUG and print "Learning stopword $1\n";
    }
  }
  return;

}

#----------------------------------------------------------------------

sub textblock {
  my($self, $paragraph) = @_;
  if(@{ $self->{'region'} }) {
    my $last = $self->{'region'}[-1];
    if($last eq 'stopwords') {
      $self->_get_stopwords_from( $paragraph );
      return;
    } elsif($last eq ':stopwords') {
      $self->_get_stopwords_from( $self->interpolate($paragraph) );
       # I guess that'd work.
      return;
    } elsif($last !~ m/^:/s) {
      DEBUG and printf "Ignoring a textblock because inside a %s region.\n",
        $self->{'region'}[-1];
      return;
    }
     # else fall thru, as with a :footnote region or something...
  }
  $self->_treat_words( $self->interpolate($paragraph) );
  return;
}

sub command {
  my $self = shift;
  my $command = shift;
  return if $command eq 'pod';

  if($command eq 'begin') {
    my $region_name;
    #print "BEGIN <$_[0]>\n";
    if(shift(@_) =~ m/^\s*(\S+)/s) {
      $region_name = $1;
    } else {
      $region_name = 'WHATNAME';
    }
    DEBUG and print "~~~~ Beginning region \"$region_name\" ~~~~\n";
    push @{ $self->{'region'} }, $region_name;
    
  } elsif($command eq 'end') {
    pop @{ $self->{'region'} }; # doesn't bother to check

  } elsif($command eq 'for') {
    if($_[0] =~ s/^\s*(\:?)stopwords\s*(.*)//s) {
      my $para = $2;
      $para = $self->interpolate($para) if $1;
      DEBUG > 1 and print "Stopword para: <$2>\n";
      $self->_get_stopwords_from( $para );
    }
  } elsif(@{ $self->{'region'} }) {  # TODO: accept POD formatting
    # ignore
  } elsif(
    $command eq 'head1' or $command eq 'head2' or
    $command eq 'head2' or $command eq 'head3' or
    $command eq 'item'
  ) {
    my $out_fh = $self->output_handle();
    print $out_fh "\n";
    $self->_treat_words( $self->interpolate(shift) );
    #print $out_fh "\n";
  } else {
    # no-op
  }
  return;
}

#--------------------------------------------------------------------------

sub interior_sequence {
  my $self = shift;
  my $command = shift;

  return '' if $command eq 'X' or $command eq 'Z';

  local $_ = shift;

  # Expand escapes into the actual character now, carping if invalid.
  if ($command eq 'E') {
    my $it = e2char($_);
    if(defined $it) {
      return $it;
    } else {
      carp "Unknown escape: E<$_>";
      return "E<$_>";
    }
  }

  # For all the other sequences, empty content produces no output.
  return if $_ eq '';

  if ($command eq 'B' or $command eq 'I' or $command eq 'S') {
    $_;
  } elsif ($command eq 'C' or $command eq 'F') {
    # don't lose word-boundaries
    my $out = '';
    $out .= ' ' if s/^\s+//s;
    my $append;
    $append = 1 if s/\s+$//s;
    $out .= '_' if length $_;
     # which, if joined to another word, will set off the Perl-token alarm
    $out .= ' ' if $append;
    $out;
  } elsif ($command eq 'L') {
    return $1 if m/^([^|]+)\|/s;
    '';
  } else {
    carp "Unknown sequence $command<$_>"
  }
}

#==========================================================================
# The guts:

sub _treat_words {
  my $p = shift;
  # Count the things in $_[0]
  DEBUG > 1 and print "Content: <", $_[0], ">\n";

  my $stopwords = $p->{'spell_stopwords'};
  my $word;
  $_[0] =~ tr/\xA0\xAD/ /d;
    # i.e., normalize non-breaking spaces, and delete soft-hyphens
  
  my $out = '';
  
  my($leading, $trailing);
  while($_[0] =~ m<(\S+)>g) {
    # Trim normal English punctuation, if leading or trailing.
    next if length $1 > MAXWORDLENGTH;
    $word = $1;
    if( $word =~ s/^([\`\"\'\(\[])//s )
     { $leading = $1 } else { $leading = '' }
    
    if( $word =~ s/([\)\]\'\"\.\:\;\,\?\!]+)$//s )
     { $trailing = $1 } else { $trailing = '' }
    
    if($word =~ m/^[\&\%\$\@\:\<\*\\\_]/s
           # if it looks like it starts with a sigil, etc.
       or $word =~ m/[\%\^\&\#\$\@\_\<\>\(\)\[\]\{\}\\\*\:\+\/\=\|\`\~]/
            # or contains anything strange
    ) {
      DEBUG and print "rejecting {$word}\n" unless $word eq '_';
      next;
    } else {
      if(exists $stopwords->{$word} or exists $stopwords->{lc $word}) {
        DEBUG and print " [Rejecting \"$word\" as a stopword]\n";
      } else {
        $out .= "$leading$word$trailing ";
      }
    }
  }

  if(length $out) {
    my $out_fh = $p->output_handle();
    print $out_fh wrap('','',$out), "\n\n";
  }

  return;
}

#--------------------------------------------------------------------------

1;
__END__

#line 401


