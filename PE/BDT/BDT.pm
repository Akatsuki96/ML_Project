package BDT;

#!/usr/bin/perl
use strict;
use warnings;
#use bignum lib => "GMP";
#use bignum;
use lib "./Point/";
use Point;
use Math::Random::OO::Normal;
use Math::Gauss ':all';
use Math::LongDouble qw(:all);
use Math::Trig;

sub draw_gaussians{
	my ($m0,$m1,$s0,$s1)=(shift,shift,shift,shift);
	my $prog=<<'__EOS__';
set title "Class-Conditional Probability Denisity"
set key outside
set xrange [-10:15]
set yrange [] writeback
plot "gaussians.dat" using 1:2 smooth bezier title 'p(x|w0)',\
	 "gaussians.dat" using 3:4 smooth bezier title 'p(x|w1)'
__EOS__
	my ($ccdp_w0,$ccdp_w1);
	open (my $fout,">","gaussians.dat") or die "Cannot open gaussians.dat";
	print "GAUSSIANS $m0 $m1 $s0 $s1 \n";	
	for(my $i=-15;$i-25<0;$i+=1){
		$ccdp_w0=pdf($i,$m0,$s0);
		$ccdp_w1=pdf($i,$m1,$s1);
		print $fout "$i $ccdp_w0 $i $ccdp_w1\n";
	}
	close $fout;
	plot($prog);
}

sub prior_rule{
	my ($p0,$p1)=(shift,shift);
	return ($p0>$p1)?-1:1;
};

sub posterior_rule{
	my $x=shift;
	my ($p0,$p1)=(shift,shift);
	my ($s0,$s1)=(shift,shift);
	my ($m0,$m1)=(shift,shift);
	my $ccdp_w0=pdf($x,$m0,$s0);
	my $ccdp_w1=pdf($x,$m1,$s1);
	my $den =$ccdp_w0*$p0+$ccdp_w1*$p1;
	my ($post0,$post1)=(($ccdp_w0*$p0)/$den,($ccdp_w1*$p1)/$den);
	if($p0==$p1){ #MAXIMUM LIKELIHOOD RULE
		return ($ccdp_w0>$ccdp_w1?-1:1,$ccdp_w0,$ccdp_w1,$ccdp_w0,$ccdp_w1);
		#return ($ccdp_w0>$ccdp_w1?-1:1,$post0,$post1);
	}	

	return ($p0>$p1?-1:1,$p0,$p1,$post0,$post1) unless($ccdp_w0!=$ccdp_w1);
	return ($post0 > $post1 ?-1:1,$ccdp_w0,$ccdp_w1,$post0,$post1);
};

sub apply_only_prior{
	my $ref_points=shift or die "You have to pass the point array";
	my ($p0,$p1)=(shift,shift) or die "You have to pass the priors: P(w0),P(w1)";
	my $fout=shift or die "You have to pass the file descriptor for the output";
	my @points=@{$ref_points};	
	my $num_error=0;
	for(my $i=0;$i<=$#points; $i++){
		my ($x,$y,$class)=($points[$i]->getX,$points[$i]->getY,$points[$i]->getLabel);
		my $class_choosen= prior_rule($p0,$p1);
		$num_error++ unless($class == $class_choosen);
		print $fout "$x $y $class_choosen\n";
	}
	return $num_error;
};

sub apply_posterior_rule{
	my $ref_points=shift;
	my ($p0,$p1,$m0,$m1,$s0,$s1)=(shift,shift,shift,shift,shift,shift) or die "You have to pass: point array, P(w0), P(w1), mean0, mean1, s0, s1, fout, fout_posterior";
	my ($fout,$fout_post) = (shift,shift);
	my @points=@{$ref_points};	
	my $num_error=0;
	my ($post0,$post1);

	for(my $i=0;$i<=$#points; $i++){
		my ($x,$y,$class)=($points[$i]->getX,$points[$i]->getY,$points[$i]->getLabel);
		my @ris=posterior_rule($x,$p0,$p1,$s0,$s1,$m0,$m1);		
		my $class_choosen=shift(@ris);
		print $fout "$x $y $class_choosen\n";
		$num_error++ unless($class == $class_choosen);
		($p0,$p1)=(shift(@ris),shift(@ris));
		($post0,$post1)=(shift(@ris),shift(@ris));
		print $fout_post $post0," ",$post1,"\n";
		
	}
	
	print "Posterior: P(w0|x)=", $post0," \t P(w1|x)=", $post1,"\n";
	return $num_error;
};

sub shuffle_elements{
	my $arr=shift;
	my @ris;
	print "DATA SIZE: ",scalar @{$arr},"\n";
	for(0..scalar@{$arr}-1){
		my $num=int(rand(scalar@{$arr}));
		print "NUM: $num ACT: ",scalar @{$arr}," ELEM: ",$$arr[$num],"\n";
		push @ris,$$arr[$num];
		splice @{$arr},$num,1;
	}
	print "RIS SIZE: ",scalar @ris,"\n";
	return @ris;

}
#Generate the dataset
sub generate_points{
	my ($num_points,$thr,$m0,$m1,$s0,$s1) = (int shift, int shift,shift,shift,shift,shift) or die "You have to pass: num points, threshold, mean0, mean1,s0,s1";
	my ($gen0,$gen1) = (Math::Random::OO::Normal->new($m0,$s0), Math::Random::OO::Normal->new($m1,$s1));
	my @points;	
	my $generated;
	for(my $i=0; $i<$num_points; $i+=1){	
		if($i-$thr<0){
			$generated=$gen0->next();
		}
		else{
			$generated=$gen1->next();
		}
		push @points,Point->new(
			X => $generated,
			Y=>rand(1),
			Label=>(($i-$thr<0) ? -1 : 1)
		);
	}
	#return shuffle_elements(\@points); #decomment it if you want to shuffle points
	return @points;
}


sub plot{
	my $prog=shift or die "gnuplot instructions required!";
	open(my $pipe, '|-', "gnuplot", "-p");
	print($pipe $prog);
	close($pipe);
}


1;
