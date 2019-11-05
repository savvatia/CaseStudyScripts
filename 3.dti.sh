#!/bin/sh

#Script adapted from Duke Shereen and Robert Nikolov
##This is the second refinement of tractography
##The algorithms for the first tractography can be found in scripts 1.dti.sh 
##The main difference here is that 1.dti.sh used 1 seed per voxel FA threshold of 0.2 while 3.dti.sh uses 16 random seeds and FA threshold of 0.15, as well as a seed mask option "-sm" with the Connectome Mapper Lausanne parcellations as the mask

module load fsl/5.0.10 
      
for sub in  sub01 sub02 sub03 sub04 sub05 

do
	echo ${sub}
	echo "\033[1;33m STARTING SUBJECT:  ${sub} \033[0m"
	export tp1Path=/home/MRIdata/DTI/CMP/${sub}/tp1

	set prepath="/home/MRIdata/DTI/CMP" 
#=====================================================================================================
#-----------------STEP 1, INITIALIZING: MAKE DIRECTORIES, FILL WITH RAW DATA-------------------------#
#=====================================================================================================
#make subject's directory and subdirectories for the second tractography 

	mkdir -p ${prepath}/${sub}/tp1_s16_a60_f15_sm/{RAWDATA/{DTI,T1},NIFTI/transformations,CMP/{raw_diffusion/{2x2x2,dti_0},fibers,scalars}}

	echo "\033[1;33m Done initializing subdirectories for ${sub} \033[0m"

	export tp1_s16_a60_f15_sm=${prepath}/${sub}/tp1_s16_a60_f15_sm

#copy any old dicom (here small scout image) into RAWDATA DTI and T1 directories (later you'll put the real data in NIFTI folder)

	cp ${prepath}/dummy_dicoms/*.dcm  ${tp1_s16_a60_f15_sm}/RAWDATA/T1
	cp ${prepath}/dummy_dicoms/*.dcm  ${tp1_s16_a60_f15_sm}/RAWDATA/DTI

#copy necessary diffusion image data, t1s, and parcellated/segmented data from first tractography

	cp ${tp1Path}/NIFTI/Diffusion_b0_resampled.nii.gz  ${tp1_s16_a60_f15_sm}/NIFTI/
	cp ${tp1Path}/NIFTI/T1-TO-b0.nii.gz  ${tp1_s16_a60_f15_sm}/NIFTI/
	cp ${tp1Path}/NIFTI/T1.nii.gz  ${tp1_s16_a60_f15_sm}/NIFTI/
	cp ${tp1Path}/NIFTI/T12B0.mat  ${tp1_s16_a60_f15_sm}/NIFTI/
	cp ${tp1Path}/NIFTI/transformations/T1-TO-b0.mat  ${tp1_s16_a60_f15_sm}/NIFTI/transformations/
	cp ${tp1Path}/CMP/raw_diffusion/dti_0/DTI_masked.nii.gz  ${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/
	cp ${tp1Path}/CMP/raw_diffusion/dti_0/DTI_first_mask.nii.gz  ${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/
	cp ${tp1Path}/CMP/scalars/dti*  ${tp1_s16_a60_f15_sm}/CMP/scalars/
	cp ${tp1Path}/CMP/scalars/dti*  ${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/
	cp -r ${tp1Path}/CMP/fs_output  ${tp1_s16_a60_f15_sm}/CMP/
	cp ${tp1Path}/CMP/raw_diffusion/dti_0/gtable_rot_4tvT_z-xy.txt  ${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/

#Register the Lausanne parcellation map with ROIs to the diffusion data (mask from b0)

	flirt -in ${tp1_s16_a60_f15_sm}/CMP/fs_output/HR__registered-TO-b0/scale33/ROIv_HR_th.nii.gz -ref ${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/DTI_first_mask.nii.gz -out ${tp1_s16_a60_f15_sm}/CMP/fs_output/HR__registered-TO-b0/scale33/ROIv_HR_th_1.7iso.nii.gz -applyxfm -init ${tp1_s16_a60_f15_sm}/NIFTI/transformations/T1-TO-b0.mat -interp nearestneighbour
	


#=======================================================================================================
#-STEP 2, DTI:  PERFORM TRACTOGRAPHY
#=======================================================================================================
#DO DTI RECONSTRUCTION AND TRACKING

	echo "\033[1;33m DOING DTI RECONSTRUCTION AND TRACTOGRAPHY FOR SUBJECT ${sub}... \033[0m"
#---------------------------------------------------------
#---------------------------------------------------------

 
	dti_tracker "${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/dti" "${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/track_tmp_a60_f15_rseed16sm.trk" -at 60 -m "${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/DTI_first_mask.nii.gz" 1 1 -m2 "${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/dti_fa.nii" 0.2 -sm "${tp1_s16_a60_f15_sm}/CMP/fs_output/HR__registered-TO-b0/scale33/ROIv_HR_th_1.7iso.nii.gz" 1 83 -it nii -rseed 16
	spline_filter "${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/track_tmp_a60_f15_rseed16sm.trk" 1 "${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/dti_a60_f15_rseed16sm.trk" 


#=======================================================================================================
#-STEP 3, MOVE TRACTOGRAPHY FOR FUTURE CONNECTOME FILES
#=======================================================================================================
	mv ${tp1_s16_a60_f15_sm}/CMP/raw_diffusion/dti_0/dti_a60_f15_rseed16sm.trk ${tp1_s16_a60_f15_sm}/CMP/fibers/streamline.trk
	cp ${tp1_s16_a60_f15_sm}/CMP/fibers/streamline.trk ${tp1_s16_a60_f15_sm}/CMP/fibers/streamline_filtered.trk


#=====================================================================================================
#-----------------rename adc as adc_real and make rd and call it adc for connectome purposes-------------------------#
#=====================================================================================================

	cd ${prepath}/${sub}/tp1_s16_a60_f15_sm/CMP/scalars
	fslmaths dti_e2.nii.gz -add dti_e3.nii.gz dti_e2pluse3.nii.gz
	fslmaths dti_e2pluse3.nii.gz -div 2 dti_rd.nii.gz
	mv dti_adc.nii.gz dti_adc_real.nii.gz
	cp dti_rd.nii.gz dti_adc.nii.gz
	mv dti_rd.nii.gz dti_rd_sameASadc.nii.gz

	cp -R ${prepath}/${sub}/tp1/FREESURFER/ ${prepath}/${sub}/tp1_s16_a60_f15_sm/FREESURFER/


#=====================================================================================================
	cd ${prepath}/${sub}/tp1_s16_a60_f15_sm/CMP/scalars
	ls dti_rd.*
#=====================================================================================================
done

echo "\033[1;33m THIS IS THE END. \033[0m"
