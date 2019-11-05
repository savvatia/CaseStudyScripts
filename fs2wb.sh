#!/bin/bash

module load freesurfer/6.0
module load connectome_workbench

#THIS SCRIPT CREATES THE FSAVERAGE INFLATED SURFACE FOR CONNECTOME WORKBENCH IMAGES

FSdir='/home/MRIdata/fs/subjects'

cd ${FSdir}

export FREESURFER_HOME=/data/apps/freesurfer/6.0
source $FREESURFER_HOME/sources.sh    
export SUBJECTS_DIR=`pwd`

cd fsaverage/surf/

#1. Convert the fs files to gifti

mris_convert lh.white lh.white.gii
mris_convert lh.pial lh.pial.gii
mris_convert rh.pial rh.pial.gii
mris_convert rh.white rh.white.gii

#2. Estimate the mid thickness surface

wb_command -surface-average -surf lh.white.gii -surf lh.pial.gii lh.midthickness.surf.gii
wb_command -surface-average -surf rh.white.gii -surf rh.pial.gii rh.midthickness.surf.gii


#3. Resample to standard space

wb_shortcuts -freesurfer-resample-prep lh.white lh.pial lh.sphere.reg /home/MRIdata/fs/standard_mesh_atlases/resample_fsaverage/fs_LR-deformed_to-fsaverage.L.sphere.164k_fs_LR.surf.gii lh.midthickness.surf.gii lh.midthickness.164k_fs_LR.surf.gii lh.sphere.reg.surf.gii

wb_shortcuts -freesurfer-resample-prep rh.white rh.pial rh.sphere.reg /home/MRIdata/fs/standard_mesh_atlases/resample_fsaverage/fs_LR-deformed_to-fsaverage.R.sphere.164k_fs_LR.surf.gii rh.midthickness.surf.gii rh.midthickness.164k_fs_LR.surf.gii rh.sphere.reg.surf.gii

#4. Generate inflated and very inflated mid thickness surfaces

wb_command -surface-generate-inflated rh.midthickness.164k_fs_LR.surf.gii rh.fsaverage.inflated.surf.gii rh.fsaverage.veryinflated.surf.gii -iterations-scale 6
wb_command -surface-generate-inflated lh.midthickness.164k_fs_LR.surf.gii lh.fsaverage.inflated.surf.gii lh.fsaverage.veryinflated.surf.gii -iterations-scale 6
