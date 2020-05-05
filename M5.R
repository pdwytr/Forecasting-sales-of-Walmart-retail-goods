library(vroom)
prices = vroom("M5/sell_prices.csv")
calendar=vroom("M5/calendar.csv")
train = vroom("M5/sales_train_validation.csv")
library(ggplot2)
library(stringr)
library(regr) 
library(dplyr)
library(forecast)
library(caret)
library(vars)
library(DMwR)

###sample output
setwd("C:/Users/multi/Desktop")
sample_output = read.csv("sub_dt_lgb.csv ")
colnames(sample_output)
dim(sample_output)
#60980x29


#-------------------------------------------------EDA-------------------------------------------------
###train
dim(train)
#30490x1919
colnames(train)
#id,item_id,dept_id,cat_id,store_id,d_1,d_2......d_1913
head(train)
train[2,1:6]
table(as.factor(train$dept_id))
table(as.factor(train$store_id))
table(as.factor(train$state_id))

###prices
dim(prices)
#6841121x4
colnames(prices)
#"store_id"   "item_id"    "wm_yr_wk"   "sell_price"
head(prices)
str(prices)

###Calender
dim(calendar)
##1969x14
colnames(calendar)
#"date"         "wm_yr_wk"     "weekday"      "wday"         "month"        "year"         "d"            "event_name_1"
#"event_type_1" "event_name_2" "event_type_2" "snap_CA"      "snap_TX"      "snap_WI"     

###There are over 30,000 time series models that need to built.

####Features
##Possible Features for each time series model can be 
#1)Price
#2)SNAP
#3)Event
#4)WeekDay
#5)Month

#Model Selection:
#Interms of the most basic timeseries models, one may consider Moving Averages(MA), Autoregression(AR) or a combination(ARMA)
#Since there are more than one time dependent features to the number of items sold variable
#the ARIMAX model is considered
#Let's first consider a more general model. One model for per State, per category

#There are two options to model on, either modelling on summation of all the measurements of a state
#or modelling on the average measurements of each states
#To use all possible information int he data for modelling, summation of all measurements is considered for modelling.
#the prediction will be averaged for each product after modelling.


#FOODS_1     FOODS_2     FOODS_3   HOBBIES_1   HOBBIES_2 HOUSEHOLD_1 HOUSEHOLD_2 
#2160        3980        8230        4160        1490        5320        5150 

#CA_1 CA_2 CA_3 CA_4 TX_1 TX_2 TX_3 WI_1 WI_2 WI_3 
#3049 3049 3049 3049 3049 3049 3049 3049 3049 3049 
 


#-------------------------------------------data preperation----------------------------------------------------
WI_FOOD = train[str_detect(train$store_id,"WI")&str_detect(train$dept_id,"FOODS"), ]
WI_HOBBIES = train[str_detect(train$store_id,"WI")&str_detect(train$dept_id,"HOBBIES"), ]
WI_HOUSEHOLD = train[str_detect(train$store_id,"WI")&str_detect(train$dept_id,"HOUSEHOLD"), ]

sum(train$state_id=="WI")
nrow(WI_FOOD)+nrow(WI_HOBBIES)+nrow(WI_HOUSEHOLD)

CA_FOOD = train[str_detect(train$store_id,"CA")&str_detect(train$dept_id,"FOODS"), ]
CA_HOBBIES = train[str_detect(train$store_id,"CA")&str_detect(train$dept_id,"HOBBIES"), ]
CA_HOUSEHOLD = train[str_detect(train$store_id,"CA")&str_detect(train$dept_id,"HOUSEHOLD"), ]

sum(train$state_id=="CA")
nrow(CA_FOOD)+nrow(CA_HOBBIES)+nrow(CA_HOUSEHOLD)


TX_FOOD = train[str_detect(train$store_id,"TX")&str_detect(train$dept_id,"FOODS"), ]
TX_HOBBIES = train[str_detect(train$store_id,"TX")&str_detect(train$dept_id,"HOBBIES"), ]
TX_HOUSEHOLD = train[str_detect(train$store_id,"TX")&str_detect(train$dept_id,"HOUSEHOLD"), ]

sum(train$state_id=="TX")
nrow(TX_FOOD)+nrow(TX_HOBBIES)+nrow(TX_HOUSEHOLD)

#1.Extracting relevant train and price data
train_each =CA_FOOD
train_each_id = train_each$id
prices_each = prices[str_detect(prices$store_id,"CA") & str_detect(prices$item_id,"FOOD"),]
weekly_total_prices_each = prices_each%>%group_by(wm_yr_wk)%>%summarise(weekly_prices = sum(sell_price))
each_day_weekly_total_prices_each = merge(x =  weekly_total_prices_each,y = calendar,by = "wm_yr_wk",all.x = T)$weekly_prices
#merging itemsold and features together
data_each = cbind(data.frame(data.frame(apply(train_each[,-c(1:6)], 2, sum))[,1]),
             calendar$snap_CA[c(1:1913)],
             calendar$event_type_1[c(1:1913)],
             calendar$weekday[c(1:1913)],
             calendar$month[c(1:1913)],
             each_day_weekly_total_prices_each[1:1913]) #Since calendar$event_type_2[c(1:1913)] is all NA, it is not considered



#2.Cleaning NA's and naming columns conviniently 
data = data_each
dim(data)
head(data)
colnames(data)= c("ItemsSold","SNAP","event","weekday","month","prices")
levels(data$event) = c("Cultural" , "National",  "Religious", "Sporting","no")
data[is.na(data$event),]$event = "no"
str(data)
plot(data$ItemsSold)
which.min(data$ItemsSold)
#data = data[-which(data$ItemsSold==0),]


#3.dummyfiying
dummyModel = dummyVars(~event+weekday,data)
data_dum = cbind(data,predict(dummyModel,data))
dim(data_dum)
colnames(data_dum)
head(data_dum)
str(data_dum)
sum(is.na(data_dum))


##Splitting
noOfWeekstoForcast = 4*7
trainRowID = 1:(nrow(data) - noOfWeekstoForcast)
trainData = data_dum[trainRowID,]
testData = data_dum[-trainRowID,]
rm(trainRowID)






#------------------------------------------------Modelling------------------------------------------------------
#-------------------------------------------state-wise-modelling------------------------------------------------


#1.granger causality of prices on ItemsSold
VARselect(data$ItemsSold)
grangertest(data$ItemsSold,data$price,order=10)
#prices are granger causing itemsold


####model_1:Freq:30####
nrow(trainData)
nrow(testData)
trainTS = ts(trainData$ItemsSold, frequency = 30)
testTS = ts(testData$ItemsSold, frequency = 30)
ts.plot(trainTS)
plot(decompose(trainTS))
acf(trainTS,lag.max = 500)
pacf(trainTS,lag.max = 500)
str(trainData)
mod_1 = auto.arima(trainTS, xreg=as.matrix(trainData[,-c(1,3,4,11,12)]))
summary(mod_1)
arimaorder(mod_1)
mod_1_train_pred = fitted(mod_1)
mod_1_train_pred
mod_1_test_pred = forecast(mod_1, h=noOfWeekstoForcast, xreg=as.matrix(testData[,-c(1,3,4,11,12)]))
mod_1_test_pred
plot(mod_1_test_pred)
err_mod_1 = regr.eval(testData$ItemsSold, data.frame(mod_1_test_pred)$Point.Forecast)



####model_2:Freq:7####
trainTS = ts(trainData$ItemsSold, frequency = 7)
testTS = ts(testData$ItemsSold, frequency = 7)
ts.plot(trainTS)
plot(decompose(trainTS))
acf(trainTS,lag.max = 500)
pacf(trainTS,lag.max = 500)
str(trainData)
mod_2 = auto.arima(trainTS, xreg=as.matrix(trainData[,-c(1,3,4,11,12)]))
summary(mod_2)
arimaorder(mod_2)
mod_2_train_pred = fitted(mod_2)
mod_2_train_pred
mod_2_test_pred = forecast(mod_2, h=noOfWeekstoForcast, xreg=as.matrix(testData[,-c(1,3,4,11,12)]))
mod_2_test_pred
plot(mod_2_test_pred)
err_mod_2 = regr.eval(testData$ItemsSold, data.frame(mod_2_test_pred)$Point.Forecast)







##Comparing mod_1 and mod_2
Box.test(resid(mod_2),type="Ljung",lag=20,fitdf=1)
Box.test(resid(mod_1),type="Ljung",lag=20,fitdf=1)
#Clearly mod_1 has patterns in its error while mod_2's errors are almost random
#MAPE is lesser for mod_2
#hence further modelling is done on freq = 7 models

#However there is still some pattern in the error as p value is 0.02.
#Let's build a new model applying log transformation



####model_3:Freq:7&log transformed####
mod_3 = auto.arima(trainTS,lambda = 0, xreg=as.matrix(trainData[,-c(1,3,4,11,12)]))
summary(mod_3)
arimaorder(mod_3)
mod_3_train_pred = fitted(mod_3)
mod_3_train_pred
mod_3_test_pred = forecast(mod_3, h=noOfWeekstoForcast, xreg=as.matrix(testData[,-c(1,3,4,11,12)]))
mod_3_test_pred
plot(mod_3_test_pred)
err_mod_3 = regr.eval(testData$ItemsSold, data.frame(mod_3_test_pred)$Point.Forecast)
##err_mod_3 is lesser than that in the first two cases
Box.test(resid(mod_3),type="Ljung",lag=20,fitdf=1)
##Residuals are independent









#Surprisingly random experimentation revealed that modelling without prices variable leads to an even better model despite simplification

####model_4:Freq:7&log transformed&prices excluded####
if(sum(trainData$ItemsSold==0)!=0){
trainData = trainData[-which(trainData$ItemsSold==0),]
}
trainTS = ts(trainData$ItemsSold, frequency = 7)
testTS = ts(testData$ItemsSold, frequency = 7)
mod_4 = auto.arima(trainTS,lambda = 0, xreg=as.matrix(trainData[,-c(1,3,4,6,11,12)]))
summary(mod_4)
arimaorder(mod_4)
Box.test(resid(mod_4),type="Ljung",lag=20,fitdf=1)
mod_4_train_pred = fitted(mod_4)
mod_4_train_pred
mod_4_test_pred = forecast(mod_4, h=noOfWeekstoForcast, xreg=as.matrix(testData[,-c(1,3,4,6,11,12)]))
mod_4_test_pred
plot(mod_4_test_pred)
err_mod_4 = regr.eval(testData$ItemsSold, data.frame(mod_4_test_pred)$Point.Forecast)


#Since mod_4 has is the most accurate one and also removing prices makes it simplar also, mod_4 is finalised for predictions











#------------------------------------------------------Predictions----------------------------------------------------------------#

#1.Preparing val data xreg for modelling
##NOTE: Change snap column for each state
regx_val = calendar[c(1914:1969),c("weekday","event_type_1","snap_CA","month")]
val_data = data.frame(regx_val)
dim(val_data)
head(val_data)
colnames(val_data)= c("weekday","event","SNAP","month")
val_data$weekday = as.factor(val_data$weekday)
val_data$event = as.factor(val_data$event)
levels(val_data$event) = c("Cultural" , "National",  "Religious", "Sporting","no")
val_data[is.na(val_data$event),]$event = "no"
str(val_data)

#2.dummyfiying
dummyModel = dummyVars(~event+weekday,val_data)
val_data_dum = cbind(val_data,predict(dummyModel,val_data))
dim(val_data_dum)
colnames(val_data_dum)
str(val_data_dum)
sum(is.na(val_data_dum))

#Prediction
str(val_data_dum)
#we had removed no and friday to remove redundantency. doing the same here 
#-c(1,2,8,9)
pred = data.frame(forecast(mod_4, h=56, xreg=as.matrix(val_data_dum[,-c(1,2,9,10)])))
#We had 216 observations. dividing by 216 is are the predictions for each of these set.
pred_points = (data.frame(pred)/length(train_each_id))$Point.Forecast

length(train_each_id)==dim(CA_FOOD)

ans = data.frame()
for(i in 1:length(train_each_id)){
  x = cbind(id = train_each_id[i],data.frame(matrix(pred_points,nrow = 1)))
  ans = rbind(ans,x)  
}
dim(ans)
##Saving the predictions for CA state and FOOD category
write.csv(ans,"CA_FOOD.csv")
