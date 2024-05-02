#!/bin/env perl

use strict;

# convert a binary file to a Model C MOS module
#
# the supplied binary file will have it's length checked and a checksum 
# appended


sub usage($$) {
	my ($fh, $msg) = @_;

	print "makemod.pl <input.bin> <output.mod>\n";

	$msg && die $msg;
}

sub error($) {
	my ($msg) = @_;
	die $msg;
}

sub checkbounds($$$$) {
	my ($base, $adj, $offset, $l) = @_;

	my $bb = $base + $adj;

	$offset >= (0x26-$bb) && $offset < $l-1-$bb || error("BRL Offset out of bounds at offset $base")
}

sub bytearound($) {
	my ($bin) = @_;
	my $ret = 0;
	if ((length($bin) & 1) == 1) {
		$bin = $bin . chr(0);
	}
	foreach my $s (unpack("S*", $bin)) {
		$ret += $s;
		if ($ret >= 0x10000) {
			$ret = ($ret & 0xFFFF)+1;
		}
	}
	return $ret;
}

my $fn_bin = shift or usage(*STDERR, "Missing bin file argument");
my $fn_mod = shift or usage(*STDERR, "Missing mod file argument");

open(my $fh_bin, "<:raw:", $fn_bin) or usage(*STDERR, "Cannot open \"$fn_bin\" for input : $!");

my $bin;
my $bin_len = read($fh_bin, $bin, 0x10001);

# sanity binary sizes

$bin_len <= 0x10000 || error("Binary file > 64K");
$bin_len >= 0x20    || error("Binary file too small");

# sanity check header

my ($b1, $o1, $b2, $o2, $b3, $o3, $b4, $o4, $l, $fl, $ot, $vn, $ohel, $ocom, $copl, $coph) = unpack("C s C s C s C s S S L S S S S S L L", $bin);

$l == $bin_len || error("Binary file length doesn't match header $bin_len <> $l");
$b1 == 0x82 || error("Expecting BRL instruction at offset 0");
$b2 == 0x82 || error("Expecting BRL instruction at offset 3");
$b3 == 0x82 || error("Expecting BRL instruction at offset 6");
$b4 == 0x82 || error("Expecting BRL instruction at offset 9");
checkbounds(0x00, 2, $o1, $l);
checkbounds(0x03, 2, $o2, $l);
checkbounds(0x06, 2, $o3, $l);
checkbounds(0x09, 2, $o4, $l);


close $fh_bin;

my $cksum = bytearound(substr($bin, 0, $l));

printf "Module: len=%d, cksum=%04x\n", $l, $cksum;

open(my $fh_mod, ">:raw:", $fn_mod) or usage(*STDERR, "Cannot open \"$fn_mod\" for output : $!");

print $fh_mod substr($bin, 0, $l);
print $fh_mod pack("S", $cksum);
my $pad = ($l + 2) % 256;
if ($pad) {
	$pad = 256-$pad;
}
print $fh_mod chr(0xFF) x $pad;

print "$l $pad\n";

close $fh_mod;