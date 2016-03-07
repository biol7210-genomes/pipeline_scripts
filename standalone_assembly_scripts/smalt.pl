#!/usr/bin/perl -w
# Aroon Chande
# SPAdes assembly pipeling
# Input is directory containing trimmed fq and outdir
# Takes gunzip'ed or uncompressed fastq files
# ./page.pl -in fqdir -o outdir -index refdir
use strict;
use Getopt::Long;
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base,$out,$indexDir);
GetOptions ('index=s' =>\$indexDir, 'o=s' => \$outDir, 'in=s' => \$inDir);
die print_usage() unless ((defined $outDir) && (defined $inDir) && (defined $indexDir));
my @infiles = glob ( "$inDir/*.fq.gz" );
my @index = glob ("$indexDir/*gz"); 
for ($i = 0; $i < @index; $i++){
	$base = $index[$i];
	$base =~ s/^\.*(\/.*\/)*//g;
	$base =~ s/\_genomic.fna.gz//g;
#	print "$base\n";
	system(`smalt index -k 13 $outDir/$base $index[$i]`);
}
my @indexes = glob ( "$outDir/*.sma" );
for ($i = 0; $i < @infiles; $i += 2){
		$base = $infiles[$i];
		$base  =~ s/\_R1_001_val_1\.fq\.gz//g;
		($out) = $base =~ m/(M\d*)/;
		system(`mkdir -p $outDir/$out`);
		my $r1 = join('_',$base,"R1_001_val_1.fq.gz");
		my $r2 = join('_',$base,"R2_001_val_2.fq.gz");
		print STDERR "Running smalt with $out\n";
		for ($i = 0; $i < @indexes; $i++){
			my $indexFile = $indexes[$i];
			$indexFile =~ s/\.sma//g;
			print "$indexFile\n";
			system(`smalt map -F fastq -f sam -i 1000 -n 2 -o $outDir/$out $indexFile $r1 $r2 `);
			}
}



exit 0;
###############
sub print_usage{
    warn <<"EOF";

USAGE
  page.pl -in <indir> -out <outdir>

DESCRIPTION
  SMALT sutff

OPTIONS
  -in	dir		Directory with FASTQ
  -index dir	Directory with reference files
  -out  dir		output files
  

EXAMPLES
  ./page.pl -in ../scratch/reads -o ./indexes -index ./reference
  ./page.pl -h

EXIT STATUS
  0     Successful completion
  >0    An error occurred

EOF
}
