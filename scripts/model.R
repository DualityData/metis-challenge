library(data.table)
library(caret)
library(glmnet)
library(pROC)


setwd('~/duality/metis-challenge/data')

rm(list=ls())

labels = fread('beetrainLabels.csv')
labels[,genus:=ifelse(genus==1,'bumble',ifelse(genus==0,'honey',NA))]
labels[,genus:=factor(genus)]

#Load PCA features.
train = fread('pca.train.csv',select=c("V1","V2","V3","V4","V5"))
ids = fread('names.train.csv',select=c("V1","V2","V3","V4","V5"))
setnames(ids,"id")
train = cbind(ids,train)
train = merge(labels,train,by="id")

train2 = fread('pca.grey.train.csv',select=c("V1","V2","V3","V4","V5"))
ids2 = fread('names.grey.train.csv',select=c("V1","V2","V3","V4","V5"))
setnames(ids2,"id")
train2 = cbind(ids2,train2)
train = merge(train,train2,by="id")

test = fread('pca.test.csv',select=c("V1","V2","V3","V4","V5"))
ids = fread('names.test.csv',select=c("V1","V2","V3","V4","V5"))
setnames(ids,"id")
test = cbind(ids,test)
test = merge(labels,test,by="id")

test2 = fread('pca.grey.test.csv',select=c("V1","V2","V3","V4","V5"))
ids2 = fread('names.grey.test.csv',select=c("V1","V2","V3","V4","V5"))
setnames(ids2,"id")
test2 = cbind(ids2,test2)
test = merge(test,test2,by="id")


#Load orange/yellow pixel count features. 
orange = fread('count_orange.csv')
setnames(orange,"orange")
yellow = fread('count_yellow.csv')
setnames(yellow,"yellow")
ids = fread('names.transform.csv')
setnames(ids,"id")
other = cbind(ids,orange,yellow)
other[,share:=orange/(yellow+1)]


#merge all features together. 
train = merge(train,other,by="id")
test = merge(test,other,by="id")
test_ids = test[,id]

#regression formula - drop id and y variable. 
####form = as.formula(paste("~0",paste(colnames(train)[-c(1,2)],collapse="+"),sep="+"))
#rhs.train = model.matrix(genus~0+. -id,data=train)
#rhs.test = model.matrix(genus~0+. -id,data=test)
##below to include interactions
train[,id:=NULL]
test[,id:=NULL]
rhs.train = model.matrix(genus~0+.*. ,data=train)
rhs.test = model.matrix(genus~0+.*. ,data=test)


set.seed(345)

trControl=trainControl(method='cv',number=10,verboseIter=TRUE,classProbs=TRUE,summaryFunction=twoClassSummary)


#-----------
#random forest
#-----------
#tuneGrid=data.frame(mtry=seq(floor(sqrt(length(colnames(rhs.train)))),15))
tuneGrid=data.frame(mtry=10)

fit.rf<-train(rhs.train,train$genus,
                                    ntree=500,
                                    method="rf",
                                    trControl=trControl,
                                    preProc = c("center", "scale"),
                                    tuneGrid=tuneGrid,
                                    metric="ROC",
                            importance=TRUE)#,
           #do.trace=TRUE)
print(fit.rf)
#print(summary(fit.rf))
varImp(fit.rf)

print(fit.rf$resample$ROC)
print(mean(fit.rf$resample$ROC))

outpred.rf = predict.train(fit.rf,type="prob",newdata=rhs.test)

#print(roc(test$genus,outpred.rf$bumble)$auc)

#-----------
#LASSO
#-----------
## #via caret
## lambdas = glmnet(rhs.train,y=train$genus,family='binomial')$lambda

## tuneGrid = expand.grid(alpha=1,lambda=lambdas)
## #tuneGrid = expand.grid(alpha=1,lambda=0.00156)

## fit.lasso = train(rhs.train,train$genus,
##                method="glmnet",
##                family="binomial",
##                trControl=trControl,
##                metric="ROC", #ROC #Accuracy
##                tuneGrid=tuneGrid,
##                preProc = c("center", "scale")
##                )

## #print(fit.lasso)
## #print(summary(fit.lasso))
## varImp(fit.lasso)
## print(fit.lasso$resample$ROC)
## print(mean(fit.lasso$resample$ROC))

## lam = fit.lasso$finalModel$lambdaOpt
## #lam = 0.00156
## coefs = coef(fit.lasso$finalModel,lam)
## test@Dimnames[[1]][test@i]

## outpred.lasso = predict(fit.lasso,type="prob",newdata=rhs.test)

#via glmnet directly - allows to use lambda1se. 
fit.lasso = cv.glmnet(rhs.train,train$genus,nfolds=10,family='binomial',type.measure="auc")

#Save two key 'lambdas' governing degree of regularization. 1se will be used for forecasting.
lam1se = fit.lasso$lambda.1se
lammin = fit.lasso$lambda.min

outpred.lasso = data.table(honey=predict(fit.lasso,newx=rhs.test,s=lam1se,type='response')[,1])
outpred.lasso[,bumble := 1-honey]

#print(roc(test$genus,outpred.lasso$bumble)$auc)




#combination
#print(roc(test$genus,0.5*(outpred.rf$bumble)+0.5*(outpred.lasso$bumble))$auc)

#finalforecast
output = data.frame(id=test_ids,genus=0.7*(outpred.rf$bumble)+0.3*(outpred.lasso$bumble))
write.table(output,file="output.csv",sep=",",row.names=FALSE)



#roc(test$genus,as.numeric(rep(0.755,nrow(test))))$auc


