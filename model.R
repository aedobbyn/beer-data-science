
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

nn_mod <- multinom(style ~ abv + srm + ibu, 
                   data = popular_beer_dat, maxit=500, trace=T)
nn_mod


# which variables are the most important in the neural net?
most_important_vars <- varImp(nn_mod)
most_important_vars


