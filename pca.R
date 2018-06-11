mydata = read.csv("C:/git/NetLogoModels/myfile.csv", header = FALSE)
names(mydata) <- c("c1","c2","c3")
mydata.pca <- prcomp(mydata,center = FALSE, scale. = FALSE) 
print(mydata.pca)
st_dev <- mydata.pca$sdev
prop_varex <- pr_var/sum(pr_var)
