# CaseStudyScripts
This repository contains experiment code and analysis code associated with Asaridou, Demir-Lira, Goldin-Meadow, Levine, &amp; Small article, "Language development and brain reorganization in a child born without the left hemisphere".

Preprocessing & Statistical analysis:
	fMRI: Bash code for running AFNI preprocessing, T-tests
	DWI: Bash code for running diffusion preprocessing


1. fs_reconall.sh: runs Freesurfer reconstruction & converts the skull stripped brain into nifti format
2. 1.dti.sh: makes all the necessary directories for Connectome Mapper Toolkit to run, fills the directory with raw data, converts dicoms to nii, runs eddy current correction, performs the diffusion tensor estimation, tractography and T1 to Diffusion registration 
3. 2.dti.sh: parallelizes and runs connectomemapper 
4. convert_gpickle2mat_func.py: this function converts the gpickle output from connectomemapper to a mat file that can be processed with the matlab-based Brain Connectivity Toolbox.
5. 3.dti.sh: refines the tractography by using 16 random seeds, angle of 60 degrees, and FA threshold of 0.15, as well as a seed mask option "-sm" with the Connectome Mapper Lausanne parcellations as the mask
6. Run 2.dti.sh again to get the connectivity matrices for the second, refined, tractography
7. 4.dti.m: Extracting graph theoretical network measures from tractography connectivity matrices from previous steps using the Brain Connectivity Toolbox (brain-connectivity-toolbox.net) 
8. fmri_native_space.sh: runs the fMRI task preprocessing and 3dDeconvolve in each subject's native space (aligning EPI to the freesurfer T1) in order to get z-stats for each contrast and overlay it on a common surface using HCP workbench 
9. fmri_MNI_space.sh: runs the fMRI task preprocessing and 3dDeconvolve in common space (aligning EPI and the freesurfer T1 to the pediatric MNI template)
10. groupTD_Ttest.sh: This script runs a One-Sample T-test on the story vs. baseline contrast at the group level for TD children
11. singleton_Ttest.sh: This script runs a TD group vs. Case Singleton T-test on the story vs. baseline contrast
12. fs2wb.sh: this script creates the Freesurfer's fsaverage mid thickness images necessary for surface images with connectome workbench 
13. convert_tstat2wb.sh: this script maps the t-stat image for a specified condition/contrast to the surface for connectome workbench images

