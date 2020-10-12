#!/bin/bash
# Calculates tissue fraction map (TFM) and uses this to modulate NDI and ODI images

iso=$1
ndi=$2
odi=$3
mask=$4

# if iso file exists
if [ -e "${iso}" ]; then
  # calculate 1-Viso (tissue weighted)
  fslmaths ${iso} -mul -1 -add 1 -mas ${mask} ${iso%.nii.gz}_ftissue.nii.gz
  # multiply by ndi
  fslmaths ${iso%.nii.gz}_ftissue.nii.gz -mul ${ndi} ${ndi%.nii.gz}_modulated.nii.gz
  ls ${ndi%.nii.gz}_modulated.nii.gz
  # multiply by odi
  fslmaths ${iso%.nii.gz}_ftissue.nii.gz -mul ${odi} ${odi%.nii.gz}_modulated.nii.gz
  ls ${odi%.nii.gz}_modulated.nii.gz
else
  echo "ISO IMAGE NOT FOUND"
fi
