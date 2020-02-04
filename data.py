# -*- coding: utf-8 -*-
"""
Created on Mon Feb  3 18:28:25 2020

@author: Arunas
"""

from  data_proc_lib import *
import pandas as pd

#%% fig9 broadcast effecto on social capital
experiment = "0201-08"
df = import_data(experiment,get_path() + '/' + experiment)
dfg = df.groupby(["Experiment","Ticks"])
df_agg_cluster = dfg.apply(calc_cluster).reset_index()
df_with_cluster = dfg.apply(calc_append_cluster_no).reset_index()
#zemiau netinka. 
#f_with_cluster = pd.merge(df,df_agg_cluster, how = 'left', on = ['Experiment','Ticks'], left_index = False, right_index = False).reset_index()
df_with_SD = add_sd_cacl(df_with_cluster,df_agg_cluster)
df_agg_avg_SocCap = cal_avg_social_capital_per_tick(df,10)
plot_var_by_ticks('SCMS',df_agg_avg_SocCap, \
                  {"title":"Broadcast impact radius effect on social capital" , "xlabel":"Steps", "ylabel" : "Social capital", \
                   "labels" : ["event-impact-radius - 0.2","event-impact-radius - 1"]})


#%% fig 7, 8 broadcast effects
experiment = "0201-07"
repetitions = 10
labels = ["prob-event - 0","prob-event - 0.2","prob-event - 1"]
#df = import_data(experiment,get_path() + '/' + experiment)
df = pd.read_csv(get_path() + '/' + experiment +"/data.csv" )
dfg = df.groupby(["Experiment","Ticks"])
df_agg_cluster = dfg.apply(calc_cluster).reset_index()
df_with_cluster = dfg.apply(calc_append_cluster_no).reset_index()
#zemiau netinka. 
#f_with_cluster = pd.merge(df,df_agg_cluster, how = 'left', on = ['Experiment','Ticks'], left_index = False, right_index = False).reset_index()
df_with_SD = add_sd_cacl(df_with_cluster,df_agg_cluster)
df_agg_avg_SocCap = cal_avg_social_capital_per_tick(df,repetitions)
plot_var_by_ticks('SCMS',df_agg_avg_SocCap, \
                  {"title":"Broadcasting effect on social capital" , "xlabel":"Steps", "ylabel" : "Social capital", "labels" : labels })
    
df_aggculster_and_scenarios = cal_avg_cluster_no_perscenariotick(df_agg_cluster,repetitions)

plot_var_by_ticks('ClusterNo',df_aggculster_and_scenarios, \
                  {"title":"Broadcasting effect on clustering" , "xlabel":"Steps", "ylabel" : "Number of clusters", \
                   "labels" : ["prob-event - 0","prob-event - 0.2","prob-event - 1"]})
    
plot_deviation(df_with_SD,True,False, {"title":"Broadcasting effect standard deviation" , "xlabel":"Steps", "ylabel" : "Standard deviantion", "labels" : labels},repetitions)
