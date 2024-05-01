perl -e binmode stdin;binmode stdout;$/=undef;my $x=<>;print pack("C*", map { ord($_)|0x80 . $_ . " " } split(//, $x));
