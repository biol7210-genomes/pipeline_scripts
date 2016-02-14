#!/usr/bin/perl
# Aroon Chande
# SPAdes assembly pipeling
# Input is directory containing trimmed fq and outdir
# Takes gunzip'ed or uncompressed fastq files
# ./spades.pl -in fqdir -o outdir
use strict;
use Getopt::Long;
use File::Basename;
use File::Temp;
use Pod::Usage;
use Term::Report;
use Async;
my $prog = basename($0);
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base,$out,$assemblyStatus,$currentStatus,$r1,$r2,$R,$ref,@steps,$link,$quast);
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir, 'R=s' => \$ref, 'steps=s{1,}' => \@steps);
if (grep(/,/, @steps)){@steps = split(/,/,join(',',@steps));}
die print_usage() unless ((defined $outDir) && (defined $inDir));
# Multiplier for main progress bar
my $stepMult = scalar @steps;
$stepMult++ if (grep(/abyss/i, @steps));
# Remove generalization and make assumptions about naming scheme
my @infiles = glob ( "$inDir/*R1_001_val_1.fq.gz" );
my $max = @infiles;
my $amax = $max * $stepMult;
# Initialize pipeline and submodule progress bars
initialize_bar();
$assemblyStatus->start;
$currentStatus -> start;
system(`mkdir -p $outDir/contigs`);
#SPAdes
if (grep(/spades/i, @steps)){
	update_bar("SPAdes progress:","1");
	foreach (@infiles){
	get_files($_);
	$currentStatus->subText("Running SPAdes on $out");
	system(`mkdir -p $outDir/spades/$out`);
	system(`spades.py -1 $r1 -2 $r2 -o $outDir/spades/$out -k 99,113,127 --only-assembler &>$outDir/status.log`);
	$link = join(".","spades",$out,"fa");
	system(`cp $outDir/spades/$out/contigs.fasta $outDir/contigs/$link`);
	system(`rm -rf $outDir/spades/$out/corrected`);
	sleep 1;
	$assemblyStatus->update();
	$currentStatus->update();
}
	$quast =  Async->new( sub {system(`quast -R $ref --threads=2 $outDir/contigs/spades* -o $outDir/quast/spades >/dev/null`)} or die);
}
# Velvet

if (grep(/velvet/i, @steps)){
	update_bar("Velvet progress:","1");
	foreach (@infiles){
	get_files($_);
	$currentStatus->subText("Running Velvet on $out");
	system(`mkdir -p $outDir/velvet/`);
	system(`VelvetOptimiser.pl -d $outDir/velvet/$out/ -s 97 -e 127 -x 10 -f '-fastq.gz -shortPaired -separate $r1 $r2' -t 6 --optFuncKmer 'n50' &>$outDir/status.log`);
	$link = join(".","velvet",$out,"fa");
	system(`cp $outDir/velvet/$out/contigs.fa $outDir/contigs/$link`);
	system(`rm -rf $outDir/velvet/$out/Sequences`);
	sleep 1;
	$assemblyStatus->update();
	$currentStatus->update();	
}
	$quast =  Async->new( sub {system(`quast -R $ref --threads=2 $outDir/contigs/velvet* -o $outDir/quast/velvet >/dev/null`)} or die);
}
# ABySS
if (grep(/abyss/i, @steps)){
 	update_bar("ABySS progress:","2");
	foreach (@infiles){
		for my $kmer ("97","115"){
			get_files($_);
			$currentStatus->subText("Running ABySS on $out with k of $kmer");
			system(`mkdir -p $outDir/abyss/k$kmer`);
			system("abyss-pe -C $outDir/abyss/k$kmer k=$kmer name=$out in='$r1 $r2' j=6 &>$outDir/status.log ");
			$link = join(".","abyss",$out,"fa");
			my $contig = join("-",$out,"contigs.fa");
			system(`cp $outDir/abyss/k$kmer/$contig $outDir/contigs/$link`);
			sleep 1;
			$currentStatus->update();
			$assemblyStatus->update();
		}
	}
	$quast =  Async->new( sub {system(`quast -R $ref --threads=2 $outDir/contigs/abyss* -o $outDir/quast/abyss &>/dev/null`)} or die);
}
print "\n\n\n\n\nWaiting on QUAST\n\n";
while (1){
	if ($quast->ready){
		#combine reports
		my $report=temp_filename();
		open REPORT, ">$report" or die "Cannot open $report: $!";
		print REPORT "Assembly\n# contigs (>= 0 bp)\n# contigs (>= 1000 bp)\n# contigs (>= 5000 bp)\n# contigs (>= 10000 bp)\n# contigs (>= 25000 bp)\n# contigs (>= 50000 bp)\nTotal length (>= 0 bp)\nTotal length (>= 1000 bp)\nTotal length (>= 5000 bp)\nTotal length (>= 10000 bp)\nTotal length (>= 25000 bp)\nTotal length (>= 50000 bp)\n# contigs\nLargest contig\nTotal length\nReference length\nGC (%)\nReference GC (%)\nN50\nNG50\nN75\nNG75\nL50\nLG50\nL75\nLG75\n# misassemblies\n# misassembled contigs\nMisassembled contigs length\n# local misassemblies\n# unaligned contigs\nUnaligned length\nGenome fraction (%)\nDuplication ratio\n# Ns per 100 kbp\n# mismatches per 100 kbp\n# indels per 100 kbp\nLargest alignment\nNA50\nNGA50\nNA75\nNGA75\nLA50\nLGA50\nLA75\nLGA75";
		close REPORT;
		system(`paste $report $outDir/quast/*/report.tsv| cut -f 1,3,5,7 > $outDir/quast/final_report.tsv`);
		print "Assembly quality scores can be found at: $outDir/quast/final_report.tsv\n";
		exit 0;
	}
	sleep 1;
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

sub temp_filename{
	    my $file = File::Temp->new(
	        TEMPLATE => 'tempXXXXX',
	        DIR      => '/tmp/',
	    );
	}

sub print_usage{
    warn <<"EOF";

USAGE
  $prog -in <indir> -o <outdir> -R <reffile> --steps <steps,to,run>

DESCRIPTION
	Spades pipeline

OPTIONS
	-in	dir		Directory with fq.gz
	-o	dir		output folder
	-R	file	Reference genome file
	--steps	list	Comma separated list of steps to run
					Valid steps: abyss, velvet, spades
EXAMPLES
  $prog -in ./scratch/reads -o ./scratch/assemblies --steps velvet,abyss,spades -R ./reference/genomic.fna.gz
  $prog -h

EXIT STATUS
  0     Successful completion
  >0    An error occurred

EOF
}
