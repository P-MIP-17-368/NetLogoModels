# -*- coding: utf-8 -*-
"""
Created on Thu Nov 14 18:23:02 2019

@author: Arunas
"""

# importing pandas module 
import pandas as pd 

# creating a blank series 

# reading csv file 
data = pd.DataFrame([['Bulbasaur','Grass'],
                     ['Ivysaur','Grass'],
                     ['Venusaur','Grass'],
                     ['Charmander','Fire'],
                     ['Charmeleon','Fire']],columns=['Pokemon','Type'])

#Type_new = pd.Series([]) 
Type_new = [None] * len(data)

# running a for loop and asigning some values to series 
for i in range(len(data)): 
	if data["Type"][i] == "Grass": 
		Type_new[i]="Green"

	elif data["Type"][i] == "Fire": 
		Type_new[i]="Orange"

	elif data["Type"][i] == "Water": 
		Type_new[i]="Blue"

	else: 
		Type_new[i]= data["Type"][i] 

		
# inserting new column with values of list made above		 
data.insert(2, "Type New", Type_new) 

# list output 
print(data.head())
