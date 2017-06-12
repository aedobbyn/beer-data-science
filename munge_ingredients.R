source("./get_ingredient_levels.R")

# 
# length(all_hops_levels)
# length(all_malt_levels)
# 
# 
# # find the length of the longest ingredient vector
# ingredient_types_length <- max(length(all_hops_levels), length(all_malt_levels))
# 
# # make all ingredient vectors that length. this introduces NAs into the shorter ones.
# length(all_hops_levels) <- ingredient_types_length
# length(all_malt_levels) <- ingredient_types_length
# 
# # now cbind them into the same df
# ingredient_types <- as_tibble(bind_cols(list(hops_type = all_hops_levels, malt_type = all_malt_levels)))
# View(ingredient_types)
# 
# 
# 
# 
# 
# # bne_slice <- beer_necessities_expanded[100:200, ] 
# 
# bne_slice <- clustered_beer %>% 
#   inner_join(beer_necessities)
# 
# # bne_slice <- clustered_beer %>%       ### replace bne with whatever we want here
# #   select(
# #     -c(id, description, glass, hops_id, malt_id, glasswareId, styleId, style.categoryId)
# #   ) %>% 
# #   as_tibble()
# 
# 
# bne_slice_hops <- bne_slice %>% 
#   select(
#     cluster_assignment,
#     name, abv, ibu, srm, style, style_collapsed, hops_name_1:hops_name_13
#   ) %>% 
#   gather(
#     key = hops,
#     value = hops_nme,
#     hops_name_1:hops_name_13
#   ) %>% 
#   mutate(
#     count = 1
#   ) 
# 
# bne_slice_hops$hops_nme <- factor(bne_slice_hops$hops_nme) # check out levels
# bne_slice_hops$hops_nme <- as.character(bne_slice_hops$hops_nme)
# 
# bne_slice_spread_hops <- bne_slice_hops %>% 
#   mutate(
#     row = 1:nrow(bne_slice_hops)        # add a unique idenfitier for row. we'll drop this later
#   ) %>%                                 # see hadley's comment on https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr
#   spread(
#     key = hops_nme,
#     value = count
#   ) %>% 
#   select(
#     name:style_collapsed, Ahtanum:Zythos
#   )
# View(bne_slice_spread_hops)
# 
# # take out all rows that have no ingredients specified at all
# ind <- apply(bne_slice_spread_hops[, 4:ncol(bne_slice_spread_hops)], 1, function(x) all(is.na(x)))
# bne_slice_spread_hops_no_na <- bne_slice_spread_hops[ !ind, ]
# 
# bne_slice_spread_hops_group <- bne_slice_spread_hops_no_na %>% 
#   group_by(name, style, style_collapsed) %>% 
#   summarise_all(                            # summarises all non-grouping columns
#     sum, na.rm = TRUE
#     # n = count()
#   ) 
# View(bne_slice_spread_hops_group)
# 
# hops_by_style <- bne_slice_spread_hops_group %>% 
#   ungroup() %>% 
#   select(-c(name, style)) %>% 
#   group_by(style_collapsed) %>% 
#   summarise_all(
#     sum, na.rm = TRUE
#   ) %>%
#   mutate(
#     total_hops = rowSums(.[2:ncol(.)])
#   ) %>% 
#   arrange(
#     desc(total_hops)
#   )
# View(hops_by_style[, c(1, 147:ncol(hops_by_style))])
# 
# 
# # bar chart
# ggplot(hops_by_style, aes(style_collapsed, total_hops)) +
#   geom_bar(stat = "identity")
# 
# 
# 
# 
# 
# bne_slice_malt <- bne_slice %>% 
#   select(
#     name, style, style_collapsed, malt_name_1:malt_name_10
#   ) %>% 
#   gather(
#     key = malt,
#     value = malt_nme,
#     malt_name_1:malt_name_10
#   ) %>% 
#   mutate(
#     count = 1
#   ) 
# 
# bne_slice_spread_malt <- bne_slice_malt %>% 
#   mutate(
#     row = 1:nrow(bne_slice_malt)        # add a unique idenfitier for row
#   ) %>%  
#   spread(
#     key = malt_nme,
#     value = count
#   ) %>% 
#   select(
#     name:style_collapsed, `Aromatic Malt`:`Wheat Malt - White`
#   )
# 
# 
# # take out all rows that have no ingredients specified at all
# ind <- apply(bne_slice_spread_malt[, 4:ncol(bne_slice_spread_malt)], 1, function(x) all(is.na(x)))
# bne_slice_spread_malt_no_na <- bne_slice_spread_malt[ !ind, ]
# 
# 
# bne_slice_spread_malt_group <- bne_slice_spread_malt_no_na %>% 
#   group_by(name, style, style_collapsed) %>% 
#   summarise_all(                            
#     sum, na.rm = TRUE
#   )
# 
# # matrix of total number of ingredient instances per beer style
# malt_by_style <- bne_slice_spread_malt_group %>% 
#   ungroup() %>% 
#   select(-c(name, style)) %>% 
#   group_by(style_collapsed) %>% 
#   summarise_all(
#     sum, na.rm = TRUE
#   ) %>%  mutate(
#     total_malt = rowSums(.[2:ncol(.)])
#   ) %>% 
#   arrange(
#     desc(total_malt)
#   )
# 
# 
# 
# # ----------- add all hops to all beers
# hops_join <- inner_join(bne_slice_spread_hops, beer_necessities)
# 
# 
# 
# 
# 
# 

















# ---------- do this w function


# take for the ingredient we want, take e.g. colums hops_name_1, hops_name_2 and make the hops names the columns
# if a given beer contains that ingredient, it gets a 1 in that column, a 0 otherwise

# gather all the hops_name_1, hops_name_2, etc. columns into one long key column called hops
# its corresponding value column, hops_nme specifies the actual hops name (Centennial, Apollo)
# add a new count column with a 1 for every beer that we'll use as the value when we spread ingredients out in their
# own columns

bne_slice <- clustered_beer %>% 
  inner_join(beer_necessities)

ingredient_want <- "hops"

get_last_ing_name_col <- function(df) {
  for (col in names(df)) {
    if (grepl(paste(ingredient_want, "_name_", sep = ""), col) == TRUE) {
      name_last_ing_col <- col
    }
  }
  return(name_last_ing_col)
}

last_ingredient_name <- get_last_ing_name_col(bne_slice)
last_ingredient_index <- which(colnames(bne_slice)==last_ingredient_name)


first_ingredient_name <- paste(ingredient_want, "_name_1", sep="")
first_ingredient_index <- which(colnames(bne_slice)==first_ingredient_name)

# vector of all ingredient names
ingredient_colnames <- names(bne_slice)[first_ingredient_index:last_ingredient_index]


to_keep_col_names <- c("cluster_assignment", "name", "abv", "ibu", "srm", "style", "style_collapsed")

gather_ingredients <- function(df, cols_to_gather) {
  to_keep_indices <- which(colnames(df) %in% to_keep_col_names)
  
  selected_df <- df[, c(to_keep_indices, first_ingredient_index:last_ingredient_index)]
  
  new_ing_indices <- which(colnames(selected_df) %in% ingredient_colnames)    # indices will have changed since we pared down 
  
  df_gathered <- selected_df %>%
    gather_(
      key_col = "ing_keys",
      value_col = "ing_names",
      gather_cols = colnames(selected_df)[new_ing_indices]
    ) %>%
    mutate(
      count = 1
    )
  df_gathered
}
beer_gathered <- gather_ingredients(bne_slice, ingredient_colnames)  # ingredient colnames defined above function

# get a vector of all ingredient levels
beer_gathered$ing_names <- factor(beer_gathered$ing_names)
ingredient_levels <- levels(beer_gathered$ing_names) 
# %>% arrange()

# take out the level that's just an empty string
# first, get all indices in ingredient_levels except for the one that's an empty string
to_keep_levels <- !(c(1:length(ingredient_levels)) %in% which(ingredient_levels == ""))
# then pare down ingredient_levels to only those indices
ingredient_levels <- ingredient_levels[to_keep_levels]



spread_ingredients <- function(df) {
  df_spread <- df %>% 
    mutate(
      row = 1:nrow(df)        # add a unique idenfitier for each row. we'll drop this later
    ) %>%                                 # see hadley's comment on https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr
    spread(
      key = ing_names,
      value = count
    ) 
  return(df_spread)
}

beer_spread <- spread_ingredients(beer_gathered)

# df <- beer_spread
select_spread_cols <- function(df) {
  to_keep_col_indices <- which(colnames(df) %in% to_keep_col_names)
  to_keep_ingredient_indices <- which(colnames(df) %in% ingredient_levels)
  
  to_keep_inds_all <- c(to_keep_col_indices, to_keep_ingredient_indices)

  new_df <- df %>% 
    select_(
      .dots = to_keep_inds_all
      # .dots = names(df)[c(to_keep_col_indices, to_keep_ingredient_indices)]  
      )
  return(new_df)
}
beer_spread_selected <- select_spread_cols(beer_spread)

# take out all rows that have no ingredients specified at all
inds_to_remove <- apply(beer_spread_selected[, first_ingredient_index:last_ingredient_index], 
             1, function(x) all(is.na(x)))
beer_spread_no_na <- beer_spread_selected[ !inds_to_remove, ]


# --------- group by all factor columns (even though we're only interested in name right now) so that
# they won't be included in the summarise_all() function
# we sum each cell of each of the ingredient columns which turns our NAs into 0s. 1 is the max outcome per cell.
groupers <- c("name", "style", "style_collapsed")
groupers_indices <- which(groupers %in% colnames(beer_spread_no_na))

not_for_summing <- which(colnames(beer_spread_no_na) %in% to_keep_col_names)
max_not_for_summing <- max(not_for_summing)

# # ------ what I'd like to be able to do -----
# ingredients_per_beer <- beer_spread_no_na %>%
#   group_by_(.dots = groupers) %>%           # not sure why not grouping by style_collapsed
#   summarise_all(
#     sum, na.rm = TRUE
#   ) %>%
#   mutate(
#     total = rowSums(.[(max_not_for_summing+1):ncol(.)], na.rm = TRUE)   # or should max_not_for_summing+1 be 2
#   )

# d <- beer_spread_no_na[, (max_not_for_summing+1):ncol(beer_spread_no_na)]



beer_spread_no_na[is.na(beer_spread_no_na)] <- 0 

ingredients_per_beer <- beer_spread_selected %>%
  mutate(
    total = rowSums(.[(max_not_for_summing + 1):ncol(.)], na.rm = TRUE)    # are there really no beers with multiple hops?
  )

ingredients_per_style <- ingredients_per_beer %>% 
  group_by(style_collapsed) %>% 
  summarise_if(
    is.numeric,
    sum, na.rm = TRUE
  ) %>%
  mutate(
    total = rowSums(.[, (max_not_for_summing + 1):ncol(.)])
  ) %>% 
  arrange(
    desc(total)
  )


