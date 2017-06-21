package Method::Signatures::PP;

use strict;
use warnings;
use Filter::Util::Call;
use PPR;

our $Statement_Start;

our @Found;

my $grammar = qr{
  (?(DEFINE)
    (?<PerlKeyword>
      (?{ local $Statement_Start = pos() })
      method (?&PerlOWS)
      (?&PerlIdentifier) (?&PerlOWS)
      (?: (?&kw_balanced_parens) (?&PerlOWS) )?+
      (?&PerlBlock) (?&PerlOWS)
      (?{ push @Found, [ $Statement_Start, pos() - $Statement_Start ] })
    )
    (?<kw_balanced_parens>
      \( (?: [^()]++ | (?&kw_balanced_parens) )*+ \)
    )
  )
  $PPR::GRAMMAR
}x;

sub import {
  my $done = 0;
  filter_add(sub {
    return 0 if $done++;
    1 while filter_read();
    #warn "CODE >>>\n$_<<<";
    local @Found;
    unless (/(?&PerlDocument) $grammar/x) {
      warn "Failed to parse file; expect complication errors, sorry.\n";
    }
    my $offset = 0;
    foreach my $case (@Found) {
      my ($start, $len) = @$case;
      $start += $offset;
      my $stmt = substr($_, $start, $len);
      die "Whit?"
        unless my @match = $stmt =~ m{
          \A
          method ((?&PerlOWS))
          ((?&PerlIdentifier)) ((?&PerlOWS))
          (?: ((?&kw_balanced_parens)) ((?&PerlOWS)) )?+
          ((?&PerlBlock)) ((?&PerlOWS))
          $grammar
        }x;
      my ($ws0, $name, $ws1, $sig, $ws2, $block, $ws3) = @match;
      my $sigcode = $sig ? " my $sig = \@_;" : '';
      $block =~ s{^\{}{\{my \$self = shift;${sigcode}};
      my $replace = "sub${ws0}${name}${ws1}${block}${ws3}";
      substr($_, $start, $len) = $replace;
      $offset += length($replace) - $len;
    }
    #warn "FINAL >>>\n$_<<<";
    return 1;
  });
}

1;
