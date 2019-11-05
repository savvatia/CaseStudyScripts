#!/bin/tcsh

#==================================================================================================================#
#----This script is for taking raw dti dicom  and producing dti reconstructed maps and tractography-------#
#----Based on a script authored by Duke Shereen and edited by Danny Siu & Salomi Asaridou--------------------------#
#==================================================================================================================#

#--------------------STEPS:---------------------------------#
#STEP 1, INITIALIZING: MAKE DIRECTORIES, FILL WITH RAW DATA
#STEP 2, DTI: EDDY CURRENT CORRECT, MASK DTI, PERFORM RECONSTRUCTIONS AND TRACTOGRAPHY
#STEP 3, REGISTRATION:  UPSAMPLE B0 TO 1MM^3 AND REGISTER T1 TO IT
#-----------------------------------------------------------#

#=====================================================================================================
#-----------------STEP 1, INITIALIZING: MAKE DIRECTORIES, FILL WITH RAW DATA-------------------------#
#=====================================================================================================

set FSdir="/home/MRIdata/fs/subjects"
set prepath="/home/MRIdata/DTI/CMP" 

echo "\033[1;33m START SCRIPT... \033[0m"

foreach sub ( sub01 sub02 sub03 sub04 sub05 ) #PUT ALL SUBJECTS HERE
	echo "\033[1;33m START SUBJECT ${sub}... \033[0m"
	echo "\033[1;33m MAKING DIRECTORIES FOR SUBJECT ${sub}... \033[0m"

#make subject's directory and subdirectories
	mkdir -p ${prepath}/${sub}/dMRI/tp1/{RAWDATA/{DTI,T1},NIFTI/transformations,CMP/{raw_diffusion/{2x2x2,dti_0},fibers,scalars}}
#copy any old dicom (here small scout image) into RAWDATA DTI and T1 directories (later you'll put the real data in NIFTI folder)
	cp  ${prepath}/dummy_dicoms/*.dcm  ${prepath}/${sub}/tp1/RAWDATA/DTI/
	cp  ${prepath}/dummy_dicoms/*.dcm  ${prepath}/${sub}/tp1/RAWDATA/T1/
	mkdir -p ${prepath}/${sub}/tp1/CMP/raw_diffusion/conversions

#====CONVERT THE DTI DCM TO NIFTI

module load dcm2niix
	
echo "\033[1;33m CONVERTING DTI TO NIFTI FOR SUBJECT ${sub}... \033[0m"

dcm2niix -f data_unreg -z y -o /home/MRIdata/scans/${sub}/DWI/DICOM/ /home/MRIdata/scans/${sub}/DWI/DICOM/

cd ${prepath}/${sub}/tp1/CMP/raw_diffusion/conversions/

cp /home/MRIdata/scans/${sub}/DWI/DICOM/data_unreg.nii.gz .
cp /home/MRIdata/scans/${sub}/DWI/DICOM/bvals .
cp /home/MRIdata/scans/${sub}/DWI/DICOM/bvecs .

mv *data_unreg*.nii DTI-${sub}.nii
gzip DTI-${sub}.nii
mv bvecs bvec		
mv bvals bval

mv DTI-${sub}.nii.gz ${prepath}/${sub}/tp1/NIFTI/
mv bval ${prepath}/${sub}/tp1/NIFTI/bval
mv bvec ${prepath}/${sub}/tp1/NIFTI/bvec

#=====COPY THE T1 NIFTI co file TO NIFTI FOLDER AND RENAME

set T1run="T1"

	cp ${FSdir}/${sub}/mri/brain.nii.gz ${prepath}/${sub}/tp1/CMP/raw_diffusion/conversions/
	mv ${prepath}/${sub}/tp1/CMP/raw_diffusion/conversions/brain.nii.gz ${prepath}/${sub}/tp1/NIFTI/T1-${sub}.nii.gz

#=====DELETE CONVERSIONS FOLDER
	rm -rf ${prepath}/${sub}/tp1/CMP/raw_diffusion/conversions/

#=======================================================================================================
#-STEP 2, DTI:  EDDY CURRENT CORRECT, MASK DTI, PERFORM RECONSTRUCTIONS AND TRACTOGRAPHY
#=======================================================================================================

#PERFORM EDDY CURRENT CORRECTION
	cd ${prepath}/${sub}/tp1/NIFTI/
echo "\033[1;33m ECC prep FOR SUBJECT ${sub}... \033[0m"
	setenv PATH ${PATH}:/cnari/hand_motor/virtual_brain/tools
echo "\033[1;33m ECC start ECC ${sub}... \033[0m"


module load fsl/5.0.10
module load afni/v17.3.07
module load matlab

eddy_correct DTI-${sub}.nii.gz DTI-${sub}_ecc.nii.gz 1

echo "\033[1;33m DONE ECC FOR SUBJECT MS-MIR-${sub}... \033[0m" 

mv DTI-${sub}_ecc.nii.gz ${prepath}/${sub}/tp1/CMP/raw_diffusion/dti_0
mv bv* ${prepath}/${sub}/tp1/CMP/raw_diffusion/dti_0

#CHANGE DIRECTORIES

cd ${prepath}/${sub}/tp1/CMP/raw_diffusion/dti_0/

#MASK THE DTI:
	
echo "\033[1;33m MASKING AND RENAMING DTI DATA FOR SUBJECT ${sub}... \033[0m" 

#CHANGE "1" IN LINE BELOW TO REFLECT THE B0 OF YOUR CHOICE
	fslroi DTI-${sub}_ecc.nii.gz DTI_b0.nii.gz 1 1
	bet DTI_b0.nii.gz DTI_first.nii.gz -f 0.2 -m
	3dmask_tool -input DTI_first_mask.nii.gz -prefix DTI_first_mask_dilate.nii.gz -dilate_input -2
	fslmaths DTI-${sub}_ecc.nii.gz -mas DTI_first_mask_dilate.nii.gz DTI_masked.nii.gz

#create gradient tables for trackvis and copy eddy current corrected file into folder where recon takes place

echo "\033[1;33m MAKE GRADIENT TABLES and FOR SUBJECT ${sub}... \033[0m"
	cat bvec bval > gtable_rot_4tv
	1dtranspose gtable_rot_4tv | awk '{print $3,"\t",-1*$1,"\t",$2,"\t",$4}' > gtable_rot_4tvT_z-xy.txt

#The following lines replace the SIEMENS coded "5" in the bvals text file with "0" and the respective bvecs to "0" as well, otherwise dti_recon cannot read the file

matlab -nosplash -nodesktop -r "gtable = load('gtable_rot_4tvT_z-xy.txt'); gtable(find(gtable(:,4) == 5),:) = 0; gtable(find(gtable(:,4) == 0),:) = 0; save('gtable_rot_4tvT_z-xy_corrected.txt', 'gtable', '-ascii'); exit" | tail -n +16


#DO DTI RECONSTRUCTION AND TRACKING
echo "\033[1;33m DOING DTI RECONSTRUCTION AND TRACTOGRAPHY FOR SUBJECT MY BRAIN... \033[0m"
	setenv PATH ${PATH}:/home/tools/dtk
#See trackvis website to pick proper arguments
	dti_recon "DTI_masked.nii.gz" "dti" -gm "gtable_rot_4tvT_z-xy_corrected.txt" 1 -b 2005 -b0 2 -sag -p 3 -sn 1 -ot nii -oc
	dti_tracker "dti" "track_tmp.trk" -at 60 -m "dti_fa.nii" 0.2 -it nii
	spline_filter "track_tmp.trk" 1 "dti.trk" 
#PUT STUFF WHERE IT BELONGS
	mv dti.trk ../../fibers/streamline.trk
	gzip *nii*
	cp * ../../scalars

#=====================================================================================================================
#-STEP 3, REGISTRATION: UPSAMPLE B0 TO 1MM^3 AND REGISTER T1 TO IT, BRING IN THE TVB'D, UMMM, VBT'D INTO NIFTI FOLDER
#=====================================================================================================================

#CHANGE CURRENT DIRECTORY
	cd ${prepath}/${sub}/tp1/NIFTI

#RESAMPLE B0 AND ALIGN T1 TO IT
echo "\033[1;33m REGISTERING T1 TO B0 FOR SUBJECT ${sub}... \033[0m"
	cp ${prepath}/${sub}/tp1/CMP/raw_diffusion/dti_0/DTI_first.nii.gz .
	mv DTI_first.nii.gz DTI_b0.nii.gz
#INEZ: CHECK IF YOUR T1S ARE 1 MM ISO, IF NOT CHANGE BELOW
	3dresample -dxyz 1.0 1.0 1.0 -prefix Diffusion_b0_resampled.nii -inset DTI_b0.nii.gz
	gzip Diffusion_b0_resampled.nii
#ZEROPAD T1 & B0
	3dZeropad -S 10 -prefix pad_T1-${sub}.nii.gz T1-${sub}.nii.gz
	3dZeropad -S 10 -prefix pad_Diffusion_b0_resampled.nii.gz Diffusion_b0_resampled.nii.gz 
#BRAIN EXTRACT T1 PRIOR TO ALIGNMENT
	bet pad_T1-${sub}.nii.gz T1_bet.nii.gz -f 0.25 -B
	flirt -in T1_bet.nii.gz -ref pad_Diffusion_b0_resampled.nii.gz -out T1-TO-b0_bet.nii.gz -cost normmi -omat T12B0.mat -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6
	flirt -in pad_T1-${sub}.nii.gz -ref pad_Diffusion_b0_resampled.nii.gz -out T1-TO-b0.nii.gz -applyxfm -init T12B0.mat
	cp T1-TO-b0.nii.gz T1.nii.gz

#CREATE IDENTITY TRANSFORMATION FOR T1.NII.GZ TO T1-TO-B0.NII.GZ

cp /home/scripts/misc/T1-TO-b0.mat ${prepath}/${sub}/tp1/NIFTI/transformations/T1-TO-b0.mat
echo "\033[1;33m moving tp1 to subject directory. \033[0m"

echo "\033[1;33m FINISHED PREPROC FOR SUBJECT ${sub}... \033[0m"

end

echo "\033[1;33m THIS IS THE END. \033[0m"

