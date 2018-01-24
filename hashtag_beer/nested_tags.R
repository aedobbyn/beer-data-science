get_reps_simple <- function(df, i) {
  rep(df$tag[i], df$val[i]) 
}
get_reps_simple(all_clean, 4)

get_reps <- function(df) {
  out <- NULL
  for (i in 1:nrow(df)) {
    x <- rep(df$tag[i], df$val[i]) 
    out <- c(out, x)
  }
  return(out)
}

unnested_tags <- get_reps(all_clean) %>% 
  as_tibble() %>% 
  rename(
    word = value
  ) 

nested_tags <- unnested_tags %>% 
  group_by(word) %>% 
  nest(word, .key = nested_word)