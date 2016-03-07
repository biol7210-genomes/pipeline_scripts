#!/usr/bin/perl -w
# Alli Gombolay
# AlignGraph Assembly Pipeline

use strict;

AlignGraph --read1 reads_1.fa --read2 reads_2.fa --contig contigs.fa --genome genome.fa --distanceLow 100 --distanceHigh 1500 --extendedContig extendedContigs.fa --remainingContig remainingContigs.fa
