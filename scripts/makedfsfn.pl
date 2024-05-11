#!/usr/bin/env perl

use strict;

print join(' ', map( { uc(substr(nosp($_), 0, 7)) } @ARGV));

sub nosp($) {
	my ($x) = @_;
	$x =~ s/[^A-Z0-9]/_/g;
	$x =~ s/__/_/g;
}