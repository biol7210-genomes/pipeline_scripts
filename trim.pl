#!/usr/bin/perl -w
# Aroon Chande
# Trimming via trim_galore
# Input is directory containing trimmed fq and outdir
# Takes gunzip'ed or uncompressed fastq files
# ./trim.pl -in fqdir -o outdir -t int
use Getopt::Long;
use File::Basename;
use File::Temp;
use Parallel::ForkManager;
use Pod::Usage;
my $prog = basename($0);
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base);
my $threads = 12;
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir, 't=s' => \$threads);
die print_usage() unless ((defined $outDir) && (defined $inDir));
my @infiles = glob ( "$inDir/*.fastq.gz" );
my $manager = Parallel::ForkManager -> new ( $threads );
for ($i = 0; $i < @infiles; $i += 2){
	$manager->start and next;
	$base = $infiles[$i];
	$base  =~ s/\_R._001\.fastq\.gz//g;
	my $r1 = join('_',$base,"R1_001.fastq.gz");
	my $r2 = join('_',$base,"R2_001.fastq.gz");
	my $r1b = basename($r1);
	my $r2b = basename($r2);
	print "Trimming: $r1b and $r2b\n";
	system("trim_galore --illumina --clip_R1 10 --clip_R2 10 --three_prime_clip_R1 5 --three_prime_clip_R2 5 --no_report_file  --length 100 --paired $r1  $r2 -o $outDir 2>./trim_galore.log");
}
$manager->wait_all_children;

exit 0;
##################
sub print_usage{
    warn <<"EOF";

USAGE
  $prog -in <indir> -out <outdir>

DESCRIPTION
  Trim galore

OPTIONS
  -in	dir		Directory with FASTQ
  -out  dir		output files
  -t	int		Number of pairs of files to process
  			at one time. 12 by default.

EXAMPLES
  $prog -in ../reads/ ./spades_out
  $prog -h

EXIT STATUS
  0     Successful completion
  >0    An error occurred

EOF
}

