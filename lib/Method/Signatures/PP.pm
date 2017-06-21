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
      method(?&PerlOWS)(?&PerlIdentifier)(?&PerlOWS)(?&PerlBlock)(?&PerlOWS)
      (?{ push @Found, [ $Statement_Start, pos() - $Statement_Start ] })
    )
  )
  $PPR::GRAMMAR
}x;

sub import {
  my $done = 0;
  filter_add(sub {
    return 0 if $done++;
    1 while filter_read();
    warn "CODE >>>\n$_<<<";
    local @Found;
    die "Um. What?" unless /(?&PerlDocument) $grammar/x;
    ::Dwarn @Found;
    my $offset = 0;
    foreach my $case (@Found) {
      my ($start, $len) = @$case;
      $start += $offset;
      my $stmt = substr($_, $start, $len);
warn $stmt;
      die "Whit?"
        unless my @match = $stmt =~ m{
          \A
          method ((?&PerlOWS))
          ((?&PerlIdentifier)) ((?&PerlOWS))
          ((?&PerlBlock)) ((?&PerlOWS))
          $PPR::GRAMMAR
        }x;
      my ($ws0, $name, $ws1, $block, $ws2) = @match;
      $block =~ s{^\{}{\{my \$self = shift;};
      my $replace = "sub${ws0}${name}${ws1}${block}${ws2}";
      substr($_, $start, $len) = $replace;
      $offset += length($replace) - $len;
    }
    warn "FINAL >>>\n$_<<<";
    return 1;
  });
}

1;
