# split ingredients

library(stringr)

simple_beer_necessities

split_ingredients <- function(df, ingredient) {
  ncol_df <- ncol(df)
  
  ingredient_split <- str_split(sbn[[ingredient]], ", ")    # this returns a list
  num_new_cols <- max(lengths(ingredient_split))

  new_col_names <- vector()
  
  for (num in 1:num_new_cols) {
    this_col <- ncol_df + 1
    
    df[, this_col] <- NA
    names(df)[this_col] <- paste0(ingredient, "_", num)
    ncol_df <- ncol(df)
    
    for (row in seq_along(ingredient_split)) {
      if (!is.null(hops_split[[row]][num])) {
        df[row, this_col] <- ingredient_split[[row]][num]
      }
    }
  }

  return(df)
}


sbn_added <- ingredient_split(sbn, "malt_name")
View(sbn_added)



hops_split <- str_split(df[["hops_name"]], ", ")
num_new_cols <- max(lengths(hops_split))


# # a more functional way of doing this using separate()

# split_sbn <- separate(data = sbn_added,
#                       col = hops_name, into = setdiff(names(sbn_added), names(sbn)), sep = ", ")
# View(split_sbn)