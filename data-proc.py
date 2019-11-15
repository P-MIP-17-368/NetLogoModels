# -*- coding: utf-8 -*-
"""
Created on Mon Mar 26 13:57:28 2018

@author: Arunas
"""
import pandas as pd
import matplotlib.pyplot as plt

"""
dt = pd.read_csv('C:/temp/Model_v2 experiment-table po 100.csv')
dt1 = dt[['[run number]','[step]','max-cluster','num-cluster','num-cluster-bigger-than-x']] [(dt['[step]'] % 100 == 0) & (dt['[step]'] > 0)]
dt1.to_csv('c:/temp/filtered.csv')
dtg = dt1.groupby(['[run number]'])
plt.figure(); dtg.plot(y='max-cluster', x='[step]');
"""
#%% 

import platform
import os, re

def get_path():
    if platform.node()== "DESKTOP-DTFRNI0":
      #wdNetlogoCode = 'C:/git/MII-NetlogoModels/NetLogoModels'
      wdExperimentArchive = 'C:/Users/oruna/OneDrive/darbas/MII projektas/Experiments/'
    else :
      #wdNetlogoCode = 'C:/code/u/NetLogoModels'
      wdExperimentArchive = 'C:/Users/milibaru/OneDrive/darbas/MII projektas/Experiments/'
    return(wdExperimentArchive)
    


rootdir = get_path()
regex = re.compile('res-[1-9]\\d*\\.csv$')

folder = get_path() + '/' + "0812-11"
li = []
for file in os.listdir(folder):
    if regex.match(file):
        print(file)
        df = pd.read_csv(folder + '/' + file, header = None, names = ["Experiment","Ticks",'id',"V1","V2","V3","sc"])
        li.append(df)

df = pd.concat(li, ignore_index = True)
  
        
#%%

from sklearn.cluster import DBSCAN  
import numpy as np

def calc_cluster(data):
    clustering = DBSCAN(eps=7, min_samples=30).fit(data)
    core_samples_mask = np.zeros_like(clustering.labels_, dtype=bool)
    core_samples_mask[clustering.core_sample_indices_] = True
    labels = clustering.labels_
    n_clusters_ = len(set(labels)) - (1 if -1 in labels else 0)
    n_noise_ = list(labels).count(-1)
    return(pd.Series(data = [n_clusters_,n_noise_], index= ['ClusterNo','NoicePoints']))

def calc_append_cluster_no(data):
    '''clustering = DBSCAN(eps=7, min_samples=30).fit(data.loc[:,['V1','V2','V3']])
    labels = clustering.labels_'''
    print(data.head())
    '''data = data.insert(loc = len(data.columns),
                       column = 'ClusterNo',
                       value = labels)
    print(data)'''
    return(data)
    
#%%

r = df.groupby(["Experiment","Ticks"]).apply(calc_cluster)
r1 = r.reset_index()

# vietoje calc_append_cluster_no
r3 = pd.merge(df,r1, how = 'left', on = ['Experiment','Ticks'], left_index = False, right_index = False)

# r2 = df.groupby(["Experiment","Ticks"]).apply(calc_append_cluster_no)


#%%  plotting pairs
import seaborn as sns

#%% examples
sns.pairplot(df_10_2000,vars = ['V1','V2','V3'])
sns.pairplot(df.loc[((df['Experiment'] == 8) & (df['Ticks'] == 3000)),:],vars=['V1','V2','V3'])
clustering = DBSCAN(eps=7, min_samples=30).fit(df.loc[((df['Experiment'] == 8) & (df['Ticks'] == 2500)),['V1','V2','V3']])
df_10_2000.insert(loc = 7, column = 'ClusterNo', value = DBSCAN(eps=7, min_samples=30).fit(df_10_2000).labels_)



#%%
import scipy.spatial as sp
from scipy.spatial import distance
a = (1, 2, 3)
b = (4, 5, 6)
dst = distance.euclidean(a, b)


d = sp.distance_matrix(df_10_2000.loc[:,['V1','V2','V3']],df_10_2000.loc[:,['V1','V2','V3']])
