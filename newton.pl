#!C:/strawberry/perl/bin/perl.exe

use strict;

my $degre = 3;
my @coeff = (1_947_000, -434_704, -434_795, -434_845, -434_850, -434_805);

my $start_value = 1.0;
my $result;
my $cpt = 0;

while(!&near_zero($result = &f_gen(\@coeff, $start_value)) && $cpt <= 20){
	print "value : ", $start_value, " result : ", $result, "\n";
	my $deriv_result = &f1_gen(\@coeff, $start_value);
	$start_value -= ($result / $deriv_result);
	$cpt++;
}
print "value finale : ", $start_value, " result : ", $result, "\n";

sub f{
	my $value = shift;
	return $value ** 3 - 2 * $value - 5;
}

sub f_deriv{
	my $value = shift;
	return 3 * ($value ** 2) - 2;
}

sub near_zero{
	my $value = shift;
	return ($value >= -0.0005 && $value <= 0.0005);
}

sub f_gen{
	my ($coeff, $value) = @_;
	my $degre = @$coeff - 1;
	my $retVal = 0;
	my $cpt = 0;
	for(@$coeff){
		$retVal += $_ * ($value ** ($degre - $cpt++));
	}
	return $retVal;
}

sub f1_gen{
	my ($coeff, $value) = @_;
	my @coeffList = @$coeff;
	pop @coeffList;
	my $degre = @coeffList - 1;
	my $retVal = 0;
	my $cpt = 0;
	for(@coeffList){
		my $deg = $degre - $cpt++;
		$retVal += $_ * ($deg + 1) * ($value ** $deg);
	}
	return $retVal;
}