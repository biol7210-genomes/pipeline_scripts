#!/bin/bash
for i in 

fq_count=`calc "$(wc -l < all_reads.fastq) / 8"`
samples=`calc "floor($fq_count / 3)"`
sample --lines-per-offset=8 --sample-size=${samples} all_reads.fastq > random_sample.fastq