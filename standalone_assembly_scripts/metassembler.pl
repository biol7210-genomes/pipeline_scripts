#!/usr/bin/perl -w
# Aroon Chande
# Metassembler pipeline
use strict;
use Getopt::Long;
use File::Basename;
use File::Temp;
use Pod::Usage;
my $prog = basename($0);
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$contigs,$base,$out);
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir, 'contigs=s' => \$contigs);
die print_usage() unless ((defined $outDir) && (defined $inDir) && (defined $contigs));
my @infiles = glob ( "$inDir/*.fq.gz" );
my $j=0;
for ($i = 0; $i < @infiles; $i += 2){
	$j++;
	$base = $infiles[$i];
	$base  =~ s/\_R1_001_val_1\.fq\.gz//g;
	($out) = $base =~ m/(M\d*)/;
	my $confFile =join(".",$out,"config");
	system(`mkdir -p $outDir/$out`);
	open OUT, ">$outDir/$out/$confFile" or die;
	my $r1 = join('_',$base,"R1_001_val_1.fq.gz");
	my $r2 = join('_',$base,"R2_001_val_2.fq.gz");
	my $spades = join('.',"spades",$out,"fa");
	my $velvet = join('.',"velvet",$out,"fa");
	my $abyss = join('.',"abyss","115",$out,"fa");
	print OUT "[global]\nbowtie2_threads=12\nbowtie2_read1=$r1\nbowtie2_read2=$r2\nbowtie2_maxins=3000\nbowtie2_minins=1000\ngenomeLength=1825000\nmateAn_A=1300\nmateAn_B=2300\n[1]\nfasta=$contigs/$spades\nID=Spades\n[2]\nfasta=$contigs/$abyss\nID=Abyss\n[3]\nfasta=$contigs/$velvet\nID=Velvet\n";
	close OUT;
#	system("metassemble --conf $outDir/$out/$confFile --outd $outDir/$out");
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

