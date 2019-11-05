#!/bin/tcsh


module load afni/v17.3.07


#SSA. This script runs 3dDeconvolve in MNI space in order to get group statistics
#Prerequisite: run fs_reconall.sh

# =========================== auto block: setup ============================
# script setup

# prepare to count setup errors
set nerrors = 0

# take note of the AFNI version
afni -ver


foreach subj (sub01 sub02 sub03 sub04 sub05) 

set	top_path  = "/home/MRIdata/fMRI/subjects/"

# assign output directory name
set output_dir = ${top_path}${subj}/task/MNISpace/

#create output_dir if it does not exist
if (-e "${output_dir}") then
    echo "output directory exists"
else
    mkdir ${output_dir}
endif
   

# set list of runs
set runs = (`count -digits 2 1 2`)

# create results and stimuli directories
mkdir $output_dir
mkdir $output_dir/stimuli
@ nerrors += $status      # accumulate error count


# convert dicoms to BRIK/HEAD format and copy file to outputdir

echo "Converting dicoms for ${subj}"

foreach run ( $runs )

cd ${top_path}${subj}/raw/taskRun${runs}/

	Dimon -infile_pattern '*.dcm' -dicom_org -use_obl_origin -gert_create_dataset

	#Rename
	3dcopy OutBrick_run_*+orig ${output_dir}/ts.${subj}.task${runs}

end


# copy stim files into stimulus directory
cp ${top_path}/${subj}/task/Onsets_Dur/context.1D   \
    ${top_path}/${subj}/task/Onsets_Dur/ISI.1D      \
    ${top_path}/${subj}/task/Onsets_Dur/response.1D \
    ${top_path}/${subj}/task/Onsets_Dur/surprise.1D \
    ${top_path}/${subj}/task/Onsets_Dur/TNI.1D      \
    ${top_path}/${subj}/task/Onsets_Dur/unsurpr.1D $output_dir/stimuli
@ nerrors += $status      # accumulate error count


# copy anatomy 
3dcopy /home/fs/subjects/${subj}/mri/brain.nii.gz \
    $output_dir/T1.${subj}
@ nerrors += $status      # accumulate error count

# check for any setup failures
if ( $nerrors > 0 ) then
    echo '** setup failure ($nerrors errors)'
    exit
endif

# ============================ auto block: tcat ============================
# apply 3dTcat to copy input dsets to results dir, while
# removing the first 0 TRs
3dTcat -prefix $output_dir/pb00.$subj.r01.tcat \
    ${top_path}/${subj}/task/ts.${subj}.task01+orig'[0..$]'
3dTcat -prefix $output_dir/pb00.$subj.r02.tcat \
    ${top_path}/${subj}/task/ts.${subj}.task02+orig'[0..$]'



# -------------------------------------------------------
# enter the results directory (can begin processing data)
cd $output_dir


# and make note of repetitions (TRs) per run

set run_TRs1 = `3dinfo -verb pb00.$subj.r01.tcat+orig | grep "Number of time steps =" | awk -F"Number of time steps = " '{sub(/ .*/,"",$2);print $2}'`
set run_TRs2 = `3dinfo -verb pb00.$subj.r02.tcat+orig | grep "Number of time steps =" | awk -F"Number of time steps = " '{sub(/ .*/,"",$2);print $2}'`

set tr_counts = ( ${run_TRs1} ${run_TRs2} )




# ========================== auto block: outcount ==========================
# data check: compute outlier fraction for each volume
touch out.pre_ss_warn.txt
foreach run ( $runs )
    3dToutcount -automask -fraction -polort 3 -legendre                     \
                pb00.$subj.r$run.tcat+orig > outcount.r$run.1D

    # censor outlier TRs per run, ignoring the first 0 TRs
    # - censor when more than 0.1 of automask voxels are outliers
    # - step() defines which TRs to remove via censoring
    1deval -a outcount.r$run.1D -expr "1-step(a-0.1)" > rm.out.cen.r$run.1D

    # outliers at TR 0 might suggest pre-steady state TRs
    if ( `1deval -a outcount.r$run.1D"{0}" -expr "step(a-0.4)"` ) then
        echo "** TR #0 outliers: possible pre-steady state TRs in run $run" \
            >> out.pre_ss_warn.txt
    endif
end

# catenate outlier counts into a single time series
cat outcount.r*.1D > outcount_rall.1D

# catenate outlier censor files into a single time series
cat rm.out.cen.r*.1D > outcount_${subj}_censor.1D

# get run number and TR index for minimum outlier volume
set minindex = `3dTstat -argmin -prefix - outcount_rall.1D\'`
set ovals = ( `1d_tool.py -set_run_lengths $tr_counts                       \
                          -index_to_run_tr $minindex` )
# save run and TR indices for extraction of vr_base_min_outlier
set minoutrun = $ovals[1]
set minouttr  = $ovals[2]
echo "min outlier: run $minoutrun, TR $minouttr" | tee out.min_outlier.txt

# ================================ despike =================================
# apply 3dDespike to each run
foreach run ( $runs )
    3dDespike -NEW -nomask -prefix pb01.$subj.r$run.despike \
        pb00.$subj.r$run.tcat+orig
end

# ================================= tshift =================================
# time shift data so all slice timing is the same 
foreach run ( $runs )
    3dTshift -tzero 0 -quintic -prefix pb02.$subj.r$run.tshift \
             -tpattern seq+z           \
             pb01.$subj.r$run.despike+orig
end

# --------------------------------
# extract volreg registration base
3dbucket -prefix vr_base_min_outlier                           \
    pb02.$subj.r$minoutrun.tshift+orig"[$minouttr]"

# ================================= align ==================================
# for e2a: compute anat alignment transformation to EPI registration base
# (new anat will be intermediate, stripped, T1.${subj}+orig)
align_epi_anat.py -anat2epi -anat T1.${subj}+orig \
       -anat_has_skull no -suffix _al_junk        \
       -epi vr_base_min_outlier+orig -epi_base 0                \
       -epi_strip 3dAutomask                                    \
       -cost lpc+ZZ -giant_move                                 \
       -volreg off -tshift off


# ================================== tlrc ==================================
# warp anatomy to standard space
@auto_tlrc -base                \
             ${top_path}/AFNI_analysis/subjects/atlas/T1_pediatric_asym_13_18.nii \
             -input T1.${subj}+orig -no_ss \
             -init_xform AUTO_CENTER

# store forward transformation matrix in a text file
cat_matvec T1.${subj}+tlrc::WARP_DATA -I > warp.anat.Xat.1D



# ================================= volreg =================================
# align each dset to base volume, align to anat

# register and warp
foreach run ( $runs )
    # register each volume to the base
    3dvolreg -verbose -zpad 1 -base vr_base_min_outlier+orig            \
             -1Dfile dfile.r$run.1D -prefix rm.epi.volreg.r$run         \
             -cubic                                                     \
             -1Dmatrix_save mat.r$run.vr.aff12.1D                       \
             pb02.$subj.r$run.tshift+orig

    # create an all-1 dataset to mask the extents of the warp
    3dcalc -overwrite -a pb02.$subj.r$run.tshift+orig -expr 1           \
           -prefix rm.epi.all1

    # catenate volreg/epi2anat xforms
    cat_matvec -ONELINE                                                 \
               T1.${subj}_al_junk_mat.aff12.1D -I         \
               mat.r$run.vr.aff12.1D > mat.r$run.warp.aff12.1D

    # apply catenated xform: volreg/epi2anat
    3dAllineate -base T1.${subj}+orig                  \
                -input pb02.$subj.r$run.tshift+orig                     \
                -1Dmatrix_apply mat.r$run.warp.aff12.1D                 \
                -mast_dxyz 2                                            \
                -prefix rm.epi.nomask.r$run

    # warp the all-1 dataset for extents masking 
    3dAllineate -base T1.${subj}+orig                  \
                -input rm.epi.all1+orig                                 \
                -1Dmatrix_apply mat.r$run.warp.aff12.1D                 \
                -mast_dxyz 2 -final NN -quiet                           \
                -prefix rm.epi.1.r$run

    # make an extents intersection mask of this run
    3dTstat -min -prefix rm.epi.min.r$run rm.epi.1.r$run+orig
end

# make a single file of registration params
cat dfile.r*.1D > dfile_rall.1D

# ----------------------------------------
# create the extents mask: mask_epi_extents+tlrc
# (this is a mask of voxels that have valid data at every TR)
3dMean -datum short -prefix rm.epi.mean rm.epi.min.r*.HEAD 
3dcalc -a rm.epi.mean+tlrc -expr 'step(a-0.999)' -prefix mask_epi_extents

# and apply the extents mask to the EPI data 
# (delete any time series with missing data)
foreach run ( $runs )
    3dcalc -a rm.epi.nomask.r$run+tlrc -b mask_epi_extents+tlrc  \
           -expr 'a*b' -prefix pb03.$sub.r$run.volreg
end

# warp the volreg base EPI dataset to make a final version
cat_matvec -ONELINE                                              \
           T1.${sub}+tlrc::WARP_DATA -I        \
           T1.${sub}_al_junk_mat.aff12.1D -I  >   \
           mat.basewarp.aff12.1D

3dAllineate -base T1.${sub}+tlrc               \
            -input vr_base_min_outlier+orig                      \
            -1Dmatrix_apply mat.basewarp.aff12.1D                \
            -mast_dxyz 2                                         \
            -prefix final_epi_vr_base_min_outlier

# create an anat_final dataset, aligned with stats
3dcopy T1.${sub}+tlrc anat_final.$sub

# record final registration costs
3dAllineate -base final_epi_vr_base_min_outlier+tlrc -allcostX   \
            -input anat_final.$sub+tlrc |& tee out.allcostX.txt


 
echo "${sub} EPI alignment done!"


# ================================== blur ==================================
# blur each volume of each run
foreach run ( $runs )
    3dBlurToFWHM -FWHM 8 -automask                   \
                 -input pb03.$subj.r$run.volreg+tlrc \
                 -prefix pb04.$subj.r$run.blur 
end

# ================================== mask ==================================
# create 'full_mask' dataset (union mask)
foreach run ( $runs )
    3dAutomask -dilate 1 -prefix rm.mask_r$run pb04.$subj.r$run.blur+tlrc
end

# create union of inputs, output type is byte
3dmask_tool -inputs rm.mask_r*+tlrc.HEAD -union -prefix full_mask.$subj

# ---- create subject anatomy mask, mask_anat.$subj+tlrc ----
#      (resampled from aligned anat)
3dresample -master full_mask.$subj+tlrc -input                       \
           T1.${subj}+tlrc                          \
           -prefix rm.resam.anat

# convert to binary anat mask; fill gaps and holes
3dmask_tool -dilate_input 5 -5 -fill_holes -input rm.resam.anat+tlrc \
            -prefix mask_anat.$subj

# compute overlaps between anat and EPI masks
3dABoverlap -no_automask full_mask.$subj+tlrc mask_anat.$subj+tlrc   \
            |& tee out.mask_ae_overlap.txt

# note Dice coefficient of masks, as well
3ddot -dodice full_mask.$subj+tlrc mask_anat.$subj+tlrc              \
      |& tee out.mask_ae_dice.txt

# ---- segment anatomy into classes CSF/GM/WM ----
3dSeg -anat anat_final.$subj+tlrc -mask AUTO -classes 'CSF ; GM ; WM'

# copy resulting Classes dataset to current directory
3dcopy Segsy/Classes+tlrc .

# make individual ROI masks for regression (CSF GM WM and CSFe GMe WMe)
foreach class ( CSF GM WM )
   # unitize and resample individual class mask from composite
   3dmask_tool -input Segsy/Classes+tlrc"<$class>"                   \
               -prefix rm.mask_${class}
   3dresample -master pb04.$subj.r01.blur+tlrc -rmode NN             \
              -input rm.mask_${class}+tlrc -prefix mask_${class}_resam
   # also, generate eroded masks
   3dmask_tool -input Segsy/Classes+tlrc"<$class>" -dilate_input -1  \
               -prefix rm.mask_${class}e
   3dresample -master pb04.$subj.r01.blur+tlrc -rmode NN             \
              -input rm.mask_${class}e+tlrc -prefix mask_${class}e_resam
end

# ================================= scale ==================================
# scale each voxel time series to have a mean of 100
# (be sure no negatives creep in)
# (subject to a range of [0,200])
foreach run ( $runs )
    3dTstat -prefix rm.mean_r$run pb04.$subj.r$run.blur+tlrc
    3dcalc -a pb04.$subj.r$run.blur+tlrc -b rm.mean_r$run+tlrc \
           -c mask_epi_extents+tlrc                            \
           -expr 'c * min(200, a/b*100)*step(a)*step(b)'       \
           -prefix pb05.$subj.r$run.scale
end

# ================================ regress =================================

# compute de-meaned motion parameters (for use in regression)
1d_tool.py -infile dfile_rall.1D -set_run_lengths ${run_TRs1} ${run_TRs2}                \
           -demean -write motion_demean.1D

# compute motion parameter derivatives (just to have)
1d_tool.py -infile dfile_rall.1D -set_run_lengths ${run_TRs1} ${run_TRs2}                \
           -derivative -demean -write motion_deriv.1D

# create censor file motion_${subj}_censor.1D, for censoring motion 
1d_tool.py -infile dfile_rall.1D -set_run_lengths ${run_TRs1} ${run_TRs2}                \
    -show_censor_count -censor_prev_TR                                   \
    -censor_motion 0.2 motion_${subj}

# combine multiple censor files
1deval -a motion_${subj}_censor.1D -b outcount_${subj}_censor.1D         \
       -expr "a*b" > censor_${subj}_combined_2.1D

# ------------------------------
# create 2 ROI regressors: WMe, CSFe
# (get each ROI average time series and remove resulting mean)
foreach run ( $runs )
    3dmaskave -quiet -mask mask_WMe_resam+tlrc                           \
              pb03.$subj.r$run.volreg+tlrc                               \
            | 1d_tool.py -infile - -demean -write rm.ROI.WMe.r$run.1D
    3dmaskave -quiet -mask mask_CSFe_resam+tlrc                          \
              pb03.$subj.r$run.volreg+tlrc                               \
            | 1d_tool.py -infile - -demean -write rm.ROI.CSFe.r$run.1D
end
# and catenate the demeaned ROI averages across runs
cat rm.ROI.WMe.r*.1D > ROI.WMe_rall.1D
cat rm.ROI.CSFe.r*.1D > ROI.CSFe_rall.1D

# note TRs that were not censored
set ktrs = `1d_tool.py -infile censor_${subj}_combined_2.1D              \
                       -show_trs_uncensored encoded`

# ------------------------------
# run the regression analysis
3dDeconvolve -input pb05.$subj.r*.scale+tlrc.HEAD                        \
    -censor censor_${subj}_combined_2.1D                                 \
    -ortvec ROI.WMe_rall.1D ROI.WMe                                      \
    -ortvec ROI.CSFe_rall.1D ROI.CSFe                                    \
    -polort 3 -float                                                     \
    -local_times                                                         \
    -num_stimts 12                                                       \
    -stim_times_AM1 1 stimuli/context.1D 'dmBLOCK(1)'                    \
    -stim_label 1 context                                                \
    -stim_times_AM1 2 stimuli/ISI.1D 'dmBLOCK(1)'                        \
    -stim_label 2 surprise                                               \
    -stim_times_AM1 3 stimuli/response.1D 'dmBLOCK(1)'                   \
    -stim_label 3 unsurpr                                                \
    -stim_times_AM1 4 stimuli/surprise.1D 'dmBLOCK(1)'                   \
    -stim_label 4 response                                               \
    -stim_times_AM1 5 stimuli/TNI.1D 'dmBLOCK(1)'                        \
    -stim_label 5 ISI                                                    \
    -stim_times_AM1 6 stimuli/unsurpr.1D 'dmBLOCK(1)'                    \
    -stim_label 6 TNI                                                    \
    -stim_file 7 motion_demean.1D'[0]' -stim_base 7 -stim_label 7 roll   \
    -stim_file 8 motion_demean.1D'[1]' -stim_base 8 -stim_label 8 pitch  \
    -stim_file 9 motion_demean.1D'[2]' -stim_base 9 -stim_label 9 yaw    \
    -stim_file 10 motion_demean.1D'[3]' -stim_base 10 -stim_label 10 dS  \
    -stim_file 11 motion_demean.1D'[4]' -stim_base 11 -stim_label 11 dL  \
    -stim_file 12 motion_demean.1D'[5]' -stim_base 12 -stim_label 12 dP  \
    -num_glt 5                                                           \
    -gltsym 'SYM: +context'                                              \
    -glt_label 1 context                                                 \
    -gltsym 'SYM: +surprise'                                             \
    -glt_label 2 surprise                                                \
    -gltsym 'SYM: +unsurpr'                                              \
    -glt_label 3 unsurpr                                                 \
    -gltsym 'SYM: +surprise -unsurpr'                                    \
    -glt_label 4 surprise-unsurpr                                        \
    -gltsym 'SYM: +unsurpr +context'                                     \
    -glt_label 5 normstory_vs_base                                       \
    -jobs 20                                                             \
    -fout -tout -x1D X.xmat.1D -xjpeg X.jpg                              \
    -x1D_uncensored X.nocensor.xmat.1D                                   \
    -fitts fitts.$subj                                                   \
    -errts errts.${subj}                                                 \
    -bucket stats.$subj


# if 3dDeconvolve fails, terminate the script
if ( $status != 0 ) then
    echo '---------------------------------------'
    echo '** 3dDeconvolve error, failing...'
    echo '   (consider the file 3dDeconvolve.err)'
    exit
endif


# display any large pairwise correlations from the X-matrix
1d_tool.py -show_cormat_warnings -infile X.xmat.1D |& tee out.cormat_warn.txt

# -- execute the 3dREMLfit script, written by 3dDeconvolve --
tcsh -x stats.REML_cmd 

# if 3dREMLfit fails, terminate the script
if ( $status != 0 ) then
    echo '---------------------------------------'
    echo '** 3dREMLfit error, failing...'
    exit
endif


# create an all_runs dataset to match the fitts, errts, etc.
3dTcat -prefix all_runs.$subj pb05.$subj.r*.scale+tlrc.HEAD

# --------------------------------------------------
# create a temporal signal to noise ratio dataset 
#    signal: if 'scale' block, mean should be 100
#    noise : compute standard deviation of errts
3dTstat -mean -prefix rm.signal.all all_runs.$subj+tlrc"[$ktrs]"
3dTstat -stdev -prefix rm.noise.all errts.${subj}_REML+tlrc"[$ktrs]"
3dcalc -a rm.signal.all+tlrc                                             \
       -b rm.noise.all+tlrc                                              \
       -c full_mask.$subj+tlrc                                           \
       -expr 'c*a/b' -prefix TSNR.$subj 

# ---------------------------------------------------
# compute and store GCOR (global correlation average)
# (sum of squares of global mean of unit errts)
3dTnorm -norm2 -prefix rm.errts.unit errts.${subj}_REML+tlrc
3dmaskave -quiet -mask full_mask.$subj+tlrc rm.errts.unit+tlrc           \
          > gmean.errts.unit.1D
3dTstat -sos -prefix - gmean.errts.unit.1D\' > out.gcor.1D
echo "-- GCOR = `cat out.gcor.1D`"

# ---------------------------------------------------
# compute correlation volume
# (per voxel: average correlation across masked brain)
# (now just dot product with average unit time series)
3dcalc -a rm.errts.unit+tlrc -b gmean.errts.unit.1D -expr 'a*b' -prefix rm.DP
3dTstat -sum -prefix corr_brain rm.DP+tlrc

# create ideal files for fixed response stim types
1dcat X.nocensor.xmat.1D'[8]' > ideal_context.1D
1dcat X.nocensor.xmat.1D'[9]' > ideal_surprise.1D
1dcat X.nocensor.xmat.1D'[10]' > ideal_unsurpr.1D
1dcat X.nocensor.xmat.1D'[11]' > ideal_response.1D
1dcat X.nocensor.xmat.1D'[12]' > ideal_ISI.1D
1dcat X.nocensor.xmat.1D'[13]' > ideal_TNI.1D

# --------------------------------------------------------
# compute sum of non-baseline regressors from the X-matrix
# (use 1d_tool.py to get list of regressor colums)
set reg_cols = `1d_tool.py -infile X.nocensor.xmat.1D -show_indices_interest`
3dTstat -sum -prefix sum_ideal.1D X.nocensor.xmat.1D"[$reg_cols]"

# also, create a stimulus-only X-matrix, for easy review
1dcat X.nocensor.xmat.1D"[$reg_cols]" > X.stim.xmat.1D

# ============================ blur estimation =============================
# compute blur estimates
touch blur_est.$subj.1D   # start with empty file

# create directory for ACF curve files
mkdir files_ACF

# -- estimate blur for each run in epits --
touch blur.epits.1D

# restrict to uncensored TRs, per run
foreach run ( $runs )
    set trs = `1d_tool.py -infile X.xmat.1D -show_trs_uncensored encoded \
                          -show_trs_run $run`
    if ( $trs == "" ) continue
    3dFWHMx -detrend -mask full_mask.$subj+tlrc                          \
            -ACF files_ACF/out.3dFWHMx.ACF.epits.r$run.1D                \
            all_runs.$subj+tlrc"[$trs]" >> blur.epits.1D
end

# compute average FWHM blur (from every other row) and append
set blurs = ( `3dTstat -mean -prefix - blur.epits.1D'{0..$(2)}'\'` )
echo average epits FWHM blurs: $blurs
echo "$blurs   # epits FWHM blur estimates" >> blur_est.$subj.1D

# compute average ACF blur (from every other row) and append
set blurs = ( `3dTstat -mean -prefix - blur.epits.1D'{1..$(2)}'\'` )
echo average epits ACF blurs: $blurs
echo "$blurs   # epits ACF blur estimates" >> blur_est.$subj.1D

# -- estimate blur for each run in errts --
touch blur.errts.1D

# restrict to uncensored TRs, per run
foreach run ( $runs )
    set trs = `1d_tool.py -infile X.xmat.1D -show_trs_uncensored encoded \
                          -show_trs_run $run`
    if ( $trs == "" ) continue
    3dFWHMx -detrend -mask full_mask.$subj+tlrc                          \
            -ACF files_ACF/out.3dFWHMx.ACF.errts.r$run.1D                \
            errts.${subj}+tlrc"[$trs]" >> blur.errts.1D
end

# compute average FWHM blur (from every other row) and append
set blurs = ( `3dTstat -mean -prefix - blur.errts.1D'{0..$(2)}'\'` )
echo average errts FWHM blurs: $blurs
echo "$blurs   # errts FWHM blur estimates" >> blur_est.$subj.1D

# compute average ACF blur (from every other row) and append
set blurs = ( `3dTstat -mean -prefix - blur.errts.1D'{1..$(2)}'\'` )
echo average errts ACF blurs: $blurs
echo "$blurs   # errts ACF blur estimates" >> blur_est.$subj.1D

# -- estimate blur for each run in err_reml --
touch blur.err_reml.1D

# restrict to uncensored TRs, per run
foreach run ( $runs )
    set trs = `1d_tool.py -infile X.xmat.1D -show_trs_uncensored encoded \
                          -show_trs_run $run`
    if ( $trs == "" ) continue
    3dFWHMx -detrend -mask full_mask.$subj+tlrc                          \
            -ACF files_ACF/out.3dFWHMx.ACF.err_reml.r$run.1D             \
            errts.${subj}_REML+tlrc"[$trs]" >> blur.err_reml.1D
end

# compute average FWHM blur (from every other row) and append
set blurs = ( `3dTstat -mean -prefix - blur.err_reml.1D'{0..$(2)}'\'` )
echo average err_reml FWHM blurs: $blurs
echo "$blurs   # err_reml FWHM blur estimates" >> blur_est.$subj.1D

# compute average ACF blur (from every other row) and append
set blurs = ( `3dTstat -mean -prefix - blur.err_reml.1D'{1..$(2)}'\'` )
echo average err_reml ACF blurs: $blurs
echo "$blurs   # err_reml ACF blur estimates" >> blur_est.$subj.1D


# add 3dClustSim results as attributes to any stats dset
mkdir files_ClustSim

# run Monte Carlo simulations using method 'ACF'
set params = ( `grep ACF blur_est.$subj.1D | tail -n 1` )
3dClustSim -both -mask full_mask.$subj+tlrc -acf $params[1-3]            \
           -cmd 3dClustSim.ACF.cmd -prefix files_ClustSim/ClustSim.ACF

# run 3drefit to attach 3dClustSim results to stats
set cmd = ( `cat 3dClustSim.ACF.cmd` )
$cmd stats.$subj+tlrc stats.${subj}_REML+tlrc


# ================== auto block: generate review scripts ===================

# generate a review script for the unprocessed EPI data
gen_epi_review.py -script @epi_review.$subj \
    -dsets pb00.$subj.r*.tcat+tlrc.HEAD

# generate scripts to review single subject results
# (try with defaults, but do not allow bad exit status)
gen_ss_review_scripts.py -mot_limit 0.2 -out_limit 0.1 -exit0

# ========================== auto block: finalize ==========================

# remove temporary files
rm -fr rm .* Segsy

# if the basic subject review script is here, run it
# (want this to be the last text output)
if ( -e @ss_review_basic ) ./@ss_review_basic |& tee out.ss_review.$subj.txt

# return to parent directory
cd ..

echo "execution finished: `date`"


end