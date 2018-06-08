mydata = read.csv("C:/git/NetLogoModels/myfile.csv")
names(mydata) <- c("c1","c2","c3")
mydata.pca <- prcomp(mydata,center = TRUE, scale. = TRUE) 
print(mydata.pca)