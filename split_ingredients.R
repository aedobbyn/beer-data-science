# split ingredients

library(stringr)


add_new_cols <- function(df) {
  ncol_df <- ncol(df)
  
  hops_split <- str_split(sbn[["hops_name"]], ", ")
  num_new_cols <- max(lengths(hops_split))

  new_col_names <- vector()
  
  for (num in 1:num_new_cols) {
    this_col <- ncol_df + 1
    
    df[, this_col] <- "foo"
    names(df)[this_col] <- paste0("hop_", num)
    ncol_df <- ncol(df)
    
    for (row in seq_along(hops_split)) {
      if (!is.null(hops_split[[row]][num])) {
        df[row, this_col] <- hops_split[[row]][num]
      }
    }
  }

  return(df)
}

add_new_cols(sbn)

sbn_added <- add_new_cols(sbn)
View(sbn_added)



hops_split <- str_split(df[["hops_name"]], ", ")
num_new_cols <- max(lengths(hops_split))


# # a more functional way of doing this using separate()

# split_sbn <- separate(data = sbn_added,
#                       col = hops_name, into = setdiff(names(sbn_added), names(sbn)), sep = ", ")
# View(split_sbn)