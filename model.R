
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


run_neural_net <- function(df, outcome, predictor_vars) {
  out <- list(outcome = outcome)
  
  # Create a new column outcome; it's style_collapsed if you set outcome to style_collapsed, and style otherwise
  if (outcome == "style_collapsed") {
    df[["outcome"]] <- df[["style_collapsed"]]
  } else {
    df[["outcome"]] <- df[["style"]]
  }
  # browser()
  df$outcome <- factor(df$outcome)
  
  cols_to_keep <- c("outcome", predictor_vars)
  
  df <- df %>%
    select_(.dots = cols_to_keep) %>%
    mutate(row = 1:nrow(df)) %>% 
    droplevels()

  # Select 80% of the data for training
  df_train <- sample_n(df, nrow(df)*(0.8))
  
  # The rest is for testing
  df_test <- df %>%
    filter(! (row %in% df_train$row)) %>%
    select(-row)
  
  df_train <- df_train %>%
    select(-row)
  
  # # Drop NAs for only outcome variable, not any other ones
  # df_train$outcome <- droplevels(df_train$outcome)
  # df_test$outcome <- droplevels(df_train$outcome)
  
  # Build multinomail neural net
  nn <- multinom(outcome ~ .,
                 data = df_train, maxit=500, trace=T)

  # Which variables are the most important in the neural net?
  most_important_vars <- varImp(nn)
  print(most_important_vars)

  # How accurate is the model? Compare predictions to outcomes from test data
  nn_preds <- predict(nn, type="class", newdata = df_test)
  nn_accuracy <- postResample(df_test$outcome, nn_preds)

  out <- list(out, nn = nn, most_important_vars = most_important_vars,
              df_test = df_test,
              nn_preds = nn_preds,
           nn_accuracy = nn_accuracy)

  return(out)
}

p_vars <- c("total_hops", "total_malt", "abv", "ibu", "srm")
nn_collapsed_out <- run_neural_net(df = beer_ingredients_join, outcome = "style_collapsed", 
                         predictor_vars = p_vars)

# How accurate was it?
nn_collapsed_out$nn_accuracy

# Most important variables
nn_collapsed_out$most_important_vars




nn_notcollapsed_out <- run_neural_net(df = beer_ingredients_join, outcome = "style", 
                                      predictor_vars = p_vars)

nn_notcollapsed_out$nn_accuracy





library(ranger)
library(stringr)

bi <- beer_ingredients_join %>% 
  select(-c(id, name, cluster_assignment, style, hops_name, malt_name,
            description, glass)) %>% 
  mutate(row = 1:nrow(.)) 

bi$style_collapsed <- factor(bi$style_collapsed)


# csrf complains about special characters and spaces in ingredient column names. take them out and replace with ""
names(bi) <- tolower(names(bi))
names(bi) <- str_replace_all(names(bi), " ", "")
names(bi) <- str_replace_all(names(bi), "([\\(\\)-\\/')]+)", "")

# Keep 80% for training
bi_train <- sample_n(bi, nrow(bi)*(0.8))

# The rest is for testing
bi_test <- bi %>%
  filter(! (row %in% bi_train$row)) %>%
  dplyr::select(-row)

bi_train <- bi_train %>%
  dplyr::select(-row)


bi_rf <- ranger(style_collapsed ~ ., data = bi_train)
bi_rf

rf_acc <- postResample(bi_rf, bi_test$style_collapsed)





bi_csrf <- csrf(style_collapsed ~ ., training_data = bi_train, test_data = bi_test,
                params1 = list(num.trees = 5, mtry = 4),
                params2 = list(num.trees = 2))

csrf_acc <- postResample(bi_csrf, bi_test$style_collapsed)

csrf_preds <- predict(bi_csrf, type="terminalNodes", newdata = bi_test$style_collapsed) 

     

rf_preds <- predict(bi_rf, bi_test)     
rf_preds <- predict(bi_rf, type="terminalNodes", newdata = bi_test$style_collapsed)


     
importance(bi_rf)

