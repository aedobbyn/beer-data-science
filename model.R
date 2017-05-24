
source("./munge.r")
source("./most_popular_styles.R")


library(neuralnet)
library(nnet)
library(caret)


# factors that could predict style
predictors <- c("abv", "glass", "srm", "ibu")


# linear model
m_1 <- glm(style ~ abv + srm + ibu, data = beer_dat_pared)
summary(m_1)


# neural net
# based off of http://amunategui.github.io/multinomial-neuralnetworks-walkthrough/

# split into training and test sets
beer_train <- sample_n(popular_beer_dat, 3000)
beer_test <- popular_beer_dat %>% filter(! (id %in% beer_train$id))

# build multinomail neural net
nn_mod <- multinom(style ~ abv + srm + ibu, 
                   data = beer_train, maxit=500, trace=T)
nn_mod


# which variables are the most important in the neural net?
most_important_vars <- varImp(nn_mod)
most_important_vars


# how accurate is the model?
# preds
nn_preds <- predict(nn_mod, type="class", newdata = beer_test)

# accuracy
postResample(beer_test$style, nn_preds)







# using neuralnet package
# 
# beer_train_mm <- model.matrix( 
#   ~ styleId + abv + srm + ibu, data = beer_train)
# 
# beer_train$style_dummy <- class.ind(beer_train$style)
# 
# neural_net <- neuralnet(style_dummy ~ abv + srm + ibu, data = beer_train, hidden = 2, threshold=0.01)
# print(neural_net)

