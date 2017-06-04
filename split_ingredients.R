# split ingredients

library(stringr)

simple_beer_necessities

ingredients <- c("hop_name", "malt_name")

split_ingredients <- function(df) {
  ncol_df <- ncol(df)
  
  for (ingredient in ingredients) {

    ingredient_split <- str_split(df[[ingredient]], ", ")    # this returns a list
    num_new_cols <- max(lengths(ingredient_split))      # find out max number of instances of an ingredient per beer. this will be the number of columns we're adding.
  
    for (num in 1:num_new_cols) {
      this_col <- ncol_df + 1         # create a new column, initialize it with NAs, and name it
      
      df[, this_col] <- NA
      names(df)[this_col] <- paste0(ingredient, "_", num)
      ncol_df <- ncol(df)             # update the number of columns
      
      for (row in seq_along(ingredient_split)) {           # for each element in our list of split up ingredients
        if (!is.null(ingredient_split[[row]][num])) {         # if it exists, add it to the correct column in our df
          df[row, this_col] <- ingredient_split[[row]][num]
        }
      }
    }
    ncol_df <- ncol(df)
  }
  return(df)
}

sbn_added <- sbn
sbn_added <- ingredient_split(sbn)
View(sbn_added)



hops_split <- str_split(df[["hops_name"]], ", ")
num_new_cols <- max(lengths(hops_split))


# # a more functional way of doing this using separate()

# split_sbn <- separate(data = sbn_added,
#                       col = hops_name, into = setdiff(names(sbn_added), names(sbn)), sep = ", ")
# View(split_sbn)