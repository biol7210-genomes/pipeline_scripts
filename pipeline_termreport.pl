#!/usr/bin/perl
# Aroon Chande
# SPAdes assembly pipeling
# Input is directory containing trimmed fq and outdir
# Takes gunzip'ed or uncompressed fastq files
# ./spades.pl -in fqdir -o outdir
use strict;
use Getopt::Long;
use File::Basename;
use Pod::Usage;
use Term::Report;
my $prog = basename($0);
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base,$out,$assemblyStatus,$currentStatus,$r1,$r2,$R,$refDir,@steps);
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir, 'R=s' => \$refDir, 'steps=s{1,}' => \@steps);
die print_usage() unless ((defined $outDir) && (defined $inDir));
# Remove generalization and make assumptions about naming scheme
my $stepMult = scalar @steps;
$stepMult++ if (defined grep(/abyss/i, @steps));
my @infiles = glob ( "$inDir/*R1_001_val_1.fq.gz" );
my $max = @infiles;
my $amax = $max * $stepMult;
# Initialize pipeline and submodule progress bars
initialize_bar();
$assemblyStatus->start;
$currentStatus -> start;
update_bar("SPAdes progress:","1");
#SPAdes
foreach (@infiles){
	get_files($_);
	$currentStatus->subText("Running SPAdes on $out");
#	system(`mkdir -p $outDir/spades/$out`);
#	system(`spades.py -h -1 $r1 -2 $r2 -o $outDir/spades/$out -k 99,115,127 --careful 2>$outDir/$out/spades.log`);
	sleep 1;
	$assemblyStatus->update();
	$currentStatus->update();
}
# Velvet
update_bar("Velvet progress:","1");
foreach (@infiles){
	get_files($_);
	$currentStatus -> label("Velvet progress: ");
#	system(`mkdir -p $outDir/velvet/`);
#	system(`VelvetOptimiser.pl -d $outDir/velvet/$out/ -s 97 -e 127 -x 10 -f '-fastq.gz -shortPaired -separate $r1 $r2' -t 2 --optFuncKmer 'n50'`);
	$currentStatus->subText("Running Velvet on $out");
	sleep 1;
	$assemblyStatus->update();
	$currentStatus->update();	
}
# ABySS
update_bar("ABySS progress:","2");
foreach (@infiles){
	for my $kmer ("97","115"){
        get_files($_);
    	$currentStatus->subText("Running ABySS on $out with k of $kmer");
#		system(`mkdir -p $outDir/abyss/k$kmer`);
#		system("abyss-pe -C $outDir/abyss/k$kmer k=$kmer name=$out in="$r1 $r2" j=4");
       	sleep 1;
		$currentStatus->update();
       	$assemblyStatus->update();
	}
}

exit 0;

#######
sub initialize_bar(){
	my $currentReport = Term::Report->new(
   		# startRow > Make submodule progress bar start below pipeline bar
   		startRow => 4,
   		numFormat => 1,
   		statusBar => [
			scale => 50,
			label => "SPAdes progress:",
			# Hope that any given step completed in linear time compared to others from same assembler
			showTime => 1,
			startRow => 4,
			subText => 'Running...',
			subTextAlign => 'center'
   		],
	);
	my $assemblyReport = Term::Report->new(
		startRow => 1,
		numFormat => 1,
   		statusBar => [
   			scale => 100,
    		startRow => 1,
    		label => 'Pipeline progress: ',
    		subText => 'Get some coffee',
    		subTextAlign => 'center',
    		# Need to add report generation functions
   			],
	);
	$assemblyStatus = $assemblyReport->{statusBar};
	$assemblyStatus->setItems($amax);
	$currentStatus = $currentReport->{statusBar};
	$currentStatus->setItems($max);
	$currentStatus->label("Starting pipeline:");
}
sub update_bar(){
	my ($label,$multiplier) = @_;
	my $realmax = $max * $multiplier;
	$currentStatus->reset({
    	start=>0,
        setItems => $realmax,
		label => $label,
	});
}
sub get_files(){
	$base = shift;
	$base  =~ s/\_R1_001_val_1\.fq\.gz//g;
	($out) = $base =~ m/(M\d*)/;
	$r1 = join('_',$base,"R1_001_val_1.fq.gz");
	$r2 = join('_',$base,"R2_001_val_2.fq.gz");
}

sub run_quast(){
		
}	

