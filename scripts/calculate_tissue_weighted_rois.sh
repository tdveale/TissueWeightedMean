#!/bin/bash
# TO DO: make input arguments named parameters

# Script that calculates tissue weighted ROIs from NODDI inputs and ROI images
# collect inputs
iso=$1
ndi=$2
odi=$3
mask=$4
roiBase=$5
outCSV=$6

# modulate noddi and create tissue fraction
# originally wanted to make the below call ./modulate_noddi.sh but getting source directory within a script was tough - working solution for now
if [ -e "${iso}" ]; then
  echo "Creating tissue fraction, modulated NDI and modulated ODI maps..."
  # calculate 1-Viso (tissue weighted)
  fslmaths ${iso} -mul -1 -add 1 -mas ${mask} ${iso%.nii.gz}_ftissue.nii.gz
  ls ${iso%.nii.gz}_ftissue.nii.gz
  # multiply by ndi
  fslmaths ${iso%.nii.gz}_ftissue.nii.gz -mul ${ndi} ${ndi%.nii.gz}_modulated.nii.gz
  ls ${ndi%.nii.gz}_modulated.nii.gz
  # multiply by odi
  fslmaths ${iso%.nii.gz}_ftissue.nii.gz -mul ${odi} ${odi%.nii.gz}_modulated.nii.gz
  ls ${odi%.nii.gz}_modulated.nii.gz
else
  echo "ISO IMAGE NOT FOUND"
fi

# set up spreadsheet
echo "NODDI_METRIC,ROI,MEAN,SD" > ${outCSV}

# loop through all roi images from ${roiBase} and create output csv
for roi in *${roiBase}*.nii*; do
  # get stats for modulated NDI
  istats=(`fslstats ${ndi%.nii.gz}_modulated.nii.gz -k ${roi} -m -s`);
  echo mNDI,${roi},${istats[0]},${istats[1]} >> ${outCSV}
  # get stats for modulated ODI
  istats=(`fslstats ${odi%.nii.gz}_modulated.nii.gz -k ${roi} -m -s`);
  echo mODI,${roi},${istats[0]},${istats[1]} >> ${outCSV}
  # get stats for Tissue Fraction
  istats=(`fslstats ${iso%.nii.gz}_ftissue.nii.gz -k ${roi} -m -s`);
  echo TissueFraction,${roi},${istats[0]},${istats[1]} >> ${outCSV}
done

echo "ROI stats saved to: ${outCSV}"
echo "Divide modulate NODDI metrics by associated Tissue Fraction to obtain tissue-weighted ROI measures."
