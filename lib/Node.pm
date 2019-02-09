package Node;
#!/usr/bin/perl
use warnings;
use strict;
use overload ('==' => 'node_compare');
use PTable;

# Class: Node
# Instance Variables: id int, name string, edges pointer to list of node, parents pointer list of node, pTable PTable
# Public Methods: get_id, get_name, get_edges, get_parents, get_ptable, exists_edge


sub new{
	my ($class,$self)=(shift,{@_});
	bless($self,$class);
	return $self;
}

#return int
sub get_id{
	return shift->{id};
}

#return string
sub get_name{
	return shift->{name};
}


#return array pointer
sub get_edges{
	return shift->{edges};
}

#return array pointer
sub get_parents{
	return shift->{parents};
}

#return PTable
sub get_ptable{
	return shift->{ptable};
}


sub contains{
	my ($elem,$list)=(shift,shift);
	chomp($elem);
	for(@{$list}){
		chomp($_);
		return 1 if($_ eq $elem);
	}
	return 0;
}
sub get_domain{
	my ($node,$data)=(shift,shift);
	my @domain;	
	my $data_size=0;
	for my $line (@{$data}){
		push @domain,${$line}[$node->get_id] if(!contains($$line[$node->get_id],\@domain));
		$data_size++;	
	}
	return @domain;
}

sub get_domains{
	my ($node,$data)=(shift,shift);
	my @domains=undef; #domains[id] = @domain of node id
	my @nds=@{$node->get_parents};
	push @nds,$node;
	my $ind=0;
	for(@nds){
		push @{$domains[$ind]},$_->get_domain($data) ; #domains[id] = [@domain,data_size]
		$ind++;	
	}
	return @domains;
}

sub get_num_cond{
	my ($data,$condRef)=(shift,shift);
	my %cond=%{$condRef};
	my $num_tuple=0;
	my $cnd=1;	
	for(@{$data}){
		while(my ($k,$v)=each(%cond)){
			next if(!defined($v));
			#print "K: $k V: $v\n";
			chomp($$_[$k]);
			chomp($v);
			$cnd=$cnd && ($$_[$k] eq $v);
		}
		$num_tuple++ if($cnd);
		$cnd=1;
	}
	return $num_tuple;
}

sub num_data{
	my ($node,$data)=(shift,shift);	
	return scalar @{$data};

}

sub estimate_gaussians{
	my ($node,$data)=(shift,shift);
	my ($gauss_prior_mean,$gauss_prior_var)=($node->{gauss_prior_mean},$node->{gauss_prior_var});
	my %str_val;
	my $cnt=0;
	my $dom=0;
	if(!defined($gauss_prior_mean)){

		for(my $i=0;$i<scalar @{$data};$i++){
			eval{
				$dom+=$$data[$i][$node->get_id];
			}or do{
				if(!defined($str_val{$$data[$i][$node->get_id]})){
					$str_val{$$data[$i][$node->get_id]}=$cnt;
					$cnt++;
				}
				$dom+=$str_val{$$data[$i][$node->get_id]};
			}
		}		
		$gauss_prior_mean= $dom/ scalar @{$data};
		my $dom_var;
		#$cnt=0;
		for(my $i=0;$i<scalar @{$data};$i++){
			eval{
				$dom_var+=($$data[$i][$node->get_id] - $gauss_prior_mean)**2;
			}or do{
				$dom_var+=($str_val{$$data[$i][$node->get_id]}-$gauss_prior_mean)**2;
			}
		}
		$gauss_prior_var=$dom_var / scalar @{$data};
		print "PRIOR MEAN: ",$gauss_prior_mean," PRIOR VAR: ",$gauss_prior_var,"\n";
	}

}

sub use_bayesian_estimation{
	return shift->{bayes_est};
}

sub estimate_jptb{
	my ($node,$data)=(shift,shift);
	my @parents=$node->get_parents;
	my @dataArray=@{$data};
	my @nodes=@{$node->get_parents};
	push @nodes,$node;
	my @domains=get_domains($node,$data);
	my @ind=();
	push @ind,0 for(0..$#domains);
	my $ptable=PTable->new(nodes => \@nodes, jptb=>undef);
	my (%c_map,$next);	
	while(1){
		$c_map{$nodes[$_]->get_id}=$domains[$_][$ind[$_]] for (0..scalar(@domains)-1);
		my %evidence=%c_map;
		delete $evidence{$node->get_id};
		my $ev=get_num_cond($data,\%c_map);
		my $dev=get_num_cond($data,\%evidence);
		if($ev == 0 && !defined($node->use_bayesian_estimation)){ #ADD 1 SMOOTHING
			$ev++;
			for(0..scalar @nodes -1){
				$dev++ for(0..scalar @{$domains[$_]}-1);
			}		
		}		
		$c_map{'P'}=$ev/$dev;#likelihood
		#$node->estimate_gaussians($data);
		#print "NODEID: ",$node->get_id," ",$c_map{($node->get_id)},"\n";
		$ptable->add_row(\%c_map);
		$next=scalar(@domains)-1;
		$next-=1 while($next>=0 && ($ind[$next] + 1 >=scalar(@{$domains[$next]})));
		last if($next<0);
		$ind[$next]++;
		$ind[$_]=0 for($next+1..scalar(@domains)-1);
		delete $c_map{'P'};
	}
	$node->{ptable}=$ptable;
	
}

sub num_states{
	my ($node,$data)=(shift,shift);
	return scalar($node->get_domain($data));
}

sub set_gaussian_prior{
	my ($node,$data)=(shift,shift);
	$node->{gaussian_prior}=1;
}

sub num_parents_states{
	my ($node,$data)=(shift,shift);
	my $states=1;
	return 1 if(!@{$node->get_parents});
	$states*=$_->num_states($data) for(@{$node->get_parents});
	return $states;
}

sub get_k_data{
	my ($node,$k,$data)=(shift,shift,shift);
	my @domain=$node->get_domain($data);
	return $domain[$k];
}

#set pTable
sub add_data{
	my ($node,$data)=(shift,shift);
	$node->get_ptable->add_row($_) for(@{$data});
}

# Overload for ==
sub node_compare{
	my ($n1,$n2)=(shift,shift);
	return (!defined($n1) && !defined($n2)) || $n1->get_id == $n2->get_id;
}


#param $node
#return true if the node is contained in the list


sub is_in{
	my ($element,$list)=(shift,shift);
	for(@{$list}){
		#print "Elem ", $element->get_id, "ElemInList ", $_->get_id,"\n";
		next if(!defined($_) || !defined($element));
		return 1 if($element == $_);
	}
	return 0;
}

#param node pointer to node
#return true if $parent is a parent of $from node
sub exists_parent{
	my ($from,$parent)=(shift,shift);
	return is_in($parent,$from->get_parents);
}

#param node pointer to node
#return true if exists an edge from this node to $node
sub exists_edge{	
	my ($from,$to)=(shift,shift);
	return is_in($to,$from->get_edges);	
}

sub add_edge{
	my ($from,$to,$dataref)=(shift,shift,shift);
	return 0 if( $from==$to || exists_edge($from,$to));
	push @{$to->{parents}},$from;	
	push @{$from->{edges}},$to;
	if(is_cycle($from,$to)){
		$from->remove_edge($to,$dataref);
		return 0;
	}

	$to->estimate_jptb($dataref);
	return 1;
}



sub remove_edge{
	my ($from,$to,$dataRef)=(shift,shift,shift);
	
	my ($edge_ind, $parents_ind)=(get_index($to,$from->get_edges),get_index($from,$to->get_parents));
	splice @{$from->{edges}},$edge_ind,1 unless($edge_ind == -1);
	splice @{$to->{parents}},$parents_ind,1 unless($parents_ind == -1);
	$to->estimate_jptb($dataRef);

}

sub reverse_edge{
	my ($from,$to,$dataRef)=(shift,shift,shift);
	#return 0 if($from==$to);	
	$from->remove_edge($to,$dataRef);
	$to->add_edge($from,$dataRef);
	if($to->is_cycle($from)){
		$to->remove_edge($from,$dataRef);
		$from->add_edge($to,$dataRef);
		return 0;	
	}
	return 1;
}

sub is_cycle{
	my ($from,$to)=(shift,shift);
	return 0 if(!@{$to->get_edges});
	return 1 if($from == $to || is_in($from,$to->get_edges));
	return is_cycle($from,$_) for(@{$to->get_edges});
	return 0;
	
}


sub get_index{
	my ($elem,$list)=(shift,shift);
	for(0..scalar(@{$list})){
		next if(!defined(${$list}[$_]));
		return $_ if($elem == ${$list}[$_]);
	}
	return -1;
}


1;
