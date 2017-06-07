
# get a vector of all the unique levels of whatever ingredient


get_ingredient_levels <- function(df, ing_name) {
  ing_levels <- vector()
  ing_cols <- df[, grepl(paste0(ing_name, "_name_"), names(df)) == TRUE]     # get a pared df of just columns that contain <ingredient>_name_
  
  for (col_num in 1:ncol(ing_cols)) {
    this_col_levels <- levels(ing_cols[, col_num])
    ing_levels <- c(ing_levels, this_col_levels)
  }
  
  unique_ing_levels <- unique(ing_levels)
  return(unique_ing_levels)
}

all_hops_levels <- get_ingredient_levels(bne, "hops")
all_malt_levels <- get_ingredient_levels(bne, "malt")


length(all_hops_levels)
length(all_malt_levels)

# find the length of the longest ingredient vector
ingredient_types_length <- max(length(all_hops_levels), length(all_malt_levels))

# make all ingredient vectors that length. this introduces NAs into the shorter ones.
length(all_hops_levels) <- ingredient_types_length
length(all_malt_levels) <- ingredient_types_length

# now cbind them into the same df
ingredient_types <- as_tibble(bind_cols(list(hops_type = all_hops_levels, malt_type = all_malt_levels)))
View(ingredient_types)





bne_slice <- beer_necessities_expanded[100:200, ] 

bne_slice <- bne_slice %>% 
  select(
    -c(id, description, abv, ibu, srm, glass, hops_id, malt_id, glasswareId, styleId, style.categoryId)
  ) %>% 
  as_tibble()


table(bne_slice)



bne_slice_gather <- bne_slice %>% 
  gather(
    key = hops,
    value = hops_nme,
    hops_name_1:hops_name_13
  ) %>% 
  gather(
    key = malt,
    value = malt_nme,
    malt_name_1:malt_name_10
  )

bne_slice_spread_hops <- bne_slice_gather %>% 
  spread(
    key = hops_nme,
    value = name
  ) 

bne_slice_spread_malt <- bne_slice_gather %>% 
  spread(
    key = malt_nme,
    value = name
  )



