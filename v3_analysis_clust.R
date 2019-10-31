library("fpc")
library("dplyr")
library("dbscan")
#library("tidyverse")

if (Sys.info()['nodename'] == "DESKTOP-DTFRNI0") {
  wdNetlogoCode <- 'C:/git/MII-NetlogoModels/NetLogoModels'
  wdExperimentArchive <- 'C:/Users/oruna/OneDrive/darbas/MII projektas/Experiments/'
} else {
  wdNetlogoCode <- 'C:/code/u/NetLogoModels'
  wdExperimentArchive <- 'C:/Users/milibaru/OneDrive/darbas/MII projektas/Experiments/'
}

calc_clusters <- function(df) {
  ds = df[4:6]
  db_p <- fpc::dbscan(ds, eps = 7, MinPts = 15)
  num_of_noicepoints = length(db_p$cluster[db_p$cluster == 0])
  num_of_clusters = max(db_p$cluster)
  if ((length(db_p$cluster[db_p$cluster > 0]) > 0 ) && (num_of_noicepoints > 0)) {
    cs = cluster.stats(dist(ds), db_p$cluster)
    #num_of_clusters = cs$cluster.number
    #plot(db_p, ds, main = "DBSCAN", frame = FALSE)
    return(c (cs$cluster.number, num_of_noicepoints, cs$avg.silwidth ))
  }
  else
    {return(c(num_of_clusters,num_of_noicepoints,NA))}
  #return(c (cs$cluster.number, cs$avg.silwidth ))
}

calc_and_append_clusters <- function(df) {
  ds = df[4:6]
  db_p <- dbscan::dbscan(ds, eps = 7, minPts = 15)
  df$cluster <- db_p$cluster
  return(df)
}


load_data_single_file <- function(filename) {
  return(setNames(load_data_file(filename),c("Experiment","Ticks","V1","V2","V3")))
}

load_data_file <- function(filename) {
  dfres<-read.table(filename,
                    header = FALSE,   # set {columns names true
                    sep = ",",    # define the separator between       columns
                    fill = TRUE )
  return(dfres)
}

load_data <- function(lf,newColumnNames){
  for (file_name in lf){
    print(file_name)
    if (!exists("dres"))
      dres <- read.table(file_name, header = FALSE, sep = ",", fill = TRUE )
    else
      dres <- rbind(dres,read.table(file_name, header = FALSE, sep = ",", fill = TRUE ))
  }
  dres <- setNames(dres,newColumnNames)
  return(dres)
}

experimentdata2clusterdata <- function(dfres){
  dt <- NULL #data.frame(Experiment = integer(), Ticks = integer(), ClusterNo =  integer(), NoicePoints = integer(), silwidth = double())
  # split by experiments
  for (ea in split(dfres,dfres$Experiment)) {
    # split further by ticks
    for (s in split(ea,ea$Ticks)){
      # foreach tick in experiment we calculate clusters
      # first row, and first 2 columns (experiment and ticks)
      r1 <- unlist(c( s[1,1:2], calc_clusters(s)))
      dt <- rbind(dt,r1)
    }
  }
  dtf <-  as.data.frame(dt,c("Experiment","Ticks","ClusterNo","NoicePoints","silwidth"))
  dtf <-  setNames(dtf,c("Experiment","Ticks","ClusterNo","NoicePoints","silwidth"))
  return(dtf)
}

#version where cluster no just added to data
experimentdataextendwithclusterdata <- function(dfres){
  dt <- NULL #data.frame(Experiment = integer(), Ticks = integer(), ClusterNo =  integer(), NoicePoints = integer(), silwidth = double())
  # split by experiments
  for (ea in split(dfres,dfres$Experiment)) {
    # split further by ticks
    for (s in split(ea,ea$Ticks)){
      # foreach tick in experiment we calculate clusters. Function just appends cluster no
      dt <- rbind(dt,calc_and_append_clusters(s))
    }
  }
#dtf <-  as.data.frame(dt,c("Experiment","Ticks","ClusterNo","NoicePoints","silwidth"))
  return(dt)
}

# should be same as experimentdataextendwithclusterdata only code is shorter
experimentdataextendwithclusterdata2 <- function(dfres) {
  t <- split(dfres,list(dfres$Experiment,dfres$Ticks))
  t2 <- lapply(t,calc_and_append_clusters)
  result_t<- do.call(rbind, t2)
  return(result_t)
}



#calculates mean values, standard deviation for columns V1, V2, V3 in frame. should filtered, grouped if needed before
meanValues <- function(d) {
  return(c(mean(d$V1),sd(d$V1),mean(d$V2),sd(d$V2),mean(d$V3),sd(d$V3), sd(as.matrix(d))))
}


#calculated mean values by cluster
meanValuesByCluster <- function(d){
  dbycluster <- split(d,d$cluster)
  r <- lapply(dbycluster,meanValues)
  return(do.call(rbind,r))
}

experimentdata2meandata <- function(dfres){
  dt <- NULL 
  for (ea in split(dfres,dfres$Experiment)) {
    for (s in split(ea,ea$Ticks)){
      r1 <- unlist(c( s[1,1:2], mean(s)))
      dt <- rbind(dt,r1)
    }
  }
  dtf <-  as.data.frame(dt,c("Experiment","Ticks","ClusterNo","NoicePoints","silwidth"))
  return(dtf)
}

aggregate_by_clusters <- function(dtf) {
  df <- group_by(dtf,Ticks)
  df <- summarize(df, V3A = mean(V3))
  return(df)
}

aggregate_by_soccap <- function(dtf) {
  df <- group_by(dtf,Ticks)
  df <- summarize(df, scA = mean(sc))
  return(df)
}



#ds = dfres[3:5]
#db <- fpc::dbscan(ds, eps = 7, MinPts = 30)
#num_of_clusters = max(db$cluster)
#num_of_noicepoints = length(db$cluster[db$cluster == 0])
#cs = cluster.stats(dist(ds), db$cluster)
# experiment_data <- split(dfres,dfres$Experiment)


#loads experiments from files.
loadExperiments <- function(fileList,scenarios_no,repetitions) {
  experimentsCount <- scenarios_no * repetitions
  if (experimentsCount != length(fileList))
    throw("Files don't match experiments")
  df <- load_data(fileList,c("Experiment","Ticks","id","V1","V2","V3","sc"))
  #df <- mutate(df, Scenario = ceiling(Experiment / repetitions))
  return(df)

}

loadAndPlotClusters <- function(fileList,scenarios_no,repetitions) {
  experimentsNo <- scenarios_no * repetitions

  dfres <- loadExperiments(fileList,scenarios_no,repetitions)
  dtf <- experimentdata2clusterdata(dfres)
  dtf <- mutate(dtf, Scenario = ceiling(Experiment / repetitions))
  #dtf <- mutate(dtf, Ticks = Ticks / 1000) #skale mazinam
  
  t1 <- group_by(dtf,Scenario)
  ts <- lapply(split(t1,t1$Scenario),aggregate_by_clusters)
  
  xrange <- range(dtf$Ticks) 
  yrange <- range(dtf$V3)
  colors <- rainbow(scenarios_no)
  linetype <- c(1:scenarios_no)
  plotchar <- seq(18,18+scenarios_no,1)
  
  #plot(xrange, yrange, type="n", xlab="Ticks (1000)", ylab="Clusters (average)" )
  plot(xrange, yrange, type="n", xlab="Ticks", ylab="Clusters (average)" ) 
  
  for (i in 1:scenarios_no) {
    i_dt <- ts[[i]]
    #lines(x = i_dt$Ticks, y=i_dt$V3A, type="b", lty=linetype[i], col=colors[i], pch=plotchar[i]  )
    lines(x = i_dt$Ticks, y=i_dt$V3A, type="l", lty=linetype[i], col=colors[i]  )# tik linijoe
  }
  
  title("Clusters", "Avergage cluters in scenarios")
  
  legend(xrange[1], yrange[2], 1:scenarios_no, cex=0.8, col=colors,
         pch=plotchar, lty=linetype, title="Scenario no")
  return()

}



loadAndPlotBySocCap <- function(listfiles,scenarios_no,repetitions){
  exps <- scenarios_no * repetitions
  dfls <- loadExperiments(listfiles,scenarios_no,repetitions)
  dtf <- mutate(dfls, Scenario = ceiling(Experiment / repetitions))
  t1 <- group_by(dtf,Experiment)
  ts <- lapply(split(t1,t1$Experiment),aggregate_by_soccap)
  xrange <- range(dtf$Ticks) 
  yrange <- range(dtf$sc)
  colors <- rainbow(scenarios_no)
  linetype <- c(1:scenarios_no)
  plot(xrange, yrange, type="n", xlab="Ticks", ylab="Soc cap (average)" ) 
  for (i in 1:exps) {
    i_dt <- ts[[i]]
    lines(x = i_dt$Ticks, y=i_dt$scA, type="l", col=colors[ceiling(i / repetitions)] #, lty=linetype[ceiling(i / repetitions)] 
          )
  }
  legend("center", yrange, legend = 1:scenarios_no, cex=0.8, col=colors,
         lty=linetype, 
         title="Scenario no")
  return()
}

loadAndPlotSingle <- function(fileName) {
  
  dfres <- load_data_single_file(fileName)
  dtf <- experimentdata2clusterdata(dfres)
  
  plot(dtf$Ticks, dtf$V3, type="b", xlab="Ticks",
       ylab="Clusters" ) 
  
  title("Clusters", "Clusters")
  
  return()
  
}



plotPairs <- function(df,ticks,i){
  di <- dfls [dfls$Ticks == ticks & dfls$Experiment == i,]
  pairs(di[,3:5],pch=19, main = sprintf("Exp %s", i))
}

dr = wdNetlogoCode
setwd(dr)


#loadAndPlotSingle("res-0.csv")


#dt1 = load_data_single_file("res-0.csv")
#d1 <- dt1[dt1$Ticks == 100,]
#pairs(d1[,3:5],pch=19)
dr <- paste(wdExperimentArchive,"0812-11",sep='')
setwd(dr)
fileList <- list.files(path = dr, pattern = "res-[1-9]\\d*\\.csv$")


#usually run until this line (functions and main vars)
#code below for testing and should be run line by line


loadAndPlotClusters(fileList, scenarios_no = 4, repetitions = 4)
#loadAndPlotClusters(list.files(path = dr, pattern = "res-[1-9]\\d*\\.csv$"), scenarios_no = 3, repetitions = 4)


dfls <- load_data(list.files(path = dr, pattern = "res-[1-9]\\d*\\.csv$"),c("Experiment","Ticks","V1","V2","V3"))

for (i in 1:8){
  plotPairs(dfls,12000,i)
}
dfls[10,]


scenarios_no <- 4
repetitions <- 4

dfres <- loadExperiments(fileList,scenarios_no,repetitions)
dtf <- experimentdata2clusterdata(dfres)

#prints plots and uses colors from dbscan cluster no
pairs(d1[4:6], col =  db_p$cluster + 1L)
colMeans(d1[db_p$cluster==1, ])

#currently it works with one experiment selected
t2 <- experimentdataextendwithclusterdata2(dfres)


#can plot pairs
d4 <- d2[which(d2$Ticks == 1000),]
pairs(d2[4:6], col = d2$cluster + 1L)

sdm <- function(d){
  d1 <- d %>% filter(cluster > 0) 
  d1s <- split(d1,d$cluster)
  r <- lapply(d1s,sdi)
  return(r)
}

sdi <- function() {
  t <- d %>% select(starts_with("V")) %>% as.matrix()
  return(sd(t))
}



#this is not working yet
d5 <- t2 %>% filter(cluster > 0)
d6 <- split(t2,list(t2$Experiment,t2$Ticks))
d7 <- lapply(d6,sdm)
%>% group_by(Experiment,Ticks, cluster) %>% summarise(s = sds())
  summarize(V12 = mean(d2$V1))

# on value cal
meanValuesByCluster(t2[which(t2$Experiment == 14 & t2$Ticks == 1000 & t2$cluster > 0),])
