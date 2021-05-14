# -*- coding: utf-8 -*-
"""
Created on Mon Feb 15 09:20:30 2021

@author: eblat
"""

# -*- coding: utf-8 -*-
"""
Created on Mon Feb 15 09:20:31 2021

@author: eblat
"""

#Books Import and Author Match
import pandas as pd 
import numpy as np 
import os 
import matplotlib.pyplot as plt


#Read in cleaned books and authors data
df=pd.read_csv('cleanedbooks10k.csv')
authlist=pd.read_csv('cleanedauthors10k.csv')
authlist=authlist.auth1

#Read in dataset which shows interactions between users and books
ints=pd.read_csv(r'https://raw.githubusercontent.com/EduinJBL/goodbooks-10k/master/ratings.csv')
ints=ints.merge(df,on='book_id',how='inner')

#Define a function that gets key stats for each author from the interactions dataset
def authorstats(author,data=ints):
    usedata=data[data.auth1==author]
    usedata1=usedata[usedata.booknum==1]
    usedata2=usedata[usedata.booknum==2]
    #calculate average ratings for author's first and second books
    avg1=usedata1['rating'].mean()
    avg2=usedata2['rating'].mean()
    #calculate number of ratings for author's first and second books
    count1=usedata1['rating'].count()
    count2=usedata2['rating'].count()
    #inner merge data together, so we are only considering people who read both
    #books
    usedata=usedata1.merge(usedata2, on=['auth1','user_id'],how='inner',
                           suffixes=('_1','_2'))
    #Find average rating for each book amongst people who read both books
    avg1adj=usedata.rating_1.mean()
    avg2adj=usedata.rating_2.mean()
    #Number of people who read both books
    countboth=usedata['rating_1'].count()
    #Outer Merge to get total dataset of everyone who read both books
    usedata=usedata1.merge(usedata2, on=['auth1','user_id'],how='outer',
                           suffixes=('_1','_2'))
    #stick key results together in a list to be outputted
    out=[author,avg1,avg2,count1,count2,avg1adj,avg2adj,countboth]
    
    return([out,usedata])




reslist=[]
fulldatalist=[]

#Loop over each author and both key stats and dataset of each observation that rated them
for x in authlist:
    res=authorstats(x)
    reslist.append(res[0])
    fulldatalist.append(res[1])
    


    
#    
results=pd.DataFrame(reslist, 
                     columns=['author_id','avg1','avg2','count1',
                              'count2','avg1adj','avg2adj','countboth',
                              ])



results.sort_values('countboth',ascending=False, inplace=True)


#Find weighted average of ratings by book
results['weighting_factor']=results.countboth.divide(results.countboth.sum())
#results['sampleratio_1']=results.count1.divide(results.work_ratings_count_1)
#results['sampleratio_2']=results.count2.divide(results.work_ratings_count_2)
wavg=results[['avg1','avg2','avg1adj','avg2adj']].multiply(results['weighting_factor'],

                                                           axis="index").sum()

#Define new variable that is difference between adjusted and actual average for book 1 and book 2
wavg['diff_1']=wavg.avg1adj-wavg.avg1
wavg['diff_2']=wavg.avg2adj-wavg.avg2

#Define new variable that is difference between book1 and book2 average, with and without adjustment
results['diff']=results.avg1-results.avg2
results['diff_adj']=results.avg1adj-results.avg2adj

#Export to csv
wavg.to_csv('wavg.csv')
results.to_csv('results.csv')

#Create a dataset that has all the reviews for all authors with two books reviewed. 
#create dataset out of list of datasets 
fulldata=fulldatalist[0]
fulldatalist=fulldatalist[1:]
for x in fulldatalist:
    fulldata=fulldata.append(x)
#Export to csv    
fulldata.to_csv('fullresults.csv',index=False)    



