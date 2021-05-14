library(tidyverse)
library(metR)
results<-read_csv('results.csv')
results<-results%>%select(-X1,-count1,-count2,-weighting_factor)
results<-results%>%gather(variable,value,-author_id,-countboth)
results<-results%>%separate(variable,c("Bookno","Adjusted"),4)
results<-results%>%spread(Bookno,value)
results<-results%>%mutate(Adjusted=ifelse(Adjusted=="adj","Adjusted \n (users who rated both books)","Not Adjusted \n (any user who rated either book)"))
results<-results%>%arrange(desc(countboth))
results<-results%>%filter(countboth>=2000)
line<-tibble(x=seq(3,5,by=0.1))
line<-line%>%mutate(y=x)
results<-results%>%mutate(lab=ifelse(countboth>=2000,author_id,NA))

g<-results%>%ggplot(aes(x=avg1,y=avg2,colour=Adjusted,size=countboth))
g<-g+geom_point()#+geom_text(aes(label=lab),hjust=0,vjust=0,size=5,colour="black")

g<-g+geom_line(data=line,aes(x=x,y=y,),colour="black",size=1,
               linetype="dashed")




#add arrows to scatter plot
res2<-read_csv('results.csv')
res2<-res2%>%mutate(diff_1=avg1adj-avg1,
                    diff_2=avg2adj-avg2)

res2<-res2%>%filter(countboth>=2000)
res2<-res2%>%mutate(author_id=replace(author_id,author_id%in%c("Suzanne Collins","J.K. Rowling","George R.R. Martin","Dan Brown"),paste(author_id,"*",sep="")))
res2<-res2%>%mutate(lab=ifelse(countboth>=2000,author_id,NA),
                    hor=-0.2,
                    vert=0.5)
res2<-res2%>%mutate(vert=replace(vert,author_id=="Khaled Hosseini",-0.1),
                    hor=replace(hor,author_id=="Dan Brown*",0.8),
                    vert=replace(vert,author_id=="Cassandra Clare",0.9),
                    vert=replace(vert,author_id=="Suzanne Collins*",0.9),
                    vert=replace(vert,author_id=="J.K. Rowling*",0.7))







g<-g+geom_segment(data=res2,aes(x=avg1,y=avg2,xend=avg1adj,yend=avg2adj),
                  colour="black",arrow=arrow(),
                  size=0.1)
g<-g+geom_text(data=res2,aes(x=avg1adj,y=avg2adj,label=lab,hjust=hor,vjust=vert),
               size=3,colour="#946157")
g<-g+theme_classic()
g<-g+scale_x_continuous(name="Book 1 Average Rating",limits=c(3.5,5))
g<-g+scale_y_continuous(name="Book 2 Average Rating",limits=c(3.5,5))
g<-g+scale_size_continuous(name="Total Ratings in Sample", range=c(3,8))
g<-g+scale_color_discrete(name="")+ guides(colour = guide_legend(override.aes = list(size=10)))
g<-g+ggtitle("Top Authors Book Ratings",subtitle="Adjusted for composition effects")
g<-g+geom_text(aes(y=4.9,x=4.8),label="Book 2 is Better",colour="black",size=4,angle=45)
g<-g+geom_text(aes(y=4.8,x=4.9),label="Book 1 is Better",colour="black",size=4,angle=45)
g<-g+labs(caption="*I have removed earlier books for some authors to capture well known series.")                        
g<-g+theme(
  plot.title=element_text(size=12),
  panel.background = element_blank(),
  panel.grid=element_blank()
)

g
ggsave("Scatter,png",dpi=1000)


#Now make bar chart
res3<-read_csv('results.csv')
res3<-res3%>%drop_na()
res3<-res3%>%select(-X1,-count1,-count2)
res3<-res3%>%gather(variable,value,-author_id,-countboth,-weighting_factor)
res3<-res3%>%separate(variable,c("Measure","Bookno","Adjusted"),c(3,4))%>%select(-Measure)
#results<-results%>%spread(Bookno,value)
res3<-res3%>%mutate(Adjusted=ifelse(Adjusted=="adj","Adjusted \n (users who rated both books)","Not Adjusted \n (any user who rated either book)"),
                    Adjusted=factor(Adjusted,levels=c("Not Adjusted \n (any user who rated either book)","Adjusted \n (users who rated both books)")))
res3<-res3%>%group_by(Bookno,Adjusted)%>%summarise(wavg=weighted.mean(value,w=weighting_factor),
                                                         wavgtest=weighted.mean(value,w=countboth))

res3<-res3%>%mutate(wavground=round(wavg,2))
g2<-res3%>%ggplot(aes(fill=Adjusted,y=wavg,x=Bookno))
g2<-g2+ylim(c(3,5))
g2<-g2+theme_classic()+geom_bar(stat="identity",position="dodge")
g2<-g2+geom_text(aes(label=wavground), position = position_dodge(width = 1),vjust=-0.5)
g2<-g2+scale_fill_manual(name="",values=c("#00BFC4","#F8766D"))+guides(fill = guide_legend(override.aes = list(size=10)))
g2<-g2+ggtitle("Average Ratings for Authors' First and Second Books on Goodreads",subtitle=
                 "Adjusted for Composition Effects")
g2<-g2+scale_x_discrete(name="Book Number",labels=c("Book 1","Book 2"))
g2<-g2+scale_y_continuous(name="Weighted Average of Ratings")
g2<-g2+theme(
  plot.title=element_text(size=18),
  panel.background = element_blank(),
  panel.grid=element_blank(),
)

g2
ggsave("Bargraph.png",dpi=1000)
                                                                          

