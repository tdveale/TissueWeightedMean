# Import librariries
import amico # error in installation
import spams


# Set-up rotation matrices
amico.core.setup()


# Set-up scheme file
amico.util.fsl2scheme('NODDI_example_dataset/example_subject/NODDI_protocol.bval', 'NODDI_example_dataset/example_subject//NODDI_protocol.bvec')


# Load data
ae.load_data(dwi_filename = "NODDI_DWI.nii.gz", scheme_filename = "NODDI_protocol.scheme", mask_filename = "NODDI_DWI_mask.nii.gz", b0_thr = 0)


# -> Loading data:
# 	* DWI signal...
# 		- dim    = 128 x 128 x 50 x 81
# 		- pixdim = 1.875 x 1.875 x 2.500
# 	* Acquisition scheme...
# 		- 81 samples, 2 shells
# 		- 9 @ b=0 , 24 @ b=700.0 , 48 @ b=2000.0
# 	* Binary mask...
# 		- dim    = 128 x 128 x 50
# 		- pixdim = 1.875 x 1.875 x 2.500
# 		- voxels = 164035

# -> Preprocessing:
# 	* Normalizing to b0... [ min=0.00,  mean=2.78, max=2862.00 ]
# 	* Keeping all b0 volume(s)...
#    [ 1.8 seconds ]


# Generate response functions
ae.set_model("NODDI")
ae.generate_kernels()

# -> Creating LUT for "NODDI" model:
#     [ 106.8 seconds ]    


# Load kernels created above
ae.load_kernels()

# -> Resampling LUT for subject "example_subject":
#     [ 54.3 seconds ]   


# Fit the NODDI model
ae.fit()


# Save results
ae.save_results()


# -> Saving output to "AMICO/NODDI/*":
# 	- configuration  [OK]
# 	- FIT_dir.nii.gz  [OK]
# 	- FIT_ICVF.nii.gz  [OK]
# 	- FIT_OD.nii.gz  [OK]
# 	- FIT_ISOVF.nii.gz  [OK]
#    [ DONE ]

