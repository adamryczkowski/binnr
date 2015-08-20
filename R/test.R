# library(binnr)
# # # 
# # # #titanic <- read.csv('~/Downloads/train.csv', header=T)
data(titanic, package='mjollnir')
# # # bins <- bin.data(titanic[,-1], titanic$Survived)
# # # adjust(bins)
# # # #
x <- titanic$Fare
y <- titanic$Survived
# # # 
# # # #keep <- c('Pclass', 'Sex', 'Age', 'SibSp', 'Parch', 'Fare', 'Embarked')
# # # 
# # # # createe an as.data 
# load("F:/SANT1507_5516/R-Santander/rv40_vs_rv50.analysis.rData")
# # mono <- mono50
# # mono[seq_along(mono50)] <- 2
# bins <- bin.data(rv50[,keep50], rv50$depvar, mono=c(ALL=2), min.iv=0, exceptions=list(ALL=-1), max.bin=20)
# 
# adjust(bins, var = "ssnproblems")
# binned <- predict(bins, rv50)
# 
# library(glmnet)
# s <- sample(nrow(binned), nrow(binned)/10)
# 
# fit1 <- cv.glmnet(binned[s,], rv50$depvar[s], alpha=1, lower.limits=0, nfolds = 5, family="binomial")
# fit2 <- cv.glmnet(binned[s,], rv50$depvar[s], alpha=0, lower.limits=0, nfolds = 5, family="binomial")
# #fit3 <- glm(binned[s,], rv50$depvar[s], lambda.max=Inf, alpha=0, lower.limits=0, family="binomial")
# 
# phat.lasso <- predict(fit1, binned[-s,], s="lambda.min")
# phat.ridge <- predict(fit2, binned[-s,], s="lambda.min")
# 
# library(mjollnir)
# ks.table(-phat.lasso, rv50$depvar[-s])
# ks.table(-phat.ridge, rv50$depvar[-s])
# 
# 
# 
# 
# # # 
# # # 
# # # 
# # # 
# # # # library(glmnet)
# # # # fit <- cv.glmnet(binned, rv50$depvar, alpha=1, nfolds=5, keep=TRUE, family='binomial')
# # # # 
# # # # phat <- fit$fit.preval[,which.min(fit$cvm)]
# # # # phat <- log(phat/(1-phat))
# # # # bin
# # # # library(mjollnir)
# # # # ks.table()
# # # # 
# # # # 
# # # # bins40 <- bin.data(rv40[,keep40], rv40$depvar, mono=mono40, min.iv=0)
# # # # binned40 <- predict(bins, rv50)
# # # # library(glmnet)
# # # # fit <- cv.glmnet(binned, rv50$depvar, alpha=1, nfolds=5, keep=TRUE, family='binomial')
# # # 
# # # 
# # # 
# # # 
# # # # view the bins and modify them if necessary
# # # 
# # # #binned <- predict(bins, titanic)
# # # 
# # #  #bin(x, y)