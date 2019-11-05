#This script converts the gpickle output from connectomemapper to a mat file that can be processed with the matlab-based Brain Connectivity Toolbox.

import networkx as nx
import numpy as np
import scipy.io
import os
import pickle
import sys

###Opens the config file to grab project directory
with open(sys.argv[3], 'rb') as f:
        data = pickle.load(f)

subject_name = sys.argv[1]
subject_timepoint = sys.argv[2]
workingdir = os.path.join(data.project_dir, subject_name, subject_timepoint, 'CMP', 'fibers', 'matrices')
print(workingdir)


a = nx.read_gpickle(workingdir + "/connectome_scale33.gpickle");
for u,v,d in a.edges_iter(data=True):
	a.edge[u][v]['weight'] = a.edge[u][v]['number_of_fibers']
	b = nx.to_numpy_matrix(a)                       
	scipy.io.savemat(workingdir + "/SC_N_scale33.mat", mdict={'matrix': b})

for u,v,d in a.edges_iter(data=True):
	a.edge[u][v]['weight'] = a.edge[u][v]['fiber_length_mean']
	b = nx.to_numpy_matrix(a)                       
	scipy.io.savemat(workingdir + "/SC_L_scale33.mat", mdict={'matrix': b})

for u,v,d in a.edges_iter(data=True):
	a.edge[u][v]['weight'] = a.edge[u][v]['fa_mean']
	b = nx.to_numpy_matrix(a)                       
	scipy.io.savemat(workingdir + "/SC_FA_scale33.mat", mdict={'matrix': b})

for u,v,d in a.edges_iter(data=True):
	a.edge[u][v]['weight'] = a.edge[u][v]['adc_mean']
	b = nx.to_numpy_matrix(a)                       
	scipy.io.savemat(workingdir + "/SC_ADC_scale33.mat", mdict={'matrix': b})

