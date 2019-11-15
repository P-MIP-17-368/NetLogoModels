# -*- coding: utf-8 -*-
"""
Created on Thu Nov 14 23:50:15 2019

@author: Arunas
"""

import pandas as pd


users = pd.DataFrame( {"User" : [1, 2], "Country" :[1, 2], "Name" : ["J","S"]})
orders = pd.DataFrame( {"Order" : [12, 21, 34, 45], "User" : [1, 2, 2, 1],  "Country": [1, 2, 2, 1]})

result = pd.merge(orders,users, how = 'left', on = ["User","Country"])
print(result)