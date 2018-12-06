## caret demo
## 12/6/18
## BKC

## caret = Classification And REgression Training
## wrapper for >300 model training techniques
## functions for plotting and summarizing model performance

library(caret)
library(patchwork)
library(tidyverse)
set.seed(1235)

# load the data and fix col names
load("wine.Rda")
colnames(wine) = make.names(colnames(wine)) # imp. when using other's code!

# peek structure of data
str(wine)
head(wine)

# view dist. of variables
wine_long = gather(wine, attr, val, -class)
ggplot(wine_long, aes(val)) + geom_density() +
  geom_histogram(aes(y=..density..), bins=30, alpha=.7) +
  facet_wrap(.~attr, scales="free")

## "recipe" for developing a model:
## 1. prepare data (separate + preprocess)
## 2. train on training set
## 3. predict on test set

## minimal working example

# partition data: prop. of classes is preserved
part = createDataPartition(wine$class, p = .8, list = F)
train = wine[part, ]
test = wine[-part, ]

# all should be roughly equal
prop.table(table(wine$class))
prop.table(table(train$class))
prop.table(table(test$class))

# train a model using the "rpart" method
rpart_model_wine = train(class ~ ., data = train, method = 'rpart')

# view model summary
rpart_model_wine

# make some predictions
rpart_wine_predict = predict(rpart_model_wine, newdata = test)
head(rpart_wine_predict)

## building a better model
## using feed forward neural network

# prepocessing with z-normalization
preproc_values = preProcess(train, method = c("center", "scale"))
train = predict(preproc_values, train)
test = predict(preproc_values, test)
head(train)

# specify parameters and resampling
modelLookup("nnet") # what params can I tune?
param_grid = expand.grid(.decay = c(0.8, 0.2, 0.05), .size = c(1, 3, 5))
resample_type = trainControl(method = "LGOCV") # leave-group-out cross-validation

# pass these to train function
nnet_model_wine = train(class ~ ., data = train, method = "nnet",
                        tuneGrid = param_grid,
                        trControl = resample_type,
                        # model specific parameters: look up in model documentation
                        maxit = 200)

# visualize training process
nnet_model_wine
p = ggplot(nnet_model_wine) | ggplot(nnet_model_wine, metric = "Kappa")
p / ggplot(nnet_model_wine, plotType = "level")

# resample performance for final model
resampleHist(nnet_model_wine)

# get predictions, and summarize predictive power
nnet_wine_predict = predict(nnet_model_wine, newdata = test)
confusionMatrix(nnet_wine_predict, test$class)

## variable importance: which variables matter for prediction?
imp = varImp(nnet_model_wine)
imp

# plot importance
imp_df = data.frame("attr" = rownames(imp[[1]]),
                    "imp" = imp[[1]][,1])
ggplot(imp_df, aes(y=imp, x=attr)) + geom_col() + coord_flip()

## what was the model picking up on?

# variable seperation by class
ggplot(wine_long, aes(x=class, y=val, col=class)) + geom_boxplot() +
  facet_wrap(.~attr, scales="free")

# pairwise variable dependencies
pairs(wine[-1])

# what is most important predictor on its own?
# variable interactions are funky sometimes
nnet_model_flav = train(class ~ Flavanoids, data = train, method = "nnet",
                        tuneGrid = param_grid,
                        trControl = resample_type,
                        maxit = 200)
nnet_model_prol = train(class ~ Proline, data = train, method = "nnet",
                        tuneGrid = param_grid,
                        trControl = resample_type,
                        maxit = 200)
nnet_model_flav
nnet_model_prol
