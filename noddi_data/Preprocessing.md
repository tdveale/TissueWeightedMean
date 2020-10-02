# Preprocessing Steps Used for Example Data

These steps do not need to be carried out as the data is already made available here. We provide the information below for completeness and transparency.


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

We will use white matter ROIs from the JHU atlas (LINK HERE) to create basic regional measurements for calculating tissue weighted averages.

First we calculated FA to register to standard space.

```
cd example_subject/
dtifit -k NODDI_DWI.nii.gz -m NODDI_DWI_mask.nii.gz -o NODDI_DWI -r NODDI_protocol.bvec -b NODDI_protocol.bval --wls --save_tensor
```

Then we used the tbss registration scripts from FSL to warp the NODDI example data to MNI space

```
mkdir tbss_reg
cp NODDI_DWI_FA.nii.gz tbss_reg/NODDI_DWI_FA.nii.gz
cd tbss_reg/
tbss_1_preproc NODDI_DWI_FA.nii.gz
tbss_2_reg -T
tbss_3_postreg -S
```

We can then inverse the transformation to map the JHU ROIs back into native space.

```
convert_xfm -omat FA/NODDI_DWI_FA_target_to_FA.mat -inverse FA/NODDI_DWI_FA_FA_to_target.mat
```

The inverted transformation can then be used to bring the ROIs back into native space.
```
flirt -in $FSLDIR/data/atlases/JHU/JHU-ICBM-labels-1mm.nii.gz -ref NODDI_DWI_FA.nii.gz -applyxfm -init tbss_reg/FA/NODDI_DWI_FA_target_to_FA.mat -o jhu_roi_native_2.nii
```
