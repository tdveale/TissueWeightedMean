# NODDI Tissue Weighting

## What is NODDI?
NODDI (**N**eurite **O**rientation **D**ispersion and **D**ensity **I**maging) is a microstructural modelling approach for diffusion MRI data [Zhang et al., NeuroImage 2012]. Diffusion within a voxel is modelled using three compartments representing three microstructural environments:

1. Isotropic diffusion compartment (i.e. water in free-flowing regions like the cerebrospinal fluid, CSF). The NODDI model provides this directly as:
  - **ISO**: Isotropic diffusion fraction

The remaining diffusion within a voxel is attributed to brain tissue and split into two compartments:

2. Extra-neurite diffusion compartment (i.e. water outside axons).
3. Intra-neurite diffusion compartment (i.e. water within axons).

  Two microstructural properties can be modelled from the intra-neurite compartment:

   - **NDI**: Neurite Density Index
   - **ODI**: Orientation Dispersion Index

## Why Tissue Weighting?

In healthy controls, voxels deep within the brain will tend to have lower **ISO** values as they are far from the CSF and most of the diffusion signal is attributed to the properties of brain tissue (grey and white matter, GM and WM). In this deep GM and WM tissue, **NDI** and **ODI** values will be comparable across voxels as they are associated with the majority of diffusion signal within the voxel.

However, this does not apply in regions near the CSF such as the corpus callosum, the fornix and cortical GM. Voxels closer to the CSF will tend to have higher **ISO** values compared to voxels deeper in the brain. This becomes troubling when extracting diffusion measures in specific regions of interest (ROIs). Although voxels within these ROIs will vary in the fraction of tissue the **NDI** and **ODI** are calculated from, all voxels are treated equally.

We can account for this by assigning greater importance to voxels with a higher tissue fraction (i.e. lower **ISO**). This can be done by calculating a weighted average of **NDI** and **ODI** in ROIs, while weighting for the tissue fraction (**1-ISO**), which represents the voxels belonging to the GM and WM tissue, rather than CSF.

It is important to notice that this bias can occur also in regions of the brain affected by pathological processes, such as atrophy, where healthy GM tissue is replaced by CSF.

See below for a tutorial on how to calculate tissue weighted ROI measures for **NDI** and **ODI**.

# Tissue Weighting Tutorial

## Overview

The steps for calculating tissue weighted regional averages of **NDI** and **ODI** are below:

1. Generate the tissue fraction map (**1-ISO**).
2. Multiply both the **NDI** and **ODI** maps by the **1-ISO** map.
3. Extract the ROI measures for **NDI**, **ODI** and **1-ISO**.
4. Divide regional **NDI** and **ODI** measures by the corresponding **1-ISO** region.

We will use the NODDI outputs from the example NODDI dataset [http://mig.cs.ucl.ac.uk/index.php?n=Tutorial.NODDImatlab] to calculate tissue weighted **NDI** and **ODI** measures for tracts of interest.


## Set up

### Software

This tutorial is performed on the linux terminal (bash) and requires FSL to be installed.

### Files

To perform tissue weighted average correction, you will need the following output file from the NODDI preprocessing:

- ISO image (* *_fiso.nii.gz* or *FIT_ISOVF.nii.gz*)
- NDI image (* *_ficvf.nii.gz* or *FIT_ICVF.nii.gz*)
- ODI image (* *_odi.nii.gz* or *FIT_OD.nii.gz*)
- Brain mask for NODDI images (* *_mask.nii.gz*)
- Regions of interest in NODDI image space (* *roi_native.nii.gz*)

To follow this tutorial exactly, download and extract the zip files in `noddi_data/` into one directory on your computer. Preprocessing steps for recreating this data can be found in `noddi_data/Preprocessing.md`

## 1. Generating Tissue Fraction Maps (1-ISO)

First we will create a tissue fraction map (*ISOVF_ftissue*). This is the fraction of the voxel remaining after **ISO** has been calculated and is attributed to tissue (**1-ISO**).

We can calculate **1-ISO** in one line using FSL by inverting the **ISO** image and adding 1.

```
fslmaths FIT_ISOVF.nii.gz -mul -1 -add 1 -mas NODDI_DWI_mask.nii.gz FIT_ISOVF_ftissue.nii.gz
```

The image should look like below:

FTISSUE IMAGE HERE

## 2. Multiplying NDI and ODI Maps by 1-ISO

We now multiply the **NDI** and **ODI** images by this tissue fraction map to create *modulated* NDI and ODI images. These allow for the tissue weighting calculation to occur on the ROI level later (step 4).

```
fslmaths FIT_ISOVF_ftissue.nii.gz -mul FIT_ICVF.nii.gz FIT_ICVF_modulated.nii.gz
fslmaths FIT_ISOVF_ftissue.nii.gz -mul FIT_OD.nii.gz FIT_OD_modulated.nii.gz
```
The images should look like the below:

MODULATED NDI AND ODI IMAGE HERE

## 3. Extracting Regions of Interest Measures

We now extract ROI measures for the `modulated NDI`, `modulated ODI` and `tissue fraction` images.

First lets set up a .csv file to store our ROI measures in.

```
echo "NODDI_METRIC,ROI,MEAN,SD" > NODDI_FIBRE_ROIs.csv
```

Then for each of our images, we loop through ROIs, extract measures and store in our csv file `NODDI_FIBRE_ROIs.csv`.

First for modulated NDI:
```
for roi in *roi_native.nii.gz; do istats=(`fslstats FIT_ICVF_modulated.nii.gz -k ${roi} -m -s`); echo mNDI,${roi%_256_roi_native.nii.gz},${istats[0]},${istats[1]} >> NODDI_FIBRE_ROIs.csv; done
```

Then for modulated ODI:

```
for roi in *roi_native.nii.gz; do istats=(`fslstats FIT_OD_modulated.nii.gz -k ${roi} -m -s`); echo mODI,${roi%_256_roi_native.nii.gz},${istats[0]},${istats[1]} >> NODDI_FIBRE_ROIs.csv; done
```

Finally for tissue fraction:

```
for roi in *roi_native.nii.gz; do istats=(`fslstats FIT_ISOVF_ftissue.nii.gz -k ${roi} -m -s`); echo TissueFraction,${roi%_256_roi_native.nii.gz},${istats[0]},${istats[1]} >> NODDI_FIBRE_ROIs.csv; done
```

## 4. Divide Regional NDI and ODI measures by 1-ISO

Finally, we have all we need to calculate tissue weighted averages in our csv file `NODDI_FIBRE_ROIs.csv`. The corpus callosum values for each metric is shown below as an example.


| NODDI_METRIC    | ROI     |  MEAN       | SD       |
| -----------     | :----:  | :---------: | :-------:|
| mNDI            | CC      |  0.486252   | 0.138766 |
| mODI            | CC      |  0.146003   | 0.118653 |
| TissueFraction  | CC      |  0.848126   | 0.213132 |

All that remains is to divide the modulated **NDI** and **ODI** ROIs mean values by the corresponding tissue fraction ROI mean values in your software of choice. Doing the following will create the tissue weighted values below:

| NODDI_METRIC    | ROI     |  MEAN       |
| -----------     | :----:  | :---------: |
| NDI_Weighted    | CC      |  0.57332519 |
| ODI_Weighted    | CC      |  0.17214777 |


# NODDI Tissue Weighting Tool

We have included a function in this repository (FUNCTION NAME HERE) to aid in the calculation of tissue weighted averages.
