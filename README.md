# ML_Project
The project is composed by different perl program realized from scratch (so i'm sorry for the performance in terms of time).
## Set-up:
	1) Download the repository (git clone)
	2) go to the directory of the project (cd ML_Project/)
	3) execute there the programs using perl (i.e. perl graph.plx ...)

## Requirements:
	0) You need the perl interpreter
	1) You need to install gnuplot
	2) You have to download the following perl module (using cpan):
		-) cpan Math::Trigon
		-) cpan Math::Gauss
		-) cpan Test::More
		-) cpan Test::Exception
		-) cpan Math::Random::OO::Normal
		-) cpan Math::Random
		-) cpan bignum
		-) cpan diagnostics
## "Heart" dataset: 
Since it was produced on windows, it has some windows character (like '^M'). We have to erase them through the command: perl -p -e 's/\r$//' heart.csv heart.csv:
	
	1) Download heart.csv from https://www.kaggle.com/ronitf/heart-disease-uci
	2) perl -p -e 's/\r$//' PATH/heart.csv > heart.csv to remove windows characters

## Programs and Description:
1) graph.plx: Program which execute the Posterior Rule and the Prior Rule.
		Command: perl graph.plx <number of point> <mean class 1> <mean class 2> <standard dev 1> <standard dev 2> <percentage of point in class 1>
		Uses: Point/Point.pm class which define a point, BDT/BDT.pm module which implements methods for applying the posterior and prior rule (and other useful functions)
2) main.plx: Program which execute the structure learning algorithm. It doesn't require any parameters.
				 The algorithm realized is the Greedy Hill Climbing and (with heart dataset) it will take a lot of hours to be completed (and this can be justified  from the fact that there are a many relationship between the attributes).
3) naive_bayes_classifier.plx: It implements a naive bayes classifier for multi-class classification problem.
		Command: perl naive_bayes_classifier.plx <split_ratio> <index_of_class>
		Where: 
			-)<split_ratio> indicates how many lines you take for the train part (i.e. 0.3 => training part will be the 30% of the dataset)
		   	-)<index_of_class> index of the attribute used for classification (the presentation use 2) (Index starts from 0)

## Tests used in the presentation:
		perl graph.plx 500000 0 0.8 0.5 0.5 0.3
		perl naive_bayes_classifier.plx 0.7 2 #i've tested for different split ratio (0.3 0.4 0.1 0.7 0.9) and for different attributes (2 8 0 13)
		perl main.plx

## GNUPlot: 
programs may fail for gnuplot (it is bugged unfortunately), in case of failure consider to execute gnuplot from your terminal (in order to avoid to repeat the execution of the programs) using files created by the faulty execution.
	1) graph.plx: creates set_ccdp.dat for posterior rule, set_only_prior.dat for prior rule, set_real.dat for real data, posteriors.dat for posterior curves, gaussians.dat for gaussians
	2) main.plx: creates sample.dat for nodes, edge.dat for edges
	3) naive_bayes_classifier.plx: creates predictions.dat for comparing predictions with real values.
For the gnuplot code to execute you can look to the programs (each variable program=<<__EOS__ ... indicates the code execute to gnuplot) 
