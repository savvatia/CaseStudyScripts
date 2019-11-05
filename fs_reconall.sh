#!/bin/bash


module load freesurfer/6.0

1. Perform freesurfer reconstruction on T1

FSdir='/home/MRIdata/fs/subjects'

cd ${FSdir}

export FREESURFER_HOME=/data/apps/freesurfer/6.0
source $FREESURFER_HOME/sources.sh    
export SUBJECTS_DIR=`pwd`

for sub in sub01 sub02 sub03 sub04 sub05 #PUT ALL SUBJECTS HERE

do

firstdicom=$(ls -t /home/MRIdata/scans/${sub}/MPRAGE/DICOM/*.dcm | head -n 1)

echo $firstdicom

recon-all -subjid ${sub} -i $firstdicom -parallel -openmp 20 -all 


done

#2. Convert skull stripped brain to nifti

for sub in sub01 sub02 sub03 sub04 sub05 

do

mri_convert ${FSdir}/${sub}/mri/norm.mgz ${FSdir}/${sub}/mri/brain.nii.gz

done

