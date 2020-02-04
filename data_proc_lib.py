#-*- coding: utf-8 -*-
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

import platform
import os, re
import shutil
from datetime import date
import pandas as pd
from math import sqrt
from sklearn.cluster import DBSCAN  
import numpy as np
import matplotlib.pyplot as plt
from math import ceil
import scipy.spatial as sp
from scipy.spatial import distance
from statistics import mean



regex = re.compile('res-[1-9]\\d*\\.csv$')

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
      codeFolder = 'C:/git/MII-NetlogoModels/NetLogoModels'
    else :
      #wdNetlogoCode = 'C:/code/u/NetLogoModels'
      codeFolder = 'C:/code/u/NetLogoModels'
    return codeFolder

def target_path(target,no):
    datepart = date.today().strftime("%m%d")
    tfolderdir = target + '/' + datepart + '-' + no
    return tfolderdir

def move_exp_files(codeFolder,tfolderdir,regex,deleteFiles = False):
       
    files_found = False
    for file in os.listdir(codeFolder):
        if regex.match(file):
            print("files found in %s" % codeFolder )
            files_found = True
            break
    
    if not files_found: 
        print("No files found in %s. Exiting" % codeFolder)
        return
               
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


def import_data(experiment, folder):
    li = []
    for file in os.listdir(folder):
        if regex.match(file):
            print(file)
            df = pd.read_csv(folder + '/' + file, header = None, names = ["Experiment","Ticks",'id',"V1","V2","V3","sc"])
            li.append(df)
    
    df = pd.concat(li, ignore_index = True)
    return df

  
#uztenka tik sito pasetinti is move'ina. data ima is dabartines
def move_experiment_files(exp_day_no):
#exp_day_no = "08"      
    regex = re.compile('res-[1-9]\\d*\\.csv$')
    move_exp_files(source_path(),target_path(get_path(),exp_day_no),regex,True)
    return
 
#%% cluster calc functions



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

def filter_e(data,experiment,ticks):
    return(data.loc[(data['Experiment'] == experiment ) & ( data['Ticks'] == ticks),:])
    
    
'''
calc_sd(df.loc[(df['Experiment']==1) & (df['Ticks'] == 1000),:],['V1','V2','V3'])
'''
# klasteriai
# sd (su klasteriais ir be)

#todo iskelti
def main(df):
    dfg = df.groupby(["Experiment","Ticks"])
    #paskaiciuojamt klasterius
    df_agg_cluster = dfg.apply(calc_cluster).reset_index()
    # kadangi agreguotas, tai prideama prie pradinio kad gauti agentus su priskirtais klasteraisi
    df_with_cluster = dfg.apply(calc_append_cluster_no).reset_index()
    return
    
    # vietoje calc_append_cluster_no uzkomentuoju nes nenaudoju
    #df_full_with_clusteraggs = pd.merge(df,df_agg_cluster, how = 'left', on = ['Experiment','Ticks'], left_index = False, right_index = False)
    
    
def add_sd_cacl(df_with_cluster,df_agg_cluster):
    # gauname pagal grupes
    sd4clusters = df_with_cluster[df_with_cluster["Cluster"] > -1].groupby(["Experiment","Ticks","Cluster"]).apply(calc_sd_series).reset_index()
    sd4clustersMean = sd4clusters.groupby(["Experiment","Ticks"])["ClusterSD"].mean().reset_index()
    sd4tickworld = df_with_cluster.groupby(["Experiment","Ticks"]).apply(calc_sd_series).reset_index()
    sdMerged = pd.merge(sd4tickworld,sd4clustersMean, how = 'left', on = ['Experiment','Ticks'], suffixes = ["global","mean"])
    sdMerged = pd.merge(sdMerged,df_agg_cluster,how = 'left', on = ['Experiment','Ticks'])
    return(sdMerged)


#%% adding scenario and making calculations by scenario



# galima padaryti viena eilute
def append_scenario(data,repetitions):
    experiments = max(df['Experiment'])
    #repetitions = 10
    scenarios = int(experiments / repetitions)
    sdMerged = data
    sdMerged['Scenario'] =  ( sdMerged['Experiment'] / repetitions ).apply(ceil)
    cols = sdMerged.columns.tolist()
    cols = cols[-1:] + cols[:-1]
    sdMerged = sdMerged[cols]
    return(sdMerged)



def cal_avg_cluster_no_perscenariotick(df_agg_cluster,repetitions):
    df_aggculster_and_scenarios = df_agg_cluster.assign( Scenario = (df_agg_cluster['Experiment'] / repetitions).apply(ceil))
    return(df_aggculster_and_scenarios.groupby(['Scenario','Ticks']).agg({'ClusterNo' : [np.mean]}).reset_index())

#df_with_culster_and_scenarios = df_with_cluster.assign( Scenario = (df_with_cluster['Experiment'] / repetitions).apply(ceil))
#df_aggculster_and_scenarios = df_agg_cluster.assign( Scenario = (df_agg_cluster['Experiment'] / repetitions).apply(ceil))

#d1 = df_aggculster_and_scenarios.groupby(['Scenario','Ticks']).agg({'ClusterNo' : [np.mean]}).reset_index()
# panasiai galima daryti ir pivot table
#p1 = df_aggculster_and_scenarios.pivot_table(index = 'Ticks', columns = 'Scenario', values = 'ClusterNo', aggfunc = np.mean)

# sd4clusters['Scenario'] = ( sd4clusters['Experiment'] / repetitions).apply(ceil) uzkomentuoju nes veliau nenaudojau

#sd4clusters_pivot = sd4clusters.pivot_table(index = 'Ticks', columns = ['Scenario','Experiment'])


#%% calc average soc capital

def cal_avg_social_capital_per_tick(data,repetitions):
    dfg = data.groupby(["Experiment","Ticks"])
    df_agg_by_socap = dfg.agg(SCM = pd.NamedAgg(column='sc', aggfunc = 'mean')).reset_index()
    df_agg_by_socap['Scenario'] =  ( df_agg_by_socap['Experiment'] / repetitions ).apply(ceil)
    df_agg_by_socap_gpr = df_agg_by_socap.groupby(["Scenario","Ticks"])
    df_agg_by_socap_scenario = df_agg_by_socap_gpr.agg(SCMS = pd.NamedAgg(column='SCM', aggfunc = 'mean')).reset_index()
    return(df_agg_by_socap_scenario)



#plot_var_by_ticks('SCMS',df_agg_by_socap_scenario, \
#                  {"title":"Broadcast impact radius effect on social capital" , "xlabel":"Steps", "ylabel" : "Social capital", \
#                   "labels" : ["0.2","1","1","0.1","0.5","0.9"]}



#plt.figtext(0,1,"Initial values effect on social capital") 



#%% plot clusters SD values


def plot_deviation(data,globalSD,meanSD, params,repetitions):
    sdMerged = data
    sdMerged['Scenario'] =  ( sdMerged['Experiment'] / repetitions ).apply(ceil)
    cols = sdMerged.columns.tolist()
    cols = cols[-1:] + cols[:-1]
    sdMerged = sdMerged[cols]
    
    if meanSD:
        raise("Not implemented")
    #sdMergedPivot = sdMerged[sdMerged["Scenario"].isin([4,5,6])].pivot_table(index = 'Ticks', columns = 'Scenario', values = ['ClusterSDglobal', 'ClusterSDmean'] )
    #sdMergedPivot = sdMerged.pivot_table(index = 'Ticks', columns = 'Scenario', values = ['ClusterSDglobal', 'ClusterSDmean'] )
    if globalSD:
        sdMergedPivotG = sdMerged.pivot_table(index = 'Ticks', columns = 'Scenario', values = ['ClusterSDglobal'] )
    
    if meanSD:
        sdMergedPivotC = sdMerged.pivot_table(index = 'Ticks', columns = 'Scenario', values = ['ClusterSDmean'] )
    
    if globalSD:
        p = sdMergedPivotG.plot(figsize=(12,9),title =params["title"])
        p.set_xlabel(params["xlabel"])
        p.set_ylabel(params["ylabel"])
        p.legend(params["labels"])
    #sdMergedPivotC.plot(figsize=(12,9))

    return

#%% plot cluster no



# params is dict

def plot_var_by_ticks(var_name,data,params):

    # galima tiesiog plot
    #df_aggculster_and_scenarios.pivot_table(index = 'Ticks', columns = 'Scenario', values = 'ClusterNo', aggfunc = np.mean).plot(figsize=(12,9))
    d1 = data
    
    scenarios = max(d1['Scenario'])
    if "labels" in params:    
        lbl1 = params["labels"]
    else:
        lbl1 = None
    for i in range(1,scenarios+1):
        dt1 = d1.loc[d1['Scenario']==i]
        if (lbl1):
            plt.plot(dt1['Ticks'],  dt1[var_name], label = lbl1[i-1])
        else:
            plt.plot(dt1['Ticks'],  dt1[var_name], label = i)
        #d1.loc[d1['Scenario']==i,['ClusterNo','Ticks']].plot(x='Ticks', y='ClusterNo')
    
    if "title" in params:
        plt.title(params["title"])
    plt.xlabel(params["xlabel"])
    plt.ylabel(params["ylabel"])
    plt.legend()
    plt.show()
    
    # norint nupaisyti tiesiog galima naudoti dataFrame metoda.
    #r.loc[r['Experiment']==10,['ClusterNo','Ticks']].plot(x='Ticks', y='ClusterNo')
    return




#%% seaborn wrapper for pair plot
import seaborn as sns

def plot_pairs(data,ex,ticks):
    sns.pairplot(data.loc[(data['Experiment'] == ex ) & ( data['Ticks'] == ticks),:], 
                    vars= ['V1','V2','V3'], 
                    hue = 'Cluster', 
                    diag_kind = 'hist')
    

#for i in range(21,31):
#    plot_pairs(df_with_cluster,i,550)
    
#%%




 

#%%



def tst(x):
    print(type(x))
    print(x)
    
#%% k-means 
from sklearn.cluster import KMeans


# pakeiciau bet netestavau
def do_kmeans_for_step(data,experiment,tick):
    
    #bandome skaiciuoti pagal K-means. Cia kokkreciame eksperimente matom kad yra klasteriu
    # juos issitraukiam i X. 
    X = filter_e(data,experiment,tick)[['V1','V2','V3']]
    
    # skaiciuojam ivairiam klasteriu skaiciui ir ziurime grafika pagal elbow method
    wcss = []
    for i in range(1,11):
        kmeans = KMeans(n_clusters=i, init='k-means++', max_iter=300, n_init=10, random_state=0)
        kmeans.fit(X)
        wcss.append(kmeans.inertia_)
    
    plt.plot(range(1, 11), wcss)
    plt.title('Elbow Method')
    plt.xlabel('Number of clusters')
    plt.ylabel('WCSS')
    plt.show()
    
    # jei luzis ant tam tikro skaiciaus issivedama ta vaizda. plius parenkam pagal klasteri spalvas
    elbowBreakPoint = 4
    kmeans = KMeans(n_clusters=elbowBreakPoint, init='k-means++', max_iter=300, n_init=10, random_state=0)
    pred_y = kmeans.fit_predict(X)
    X['clusterKM'] = pred_y
    sns.pairplot(X, vars= ['V1','V2','V3'], hue = "clusterKM", diag_kind = 'hist')
    
    #plt.scatter(X[:,0], X[:,1])
    #plt.scatter(kmeans.cluster_centers_[:, 0], kmeans.cluster_centers_[:, 1], s=300, c='red')
    #plt.show()
    return


from sklearn.decomposition import PCA

def do__plot_pca(X):
    pca = PCA(n_components=2)
    
    X = X.reset_index()
    x2 = X[['V1','V2','V3']]
    principalComponents = pca.fit_transform(x2)
    principalDf = pd.DataFrame(data = principalComponents, columns = ['pcV1', 'pcV2'])
    print(pca.explained_variance_ratio_)    
    finalDf = pd.concat([principalDf, X[['clusterKM']] ], axis = 1)
    
    plt.scatter(finalDf.pcV1,finalDf.pcV2,c =finalDf.clusterKM)




