#!/bin/bash
# Aroon Chande
# Quick oneliner for abyss build
for i in {97,115};do
  for j in $(ls /data/projects/assembly/aroon/files/*val_1*); do;
    k=$(echo $j | sed s'/R1_001_val_1/R2_001_val_2/'g)
    abyss-pe -C k$i k=$i name=M16180 in="$j $k" j=4
  done
done 
