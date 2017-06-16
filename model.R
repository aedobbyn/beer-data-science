
source("./munge.r")
source("./most_popular_styles.R")


library(neuralnet)
library(nnet)
library(caret)


# factors that could predict style
predictors <- c("abv", "glass", "srm", "ibu")


# linear model
m_1 <- glm(style_collapsed ~ abv + srm + ibu, data = beer_dat_pared, na.rm = TRUE)
summary(m_1)


# neural net
# based off of http://amunategui.github.io/multinomial-neuralnetworks-walkthrough/

# split into training and test sets
beer_train <- sample_n(popular_beer_dat, 3000)
beer_test <- popular_beer_dat %>% filter(! (id %in% beer_train$id))


beer_necessities_train <- sample_n(beer_necessities, 5000)
beer_necessities_test <- beer_necessities %>% filter(! (id %in% beer_necessities_train$id))


# select columns from beer_ingredients_join that are fair game for the neural net
beer_ingredients_fair_game <- beer_ingredients_join %>% select(c(style_collapsed, 
                                        id, total_hops, total_malt, abv, ibu, srm, glass, 
                                       `Aged / Debittered Hops (Lambic)`:Fuggles
                                       ))
beer_ingredients_fair_game$style_collapsed <- factor(beer_ingredients_fair_game$style_collapsed) %>% droplevels()

beer_ingredients_join_train <- sample_n(beer_ingredients_fair_game, 2500) %>% droplevels()
beer_ingredients_join_test <- beer_ingredients_fair_game %>% 
  filter(! (id %in% beer_ingredients_join_train$id)) %>% 
  select(-id) %>% droplevels() 
# take out id
beer_ingredients_join_train <- beer_ingredients_join_train %>% 
  select(-id) %>% droplevels() 


# build multinomail neural net
nn_mod <- multinom(style ~ abv + srm + ibu, 
                   data = beer_train, maxit=500, trace=T)
nn_mod

# same model on style_collapsed
nn_collapsed <- multinom(style_collapsed ~ abv + srm + ibu, 
                   data = beer_necessities_train, maxit=500, trace=T)
nn_collapsed


nn_ingredients <- multinom(style_collapsed ~ .,
                           data = beer_ingredients_join_train, 
                       maxit=500, trace=T)
nn_ingredients


# which variables are the most important in the neural net?
most_important_vars <- varImp(nn_mod)
most_important_vars

# which variables are the most important in the neural net?
most_important_vars_collapsed <- varImp(nn_collapsed)
most_important_vars_collapsed


most_important_vars_ingredients <- varImp(nn_ingredients)
most_important_vars_ingredients

# how accurate is the model?
# preds
nn_preds <- predict(nn_mod, type="class", newdata = beer_test)
nn_preds_collapsed <- predict(nn_collapsed, type="class", newdata = beer_necessities_test)

nn_preds_ingredients <- predict(nn_ingredients, type="class", newdata = beer_ingredients_join_test)


# accuracy
postResample(beer_test$style, nn_preds)
postResample(beer_necessities_test$style_collapsed, nn_preds_collapsed)
postResample(beer_ingredients_join_test$style_collapsed, nn_preds_ingredients)










# ------------------------ xgboost -------------------

library(xgboost)
boost <- xgboost(style_collapsed ~ .,
                          data = beer_ingredients_fair_game, 
                          verbose = 1)



# using neuralnet package
# 
# beer_train_mm <- model.matrix( 
#   ~ styleId + abv + srm + ibu, data = beer_train)
# 
# beer_train$style_dummy <- class.ind(beer_train$style)
# 
# neural_net <- neuralnet(style_dummy ~ abv + srm + ibu, data = beer_train, hidden = 2, threshold=0.01)
# print(neural_net)





















# --------------- neural net function



outcome <- "style_collapsed"



run_neural_net <- function(df, outcome) {
  out <- list(outcome = outcome)
  
  predictors_to_keep <- c("style_collapsed", "style", "total_hops", "total_malt", "abv", "ibu", "srm", "glass")
  non_outcome <- ifelse(outcome == "style_collapsed", "style", "style_collapsed")
  
  nrow_df <- nrow(df)
  df$style_collapsed <- factor(df$style_collapsed)
  df <- df %>% 
    select_(predictors_to_keep) %>% 
    # select(style_collapsed, total_hops, total_malt, abv, ibu, srm, glass) %>% 
    droplevels() %>% 
    mutate(row = 1:nrow_df)
  
  df_train <- sample_n(df, nrow_df*(0.8)) %>% 
    select(-row) %>% 
    select_(-non_outcome)
  df_test <- df %>% 
    filter(! (row %in% df_train$row)) %>%
    select(-row) %>% 
    select_(-non_outcome)
  
  
  
  # build multinomail neural net
  nn <- multinom(outcome ~ ., 
                 data = df_train, maxit=500, trace=T)
  
  # which variables are the most important in the neural net?
  most_important_vars <- varImp(nn)
  
  
  # how accurate is the model?
  # preds
  nn_preds <- predict(nn, type="class", newdata = df_test)
  # accuracy
  nn_accuracy <- postResample(df_test$outcome, nn_preds)
  
  out <- c(out, nn = nn, most_important_vars = most_important_vars,
           nn_accuracy = nn_accuracy)
  
  return(out)
}


run_neural_net(df = beer_ingredients_join, outcome = "style_collapsed")

