package Method::Signatures::PP;

use strict;
use warnings;
use Filter::Util::Call;
use PPR;

my $grammar = qr{
  (?(DEFINE)
    (?<PerlKeyword>
      method(?&PerlOWS)(?&PerlIdentifier)(?&PerlOWS)(?&PerlBlock)(?&PerlOWS)
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
    while (/(?&PerlOWS)?((?&PerlStatement)) $grammar/xg) {
      my $len = length($1);
      my $start = pos() - $len;
      my $stmt = $1;
warn $stmt;
      if (my @match = $stmt =~ m{
        \A
        method ((?&PerlOWS))
        ((?&PerlIdentifier)) ((?&PerlOWS))
        ((?&PerlBlock)) ((?&PerlOWS))
        $PPR::GRAMMAR
      }x) {
        my ($ws0, $name, $ws1, $block, $ws2) = @match;
        $block =~ s{^\{}{\{my \$self = shift;};
        my $replace = "sub${ws0}${name}${ws1}${block}${ws2}";
        substr($_, $start, $len) = $replace;
        pos() += length($replace) - $len;
      }
    }
    return 1;
  });
}

1;
