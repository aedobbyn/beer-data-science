
# Truncate total_hops and total_malt to ints
integerize_ingredients <- function(df) {
  
  for (i in seq_along(names(df))) {
    if (names(df[, i]) %in% c("total_hops", "total_malt")) {
      df[, i] <- df[, i] %>% unlist() %>%  round(digits = 0) %>% as.integer()
    }
  }
  
  return(df)
}