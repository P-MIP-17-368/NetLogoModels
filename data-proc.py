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
    
dfs = []

rootdir = get_path()
regex = re.compile('res-[1-9]\\d*\\.csv$')

folder = get_path() + '/' + "0812-11"
li = []
for file in os.listdir(folder):
    if regex.match(file):
        print(file)
        df = pd.read_csv(folder + '/' + file, header = None, names = ["Experiment","Ticks","V1","V2","V3","sc"])
        li.append(df)


#%%

from sklearn.cluster import DBSCAN      
        
clustering = DBSCAN(eps=7, min_samples=30).fit(X)

    
        


