package PTable;
#!/usr/bin/perl
use warnings;
use strict;
use Node;

# Class: PTable
# Instance Variables: nodes pointer to array of Node, jptb pointer to array of array of element (domain of nodes)
# Public Methods: add_row, get_jptb, get_nodes, get_values


sub new{
	my ($class,$self)=(shift,{@_});
	bless($self,$class);
	return $self;
}

sub get_jptb{
	return shift->{jptb};
}

sub get_nodes{
	return shift->{nodes};
}


#param $rowRef: pointer to hashmap
#param $prob: conditional probability
sub add_row{
	my ($table,$rowRef)=(shift,shift);
	my @nodes=$table->get_nodes;
	my @jptb=$table->get_jptb;
	while(my ($k,$v)=each(%{$rowRef})){
		($k eq 'P')? push @{$table->{jptb}[0]},$v:push @{$table->{jptb}[$k+1]},$v; #k+1 value
	}
}

#param $params: pointer to hashmap
sub get_values{
	my ($table,$params)=(shift,shift);
	my @jptb=$table->get_jptb;
	my @nodes=$table->get_nodes;	
	my @result;
	my $conditions=0;	
	for my $line (@jptb){
		#print "L: ",scalar "@{$line}\n";
		foreach my $n(@{$table->get_nodes}){
			my $len=scalar @{${$line}[$n->get_id+1]};
			while(my ($k,$v)=each(%{$params})){
				for(0..scalar @{${$line}[$k+1]}-1){
					$conditions=$conditions || ${$line}[$k][$_] eq $v ;
					
				}
			}	

		}
		push @result,$line if($conditions);
		$conditions=0;
	}

	return @result;
}

1;


