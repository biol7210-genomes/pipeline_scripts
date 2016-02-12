#!/usr/bin/perl -w
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
use Term::ProgressBar;
my $prog = basename($0);
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base,$out);
<<<<<<< HEAD
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir);
die print_usage() unless ((defined $outDir) && (defined $inDir));
my @infiles = glob ( "$inDir/*.fq.gz" );
=======
my $j=0;
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir);
die print_usage() unless ((defined $outDir) && (defined $inDir));
my @infiles = glob ( "$inDir/*.fq.gz" );
my $max =  @infiles/2;
my $spades_progress = Term::ProgressBar->new ({count => $max, name => 'SPAdes progress', term_width => '80', ETA   => 'linear',});
>>>>>>> refs/remotes/biol7210-genomes/aroon
for ($i = 0; $i < @infiles; $i += 2){
	$j++;
	$base = $infiles[$i];
	$base  =~ s/\_R1_001_val_1\.fq\.gz//g;
	($out) = $base =~ m/(M\d*)/;
	system(`mkdir -p $outDir/$out`);
	my $r1 = join('_',$base,"R1_001_val_1.fq.gz");
	my $r2 = join('_',$base,"R2_001_val_2.fq.gz");
<<<<<<< HEAD
	print STDERR "Running SPAdes with $r1 and $r2\n";
	system(`spades.py -1 $r1 -2 $r2 -o $outDir/$out -k 21,33,55,77,99,127 --careful 2>$outDir/$out/spades.log`);
=======
	system("spades.py -1 $r1 -2 $r2 -o $outDir/$out -k 97,115,127 --careful 2>$outDir/$out/spades.log");
        $spades_progress->update($j);
	sleep 1;
>>>>>>> refs/remotes/biol7210-genomes/aroon
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
  -out  dir		output files

EXAMPLES
  $prog -in ../reads/ ./spades_out
  $prog -h

EXIT STATUS
  0     Successful completion
  >0    An error occurred

EOF
}

