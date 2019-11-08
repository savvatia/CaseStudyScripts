#!/bin/tcsh 

#source $FSLDIR/etc/fslconf/fsl.csh 

 
set VBTlist="01 02 03" #List of subject codes
set original = "skullstrippedT1.$VBTlist" 
set lesion   = "lesion.$VBTlist" 
set script_path  = "/home/scripts/" 
 
set iterations = 6; 
set mesh = 0.4; 


foreach value ($VBTlist);
	cd $script_path
	set subjID = $value
	set data_path    = "/home/MRIdata/subjects/${value}/T1/" 
	mkdir "/home/MRIdata/subjects/${value}"
	set results_path = "/home/MRIdata/subjects/${value}/"
	source synVBT
end


