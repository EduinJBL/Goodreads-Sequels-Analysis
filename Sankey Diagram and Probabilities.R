
library(tidyverse)
library(ggalluvial)
full<-read_csv('fullresults.csv')
full<-as.tibble(full)
full<-full%>%mutate(rating_1=ifelse(is.na(rating_1),0,rating_1),
                    rating_2=ifelse(is.na(rating_2),0,rating_2),
                    count=1)
freqs<-full%>%group_by(rating_1,rating_2)%>%summarise(count=sum(count))
freqs<-freqs%>%arrange(desc(rating_1),desc(rating_2))
freqs<-freqs%>%filter(rating_1*rating_2!=0)
freqs<-freqs%>%mutate(fillc=ifelse(rating_1>rating_2,"Rates Book 1 Better",
                    ifelse(rating_1==rating_2,"Rates Books the Same","Rates Book 2 Better")),
                    freq=count/10^3)

g<-freqs%>%ggplot(aes(y=freq,axis1=rating_1,axis2=rating_2,fill=fillc))
g<-g+geom_alluvium(reverse=FALSE)
g<-g+geom_stratum(width = 1/12,fill="white", reverse=FALSE) +
  geom_label(stat = "stratum", aes(label = after_stat(stratum)),reverse=FALSE,
             min.y=2.5,color="white",show.legend=FALSE)
g<-g+scale_fill_discrete(name="")
g<-g+ggtitle("Goodreads Ratings for Authors' First Two Books",subtitle="Users who rated both books")
g<-g+theme_classic()
g<-g+theme(
  plot.title=element_text(size=18),
  axis.text.x=element_text(size=16),
  panel.background = element_blank(),
  panel.grid=element_blank(),
)
g<-g+scale_x_continuous(breaks=1:2,labels=c("Book 1 Rating","Book 2 Rating"))
g<-g+scale_y_continuous(name="Number of Ratings (1000s)")
g
ggsave("Sankey.png",dpi=1000)

probs<-full%>%mutate(book2notread=ifelse(rating_2==0,1,0))
probs<-probs%>%filter(rating_1!=0)
probs<-probs%>%group_by(rating_1)%>%summarise(count=sum(booknum_1),
                                              notread=sum(book2notread))
probs<-probs%>%mutate(probnotread=notread/count,
                      probread=1-probnotread,
                      count=count/10^3)

g2<-probs%>%ggplot(aes(x=rating_1,y=probread,fill=count))
g2<-g2+geom_bar(stat="identity")+coord_flip()
g2<-g2+theme_classic()+scale_x_continuous(name="Book 1 Rating")
g2<-g2+scale_fill_gradient(name="Number of Ratings(Thousands)",high="springgreen4",low="springgreen2")
g2<-g2+ggtitle("Probability of User Reading Author's 2nd Book \nbased on Rating for 1st Book")
g2<-g2+theme(
  plot.title=element_text(size=18),
  panel.background = element_blank(),
  panel.grid=element_blank(),
)
g2+scale_y_continuous(name="Proportion of Users who rate Book 2",labels=scales::percent)
ggsave("Probabilities.png",dpi=1000)


