package BayesianNetwork;
#!/usr/bin/perl
use warnings;
use strict;
use diagnostics;
use Math::Trig;
use Node;
use bignum;
use Math::Gauss ':all';
use constant{ AIC => 0, BIC =>1, ADD=>'A', REM=>'R', REV=>'V'};

# Class: BayesianNetwork
# Instance Variables: nodes array of node
# Public Methods: build_graph_from_csv, get_data, get_nodes, add_node, add_edge


#my @data;

sub new{
	my ($class,$self)=(shift,{@_});
	bless($self,$class);
	return $self;
}

#Class Method
#Return pointer to BayesianNetwork
sub build_graph_from_csv{
	my ($name,$csv,$method)=(shift,shift,shift); 
	my @nodes;
	my @data;
	eval{	
		open(my $fin,"<",$csv);
		my @variables=split(/,/, <$fin>);
		for(0..$#variables){
			chomp($variables[$_]);
			push @nodes,Node->new(id=>$_, name=>$variables[$_], edges=>[], parents=>[], ptable=>PTable->new(nodes=>[$_],jptb=>undef));

		}
		my $count=0;		
		while(my $line=<$fin>){
			my @values=split(/,/,$line);
			push @{$data[$count]}, $values[$_] for(0..$#values); 
			$count++;
		}
		for my $n (@nodes){
			my $num_data=0;
			my %dataRow;			
			for(@data){
				$dataRow{${$_}[$n->get_id]}++;
				$num_data++;
			}
			my @dataToInsert=undef;
			while(my ($k,$v)=each(%dataRow)){
				push @dataToInsert,{P=>$v/$num_data,$n->get_id =>$k};
			}
			$n->add_data(\@dataToInsert);
		}
		close($fin);	
		return BayesianNetwork->new(name=>$name,nodes=>\@nodes,data=>\@data);
	}or do{
		die $@ || "Unknown error\n";
	}
}

sub get_nodes{
	return shift->{nodes};
}

sub get_name{
	return shift->{name};
}

sub get_data{
	return shift->{data};
}

sub print_data_with_limit{
	my ($net,$num_data)=(shift,shift);
	my @nodes=@{$net->get_nodes};
	my @data=@{$net->get_data};	
	print "\t";	
	print $_->get_name,"\t"for(@nodes);
	print "\n";
	for (my $i=0;$i<$num_data;$i++){
		for(my $j=0;$j<scalar@{$data[$i]};$j++){
			print $data[$i][$j],"\t";
		}
		print "\n";
	}
	print "-"x(scalar @data),"\n";
}

sub print_data{
	my $net=shift;
	$net->print_data_with_limit(scalar @{$net->get_data});
}

sub set_data{
	my ($net,$dataRef)=(shift,shift);
	$net->{data}=$dataRef;
	
}

sub get_node_by_name{
	my ($graph,$name)=(shift,shift);
	for(@{$graph->get_nodes}){		
		return $_ if($_->get_name eq $name);	
	}
	die 'Error: node ',$name,' doesn\' exists!\n';
}

sub add_edge_by_id{
	my ($graph,$n1,$n2)=(shift,shift,shift);
	my @nodes=$graph->get_nodes;
	return $nodes[$n1]->add_edge($nodes[$n2],$graph->get_data);
}


sub duplicate_graph{
	my $net=shift;
	my $new_net;
	my @new_nodes;
	for my $n (@{$net->get_nodes}){
		my ($id,$name)=($n->get_id,$n->get_name);
		my (@edges,@parents);
		my $ptable;
		my $newNode=Node->new(id=>$id,name=>$name,edges=>[],parents=>[],gaussian_prior=>0,ptable=>PTable->new(nodes=>[$_],jptb=>undef));
		$newNode->add_edge($_,$net->get_data) for(@{$n->get_edges});
		push @new_nodes,$newNode;
	}
	$new_net=BayesianNetwork->new(nodes=>\@new_nodes);

	return $new_net;
}

sub check_edge_add{
	my ($add_net,$score,$method)=(shift,shift,shift);
	my $act_score;
	my ($ris_graph,$from,$to);
	for my $n (@{$add_net->get_nodes}){
		for(@{$add_net->get_nodes}){
			next if(!$n->add_edge($_,$add_net->get_data));
			$act_score=&$method($add_net);
			print "[add] ",$n->get_id,"->",$_->get_id," score: $score act_score: $act_score";
			if($score<$act_score){
				print " Found=> ",$n->get_id,"->",$_->get_id;
				($from,$to)=($n,$_);
				$score=$act_score;				
			}
			print "\n";
			$n->remove_edge($_,$add_net->get_data);
		}
	}
	print "\n","-"x33,"\n";
	return ($score,$from,$to);
}

sub check_edge_remove{
	my ($rem_net,$score,$method)=(shift,shift,shift);
	my ($from,$to)=(undef,undef);
	#my %edges_evaluated;
	my $act_score;
	my @nodes=@{$rem_net->get_nodes};
	for my $n(@{$rem_net->get_nodes}){
		print "[rem] Node Edges: ",scalar @{$n->get_edges};
		print " -> ";		
		print $_->get_id," " for(@{$n->get_edges});		
		print "\n";
		#next if(@{$n->get_edges});
		for my $e(@{$n->get_edges}){
			print "[rem] E: ",$n->get_id,"->",$e->get_id," ",$e->get_name," \n";

			$n->remove_edge($e,$rem_net->get_data);
			my $act_score=&$method($rem_net);

			print "[rem] score: $score act_score: $act_score";
			
			if($act_score>$score){
				print " Found";				
				$score=$act_score;
				$from=$n;
				$to=$_;
			}
			#READD EDGE ON END LIST
			print "\n";
			unshift @{$e->{parents}},$n;	
			unshift @{$n->{edges}},$e;
			$e->estimate_jptb($rem_net->get_data);
		}

	}

	print "\n","-"x33,"\n";
	return ($score,$from,$to);
}


sub check_edge_reverse{
	my ($rev_net,$score,$method)=(shift,shift,shift);
	my ($from,$to)=(undef,undef);
	my $act_score;	
	for my $n(@{$rev_net->get_nodes}){
		print "[rev] Node Edges: ",scalar @{$n->get_edges},"\n";
		for(@{$n->get_edges}){
			
			print "[rev] E: ",$n->get_id,"->",$_->get_id,"\n";
			$n->reverse_edge($_,$rev_net->get_data);
			$act_score=&$method($rev_net);
			print "[rev] score: $score act_score: $act_score";
			if($act_score>$score){
				print " Found";				
				$score=$act_score;
				$from=$n;
				$to=$_;
			}
			print "\n";
			$_->remove_edge($n,$rev_net->get_data);
			unshift @{$_->{parents}},$n;	
			unshift @{$n->{edges}},$_;
			$_->estimate_jptb($rev_net->get_data);
		}
	}
	#if(defined($from) && defined($to)){
	#	$from->remove_edge($to,\@data);
	#}
	print "\n","-"x33,"\n";
	return ($score,$from,$to);
}


sub greedy_hill_climbing{
	print "[GHC] Greedy_hill_climbing!\n\n";
	my ($net,$method)=(shift,shift);
	my ($score_max,$score,$score_add,$score_rem,$score_rev);
	my ($from_add,$from_rem,$from_rev,$to_add,$to_rem,$to_rev);
	if($method == BIC){
		$score=$net->bic;
		$method=\&bic;
		print "got method!\n";
	}elsif($method == AIC){
		$score=$net->aic;
		$method=\&aic;
	}else{
		die 'Method wasn\'t recognised!';
	}
	while(1){
		#print "[ghc]"
		#my @nodes=$net->get_nodes;
		$score_max=$score;
		print "[ghc] Evaluating actions...\n";
		#Get graphs which max add,rem and rev	
		($score_add,$from_add,$to_add)=$net->check_edge_add($score,$method);
		($score_rem,$from_rem,$to_rem)=$net->check_edge_remove($score,$method);			
		($score_rev,$from_rev,$to_rev)=$net->check_edge_reverse($score,$method);
		

		print "[ghc] Actual Score: ",$score," Actual Max: ",$score_max," Actual Add: ",$score_add," Actual Rem: ",$score_rem," Actual Rev: ",$score_rev,"\n";
		
		#Compare and set
		if(defined($from_add) && defined($to_add) && $score_add> $score && $score_add > $score_rem && $score_add>$score_rev){
			$from_add->add_edge($to_add,$net->get_data);
			$score=$score_add;
		}elsif(defined($from_rem) && defined($to_rem) && $score_rem> $score && $score_rem > $score_add && $score_rem>$score_rev){
			$from_rem->remove_edge($to_rem,$net->get_data);
			$score=$score_rem;
		}elsif(defined($from_rev) && defined($to_rev) && $score_rev> $score && $score_rev > $score_add && $score_rev>$score_rem){
			$from_rev->reverse_edge($to_rev,$net->get_data);
			$score=$score_rev;
		}
			
		#$score_max=!defined($score_max)?$score:$score_max;
		#Exit Condition

		last if($score==$score_max);
		$score_max=$score;
	}
	return $net;
}


sub ll{ #for mle modify sum, put likelihood to 1 and remove log
	my $net=shift;
	my $log_likelihood=0;
	my %cond;
	for my $n (@{$net->get_nodes}){
		#print "[LL] Calculating for N[",$n->get_id,"] having p_states=",$n->num_parents_states(\@data)-1,"\n";
		#next if($n->num_parents_states(\@data)-1==0);
		for my $j (0..$n->num_parents_states($net->get_data)){
			for my $k (0..$n->num_states($net->get_data)){
				my $ptable=$n->get_ptable;
				my @parents=$n->get_parents;			
				for(@{$n->get_parents}){
					my $jptb=$ptable->get_jptb;
					$cond{$_->get_id}=$$jptb[$_->get_id+1][$j];				
				}
				$cond{$n->get_id}=$n->get_k_data($k,$net->get_data);
				my $Nijk=Node::get_num_cond($net->get_data,\%cond);	
				delete $cond{$n->get_id};
				my $Nij=Node::get_num_cond($net->get_data,\%cond);
				
				$log_likelihood+= $Nijk*log($Nijk/$Nij) unless($Nijk==0);
				foreach my $key (keys(%cond)){				
					delete $cond{$key};
				}
			}		
		}			
	}
	#print "[LL] log-likelihood calculated!\n";
	return $log_likelihood;
}
sub plot_graph{


	my ($net,$prog,$graph_f,$edge_f)=(shift,shift,shift,shift);
	my @nodes=@{$net->get_nodes};
	open(my $g_file,">",$graph_f);
	open(my $e_file,">",$edge_f);

	for my $n (@nodes){
		
		print $g_file cos($n->get_id+2*scalar @nodes/2)," ",sin($n->get_id+scalar @nodes/2)," ",$n->get_id," ",$n->get_id,"=",$n->get_name,"\n";
		#print $e_file $_->get_id ," ",$_->get_id,"\n";
		for(@{$n->get_edges}){
			print $e_file cos($n->get_id+2*scalar @nodes/2)," ",sin($n->get_id+scalar @nodes/2)," ",cos($_->get_id+2*scalar @nodes/2)," ",sin($_->get_id+scalar @nodes/2),"\n";
		}
	}
	open(my $pipe, '|-', "gnuplot", "-p");
	print($pipe $prog);
	close($pipe);

}
sub bic{
	my $net=shift;
	my $num_data=scalar @{$net->get_data};	
	my $B=0;
	$B+=($_->num_states($net->get_data)-1)*$_->num_parents_states($net->get_data) for(@{$net->get_nodes});
	return  $net->ll - (log($num_data)*$B)/2  ;
}

sub aic{
	my $net=shift;
	my $num_data=scalar @{$net->get_data};
	my $B=0;
	$B+=($_->num_states($net->get_data)-1)*$_->num_parents_states($net->get_data) for(@{$net->get_nodes});
	return $net->ll - $B;
}

sub compare_graph{
	my($net1,$net2,$method)=(shift,shift,shift);
	if($method==AIC){
		return $net1->aic > $net2->aic?$net1:$net2;
	}elsif($method==BIC){
		return $net1->bic > $net2->bic?$net1:$net2;
	}else{
		die 'Method wasn\'t recognised!';
	}
}

1;

