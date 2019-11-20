# -*- coding: utf-8 -*-
"""
Created on Mon Mar 26 13:57:28 2018

@author: Arunas
"""


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
import pandas as pd


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

#folder = get_path() + '/' + "0812-11"
folder = get_path() + '/' + "1112-01"
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
    clustering = DBSCAN(eps=7, min_samples=15).fit(data.loc[:,['V1','V2','V3']])
    core_samples_mask = np.zeros_like(clustering.labels_, dtype=bool)
    core_samples_mask[clustering.core_sample_indices_] = True
    labels = clustering.labels_
    n_clusters_ = len(set(labels)) - (1 if -1 in labels else 0)    
    n_noise_ = list(labels).count(-1)
    return(pd.Series(data = [n_clusters_,n_noise_], index= ['ClusterNo','NoicePoints']))

def calc_append_cluster_no(data):
    clustering = DBSCAN(eps=7, min_samples=15).fit(data.loc[:,['V1','V2','V3']])
    labels = clustering.labels_
    data['Cluster'] =  labels
    #print(data.head())
    '''data = data.insert(loc = len(data.columns),
                       column = 'Cluster',
                       value = labels)'''
    '''print(data)'''
    return(data)
    
#%% 

def calc_sd(data, columns):
    a = data.loc[:,columns].to_numpy()
    #print(np.sum(np.sqrt(np.sum(( a - np.mean(a, axis = 0) ) ** 2, axis = 1))))
    return(sdnp(a))
    #means = list(map(lambda x: mean(data.loc[:,x]),['V1','V2','V3']))
    #
    
def calc_gc(data, columns):
    a = data.loc[:,columns].to_numpy()
    sd = sdnp(a)
    return(1 - (1 / (len(a) - sd) ))
 
def sdnp(a):
    res = np.sum(np.sqrt(np.sum(( a - np.mean(a, axis = 0) ) ** 2, axis = 1)))/(len(a) - 1)
    return(res)
    
def calc_sd_series(data):
    return(pd.Series(data = [calc_sd(data, ['V1','V2','V3'])], index = ['ClusterSD']))
    
'''
calc_sd(df.loc[(df['Experiment']==1) & (df['Ticks'] == 1000),:],['V1','V2','V3'])
'''
#%%
from math import sqrt

dfg = df.groupby(["Experiment","Ticks"])
r = dfg.apply(calc_cluster).reset_index()

r2 = dfg.apply(calc_append_cluster_no).reset_index()

# vietoje calc_append_cluster_no
r3 = pd.merge(df,r, how = 'left', on = ['Experiment','Ticks'], left_index = False, right_index = False)

df_mean = dfg.agg(V1mean = pd.NamedAgg(column='V1', aggfunc = 'mean'), V2mean = pd.NamedAgg(column = 'V2', aggfunc = 'mean'), V3mean = pd.NamedAgg(column='V3', aggfunc = 'mean')).reset_index()
r_mean =  pd.merge(df,df_mean, how = 'left', on = ['Experiment','Ticks'], left_index = False, right_index = False)
# susiskaiciuojame pagal euklida kiekvieno nuokrypi nuo vidurkiniu reiksmiu
r_mean['dist'] = (r_mean.V1 - r_mean.V1mean)**2 + (r_mean.V2 - r_mean.V2mean)**2 + (r_mean.V3 - r_mean.V3mean)**2
# istraukiame kuba
r_mean['sdist'] = r_mean['dist'].apply(sqrt)
# r2 = df.groupby(["Experiment","Ticks"]).apply(calc_append_cluster_no)
# sugrupuojame i kiekvienai grupe paskaiciuojam suma nuokrypiu ir kiek grupeje yra viso
r_mean2 = r_mean.groupby(['Experiment','Ticks']).agg(devSum = pd.NamedAgg(column = 'sdist', aggfunc='sum'), cnt = pd.NamedAgg(column = 'dist', aggfunc = 'count')).reset_index()
#r_mean2['devSum'] = r_mean2['devSum'].apply(sqrt)
r_mean2 = r_mean2.assign(sd = lambda x: x.devSum / ( x.cnt - 1 ))


# gauname pagal grupes
sd4clusters = r2.groupby(["Experiment","Ticks","Cluster"]).apply(calc_sd_series).reset_index()



#%%  plotting pairs
import seaborn as sns
import matplotlib.pyplot as plt

#%% 

# norint nupaisyti tiesiog galima naudoti dataFrame metoda.
r.loc[r['Experiment']==10,['ClusterNo','Ticks']].plot(x='Ticks', y='ClusterNo')


#%% examples
sns.pairplot(df_10_2000,vars = ['V1','V2','V3'])

# cia sudetingesnis
sns.pairplot(r2.loc[(r2['Experiment'] == 10 ) & ( r2['Ticks'] == 1500),:], 
                    vars= ['V1','V2','V3'], 
                    hue = 'Cluster', 
                    diag_kind = 'hist')

clustering = DBSCAN(eps=7, min_samples=30).fit(df.loc[((df['Experiment'] == 8) & (df['Ticks'] == 2500)),['V1','V2','V3']])
df_10_2000.insert(loc = 7, column = 'ClusterNo', value = DBSCAN(eps=7, min_samples=30).fit(df_10_2000).labels_)

 dfg.agg(V1mean = pd.NamedAgg(column='V1', aggfunc = 'mean'))

#%%
import scipy.spatial as sp
from scipy.spatial import distance
from statistics import mean

from math import sqrt
a = (1, 2, 3)
b = (4, 5, 6)
dst = distance.euclidean(a, b)


d = sp.distance_matrix(df_10_2000.loc[:,['V1','V2','V3']],df_10_2000.loc[:,['V1','V2','V3']])

def tst(x):
    print(type(x))
    print(x)
    
