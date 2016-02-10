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
my($inDir,$outDir,$i,$base,$out);
GetOptions ('o=s' => \$outDir, 'in=s' => \$inDir);
die print_usage() unless ((defined $outDir) && (defined $inDir));
my @infiles = glob ( "$inDir/*.fq.gz" );
my $max = @infiles/2;
my $amax = $max * 3;
my $currentReport = Term::Report->new(
   startRow => 4,
   numFormat => 1,
   statusBar => [
      startRow => 4,
      #label => 'progress: ',
      subText => 'Running SPAdes...',
      subTextAlign => 'center'
   ],
);
my $assemblyReport = Term::Report->new(
   startRow => 1,
   numFormat => 1,
   statusBar => [
      startRow => 1,
      label => 'Pipeline progress: ',
      subText => 'Get some coffee',
      subTextAlign => 'center'
   ],
);
my $assemblyStatus = $assemblyReport->{statusBar};
$assemblyStatus->setItems($amax);
$assemblyStatus->start;
my $currentStatus = $currentReport->{statusBar};
$currentStatus->setItems($max);
$currentStatus->start;
$currentStatus->label('SPAdes progress: ');
for ($i = 0; $i < @infiles; $i += 2){
        no warnings 'uninitialized';
		#$currentStatus->reset;  
        $base = $infiles[$i];
        $base  =~ s/\_R1_001_val_1\.fq\.gz//g;
        ($out) = $base =~ m/(M\d*)/;
        my $r1 = join('_',$base,"R1_001_val_1.fq.gz");
        my $r2 = join('_',$base,"R2_001_val_2.fq.gz");
#		system(`mkdir -p $outDir/spades/$out`);
		$currentStatus->subText("Running SPAdes on $out");
#		system(`spades.py -h -1 $r1 -2 $r2 -o $outDir/$out -k 21,33,55,77,99,127 --careful 2>$outDir/$out/spades.log`);
		sleep 1;
		$assemblyStatus->update();
        $currentStatus->update();
	}
$currentStatus->reset;  
$currentStatus=>label('Velvet progress: ');
	for ($i = 0; $i < @infiles; $i += 2){
		$base = $infiles[$i];
		$base  =~ s/\_R1_001_val_1\.fq\.gz//g;
		($out) = $base =~ m/(M\d*)/;
#		system(`mkdir -p $outDir/velvet/$out`);
		my $r1 = join('_',$base,"R1_001_val_1.fq.gz");
		my $r2 = join('_',$base,"R2_001_val_2.fq.gz");
#		system(`VelvetOptimiser.pl -d $outDir/$out/ -s 43 -e 127 -x 25 -f '-fastq.gz -shortPaired -separate $r1 $r2' -t 2 --optFuncKmer 'n50'`);
		$currentStatus->subText("Running Velvet on $out");
		sleep 1;
		$assemblyStatus->update();
        $currentStatus->update();	
}

exit 0;
