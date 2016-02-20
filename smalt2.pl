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
my($help,$inDir,$outDir,$i,$base,$out,$assemblyStatus,$currentStatus,$r1,$r2,$R,$ref,@steps,$link,$quast);
GetOptions ('h' => \$help, 'o=s' => \$outDir, 'in=s' => \$inDir, 'R=s' => \$ref, 'steps=s{1,}' => \@steps);
if (grep(/,/, @steps)){@steps = split(/,/,join(',',@steps));}
die print_usage() if (defined $help);
die print_usage() unless ((defined $outDir) && (defined $inDir));








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
