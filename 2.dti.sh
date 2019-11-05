#!/bin/bash

##########################################################
# Purpose: To run connectomemapper in batch and parallel #
# Adapted from a script by Danny Siu		         #
# 		                                         #
# Run script doing ./connectome_batcher                  #
# 							 #
# Can change the max number of subshells relative to     #
# computational load                                     #
# Change config files, timepoints and subjects as needed #
#                                                        #
# IMPORTANT: Put convert_gpickle2mat_func.py in same     #
# directory as this script				 #
##########################################################

configfile='/home/MRIdata/DTI/CMP/template_step2.pkl'
timepoint='tp1'
#timepoint='tp1_s16_a60_f15_sm' #after re-running the tractography with 16 random seeds, angle 60 degrees and FA threshold of 0.15
iter=0
max_parallel=5 ###How many subshells you want

for sub in sub01 sub02 sub03 sub04 sub05 

do
	###Main parallel part. Can remove if you want. The & allows the command to be run in the background, exits, and starts another run.	
	(connectomemapper $sub $timepoint $configfile) & 
	##Can also run it with the project dir now as connectomemapper $sub $timepoint $configfile $project_dir

	###Increases iteration and does a check to only perform as many runs as the max_parallel
	iter=$(($iter+1))
	if (( $iter % $max_parallel  == 0)); 
	then 
		wait; 
	fi
done
wait
