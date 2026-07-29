#!/usr/bin/perl
use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;

my %objs = (); # object files

sub getobj($) {
    my ($o) = @_;

    if (!exists($objs{$o})) {
        $objs{$o} = {
            name => $o,
            symbols => {}
        };
    }

    return $objs{$o};
}

sub getsym($$) {
    my ($do, $s) = @_;

    my $symbols = $do->{symbols};

    if (!exists($symbols->{$s})) {
        $do->{symbols}->{$s} = {
            name => $s,
            refs => []
        };
    }

    return $do->{symbols}->{$s};
}


sub create_gexf {
    my (%args) = @_;
    my $nodes = $args{nodes} // [];
    my $edges = $args{edges} // [];
    my $mode  = $args{mode} // "static";
    my $defaultedgetype = $args{defaultedgetype} // "directed";

    my $doc = XML::LibXML::Document->new("1.0", "UTF-8");

    # Root <gexf> element
    my $gexf = $doc->createElement("gexf");
    $gexf->setAttribute("xmlns", "http://gexf.net/1.3");
    $gexf->setAttribute("version", "1.3");
    $doc->setDocumentElement($gexf);

    # <graph>
    my $graph = $doc->createElement("graph");
    $graph->setAttribute("mode", $mode);
    $graph->setAttribute("defaultedgetype", $defaultedgetype);
    $gexf->appendChild($graph);

    # <nodes> — created dynamically from the array of hashes
    my $nodes_elem = $doc->createElement("nodes");
    $graph->appendChild($nodes_elem);
    for my $o (keys %objs) {
        my $obj_node_elem = $doc->createElement("node");
        $obj_node_elem->setAttribute("id", $o);        
        $obj_node_elem->setAttribute("label", $o);        
        $nodes_elem->appendChild($obj_node_elem);        
    }

    # <edges> — created dynamically, auto-incrementing id if not provided
    my $edges_elem = $doc->createElement("edges");
    $graph->appendChild($edges_elem);
    my $i = 0;
    for my $o (keys %objs) {
        for my $s (keys(%{$objs{$o}->{symbols}})) {            
            for my $ro (@{$objs{$o}->{symbols}->{$s}->{refs}}) {
                my $edge_elem = $doc->createElement("edge");
                $edge_elem->setAttribute("id", $i);
                $edge_elem->setAttribute("target", $o);
                $edge_elem->setAttribute("source", $ro);
                $edge_elem->setAttribute("label", $s);
                $edges_elem->appendChild($edge_elem);
                $i++;
            }
        }
    }

    return $doc;
}

sub Usage($) {
    my ($msg) = @_;

    print STDERR "ERROR: $msg\n";

    print STDERR "Usage: gerphmap.pl <input> <output>

Converts symbol references in an ld65 map file to a 

";

    exit 10;
}

#GetOptions("romno=s" => \$romno) or Usage("Bad options $!");

$#ARGV == 1 or Usage("Wrong number of arguments");

my ($fn_in, $fn_out) = @ARGV;

open (my $f_in, "<", $fn_in) or die "Cannot open \"$fn_in\" for input: $!";
open (my $f_out, ">", $fn_out) or die "Cannot open \"$fn_out\" for output: $!";


my $state = 0;


my $cur_sym;
while (<$f_in>) {

    s/[\r\n\s]+$//;


    if ($state == 0) {
        if ($_ =~ /^Imports list:/) {
            $state = 1;
        }
    } elsif ($_ =~ /^-*$/) {
        # nowt
    } elsif ($_ =~ /^\*$/) {
        # nowt
    } elsif ($_ =~ /^([\w_]+)\s*\(([\w_\-]+\.o|\[linker generated\])\):/) {
        
        my ($dest_obj, $dest_sym) = ($2, $1);

        my $do = getobj($2);
        $cur_sym = getsym($do, $1)

    } elsif ($_ =~ /^\s+([\w_\-]+\.o).*/) {
     
        my $o = $1;

        my $so = getobj($o);

        push @{$cur_sym->{refs}}, $o;

    } else {
        die;
    }
}

close($f_in);

#print Dumper(\%objs);

my $doc = create_gexf();

#print $doc->toString(1);  # 1 = pretty-print/indent

print $f_out $doc->toString(1);
close $f_out;