#!/usr/bin/perl -w
# Aroon Chande
# Velvet assembly pipeling using Veletoptimiser.pl
# Input is directory containing trimmed fq.gz and outdir
use strict;
use Getopt::Long;
use File::Basename;
use File::Temp;
use Parallel::ForkManager;
use Pod::Usage;
my $prog = basename($0);
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base,$out);
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir);
die print_usage() unless ((defined $outDir) && (defined $inDir));
my @infiles = glob ( "$inDir/*.fq.gz" );
for ($i = 0; $i < @infiles; $i += 2){
	$base = $infiles[$i];
	$base  =~ s/\_R1_001_val_1\.fq\.gz//g;
	($out) = $base =~ m/(M\d*)/;
	system(`mkdir -p $outDir/$out`);
	my $r1 = join('_',$base,"R1_001_val_1.fq.gz");
	my $r2 = join('_',$base,"R2_001_val_2.fq.gz");
	print STDERR "Running SPAdes with $r1 and $r2\n";
	system(`VelvetOptimiser.pl -d $outDir/$out/ -s 43 -e 127 -x 25 -f '-fastq.gz -shortPaired -separate $r1 $r2' -t 2 --optFuncKmer 'n50'`);
}

exit 0;
##################
sub print_usage{
    warn <<"EOF";

USAGE
  $prog -in <indir> -out <outdir>

DESCRIPTION
  Spades pipeline

OPTIONS
  -in	dir		Directory with FASTQ
  -out  dir		outpur files

EXAMPLES
  $prog -in ../reads/ ./spades_out
  $prog -h

EXIT STATUS
  0     Successful completion
  >0    An error occurred

EOF
}
