#!/usr/bin/perl -w
# Aroon Chande
# SPAdes assembly pipeling
# Input is directory containing trimmed fq and outdir
# Takes gunzip'ed or uncompressed fastq files
# ./aligngraph.pl -in <fqdir> -o <outdir> -index <refdir> -contigs <contigdir>
use strict;
use Getopt::Long;
use Parallel::ForkManager;
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base,$out,$indexDir,$contigs);
GetOptions ('index=s' =>\$indexDir, 'o=s' => \$outDir, 'in=s' => \$inDir, 'contigs=s' => \$contigs);
die print_usage() unless ((defined $outDir) && (defined $inDir) && (defined $indexDir) && (defined $contigs));
my @infiles = glob ( "$inDir/*.fq.gz" );
my @index = glob ("$indexDir/*gz");
#my @contigFiles= glob ("$contigs/*"); 
##Preprocessing
system(`mkdir -p $outDir/ref $outDir/fastq`);
#gunzip references
foreach my $ref (@index){
	system(`cp $ref $outDir/ref/`);
	$ref =~ s/^\.*(\/.*\/)*//g;
	system(`gunzip $outDir/ref/$ref`);
}
my $manager = Parallel::ForkManager -> new ( 2 );
foreach my $fq (@infiles){
	$manager->start and next;
	my $fqbase =~ s/^\.*(\/.*\/)*//g;
	$fqbase =~ s/\.fq/\.fa/g;
	system(`fastq_to_fasta -i <(gzip -dc $fq) -o $outDir/fastq/$fqbase`);
}
$manager->wait_all_children;
my @indexes = glob ( "$outDir/ref/*.fna" );
my @fa = glob ( "$outDir/fastq/*.fa");
for ($i = 0; $i < @fa; $i += 2){
		$base = $fa[$i];
		$base  =~ s/\_R1_001_val_1\.fa//g;
		($out) = $base =~ m/(M\d*)/;
		system(`mkdir -p $outDir/$out`);
		my $r1 = join('_',$base,"R1_001_val_1.fa");
		my $r2 = join('_',$base,"R2_001_val_2.fa");
		for ($i = 0; $i < @indexes; $i++){
			my $indexFile = $indexes[$i];
			print STDERR "Running Abyss on $out with $indexFile\n";
			#$indexFile =~ s/\.sma//g;
			my $extended = join("_",$out,$indexFile,"extendedContigs.fa");
			my $remaining = join("_",$out,$indexFile,"remainingContigs.fa");
			my $contigFile = join(".",$out,"fa");
			system(`AlignGraph --read1  $outDir/fastq/$r1 --read2  $outDir/fastq/$r2 --contig $contigs/$contigFile --genome $indexFile --distanceLow 20 --distanceHigh 2000 --extendedContig  --remainingContig  --iterativeMap `);
			}
}



exit 0;
###############
sub print_usage{
    warn <<"EOF";

USAGE
  aligngraph.pl -in <fqdir> -o <outdir> -index <refdir> -contigs <contigdir> 

DESCRIPTION
  SMALT sutff

OPTIONS
  -contigs dir  Directory with contigs.fa
  -in	dir		Directory with FASTQ
  -index dir	Directory with reference files
  -out  dir		output files
  

EXAMPLES
  ./aligngraph.pl -in ../scratch/reads -o ./indexes -index ./reference -contigs ./contigs
  ./aligngraph.pl -h

EXIT STATUS
  0     Successful completion
  >0    An error occurred

EOF
}
