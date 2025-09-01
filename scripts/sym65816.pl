#!/usr/bin/env perl

use strict;

# adds symbolic information to a decode6502.exe listing file

my %syms=();

sub symsubst($$) {
	my ($romno,$orgaddr) = @_;
	
	my $addr;
	if (length($orgaddr) == 2) {
		$addr = "00" . $orgaddr;
	} else {
		if ($orgaddr =~ /^[89AB]/ && $romno) {
			$addr = $romno . ':' . $orgaddr;
		} else {
			$addr = $orgaddr;
		}
	}

	my $sym = $syms{$addr};


	if ($sym)
	{
		return $sym;
	} else {
		return $addr;
	}
}

my $fn_s = shift or die "missing symbol filename";

open(my $fh_s, '<', $fn_s) or die "Cannot open $fn_s for reading $!";


while (<$fh_s>) {
	my $l = $_;

	if ($l =~ /^DEF\s+(\w+)\s+(([0-9A-F]:)?[0-9A-F]{1,6})/) {
		my $lbl = $1;
		my $addr = $2;
		$addr =~ s/^([0-9A-F]:)?([0-9A-F]{1,6})$/$1$2/;
		if (length($addr) == 4) {
			$addr = "FF" . $addr;
		}
		$syms{$addr} = $lbl;
#		print "$addr = $lbl\n";
	}
}

foreach my $k (keys %syms) {
	print "$k : $syms{$k}\n";
}

while (<>) {
	my $l = $_;
	chomp $l;
	$l =~ s/[\s\r\n]+$//;

	if (/^\s*(([0-9A-F]:)?[0-9A-F]{6})/) {
		my $lbl = $syms{$1};
		if ($lbl) {
			print ".$lbl\n";
		}
	}

	if ($l =~ /^\s*((([0-9A-F]):)?[0-9A-F\?]{6})\s:\s(.{11})\s:\s(.{14})\s(.*)/)
	{
		my $rom=$3;
		my $add = $1;
		my $bytes = $4;
		my $dis = $5; 
		my $rest = $6;
		$dis =~ s/^\s+//;
		$dis =~ s/\s+$//;
		$dis =~ s/((?<!(#|\w))([0-9A-F]{2,6}))(?!\w)/symsubst($rom,$1)/ge;
		
		$l = sprintf("%s : %s : %-40s : %s", $add, $bytes, $dis, $rest);
	}

	print "\t$l\n";

}