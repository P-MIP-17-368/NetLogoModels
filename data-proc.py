# -*- coding: utf-8 -*-
"""
Created on Mon Mar 26 13:57:28 2018

@author: Arunas
"""
import pandas as pd
import matplotlib.pyplot as plt
dt = pd.read_csv('C:/temp/Model_v2 experiment-table po 100.csv')
dt1 = dt[['[run number]','[step]','max-cluster','num-cluster','num-cluster-bigger-than-x']] [(dt['[step]'] % 100 == 0) & (dt['[step]'] > 0)]
dt1.to_csv('c:/temp/filtered.csv')
dtg = dt1.groupby(['[run number]'])
plt.figure(); dtg.plot(y='max-cluster', x='[step]');