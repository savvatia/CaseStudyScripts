#!/bin/tcsh

#This script runs a One-Sample T-test on the story vs. baseline contrast (in this case beta image stored in sub-brick 10) at the group level for TD children

module load afni/v17.3.07


set	top_path  = "/home/MRIdata/fMRI/subjects/"
set	output_path = ${top_path}group

if (-e "${output_path}") then
    echo "output directory exists"
else
    mkdir ${output_path}
endif
   

cd ${output_path}

 3dttest++ \
    -setA Story_vs_baseline \
        sub01    ${top_path}sub01/task/MNISpace/stats.sub01+tlrc'[10]' \
        sub02    ${top_path}sub02/task/MNISpace/stats.sub02+tlrc'[10]' \
        sub05    ${top_path}sub05/task/MNISpace/stats.sub05+tlrc'[10]' \
        sub08    ${top_path}sub08/task/MNISpace/stats.sub08+tlrc'[10]' \
        sub09    ${top_path}sub09/task/MNISpace/stats.sub09+tlrc'[10]' \
        sub11    ${top_path}sub11/task/MNISpace/stats.sub11+tlrc'[10]' \
        sub12    ${top_path}sub12/task/MNISpace/stats.sub12+tlrc'[10]' \
        sub15    ${top_path}sub15/task/MNISpace/stats.sub15+tlrc'[10]' \
        sub16    ${top_path}sub16/task/MNISpace/stats.sub16+tlrc'[10]' \
        sub17    ${top_path}sub17/task/MNISpace/stats.sub17+tlrc'[10]' \
        sub18    ${top_path}sub18/task/MNISpace/stats.sub18+tlrc'[10]' \
        sub19    ${top_path}sub19/task/MNISpace/stats.sub19+tlrc'[10]' \
        sub20    ${top_path}sub20/task/MNISpace/stats.sub20+tlrc'[10]' \
        sub21    ${top_path}sub21/task/MNISpace/stats.sub21+tlrc'[10]' \
        sub22    ${top_path}sub22/task/MNISpace/stats.sub22+tlrc'[10]' \
        sub23    ${top_path}sub23/task/MNISpace/stats.sub23+tlrc'[10]' \
        sub26    ${top_path}sub26/task/MNISpace/stats.sub26+tlrc'[10]' \
        sub27    ${top_path}sub27/task/MNISpace/stats.sub27+tlrc'[10]' \
        sub28    ${top_path}sub28/task/MNISpace/stats.sub28+tlrc'[10]' \
        sub29    ${top_path}sub29/task/MNISpace/stats.sub29+tlrc'[10]' \
        sub30 ${top_path}sub30/task/MNISpace/stats.sub30+tlrc'[10]' \
        sub32 ${top_path}sub32/task/MNISpace/stats.sub32+tlrc'[10]' \
        sub33 ${top_path}sub33/task/MNISpace/stats.sub33+tlrc'[10]' \
        sub35 ${top_path}sub35/task/MNISpace/stats.sub35+tlrc'[10]' \
        sub37 ${top_path}sub37/task/MNISpace/stats.sub37+tlrc'[10]' \
        sub31 ${top_path}sub31/task/MNISpace/stats.sub31+tlrc'[10]' \
    -mask ${top_path}group/mask_group+tlrc\
    -resid resid\
    -prefix_clustsim ClustSimOut\
    -Clustsim\
    -debug\
    -prefix 3dttest_Story

