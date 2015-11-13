library(data.table)
library(caret)
library(glmnet)
library(pROC)


setwd('~/duality/metis-challenge/data')

labels = fread('beetrainLabels.csv')
labels[,genus:=ifelse(genus==1,'bumble',ifelse(genus==0,'honey',NA))]
labels[,genus:=factor(genus)]

train = fread('pca.train.csv')
ids = fread('names.train.csv')
setnames(ids,"id")
train = cbind(ids,train)
train = merge(labels,train,by="id")

test = fread('pca.test.csv')
ids = fread('names.test.csv')
setnames(ids,"id")
test = cbind(ids,test)
test = merge(labels,test,by="id")

#regression formula - drop id and y variable. 
#form = as.formula(paste("~0",paste(colnames(train)[-c(1,2)],collapse="+"),sep="+"))
rhs.train = model.matrix(genus~0+. -id,data=train)
rhs.test = model.matrix(genus~0+. -id,data=test)
#below to include interactions
## rhs.train = model.matrix(genus~0+.*. -id,data=train)
## rhs.test = model.matrix(genus~0+.*. -id,data=test)


set.seed(345)

trControl=trainControl(method='cv',number=5,verboseIter=TRUE,classProbs=TRUE,summaryFunction=twoClassSummary)


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

print(fit.rf$resample$ROC)
print(mean(fit.rf$resample$ROC))

outpred.rf = predict.train(fit.rf,type="prob",newdata=rhs.test)

print(roc(test$genus,outpred.rf$bumble)$auc)

#-----------
#LASSO
#-----------
lambdas = glmnet(rhs.train,y=train$genus,family='binomial',standardize=T,intercept=T)$lambda

tuneGrid = expand.grid(alpha=1,lambda=lambdas)
#tuneGrid = expand.grid(alpha=1,lambda=lammin)

fit.lasso = train(rhs.train,train$genus,
               method="glmnet",
               family="binomial",
               trControl=trControl,
               metric="ROC", #ROC #Accuracy
               tuneGrid=tuneGrid,
               preProc = c("center", "scale")
               )

#print(fit.lasso)
#print(summary(fit.lasso))
print(fit.lasso$resample$ROC)
print(mean(fit.lasso$resample$ROC))

outpred.lasso = predict.train(fit.lasso,type="prob",newdata=rhs.test)

print(roc(test$genus,outpred.lasso$bumble)$auc)



#combination
print(roc(test$genus,0.5*(outpred.rf$bumble)+0.5*(outpred.lasso$bumble))$auc)

#finalforecast
output = data.frame(id=test$id,genus=0.5*(outpred.rf$bumble)+0.5*(outpred.lasso$bumble))
write.table(output,file="output.csv",sep=",",row.names=FALSE)



#roc(test$genus,as.numeric(rep(0.755,nrow(test))))$auc


