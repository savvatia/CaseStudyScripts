#!/bin/bash

module load freesurfer/6.0
module load connectome_workbench

#THIS SCRIPT MAPS THE TSTAT IMAGE FOR A SPECIFIED CONDITION/CONTRAST TO THE SURFACE FOR CONNECTOME WORKBENCH IMAGES

export FREESURFER_HOME=/data/apps/freesurfer/6.0
source $FREESURFER_HOME/sources.sh
export SUBJECTS_DIR=`pwd`


Meshdir='/home/MRIdata/fs/standard_mesh_atlases'



for subj in sub01 sub02 sub03 

do

	FSdir="/home/MRIdata/fs/subjects/${subj}/surf/"
	Outdir="/home/MRIdata/task/subjects/${subj}/"

#1. Convert Freesurfer surfaces to .gii files

cd ${FSdir}

	for hemi in lh rh

	do

		mris_convert --cras_correction $hemi.white $hemi.white.gii
		mris_convert --cras_correction $hemi.pial $hemi.pial.gii
		mris_convert --cras_correction $hemi.infated $hemi.infated.gii


#2. Create midthickness surface

		wb_command -surface-average -surf $hemi.white.gii -surf $hemi.pial.gii $hemi.midthickness.surf.gii


	done

#3. Map functional tstats nii image to surface

cd ${Outdir}

	for hemi in lh rh

	do
		for i in taskCondition1 taskCondition2

		do

			wb_command -volume-to-surface-mapping ${subj}_${i}.nii.gz ${FSdir}/${hemi}.midthickness.surf.gii ${hemi}.${i}.tstats.func.gii -trilinear

		done

	done


#4. Get native FS data to fs_LR standard space

cd ${FSdir}

wb_shortcuts -freesurfer-resample-prep lh.white lh.pial lh.sphere.reg $Meshdir/resample_fsaverage/fs_LR-deformed_to-fsaverage.L.sphere.164k_fs_LR.surf.gii lh.midthickness.surf.gii lh.midthickness.164k_fs_LR.surf.gii lh.sphere.reg.surf.gii

wb_shortcuts -freesurfer-resample-prep rh.white rh.pial rh.sphere.reg $Meshdir/resample_fsaverage/fs_LR-deformed_to-fsaverage.R.sphere.164k_fs_LR.surf.gii rh.midthickness.surf.gii rh.midthickness.164k_fs_LR.surf.gii rh.sphere.reg.surf.gii


#5. Get functional data to fs_LR standard space

cd ${Outdir}

	for i in taskCondition1 taskCondition2

	do

		wb_command -metric-resample lh.${i}.tstats.func.gii ${FSdir}lh.sphere.reg.surf.gii ${Meshdir}/resample_fsaverage/fs_LR-deformed_to-fsaverage.L.sphere.164k_fs_LR.surf.gii ADAP_BARY_AREA ${subj}.${i}.tstats.lh.168k_fs_LR.func.gii  -area-surfs ${FSdir}lh.midthickness.surf.gii  ${FSdir}lh.midthickness.164k_fs_LR.surf.gii

		wb_command -metric-resample  rh.${i}.tstats.func.gii ${FSdir}rh.sphere.reg.surf.gii ${Meshdir}/resample_fsaverage/fs_LR-deformed_to-fsaverage.R.sphere.164k_fs_LR.surf.gii ADAP_BARY_AREA ${subj}.${i}.tstats.rh.168k_fs_LR.func.gii  -area-surfs ${FSdir}rh.midthickness.surf.gii  ${FSdir}rh.midthickness.164k_fs_LR.surf.gii

	done


#6. Binarize the maps
	for hemi in lh rh
	do
		for i in taskCondition1 taskCondition2
		do
			wb_command -metric-math "(x>0.9)" ${subj}.${i}.${hemi}.TstatMask.func.gii -var x ${subj}.${i}.tstats.${hemi}.168k_fs_LR.func.gii

		done
	done


echo $subj "done!"
done
