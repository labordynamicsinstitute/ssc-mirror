rm(list = ls())
library(AER)
library(data.table)
library(zipcode)
library(readstata13)
library(geosphere)
library(evd)

#####################
### Preliminaries ###
#####################
set.seed(1234)
num_hosp <- 15
num_sys <- 7
num_pat <- 50000

# Zipcodes #
num_zip <- 50
patzip <- data.table(zip=(1:num_zip),
                     county=c(rep("A County",round(num_zip/2)),rep("B County",round(num_zip/3)),rep("C County",num_zip - round(num_zip/3) - round(num_zip/2))),
                     latitude=38+rnorm(num_zip,0,1),
                     longitude=-77+rnorm(num_zip,0,1))

# Hospital locations #
hospitals <- data.table(hospid=(1:num_hosp),hospital="",lat=0,lon=0)
alphabet <- "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
for (h in 1:num_hosp) {
  hospitals[h,c('lat','lon')] <- patzip[runif(dim(patzip)[1]) > 0.75,.(lat=mean(latitude),lon=mean(longitude))]
  hospitals[h,c('hospital')] <- paste("Hospital",substring(alphabet,h,h),sep=" ")
}

# Assign systems #
hospitals <- hospitals[,system:=paste("System",sample(1:num_sys,num_hosp,replace=T),sep=" ")]

# Diagnoses #
num_drg <- 999
num_mdc <- 25
diag <- data.table(drg=(1:num_drg),
                   version=1,
                   weight=exp(rnorm(num_drg,0,1)),
                   mdc=sample(1:num_mdc,num_drg,replace=T),
                   med=sample(c("MED","SURG"),num_drg,replace=T))
diag <- diag[, drg.prob:=((1/weight)/sum(1/weight))]

#########################
### Generate patients ###
#########################
discharge <- data.table(id=(1:num_pat),
                        patzip[sample(1:dim(patzip)[1],num_pat,replace=T,prob=patzip$prob),],
                        age=floor(qnorm(pnorm(-35/20) + runif(num_pat)*(1-pnorm(-35/20)))*20 + 35),
                        female=(runif(num_pat) > 0.5),
                        payer_type="Commercial",
                        diag[sample(1:dim(diag)[1],num_pat,replace=T,prob=drg.prob),])

### Hospital choice ###
## Panel dataset ##
panel <- CJ(discharge$id,hospitals$hospid)
colnames(panel) <- c("id","hospid")
panel <- merge(panel,hospitals,by="hospid",all=TRUE)
panel <- merge(panel,discharge,by="id",all=TRUE)
panel <- panel[,dist:=distHaversine(cbind(lon,lat),cbind(longitude,latitude))/1609.34]

## Output distances ##
sim_dist <- panel[,.(admission=id,hospid,hospital,dist)]

## Utility ##
hosp.fe <- 2*rnorm(num_hosp)
util <- with(panel,2*log(dist) + hosp.fe[hospid] + rgumbel(num_pat*num_hosp))

# DRG X (distance, hosp.fe) #
for (i in diag$drg) {
  param <- with(diag,rnorm(1,1/weight[drg == i],1))
  util <- util + param*with(panel,(drg == i)*log(dist))
  for (j in 1:num_hosp) {
    param <- rnorm(1,0,1)
    util <- util + param*with(panel,(drg == i & hospid == j))
  }
}

# (age, gender) X (distance,hosp.fe) #
param <- rnorm(1,0,1) 
util <- util + param*with(panel,(age < 18)*log(dist))
param <- rnorm(1,0,1)
util <- util + param*with(panel,(female == 1)*log(dist))
param <- abs(rnorm(1,0,1))
for (j in 1:num_hosp) {
  param <- rnorm(1,0,1)
  util <- util + param*with(panel,(age < 18 & hospid == j))
  param <- rnorm(1,0,1)
  util <- util + param*with(panel,(female == 1 & hospid == j))
}

## Utility maximizing choice ##
panel <- data.table(panel,util)
choice <- panel[,.(hospid=which.max(util)),by=.(id)]
choice <- merge(choice,hospitals,by="hospid",all=TRUE)

### Combine ###
discharge <- merge(discharge,choice,by="id",all=TRUE)
output <- discharge[,.(admission=id,
                       pat_zip=zip,
                       pat_county=county,
                       age,
                       age_lt18=as.numeric(age < 18),
                       female=as.numeric(female),
                       hosp_id=hospid,
                       hospital,
                       system,
                       drg,
                       version,
                       weight,
                       mdc,
                       payer_type)]

### Save ###
save.dta13(output,file="sim_data.dta",version=15)
