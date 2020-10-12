#!/bin/bash

# Script that calculates tissue weighted ROIs from NODDI inputs and ROI images

# collect inputs - make these names inputs instead of by position
iso=$1
ndi=$2
odi=$3
mask=$4
roiBase=$5
outCSV=$6

# use modulate_noddi.sh to create tissue fraction and modulated NDI and ODI

# loop through all roi images from ${roiBase} and create output csv
