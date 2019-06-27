library("fpc")
library("dplyr")


calc_clusters <- function(df) {
  ds = df[3:5]
  db_p <- fpc::dbscan(ds, eps = 7, MinPts = 30)
  num_of_noicepoints = length(db_p$cluster[db_p$cluster == 0])
  num_of_clusters = max(db_p$cluster)
  #return(db_p)
  #print(db_p$cluster)
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

#

# dfres<-read.table("res-1.csv",
#                   header = FALSE,   # set {columns names true
#                   sep = ",",    # define the separator between       columns
#                   fill = TRUE )
load_data <- function(lf,wd){
  setwd(wd)
  for (file_name in lf){
    print(file_name)
    if (!exists("dres"))
      dres <- read.table(file_name, header = FALSE, sep = ",", fill = TRUE )
    else
      dres <- rbind(dres,read.table(file_name, header = FALSE, sep = ",", fill = TRUE ))
  }
  dres <- setNames(dres,c("Experiment","Ticks","V1","V2","V3"))
  return(dres)
}

experimentdata2clusterdata <- function(dfres){
  dt <- NULL #data.frame(Experiment = integer(), Ticks = integer(), ClusterNo =  integer(), NoicePoints = integer(), silwidth = double())
  for (ea in split(dfres,dfres$Experiment)) {
    for (s in split(ea,ea$Ticks)){
      r1 <- unlist(c( s[1,1:2], calc_clusters(s)))
      #print(class(r1))
      #print("eee")
      dt <- rbind(dt,r1)
    }
  }
  dtf <-  as.data.frame(dt,c("Experiment","Ticks","ClusterNo","NoicePoints","silwidth"))
  return(dtf)
}
#ds = dfres[3:5]
#db <- fpc::dbscan(ds, eps = 7, MinPts = 30)
#num_of_clusters = max(db$cluster)
#num_of_noicepoints = length(db$cluster[db$cluster == 0])
#cs = cluster.stats(dist(ds), db$cluster)

# experiment_data <- split(dfres,dfres$Experiment)
r1 = NULL
dr = "C:/git/MII-NetlogoModels/NetLogoModels"
file_list = list.files(path = dr, pattern = "res-..csv")
experiments <- 1:8
repetitions <- 4

if (length(experiments) != length(file_list))
  throw("Files don't match experiments")


dfres <- load_data(file_list,dr)
dtf <- experimentdata2clusterdata(dfres)


dtfs <- split(dtf,dtf$Experiment)
dx =dtfs[[1]]$V3
plot(x=dx, type="l")
 
for (dn in dtfs[-1]) {
   #print(dn)
   lines(x = dn$V3 )
}
  


# ls_ds <- split(dfres,dfres$Ticks)
# 
# ls_ds_1 = ls_ds[[1]]

# #f1(ls_ds[[1]])
# 
# rf = NULL
# 
# for (d in ls_ds) {
#   rf <- rbind(rf,calc_clusters(d))
#   
# }
