#!/usr/bin/perl
# Aroon Chande
# BIOL-7210 -- Comp Genomics 2016 
# Genome Assembly pipeline, for use in webapp
use strict;
use Async;
use File::Basename;
use File::Temp;
use Getopt::Long;
my $prog = basename($0);
if (@ARGV < 1){print_usage();exit 1;}
my($inDir,$outDir,$i,$base,$out,$r1,$r2,@steps,$link,$quast,$contigs);
$inDir = "/data/public/reads/";
$outDir = "/data/public/assemblies/";
$tmpDir = temp_filename();
$contigs = "$tmpDir/contigs";
my $kmer = '115';
GetOptions ('steps=s{1,}' => \@steps);
if (grep(/,/, @steps)){@steps = split(/,/,join(',',@steps));}
# Remove generalization and make assumptions about naming scheme
my @infiles = glob ( "$inDir/*R1_001_val_1.fq.gz" );
system(`mkdir -p $tmpDir/contigs`);
#SPAdes
if (grep(/spades|meta/i, @steps)){
	foreach (@infiles){
	get_files($_);
	system(`mkdir -p $tmpDir/spades/$out`);
	system(`spades.py -1 $r1 -2 $r2 -o $tmpDir/spades/$out -k 99,113,127 --only-assembler &>$tmpDir/status.log`);
	$link = join(".","spades",$out,"fa");
	system(`cp $tmpDir/spades/$out/contigs.fasta $tmpDir/contigs/$link`) if (grep(/meta/i, @steps));
	system(`cp $tmpDir/spades/$out/contigs.fasta $outDir/$link`) if !(grep(/meta/i, @steps));
	system(`rm -rf $tmpDir/spades/$out/corrected`);
}
}
# Velvet
if (grep(/velvet|meta/i, @steps)){
	foreach (@infiles){
	get_files($_);
	system(`mkdir -p $tmpDir/velvet/`);
	system(`VelvetOptimiser.pl -d $tmpDir/velvet/$out/ -s 97 -e 127 -x 10 -f '-fastq.gz -shortPaired -separate $r1 $r2' -t 6 --optFuncKmer 'n50' &>$tmpDir/status.log`);
	$link = join(".","velvet",$out,"fa");
	system(`cp $tmpDir/velvet/$out/contigs.fa $tmpDir/contigs/$link`) if (grep(/meta/i, @steps));
	system(`cp $tmpDir/velvet/$out/contigs.fa $outDir/$link`) if !(grep(/meta/i, @steps));
	system(`rm -rf $tmpDir/velvet/$out/Sequences`);
}
}
# ABySS
if (grep(/abyss|meta/i, @steps)){
	foreach (@infiles){
		get_files($_);
		system(`mkdir -p $tmpDir/abyss/k$kmer`);
		system("abyss-pe -C $tmpDir/abyss/k$kmer k=$kmer name=$out in='$r1 $r2' j=6 &>$tmpDir/status.log ");
		$link = join(".","abyss",$out,"fa");
		my $contig = join("-",$out,"contigs.fa");
		system(`cp $tmpDir/abyss/k$kmer/$contig $tmpDir/contigs/$link`) if (grep(/meta/i, @steps));
		system(`cp $tmpDir/abyss/k$kmer/$contig $ourDir/$link`) if !(grep(/meta/i, @steps));
	}
}


if (grep(/meta/i, @steps)){
	system(`mkdir -p $tmpDir/meta/ 2>$tmpDir/status.log`);
	foreach (@infiles){
	my $confFile =join(".",$out,"config");
	open OUT, ">$tmpDir/$out/$confFile" or die;
	my $spades = join('.',"spades",$out,"fa");
	my $velvet = join('.',"velvet",$out,"fa");
	my $abyss = join('.',"abyss","115",$out,"fa");
	my $meta = join(".","meta",$out,"fa");
	print OUT "[global]\nbowtie2_threads=12\nbowtie2_read1=$r1\nbowtie2_read2=$r2\nbowtie2_maxins=3000\nbowtie2_minins=1000\ngenomeLength=1825000\nmateAn_A=1300\nmateAn_B=2300\n[1]\nfasta=$contigs/$spades\nID=Spades\n[2]\nfasta=$contigs/$abyss\nID=Abyss\n[3]\nfasta=$contigs/$velvet\nID=Velvet\n";
	close OUT;
	system("metassemble --conf $tmpDir/$out/$confFile --outd $tmpDir/$out 2>>$tmpDir/status.log");
	system("sed -i s/QVelvet.Abyss.Spades/$out $tmpDir/meta/$out/Metassembly/QVelvet.Abyss.Spades/M1/QVelvet.Abyss.Spades.fasta" );
	system("cp $tmpDir/meta/$out/Metassembly/QVelvet.Abyss.Spades/M1/QVelvet.Abyss.Spades.fasta $outDir/contigs/$meta");
	}
}

if (grep(/velvet/i, @steps)){$quast =  Async->new( sub {system(`quast -R $ref --threads=2 $tmpDir/contigs/velvet* -o $tmpDir/quast/velvet >/dev/null`)} or die);}
if (grep(/spades/i, @steps)){$quast =  Async->new( sub {system(`quast -R $ref --threads=2 $tmpDir/contigs/spades* -o $tmpDir/quast/spades >/dev/null`)} or die);}
if (grep(/abyss/i, @steps)){$quast =  Async->new( sub {system(`quast -R $ref --threads=2 $tmpDir/contigs/abyss* -o $tmpDir/quast/abyss &>/dev/null`)} or die);}
if (grep(/meta/i, @steps)){$quast =  Async->new( sub {system(`quast -R $ref --threads=2 $tmpDir/contigs/meta* -o $tmpDir/quast/meta >/dev/null`)} or die);}
while (1){
	if ($quast->ready){
		#combine reports
		my $report=temp_filename();
		open REPORT, ">$report" or die "Cannot open $report: $!";
		print REPORT "Assembly\n# contigs (>= 0 bp)\n# contigs (>= 1000 bp)\n# contigs (>= 5000 bp)\n# contigs (>= 10000 bp)\n# contigs (>= 25000 bp)\n# contigs (>= 50000 bp)\nTotal length (>= 0 bp)\nTotal length (>= 1000 bp)\nTotal length (>= 5000 bp)\nTotal length (>= 10000 bp)\nTotal length (>= 25000 bp)\nTotal length (>= 50000 bp)\n# contigs\nLargest contig\nTotal length\nReference length\nGC (%)\nReference GC (%)\nN50\nNG50\nN75\nNG75\nL50\nLG50\nL75\nLG75\n# misassemblies\n# misassembled contigs\nMisassembled contigs length\n# local misassemblies\n# unaligned contigs\nUnaligned length\nGenome fraction (%)\nDuplication ratio\n# Ns per 100 kbp\n# mismatches per 100 kbp\n# indels per 100 kbp\nLargest alignment\nNA50\nNGA50\nNA75\nNGA75\nLA50\nLGA50\nLA75\nLGA75";
		close REPORT;
		system(`paste $report $tmpDir/quast/*/report.tsv| cut -f 1,3,5,7,9,11,13,15,17 > $tmpDir/quast/final_report.tsv`);
		system("rm -rf $tmpDir/quast/spades $tmpDir/quast/velvet $tmpDir/quast/meta $tmpDir/quast/abyss $tmpDir/quast/meta &>/dev/null");
		exit 0;
	}
	sleep 1;
}
}

exit 0;

#######
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
	        DIR      => '/data/public/tmp/',
	    );
	}

