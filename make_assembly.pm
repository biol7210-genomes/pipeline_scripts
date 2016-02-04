#!/usr/bin/perl -w
# Aroon Chande
# Assembly pipeline, setup submodules for running assemblers
sub make_assembly($$$$){		#Takes in files, outdir, method to call
my @infiles = @{$_[0]};
my ($outDir,$method,$program,$out) = ("@_[1]","@_[2]","@_[3]","");
for ($i = 0; $i < @infiles; $i += 2){
	$base = $infiles[$i];
	$base  =~ s/\_R1_001_val_1\.fq\.gz//g;
	($out) = $base =~ m/(M\d*)/;
	system(`mkdir -p $outDir/$out`) unless ($program =~ "velvet");
	my $r1 = join('_',$base,"R1_001_val_1.fq.gz");
	my $r2 = join('_',$base,"R2_001_val_2.fq.gz");
	system(`$method`);
}

}