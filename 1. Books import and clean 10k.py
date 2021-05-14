# -*- coding: utf-8 -*-
"""
Created on Mon Feb 15 09:20:31 2021

@author: eblat
"""

#First Script: Books Import and Clean
import pandas as pd 
import numpy as np 
import os 

#Read in books data
books=pd.read_csv(r'https://raw.githubusercontent.com/EduinJBL/goodbooks-10k/master/books.csv')
#authors column lists multiple authors. For now only work with first author
auths=books.authors.str.split(',',expand=True)
books['auth1']=auths.iloc[:,0]
#drop books without isbn codes
books=books.dropna(subset=['isbn'])

#do some cleaning of high profile authors so we get the right books in the series
#drop book GRR Martin published before GoT
grr=books[books.auth1=='George R.R. Martin']
books=books[books.book_id!=7082]
#drop two boxsets of harry potter books which stop it matching 
jkr=books[books.auth1=='J.K. Rowling']
books=books[(books.book_id!=422) & (books.book_id!=2101)]
#drop suzanne collins books before Hunger Games
sc=books[books.auth1=='Suzanne Collins']
scnohg=sc[sc.book_id>1000]
books=books[books.book_id.isin(scnohg.book_id)==False]

db=books[books.auth1=='Dan Brown']
dblesserbooks=db[db.book_id>26]
books=books[books.book_id.isin(dblesserbooks.book_id)==False]
#remove anonymous books
books=books[books.auth1!='Anonymous']


#just test how many times each author comes up
df=books[['auth1','book_id']].groupby('auth1').count()
df=df.sort_values('book_id',ascending=False)

#Check there are no duplicate works. 
books=books.sort_values(['book_id','original_publication_year'])
books=books.drop_duplicates(subset='work_id')

#Find first book published by author
df=books[['auth1','original_publication_year']].groupby('auth1').min()
narrowbook=books[['book_id','auth1','original_publication_year','work_id',
                  'title','work_ratings_count']]

#some authors publish multiple books in the same year. drop these observations 
df=df.merge(narrowbook,on=['auth1','original_publication_year'],how='left')
count=df[['auth1','book_id']].groupby('auth1').count()

count.rename(columns={'book_id':'count'},inplace=True)
df=df.merge(count,on=['auth1'],how='left')
df['count'].value_counts()

df=df[df['count']==1]


#keep only books written by authors where we have the 1st book 
books=books[books['auth1'].isin(df['auth1'])]
#create new dataframe which doesn't have 1st books
books2=books[books['book_id'].isin(df['book_id'])==False]
#now find earliest book published other than the first books
df2=books2[['auth1','original_publication_year']].groupby('auth1').min()
df2=df2.merge(narrowbook,on=['auth1','original_publication_year'],how='left')
count=df2[['auth1','book_id']].groupby('auth1').count()
count.rename(columns={'book_id':'count'},inplace=True)
df2=df2.merge(count,on=['auth1'],how='left')
df2['count'].value_counts()
df2=df2[df2['count']==1]


#Merge 2 dfs to give 1st and second books
df=df.merge(df2,on='auth1',how='inner',suffixes=('1','2'))
df=df.drop(columns=['count1','count2'])
df['total_ratings']=df.work_ratings_count1+df.work_ratings_count2
df.sort_values('total_ratings',ascending=False,inplace=True)
df=df.drop('total_ratings',axis=1)

authlist=df.auth1
df=pd.wide_to_long(df,stubnames=['original_publication_year','book_id',
                                 'work_id','title','work_ratings_count'],
                   i='auth1',j='booknum')

df=df.reset_index(level=['auth1','booknum'])
#Write csvs with just the books we want and just the authors we want 
df.to_csv('cleanedbooks10k.csv',index=False)
authlist.to_csv('cleanedauthors10k.csv',index=False)








