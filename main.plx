#!/usr/bin/perl
use warnings;
use strict;
use diagnostics;
use lib './lib/';
use BayesianNetwork;
use Test::More;
use Test::Exception;


my $net=BayesianNetwork::build_graph_from_csv('Sample','heart.csv');
my $nodes=$net->get_nodes;
my $data=$net->get_data;
my ($A,$B,$C,$D)=(${$nodes}[0],${$nodes}[1],${$nodes}[2],${$nodes}[3]);


plan tests=>5;

subtest 'Graph Tests' =>sub{
	plan tests=>3;
	my $empty_graph=BayesianNetwork->new(nodes=>[]);	
	ok(scalar @{$empty_graph->get_nodes}==0,'Empty Graph');
	ok(scalar @{$nodes}==14,'Number of node in graph');
	ok(scalar @{$data}>0,'Data defined');
};


subtest 'Generic Node Tests' =>sub{
	plan tests=>4;
	ok(scalar @{$nodes}==14,'Number of Nodes');
	ok($net->get_node_by_name('sex')==$B,'Node by Name');
	dies_ok{$net->get_node_by_name('Inexistent Node')}'Node by Name (Node doesn\'t exists)';
	dies_ok{$net->get_node_by_name(12)}'Node by Name (Passed a non string value)';
};


subtest 'Edges and Parents Tests' =>sub{
	plan tests=>11;
	ok($A->add_edge($B,$data)==1,'Add Edge 1: A->B');
	ok($A->add_edge($C,$data)==1,'Add Edge 2: C->A');
	ok($B->add_edge($D,$data)==1,'Add Edge 3: A->D');
	ok($D->add_edge($A,$data)==0,'Add Edge (Cycle)');
	ok($C->add_edge($A,$data)==0,'Add Edge (Already Exists)');

	ok(scalar (@{$A->get_parents})==0,'Num Parents of A');
	ok(scalar (@{$B->get_parents})==1,'Num Parents of B');
	ok(scalar (@{$C->get_parents})==1,'Num Parents of C');

	ok(scalar @{$A->get_edges}==2,'Num Edges 1'); 
	
	ok(scalar @{${$B->get_ptable->get_jptb}[0]}==(scalar $A->get_domain($data) * scalar $B->get_domain($data)),'Num JPTB lines of B (P(B|A))');
	ok(scalar @{$B->get_ptable->get_nodes}==2,'Num Value for B lines of A (P(A|C))');
};



subtest 'Score Graph and Comparing'=>sub{
	plan tests=>4;
	my ($bic,$aic)=($net->bic,$net->aic);
	my $net2=BayesianNetwork::build_graph_from_csv('Sample','heart.csv');
	my @nodes2=@{$net2->get_nodes};
	my $net_duplicated=$net2->duplicate_graph;
	ok(scalar @{$net_duplicated->get_nodes}==scalar @{$net2->get_nodes},'Num Graph Duplicated Nodes = NumGraph Nodes');	

	$nodes2[0]->add_edge($nodes2[1],$net2->get_data);
	$nodes2[0]->add_edge($nodes2[2],$net2->get_data);
	$nodes2[0]->add_edge($nodes2[3],$net2->get_data);

	my $dup_node=${$net_duplicated->get_nodes}[0];	
	ok(scalar @{$dup_node->get_edges}!=scalar @{$nodes2[0]->get_edges},'Graph Duplicated Different Num Edges');

	ok($bic<0,'BIC of the graph');
	ok($aic<0,'AIC of the graph');	
};

subtest 'Structure Learning'=> sub{
	plan tests=>1;
	my $graph=BayesianNetwork::build_graph_from_csv('SampleNet','heart.csv');
	my $prog =  <<'__EOS__';
set key outside
set terminal wxt size 860,720
unset tics
c2s = system("awk '!/^#/ { print $4 }' sample.dat | sort | uniq")
set title "Bayesian Network: Network"
plot for [c2 in c2s] sprintf('< grep ''\b%s\b'' sample.dat', c2) using 1:2:(sprintf("%d", $3)) with labels point pt 7 offset char 1,-1 title c2,\
"edge.dat" using 1:2:($3-$1):($4-$2) with vectors notitle
__EOS__
	$graph->plot_graph($prog,'sample.dat','edge.dat');	
	my $ghc_bic=$graph->greedy_hill_climbing(BayesianNetwork::AIC);
	my @nodesBIC=@{$ghc_bic->get_nodes};
	my $AN=$nodesBIC[3];
	print "-"x33,"AIC","-"x33,"\n";	
	$graph->plot_graph($prog,'sample.dat','edge.dat');	
	ok(1);

};


