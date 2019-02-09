#!/usr/bin/perl

use Math::Trig;
use diagnostics;
#use bignum;

my @vars;

sub loadData{
	my $file=shift or die "File required";
	my @dataset;	
	open(my $f_hand,"<",$file);	
	my $count=0;
	push @vars,split(/,/,<$f_hand>);		
	while(my $line=<$f_hand>){
		my @arr=split(/,/,$line);
		push @{$dataset[$count]},@arr; 
		$count++;
	}
	return @dataset;
}


#splitting in test and train set

sub splitDataset{
	
	my $dataset=shift;
	my $split=shift;
	my $train_length=int(scalar @{$dataset}*$split);
	my (@train_set,@test_set);
	@test_set=@{$dataset};
	my $count=0;
	while(scalar(@train_set) < $train_length){
		my $ind=int(rand(scalar @test_set));

		push @{$train_set[$count]},@{$test_set[$ind]};
		splice @test_set,$ind,1;
		$count++;
	}
	return (\@train_set,\@test_set);
}
sub contains{
	my $list=shift;
	my $class=shift;
	for(@{$list}){
		return 1 if($class==$_);
	}
	return 0;

}
sub separateByClass{
	my $dataset=shift;
	my $classInd=shift;
	my %separated;
	my @vect;
	my $count=0;
	my @data=@{$dataset};
	for(0..scalar(@data)-1){
		push @vect,@{$$dataset[$_]};
		chomp($vect[$classInd]);
		push @{$separated{$vect[$classInd]}},[@vect];
		@vect=();
		$count++;
		
	}
	return %separated;
}

sub mean{
	my $values=shift;
	my $sum=0;
	$sum+=$_ for(@{$values});
	return $sum/scalar(@{$values});
} 

sub stdev{
	my $values=shift;
	my $mean=mean($values);
	my $num=0;
	my @v=@{$values};
	$num+=($_ - $mean)**2 for(@v);
	return sqrt($num/(scalar @v-1));
}

sub zip{
	my $dataset=shift;
	my $index=shift;
	my @zipped=();
	my @ds=@{$dataset};
	push @zipped,${$_}[$index] for(@{$dataset});
	return @zipped;
}


sub summarize{
	my $dataset=shift;
	my $toClassify=shift;
	my @summary;
	my @data=@{$dataset};
	for(0..scalar @{$$dataset[0]}-1){
		my @zipped=zip($dataset,$_);
		my @pair=[mean(\@zipped),stdev(\@zipped)];
		push @summary,@pair;
	}
	splice @summary,$toClassify,1;
	return \@summary;
}

sub summaryByClass{
	my $dataset=shift;
	my $ind_class=shift;
	my %summaries;
	my %separated=separateByClass($dataset,$ind_class);
	while(my ($k,$v)=each(%separated)){
		$summaries{$k}=summarize(\@{$v},$ind_class);
	}
	return %summaries;
}

sub calculateProb{
	my ($elem,$mean,$stdev)=(shift,shift,shift);
	$stdev= 0.5 if($stdev==0);
	my $exp=exp(-(($elem-$mean)**2/(2*($stdev**2))));
	return (1/(sqrt(2*pi)*$stdev))*$exp;
}


sub calculateClassProb{
	my $summaries=shift;
	my $inVect=shift;
	my $classInd=shift;
	my %probs;
	while(my ($k,$v)=each(%{$summaries})){
		$probs{$k}=1;
		for(0..scalar@{$v}-1){
			my ($mean,$stdev)=($$v[$_][0],$$v[$_][1]);
			my @x=@{$inVect};
			my $prob=calculateProb($x[$_],$mean,$stdev);
			$probs{$k}*=$prob;
		}
	}
	return %probs;
	
}

sub predict{
	my $sums=shift;
	my $inVect=shift;
	my $cInd=shift;
	#print "[bnc] Caclulating Class Probabilities\n";
	my %probs=calculateClassProb($sums,$inVect,$cInd);	
	my ($bestLabel,$bestProb)=(undef,-1);
	while(my ($k,$v)=each(%probs)){
		
		if(!defined($bestLabel) || $bestProb < $v){
			$bestProb=$v;
			$bestLabel=$k;
		}
	}
	return $bestLabel;
}

sub getPredictions{
	my $sums=shift;
	my $set=shift;
	my $cInd=shift;
	my @preds;
	for(0..scalar@{$set}-1){
		my $ris=predict($sums,$$set[$_],$cInd);
		push @preds,$ris;
	}
	return @preds;

}

sub getAccuracy{
	my $set=shift;
	my $preds=shift;
	my $indClass=shift;
	my $correct=0;
	my $file="predictions.dat";
	open(my $f_key,">",$file);
	for(0..scalar@{$set}-1){
		chomp($$set[$_][$indClass]);
		chomp($$preds[$_]);
		#print "[nbc] Real Class: ",$$set[$_][$indClass]," Prediction: ",$$preds[$_],"\n";
		$correct++ if($$set[$_][$indClass]==$$preds[$_]);
		print $f_key $_," ",$$preds[$_]," ",$_," ",$$set[$_][$indClass],"\n";
	}
	close($f_key);
	return ($correct/scalar(@{$set}))*100;

}

die "Usage:perl naive_bayes_classifier.plx <split_ratio> <index_of_classes>" if(scalar @ARGV < 2);

my $split=shift;
my $classInd=shift;
my @dataset=loadData('heart.csv');
die "Class index greater then row size!" if($classInd > scalar @{$dataset[0]}-1);
print "[nbc] Data Loaded! Size: ",scalar @dataset," Rows\n";
my ($trainSet, $testSet) = splitDataset(\@dataset, $split);
print "[nbc] Data Splitted in Train (",scalar @{$trainSet}," rows) and Test (",scalar  @{$testSet}," rows) sets!\n";
my %summ=summaryByClass($trainSet,$classInd);
print "[nbc] Summaries Produced! \n";
print "-"x33,"\n";
while(my ($k,$v)=each(%summ)){
	#chomp($k);
	print "\t[nbc] K: ", $k ," Lenght: ",scalar @{$v},"\n";
}
print "-"x33,"\n";
my @predictions = getPredictions(\%summ, $testSet,$classInd);
print "[nbc] Predictions produced! Num Predictions: ",scalar @predictions,"\n";
my $accuracy = getAccuracy($testSet, \@predictions,$classInd);
print "[nbc] Accuracy: Test Set Size: ",scalar @{$testSet}," Predictions: ",scalar @predictions ,"  => accuracy (%): $accuracy\n";

my $prog =  <<'__EOS__';
set key outside
set terminal wxt size 860,720

set title "Naive Bayes: Posteriors"
plot "predictions.dat" using 1:2 with point pt 7 lt rgb "black" title 'prediction',\
	"predictions.dat" using 3:4 with point pt 1 lt rgb "blue" title 'real'
__EOS__
open($p1,"|-","gnuplot", "-p");
print($p1 $prog);
close($p1);





