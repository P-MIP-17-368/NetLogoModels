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
import shutil

def get_path():
    if platform.node()== "DESKTOP-DTFRNI0":
      #wdNetlogoCode = 'C:/git/MII-NetlogoModels/NetLogoModels'
      wdExperimentArchive = 'C:/Users/oruna/OneDrive/darbas/MII projektas/Experiments/'
    else :
      #wdNetlogoCode = 'C:/code/u/NetLogoModels'
      wdExperimentArchive = 'C:/Users/milibaru/OneDrive/darbas/MII projektas/Experiments/'
    return(wdExperimentArchive)
    
def source_path():
    if platform.node()== "DESKTOP-DTFRNI0":
      #wdNetlogoCode = 'C:/git/MII-NetlogoModels/NetLogoModels'
      codeFolder = 'C:/Users/oruna/OneDrive/darbas/MII projektas/Experiments/'
    else :
      #wdNetlogoCode = 'C:/code/u/NetLogoModels'
      codeFolder = 'C:/code/u/NetLogoModels'
    return codeFolder

def target_path(target,no):
    datepart = date.today().strftime("%m%d")
    tfolderdir = target + '/' + datepart + '-' + no
    return tfolderdir

def move_exp_files(codeFolder,tfolderdir,regex,deleteFiles = False):
    
    print("target folder %s" % tfolderdir)
    if os.path.isdir(tfolderdir):
        if (deleteFiles):
            print("folder %s found. Deleting old files.." % tfolderdir )
            for file in os.listdir(tfolderdir):
                if regex.match(file):
                    tfile = tfolderdir + "/" + file
                    print("Deleting file %s" % tfile )
                    os.remove(tfile)
        else:
            print("folder %s found. Use deteleFolder = True to overwrite" % tfolderdir)
            for file in os.listdir(tfolderdir):
                if regex.match(file): 
                    print("File %s is in folder %s. Use deteleFolder = True to overwrite" % (file, tfolderdir))
                    return
             
    else:
        os.mkdir(tfolderdir)
        
    for file in os.listdir(codeFolder):
        if regex.match(file):
            print("moving file %s" % file )
            shutil.move(codeFolder + "/" + file,tfolderdir)
    
    return 

#%% 
experiment = "1210-03"
rootdir = get_path()
regex = re.compile('res-[1-9]\\d*\\.csv$')
#folder = get_path() + '/' + "0812-11"
folder = get_path() + '/' + experiment

#%% 


import pandas as pd
from datetime import date

columns = ["V1","V2","V3"]

li = []
for file in os.listdir(folder):
    if regex.match(file):
        print(file)
        df = pd.read_csv(folder + '/' + file, header = None, names = ["Experiment","Ticks",'id',"V1","V2","V3","sc"])
        li.append(df)

df = pd.concat(li, ignore_index = True)
  


#%% run only to copy files to experiment folder

exp_day_no = "03"      
move_exp_files(source_path(),target_path(get_path(),exp_day_no),regex,True)
 
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
df_agg_cluster = dfg.apply(calc_cluster).reset_index()

df_with_cluster = dfg.apply(calc_append_cluster_no).reset_index()

# vietoje calc_append_cluster_no
df_full_with_clusteraggs = pd.merge(df,df_agg_cluster, how = 'left', on = ['Experiment','Ticks'], left_index = False, right_index = False)

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
sd4clusters = df_with_cluster[df_with_cluster["Cluster"] > -1].groupby(["Experiment","Ticks","Cluster"]).apply(calc_sd_series).reset_index()
sd4clustersMean = sd4clusters.groupby(["Experiment","Ticks"])["ClusterSD"].mean().reset_index()
sd4tickworld = df_with_cluster.groupby(["Experiment","Ticks"]).apply(calc_sd_series).reset_index()
sdMerged = pd.merge(sd4tickworld,sd4clustersMean, how = 'left', on = ['Experiment','Ticks'], suffixes = ["global","mean"])
sdMerged = pd.merge(sdMerged,df_agg_cluster,how = 'left', on = ['Experiment','Ticks'])


#%% adding scenario and making calculations by scenario
from math import ceil

experiments = max(df['Experiment'])
repetitions = 10
scenarios = int(experiments / repetitions)

sdMerged['Scenario'] =  ( sdMerged['Experiment'] / repetitions ).apply(ceil)
cols = sdMerged.columns.tolist()
cols = cols[-1:] + cols[:-1]
sdMerged = sdMerged[cols]

df_with_culster_and_scenarios = df_with_cluster.assign( Scenario = (df_with_cluster['Experiment'] / repetitions).apply(ceil))
df_aggculster_and_scenarios = df_agg_cluster.assign( Scenario = (df_agg_cluster['Experiment'] / repetitions).apply(ceil))

d1 = df_aggculster_and_scenarios.groupby(['Scenario','Ticks']).agg({'ClusterNo' : [np.mean]}).reset_index()
# panasiai galima daryti ir pivot table
p1 = df_aggculster_and_scenarios.pivot_table(index = 'Ticks', columns = 'Scenario', values = 'ClusterNo', aggfunc = np.mean)

sd4clusters['Scenario'] = ( sd4clusters['Experiment'] / repetitions).apply(ceil)

#sd4clusters_pivot = sd4clusters.pivot_table(index = 'Ticks', columns = ['Scenario','Experiment'])


#%% export to excel
xf = folder + "/output.xlsx"
print("saving file %s" % xf )
sdMerged.to_excel(xf)

#%%
import matplotlib.pyplot as plt


sdMergedPivot = sdMerged.pivot_table(index = 'Ticks', columns = 'Scenario', values = ['ClusterSDglobal', 'ClusterSDmean'] )

sdMergedPivot.plot(figsize=(12,9))

#%% 




# galima tiesiog plot
df_aggculster_and_scenarios.pivot_table(index = 'Ticks', columns = 'Scenario', values = 'ClusterNo', aggfunc = np.mean).plot(figsize=(12,9))

for i in range(1,scenarios):
    dt1 = d1.loc[d1['Scenario']==i],['Ticks','ClusterNo']
    plt.plot(x= dt1['Ticks'], y = dt1['ClusterNo'])
    #d1.loc[d1['Scenario']==i,['ClusterNo','Ticks']].plot(x='Ticks', y='ClusterNo')

# norint nupaisyti tiesiog galima naudoti dataFrame metoda.
r.loc[r['Experiment']==10,['ClusterNo','Ticks']].plot(x='Ticks', y='ClusterNo')



#%% examples
import seaborn as sns

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
    
