library("fpc")
library("dplyr")

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
  for (ea in split(dfres,dfres$Experiment)) {
    for (s in split(ea,ea$Ticks)){
      r1 <- unlist(c( s[1,1:2], calc_clusters(s)))
      dt <- rbind(dt,r1)
    }
  }
  dtf <-  as.data.frame(dt,c("Experiment","Ticks","ClusterNo","NoicePoints","silwidth"))
  return(dtf)
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

loadAndPlotClusters(fileList, scenarios_no = 3, repetitions = 4)

loadAndPlotClusters(list.files(path = dr, pattern = "res-[1-9]\\d*\\.csv$"), scenarios_no = 3, repetitions = 4)



#dfls <- load_data(list.files(path = dr, pattern = "res-[1-9]\\d*\\.csv$"),c("Experiment","Ticks","V1","V2","V3"))

#for (i in 1:8){
#  plotPairs(dfls,12000,i)
#}
#dfls[10,]




