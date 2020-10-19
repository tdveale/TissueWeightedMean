# Preprocessing Steps Used for Example Data

These steps do not need to be carried out as the data to complete the tissue weighting tutorial is already made available here. We provide the information below for completeness and transparency.


## 1. Prepare Example Data Files

Within the NODDI_example_dataset folder, set up a subfolder needed for later processing. Move the files into this subdirectory:
```
mkdir NODDI_example_dataset/example_subject/
mv NODDI_example_dataset/*.* NODDI_example_dataset/example_subject/
```

Enter the data directory:
```
cd NODDI_example_dataset/example_subject/
```

Convert the diffusion MRI data into NIFTI format:
```
fslchfiletype NIFTI_GZ NODDI_DWI
```

## 2. Create Whole Brain Mask

We used MRtrix3 (https://www.mrtrix.org) to create a whole brain mask used in the NODDI fitting:

```
dwi2mask -fslgrad NODDI_protocol.bvec NODDI_protocol.bval NODDI_DWI.nii.gz NODDI_DWI_mask.nii.gz
```

## 3. Fit NODDI Model Using AMICO

We used the AMICO toolbox in python to fit the NODDI model for speed purposes (https://github.com/daducci/AMICO/wiki/Fitting-the-NODDI-model). This requires the `spams` and `amico` python libraries to be installed. The steps here follow the AMICO tutorial in the above link.

If you prefer MATLAB, steps on fitting the NODDI model in the MATLAB toolbox can be found here http://mig.cs.ucl.ac.uk/index.php?n=Tutorial.NODDImatlab

To fit NODDI with AMICO in python, first move back up to the directory tree (for AMICO to see directory structure)

```
cd ../../
```

Activate python from the terminal
```
python
```

Import `amico` and `spams`
```
>>> import amico
>>> import spams
```

Set-up rotation matrices
```
>>> amico.core.setup()
```

Set-up scheme file
```
>>> amico.util.fsl2scheme('NODDI_example_dataset/example_subject/NODDI_protocol.bval', 'NODDI_example_dataset/example_subject//NODDI_protocol.bvec')
```

Load data
```
>>> ae.load_data(dwi_filename = "NODDI_DWI.nii.gz", scheme_filename = "NODDI_protocol.scheme", mask_filename = "NODDI_DWI_mask.nii.gz", b0_thr = 0)

-> Loading data:
	* DWI signal...
		- dim    = 128 x 128 x 50 x 81
		- pixdim = 1.875 x 1.875 x 2.500
	* Acquisition scheme...
		- 81 samples, 2 shells
		- 9 @ b=0 , 24 @ b=700.0 , 48 @ b=2000.0
	* Binary mask...
		- dim    = 128 x 128 x 50
		- pixdim = 1.875 x 1.875 x 2.500
		- voxels = 164035

-> Preprocessing:
	* Normalizing to b0... [ min=0.00,  mean=2.78, max=2862.00 ]
	* Keeping all b0 volume(s)...
   [ 1.8 seconds ]


```

Generate response functions
```
>>> ae.set_model("NODDI")
>>> ae.generate_kernels()

-> Creating LUT for "NODDI" model:
    [ 106.8 seconds ]    

```

Load kernels created above
```
>>> ae.load_kernels()

-> Resampling LUT for subject "example_subject":
    [ 54.3 seconds ]   
```

Fit the NODDI model
```
>>> ae.fit()
```

Save results
```
ae.save_results()

-> Saving output to "AMICO/NODDI/*":
	- configuration  [OK]
	- FIT_dir.nii.gz  [OK]
	- FIT_ICVF.nii.gz  [OK]
	- FIT_OD.nii.gz  [OK]
	- FIT_ISOVF.nii.gz  [OK]
   [ DONE ]

```


# 4. Generate ROI Masks

## Create ROIs using IIT template

The principal of tissue weighted average measures apply to a range of ROI measures (i.e. FreeSurfer cortical ROIs, white matter tracts and white matter regions). Here we will use white matter fibre bundle ROIs from the IIT human brain atlas (LINK HERE) to create basic regional measurements for calculating tissue weighted averages.

INSERT INFO ON ACCESS AND DOWNLOADING NECESSARY FILES FROM IIT https://www.nitrc.org/projects/iit/

The IIT template provides track densities from whole brain tractogram and segmented using RecoBundles (Neuroimage 2018;170:283-295). A selection of major fibre bundles were thresholded manually after visualisation of track densities and binarised to create ROIs.

```
fslmaths CC_256.nii.gz -thr 50 -bin CC_256_roi.nii.gz
fslmaths C_L_256.nii.gz -thr 20 -bin C_L_256_roi.nii.gz
fslmaths C_R_256.nii.gz -thr 20 -bin C_R_256_roi.nii.gz
fslmaths CST_L_256.nii.gz -thr 20 -bin CST_L_256_roi.nii.gz
fslmaths CST_R_256.nii.gz -thr 20 -bin CST_R_256_roi.nii.gz
fslmaths UF_L_256.nii.gz -thr 10 -bin UF_L_256_roi.nii.gz
fslmaths UF_R_256.nii.gz -thr 10 -bin UF_R_256_roi.nii.gz
```


## Mapping IIT ROIs to Native Space

In order to use the IIT atlas ROIs, we need to map these ROIs from standard space into the native space of the NODDI example data. We will do this by registering the example data to an IIT tensor template using the DTI-TK package (http://dti-tk.sourceforge.net) and then inverting the transformation to bring the ROIs back into native space.

### Setting up Files

We will use the `IITmean_tensor_256.nii.gz` image as a template to calculate the transformation of the NODDI example data to template space.

First we need to do some basic DTI processing in FSL to fit the tensors.

```
dtifit -k NODDI_DWI.nii.gz -m NODDI_DWI_mask.nii.gz -o NODDI_DWI -r NODDI_protocol.bvec -b NODDI_protocol.bval --wls --save_tensor
```

Then we need to convert FSL outputs to the DTI-TK file format.

```
fsl_to_dtitk NODDI_DWI
```

This will provide the tensor image `NODDI_DWI_dtitk.nii.gz` which we will use to register to the IIT atlas tensor image (`IITmean_tensor_256.nii.gz`)

### Registering Example NODDI dataset to IIT template

Perform rigid registration

```
dti_rigid_reg IITmean_tensor_256.nii.gz NODDI_DWI_dtitk.nii.gz EDS 4 4 4 0.01
```

Perform affine registration

```
dti_affine_reg IITmean_tensor_256.nii.gz NODDI_DWI_dtitk.nii.gz EDS 4 4 4 0.01 1
```

Non-linearly register NODDI example data to IIT template

```
dti_diffeomorphic_reg IITmean_tensor_256.nii.gz NODDI_DWI_dtitk_aff.nii.gz IITmean_tensor_mask_256.nii.gz 1 5 0.002
```


### Inverting Transformation

We need to invert the transformation to now map the images in the opposite direction `IITmean_tensor_256.nii.gz` -> `NODDI_DWI_dtitk.nii.gz`. More information about these steps can be found here http://dti-tk.sourceforge.net/pmwiki/pmwiki.php?n=Documentation.OptionspostReg

Invert the affine transformation
```
affine3Dtool -in NODDI_DWI_dtitk.aff -invert -out NODDI_DWI_dtitk_inv.aff
```

Invert the deformable transformation

```
dfToInverse -in NODDI_DWI_dtitk_aff_diffeo.df.nii.gz
```

Combine these inverted transformations to now map from template -> native space in one step

```
dfLeftComposeAffine -df NODDI_DWI_dtitk_aff_diffeo.df_inv.nii.gz -aff NODDI_DWI_dtitk_inv.aff -out NODDI_DWI_dtitk_combined.df_inv.nii.gz
```

### Mapping ROIs back into Native Space

We can now use `NODDI_DWI_dtitk_combined.df_inv.nii.gz` as our transformation to bring the ROIs in IIT template space back into the native space. This can be done with another dti-tk command called `deformationScalarVolume`.

We can loop through each fibre bundle ROIs we created earlier and map them back into the native NODDI example data space.

```
for roi in *_256_roi.nii.gz; do deformationScalarVolume -in ${roi} -trans NODDI_DWI_dtitk_combined.df_inv.nii.gz -target NODDI_DWI_dtitk.nii.gz -interp 1 -out ${roi%.nii.gz}_native.nii.gz; done
```

# 5. Start Extracting Tissue Weighting Average Measures!

Congratulations! You should now have all you need to recreate the data for the NODDI tissue weighting tutorial.

See below for a checklist of the files used in this tutorial:

AMICO NODDI outputs:
```
FIT_dir.nii.gz
FIT_ICVF.nii.gz
FIT_ISOVF.nii.gz
FIT_OD.nii.gz
```
NODDI Mask:

```
NODDI_DWI.nii.gz
```

Fibre bundle ROIs in native NODDI data space:
```
CC_256_roi_native.nii.gz
C_L_256_roi_native.nii.gz
C_R_256_roi_native.nii.gz
CST_L_256_roi_native.nii.gz
CST_R_256_roi_native.nii.gz
UF_L_256_roi_native.nii.gz
UF_R_256_roi_native.nii.gz   
```
