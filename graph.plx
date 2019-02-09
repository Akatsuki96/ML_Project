#!/usr/bin/perl
use strict;
use warnings;

use lib "./Point/";
use lib "./BDT/";
use Point;
use BDT;
use Math::Random::OO::Normal;
use Math::Trig;

my (@points,$num_points);
die "Usage: perl graph.plx <num_points> <mean1> <mean2> <stdev1> <stdev2> <prior>" if(scalar @ARGV<6);
$num_points=int shift or die "Insert number of points";
my ($m0,$m1,$s0,$s1)=(Math::LongDouble->new(shift),Math::LongDouble->new(shift),Math::LongDouble->new(shift),Math::LongDouble->new(shift)) or die "Insert means and standard deviations";


#PRIORS
my $p0=Math::LongDouble->new(shift);
my $p1=Math::LongDouble->new(1-$p0);
my $thr=$num_points*$p0;


print "-"x25,"PRIORS","-"x25,"\nP(w0)=$p0 \t P(w1)=$p1\n";
print "w0 = -1 \t w1 = 1\n";

@points=BDT::generate_points($num_points,$thr,$m0,$m1,$s0,$s1);

print "Classifing points...\n";
open (my $fout_ccdp,">","set_ccdp.dat") or die "Error: Cannot open set_ccdp.dat";
open (my $fout_prior,">","set_only_prior.dat") or die "Error: Cannot open set_only_prior.dat";
open (my $fout_real,">","set_real.dat") or die "Error: Cannot open set_real.dat";
open (my $fout_post,">","posteriors.dat") or die "Error: Cannot open posteriors.dat";
print $fout_post "$p0 $p1\n";
BDT::draw_gaussians($m0,$m1,$s0,$s1);
my ($prior_errors,$posterior_errors)=(BDT::apply_only_prior(\@points,$p0,$p1,$fout_prior),BDT::apply_posterior_rule(\@points,$p0,$p1,$m0,$m1,$s0,$s1,$fout_ccdp,$fout_post));

print "Errors on only priors: ",$prior_errors,"=> ",($prior_errors/$num_points)*100,"%\n";
print "Errors on posterior rule: ",$posterior_errors,"=> ",($posterior_errors/$num_points)*100,"%\n";


for(my $i=0;$i<$num_points; $i++){
	my ($x,$y,$label)=($points[$i]->getX,$points[$i]->getY,$points[$i]->getLabel);
	print $fout_real "$x $y $label\n";
}
close $fout_ccdp;
close $fout_real;
close $fout_prior;
close $fout_post;;


my $program = <<'__EOS__';
set palette model RGB defined(-1 'black', 1 'red')
set title "Posteriors Bayes Rule"
plot "set_ccdp.dat" with points palette notitle
__EOS__

my $prog1 = <<'__EOS__';
set palette model RGB defined(-1 'black', 1 'red')
set title "Prior Bayes Rule"
plot "set_only_prior.dat" with points palette notitle
__EOS__

my $prog2=<<'__EOS__';
set palette model RGB defined(-1 'black', 1 'red')
set title "Real"
plot "set_real.dat" with points palette notitle
__EOS__


my $prog3=<<'__EOS__';
set title "Posteriors"
set key outside
plot "posteriors.dat" using 1 smooth bezier title 'P(w0|x)',\
	 "posteriors.dat" using 2 smooth bezier title 'P(w1|x)'
__EOS__

BDT::plot($program);
BDT::plot($prog1);
BDT::plot($prog2);
BDT::plot($prog3);

