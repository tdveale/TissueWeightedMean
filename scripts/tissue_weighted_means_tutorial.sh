# Define directories
data_dir=$1

# Run Preprocessing.md to download data, extract NODDI metrics, and extract ROIs

# Navigate to data directory
cd $data_dir

# 1. Generate tissue fraction maps
fslmaths FIT_ISOVF.nii.gz -mul -1 -add 1 -mas NODDI_DWI_mask.nii.gz FIT_ISOVF_ftissue.nii.gz

# 2. Multiplpy NDI and ODI maps by tissue fraction
fslmaths FIT_ISOVF_ftissue.nii.gz -mul FIT_ICVF.nii.gz FIT_ICVF_modulated.nii.gz
fslmaths FIT_ISOVF_ftissue.nii.gz -mul FIT_OD.nii.gz FIT_OD_modulated.nii.gz

# 3. Extract ROI metrics (mean modulated tissue metrics, mean tissue fraction) 
echo "ROI, NDI_MOD_MEAN, OD_MOD_MEAN, TF_MEAN" > NODDI_FIBER_ROIs.csv
for roi in *roi_native.nii.gz; do 
	roi_short_name=${roi%_256_roi_native.nii.gz}
	ndi_mod_mean=(`fslstats FIT_ICVF_modulated.nii.gz -k ${roi} -m`)
	od_mod_mean=(`fslstats FIT_OD_modulated.nii.gz -k ${roi} -m`)
	tf_mean=(`fslstats FIT_ISOVF_ftissue.nii.gz -k ${roi} -m`)
	line="${roi_short_name}, ${ndi_mod_mean}, ${od_mod_mean}, ${tf_mean}"
	echo ${line} >> NODDI_FIBER_ROIs.csv
done
echo "ROI traditional stats saved to: ${data_dir}/NODDI_FIBER_ROIs.csv"

# 4. Tissue-weighted means: Divide regional NDI and ODI measures by Tissue Fraction
echo "ROI, NDI_TWMEAN, OD_TWMEAN" > TWM_NODDI_FIBER_ROIs.csv
skip_headers=1
while IFS=, read -r roi_short_name ndi_mod_mean od_mod_mean tf_mean
do
    if ((skip_headers))
    then
        ((skip_headers--))
    else
        ndi_twm=`printf "%0.6f\n" $(bc -q <<< "scale=10; ${ndi_mod_mean}/${tf_mean}")`
        od_twm=`printf "%0.6f\n" $(bc -q <<< "scale=10; ${od_mod_mean}/${tf_mean}")`
        line="${roi_short_name}, ${ndi_twm}, ${od_twm}"
        echo ${line} >> TWM_NODDI_FIBER_ROIs.csv
    fi
done < NODDI_FIBER_ROIs.csv
echo "Tissue-weighted mean ROI stats saved to: ${data_dir}/TWM_NODDI_FIBER_ROIs.csv"