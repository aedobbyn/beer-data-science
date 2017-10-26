
run_neural_net <- function(df, multinom = TRUE, outcome, predictor_vars, 
                           maxit = 500, size = 5, trace = FALSE, seed = 9) {
  set.seed(seed)
  
  out <- list(outcome = outcome)
  
  # Create a new column outcome; it's style_collapsed if you set outcome to style_collapsed, and style otherwise
  if (outcome == "style_collapsed") {
    df[["outcome"]] <- df[["style_collapsed"]]
  } else {
    df[["outcome"]] <- df[["style"]]
  }
    
  cols_to_keep <- c("outcome", predictor_vars)
  
  df <- df %>%
    select_(.dots = cols_to_keep) %>%
    mutate(row = 1:nrow(df)) %>% 
    droplevels()
  
  # Select 80% of the data for training
  df_train <- sample_n(df, nrow(df)*(0.8)) %>% droplevels()
  
  # The rest is for testing
  df_test <- df %>%
    filter(! (row %in% df_train$row)) %>%
    select(-row)
  
  df_train <- df_train %>%
    select(-row)
  
  if(multinom==TRUE) {
    nn <- multinom(outcome ~ .,
                   data = df_train, maxit=maxit, trace=trace)
    
    # Which variables are the most important in the neural net?
    most_important_vars <- varImp(nn)
    
  } else if (multinom==FALSE) {
    nn <- nnet(outcome ~ ., size = size,
                   data = df_train, maxit=maxit, trace=trace)
    most_important_vars <- NULL

  }
  
  # How accurate is the model? Compare predictions to outcomes from test data
  nn_preds <- predict(nn, type="class", newdata = df_test) %>% factor()
  nn_accuracy <- postResample(df_test$outcome, nn_preds)
  

  
  out <- list(out, nn = nn, 
              most_important_vars = most_important_vars,
              df_test = df_test,
              nn_preds = nn_preds,
              nn_accuracy = nn_accuracy)
  
  return(out)
}
