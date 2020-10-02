# NODDI Tissue Weighting

## What is NODDI?
NODDI (**N**eurite **O**rientation **D**ispersion and **D**ensity **I**maging) is a microstructural modelling approach for diffusion MRI data. Diffusion within a voxel is modelled using three separate compartments representing 3 microstructural environments:

1. Isotropic diffusion compartment (i.e. water in free flowing regions like CSF). The NODDI model provides this directly as:
  - **ISO**: Isotropic diffusion fraction

The remaining diffusion within a voxel is attributed to brain tissue and split into two compartments:

2. Extra-neurite diffusion compartment (i.e. water outside axons).
3. Intra-neurite diffusion compartment (i.e. water within axons).

  Two microstructural properties can be modelled from the intra-neurite compartment:
  
   - **NDI**: Neurite Density Index
   - **ODI**: Orientation Dispersion Index

## Why Tissue Weighting?

Voxels deep within the brain will have low **ISO** values as they are far from the CSF and most of the diffusion is attributed to the brain tissue. **NDI** and **ODI** here will be comparable across voxels as they are associated with the majority of diffusion within the voxel.

However, this does not apply in regions near the CSF such as the corpus callosum and cortical grey matter. Voxels closer to the CSF will have higher **ISO** values compared to voxels deeper in the brain. This becomes troubling when extracting regions of interest measures. Although voxels within a these regions will vary in the fraction of tissue the **NDI** and **ODI** are calculated from, all voxels are treated equally.

We can account for this by assigning greater importance to voxels with a higher tissue fraction (i.e. lower **ISO**). This can be done by calculating a weighted average of **NDI** and **ODI** in regions of interest, where the tissue fraction (**1-ISO**) are the weights.

See below for a tutorial on how to calculate tissue weighted region of interest measures for NDI and ODI.

# Tissue Weighting Tutorial

## Overview

The steps for calculating tissue weighted regional averages of NDI and ODI are below:

1. Generate tissue fraction map (1-ISO).
2. Multiply the NDI and ODI maps by the 1-ISO map.
3. Extract region of interest measures for NDI, ODI and 1-ISO.
4. Divide regional NDI and ODI measures by corresponding 1-ISO region.

We will use the NODDI outputs from the example NODDI dataset to calculate tissue weighted NDI and ODI measures for tracts of interest.


## 1. Generating Tissue Fraction Maps (1-ISO)

- We start from the NODDI outputs and assume you have already fit the NODDI model to your data.
  - For help on fitting the NODDI model please visit http://mig.cs.ucl.ac.uk/index.php?n=Tutorial.NODDImatlab
  - Example diffusion MRI data can be found here (free account needed): https://www.nitrc.org/projects/noddi_toolbox
  -

```

```

## 2. Multiplying NDI and ODI Maps by 1-ISO

## 3. Extracting Regions of Interest Measures

## 4. Divide Regional NDI and ODI measures by 1-ISO

# NODDI Tissue Weighting Tool

We have included a function in this repository (FUNCTION NAME HERE) to aid in the calculation of tissue weighted averages.
