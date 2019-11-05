%%% Extracting graph theoretical network measures from tractography connectivity matrices from previous steps
%%% Uses the Brain Connectivity Toolbox (brain-connectivity-toolbox.net) 
%%% Complex network measures of brain connectivity: Uses and interpretations. Rubinov M, Sporns O (2010) NeuroImage 52:1059-69.
%%% 
%%% Generates scores for network node degree centrality, efficiency, etc. separately for right hemisphere and left hemisphere
%%% Requires uipickfiles.m function to select the subjects to process

addpath /<path to Brain Connectivity Toolbox>/
addpath /home/Scripts/functions/


defaultdir = '/home/MRIdata/DTI/CMP/';
getfiles = uipickfiles('FilterSpec', defaultdir);
version = 'V1';
resultsdir = '/home/MRIdata/DTI/CMP/BrainConnectivityToolbox/LL/';  % Replace "LL" with "RR" for right hemisphere measures



SC_data = {'Summary', 'Cluster', 'Degree', 'Eff', 'Eigen Centrality', 'Geff', Modularity_Q', 'Betweenness', 'Density'}'; %Weighted, undirected connectivity matrix

%%%Thresholding the matrix: with a 0.3 threshold, we keep 30% of the data:
threshMat =0.3;

threshCell = textscan(num2str(threshMat), '%s');

[~, subjects] = cellfun(@fileparts, getfiles, 'UniformOutput', 0);


supraThresh = 1- threshMat; %  30% of max
store_bin = [];


for fn_ind = 1:length(getfiles)

        display(num2str([fn_ind thresh_num]));
        post_dir = [getfiles{fn_ind} '/tp1_s16_a60_f15_sm/CMP/fibers/matrices/'];

        %%%Load SC for subject and store
        [~, sub, ~] =fileparts(getfiles{fn_ind});          
        SC = load([post_dir 'SC_N_scale33.mat']);
        SC = SC.matrix;
        %Separate to r-r l-l. Change according to the ParcellationLausanne2008.xls parcellation scheme with scale 33
	%Scheme can be found: https://github.com/LTS5/cmp_nipype/tree/master/cmtklib/data/parcellation/lausanne2008
        %SC = SC(1:34,1:34); % R-R matrix including lateralorbitofrontal until insula
        SC = SC(42:75, 42:75); % L-L matrix


        %%%Thresholding to top x% of correlations
        SC = threshold_FC(SC, supraThresh);

        %%%Weighted
        SC_data{2,2}(fn_ind,:) = clustering_coef_wu(SC);
        SC_data{3,2}(fn_ind,:) = degrees_und(SC);
        SC_data{4,2}(fn_ind,:) = efficiency_wei(SC,2);
        SC_data{5,2}(fn_ind,:) = eigenvector_centrality_und(SC);
        SC_data{6,2}(fn_ind,:) = efficiency_wei(SC);
        SC_data{7,2}(fn_ind,:) = betweenness_wei(SC);
        SC_data{8,2}(fn_ind,:) = density_und(SC);

        SC = threshold_FC(SC, supraThresh);
        Ci = modularity_und(SC);
        [Ci Q] = modularity_und(SC,1);
        SC_data{9,2}(fn_ind,:) = Q; 

end

    
     

save([resultsdir 'data_all.mat'], 'SC_data', 'store_bin');

%% Save every  measure in a csv file for analysis with R %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%WEIGHTED


%%%Save Clustering for analysis with R
clustering_temp = SC_data{2,2};
clusteringfile = fopen('DTI_Clustering.csv', 'w');

roi_size = size(clustering_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(clustering_temp,1)
    %fprintf(fileID, format, data)
    fprintf(clusteringfile, formatstr,  clustering_temp(i,:));
end
fclose(clusteringfile);


degree_temp = SC_data{3,2};
degreefile = fopen('DTI_DegreeCentrality.csv', 'w');

%%%size(degree_temp,2)  is equal to # of rois
roi_size = size(degree_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(degree_temp,1)
    %fprintf(fileID, format, data)
    fprintf(degreefile, formatstr,  degree_temp(i,:));
end
fclose(degreefile);

%%%Save Local Efficiency for analysis with R
Efficiency_temp = SC_data{4,2};
Efficiencyfile = fopen('DTI_Efficiency.csv', 'w');

roi_size = size(Efficiency_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(Efficiency_temp,1)
    %fprintf(fileID, format, data)
    fprintf(Efficiencyfile, formatstr,  Efficiency_temp(i,:));
end
fclose(Efficiencyfile);

%%%Save Eigenvector Centrality for analysis with R
EigCentr_temp = SC_data{5,2};
EigCentrfile = fopen('DTI_EigCentr.csv', 'w');

roi_size = size(EigCentr_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(EigCentr_temp,1)
    %fprintf(fileID, format, data)
    fprintf(EigCentrfile, formatstr,  EigCentr_temp(i,:));
end
fclose(EigCentrfile);

%%%Save Global Efficiency for analysis with R
Gefficiency_temp = SC_data{6,2};
Gefficiencyfile = fopen('DTI_Gefficiency.csv', 'w');

roi_size = size(Gefficiency_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(Gefficiency_temp,1)
    %fprintf(fileID, format, data)
    fprintf(Gefficiencyfile, formatstr,  Gefficiency_temp(i,:));
end
fclose(Gefficiencyfile);


%%%Save Betweenness for analysis with R
betweenness_temp = SC_data{7,2};
betweennessfile = fopen('DTI_betweenness.csv', 'w');

roi_size = size(betweenness_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(betweenness_temp,1)
    %fprintf(fileID, format, data)
    fprintf(betweennessfile, formatstr,  betweenness_temp(i,:));
end
fclose(betweennessfile);


%%%Save Density for analysis with R
density_temp = SC_data{8,2};
densityfile = fopen('DTI_density.csv', 'w');

roi_size = size(density_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(density_temp,1)
    %fprintf(fileID, format, data)
    fprintf(densityfile, formatstr,  density_temp(i,:));
end
fclose(densityfile);

%%%Save Modularity for analysis with R
modularity_temp = SC_data{9,2};
modularityfile = fopen('DTI_modularity.csv', 'w');

roi_size = size(modularity_temp,2);
formatstr = [repmat('%i\t', 1,roi_size), '\n'];

for i = 1:size(modularity_temp,1)
    %fprintf(fileID, format, data)
    fprintf(modularityfile, formatstr,  modularity_temp(i,:));
end
fclose(modularityfile);


movefile('*.csv', resultsdir);