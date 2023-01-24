# Preprocessing Steps Used for Example Data
# Assumes example data is in current directory

# 0. Download NODDI example dataset
# http://mig.cs.ucl.ac.uk/index.php?n=Tutorial.NODDImatlab


# 1. Prepare Example Data Files
mkdir NODDI_example_dataset/example_subject/
mv NODDI_example_dataset/*.* NODDI_example_dataset/example_subject/

# Enter the data directory:
cd NODDI_example_dataset/example_subject/

# Convert the diffusion MRI data into NIFTI format:
fslchfiletype NIFTI_GZ NODDI_DWI

# 2. Create Whole Brain Mask
dwi2mask -fslgrad NODDI_protocol.bvec NODDI_protocol.bval NODDI_DWI.nii.gz NODDI_DWI_mask.nii.gz

# 3. Fit NODDI Model Using AMICO
cd ../../

### Python script for NODDI fitting using AMICO
python3 Preprocessing.py

# 4. Generate ROI Masks
fslmaths CC_256.nii.gz -thr 50 -bin CC_256_roi.nii.gz
fslmaths C_L_256.nii.gz -thr 20 -bin C_L_256_roi.nii.gz
fslmaths C_R_256.nii.gz -thr 20 -bin C_R_256_roi.nii.gz
fslmaths CST_L_256.nii.gz -thr 20 -bin CST_L_256_roi.nii.gz
fslmaths CST_R_256.nii.gz -thr 20 -bin CST_R_256_roi.nii.gz
fslmaths UF_L_256.nii.gz -thr 10 -bin UF_L_256_roi.nii.gz
fslmaths UF_R_256.nii.gz -thr 10 -bin UF_R_256_roi.nii.gz


#- Mapping IIT ROIs to Native Space

# Setting up Files
dtifit -k NODDI_DWI.nii.gz -m NODDI_DWI_mask.nii.gz -o NODDI_DWI -r NODDI_protocol.bvec -b NODDI_protocol.bval --wls --save_tensor


# Convert FSL outputs to the DTI-TK file format.
fsl_to_dtitk NODDI_DWI

# Registering Example NODDI dataset to IIT template
dti_rigid_reg IITmean_tensor_256.nii.gz NODDI_DWI_dtitk.nii.gz EDS 4 4 4 0.01


# Perform affine registration
dti_affine_reg IITmean_tensor_256.nii.gz NODDI_DWI_dtitk.nii.gz EDS 4 4 4 0.01 1


# Non-linearly register NODDI example data to IIT template
dti_diffeomorphic_reg IITmean_tensor_256.nii.gz NODDI_DWI_dtitk_aff.nii.gz IITmean_tensor_mask_256.nii.gz 1 5 0.002

# Inverting Transformation
affine3Dtool -in NODDI_DWI_dtitk.aff -invert -out NODDI_DWI_dtitk_inv.aff

# Invert the deformable transformation
dfToInverse -in NODDI_DWI_dtitk_aff_diffeo.df.nii.gz

# Combine these inverted transformations to now map from template -> native space in one step
dfLeftComposeAffine -df NODDI_DWI_dtitk_aff_diffeo.df_inv.nii.gz -aff NODDI_DWI_dtitk_inv.aff -out NODDI_DWI_dtitk_combined.df_inv.nii.gz

# Mapping ROIs back into Native Space
for roi in *_256_roi.nii.gz; do deformationScalarVolume -in ${roi} -trans NODDI_DWI_dtitk_combined.df_inv.nii.gz -target NODDI_DWI_dtitk.nii.gz -interp 1 -out ${roi%.nii.gz}_native.nii.gz; done


# 5. Start Extracting Tissue Weighting Average Measures! 

# Congratulations! You should now have all you need to recreate the data for the NODDI tissue weighting tutorial.

# See below for a checklist of the files need for the tutorial:

# #- AMICO NODDI outputs:
# FIT_dir.nii.gz
# FIT_ICVF.nii.gz
# FIT_ISOVF.nii.gz
# FIT_OD.nii.gz

# #- Fibre bundle ROIs in native NODDI data space:
# CC_256_roi_native.nii.gz
# C_L_256_roi_native.nii.gz
# C_R_256_roi_native.nii.gz
# CST_L_256_roi_native.nii.gz
# CST_R_256_roi_native.nii.gz
# UF_L_256_roi_native.nii.gz
# UF_R_256_roi_native.nii.gz  

# #- Original files (.nii.gz)
# NODDI Mask:
# NODDI_DWI.nii.gz 

