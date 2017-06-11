source("./get_ingredient_levels.R")


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





# bne_slice <- beer_necessities_expanded[100:200, ] 

bne_slice <- clustered_beer %>% 
  inner_join(beer_necessities)

# bne_slice <- clustered_beer %>%       ### replace bne with whatever we want here
#   select(
#     -c(id, description, glass, hops_id, malt_id, glasswareId, styleId, style.categoryId)
#   ) %>% 
#   as_tibble()


bne_slice_hops <- bne_slice %>% 
  select(
    cluster_assignment,
    name, abv, ibu, srm, style, style_collapsed, hops_name_1:hops_name_13
  ) %>% 
  gather(
    key = hops,
    value = hops_nme,
    hops_name_1:hops_name_13
  ) %>% 
  mutate(
    count = 1
  ) 

bne_slice_hops$hops_nme <- factor(bne_slice_hops$hops_nme) # check out levels
bne_slice_hops$hops_nme <- as.character(bne_slice_hops$hops_nme)

bne_slice_spread_hops <- bne_slice_hops %>% 
  mutate(
    row = 1:nrow(bne_slice_hops)        # add a unique idenfitier for row. we'll drop this later
  ) %>%                                 # see hadley's comment on https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr
  spread(
    key = hops_nme,
    value = count
  ) %>% 
  select(
    name:style_collapsed, Ahtanum:Zythos
  )
View(bne_slice_spread_hops)

# take out all rows that have no ingredients specified at all
ind <- apply(bne_slice_spread_hops[, 4:ncol(bne_slice_spread_hops)], 1, function(x) all(is.na(x)))
bne_slice_spread_hops_no_na <- bne_slice_spread_hops[ !ind, ]

bne_slice_spread_hops_group <- bne_slice_spread_hops_no_na %>% 
  group_by(name, style, style_collapsed) %>% 
  summarise_all(                            # summarises all non-grouping columns
    sum, na.rm = TRUE
    # n = count()
  ) 
View(bne_slice_spread_hops_group)

hops_by_style <- bne_slice_spread_hops_group %>% 
  ungroup() %>% 
  select(-c(name, style)) %>% 
  group_by(style_collapsed) %>% 
  summarise_all(
    sum, na.rm = TRUE
  ) %>%
  mutate(
    total_hops = rowSums(.[2:ncol(.)])
  ) %>% 
  arrange(
    desc(total_hops)
  )
View(hops_by_style[, c(1, 147:ncol(hops_by_style))])


# bar chart
ggplot(hops_by_style, aes(style_collapsed, total_hops)) +
  geom_bar(stat = "identity")





bne_slice_malt <- bne_slice %>% 
  select(
    name, style, style_collapsed, malt_name_1:malt_name_10
  ) %>% 
  gather(
    key = malt,
    value = malt_nme,
    malt_name_1:malt_name_10
  ) %>% 
  mutate(
    count = 1
  ) 

bne_slice_spread_malt <- bne_slice_malt %>% 
  mutate(
    row = 1:nrow(bne_slice_malt)        # add a unique idenfitier for row
  ) %>%  
  spread(
    key = malt_nme,
    value = count
  ) %>% 
  select(
    name:style_collapsed, `Aromatic Malt`:`Wheat Malt - White`
  )
View(bne_slice_spread_malt)


# take out all rows that have no ingredients specified at all
ind <- apply(bne_slice_spread_malt[, 4:ncol(bne_slice_spread_malt)], 1, function(x) all(is.na(x)))
bne_slice_spread_malt_no_na <- bne_slice_spread_malt[ !ind, ]


bne_slice_spread_malt_group <- bne_slice_spread_malt_no_na %>% 
  group_by(name, style, style_collapsed) %>% 
  summarise_all(                            
    sum, na.rm = TRUE
  )
View(bne_slice_spread_malt_group)

# matrix of total number of ingredient instances per beer style
malt_by_style <- bne_slice_spread_malt_group %>% 
  ungroup() %>% 
  select(-c(name, style)) %>% 
  group_by(style_collapsed) %>% 
  summarise_all(
    sum, na.rm = TRUE
  ) %>%  mutate(
    total_malt = rowSums(.[2:ncol(.)])
  ) %>% 
  arrange(
    desc(total_malt)
  )
View(malt_by_style)



# ----------- add all hops to all beers
hops_join <- inner_join(bne_slice_spread_hops, beer_necessities)























# ---------- do this w function


# take for the ingredient we want, take e.g. colums hops_name_1, hops_name_2 and make the hops names the columns
# if a given beer contains that ingredient, it gets a 1 in that column, a 0 otherwise

# gather all the hops_name_1, hops_name_2, etc. columns into one long key column called hops
# its corresponding value column, hops_nme specifies the actual hops name (Centennial, Apollo)
# add a new count column with a 1 for every beer that we'll use as the value when we spread ingredients out in their
# own columns

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


gather_ingredients <- function(df) {
  to_select <- c("cluster_assignment", "name", "abv", "ibu", "srm", "style", "style_collapsed",
                 first_ingredient_name:last_ingredient_name)
  
  ing_cols <- bne_slice[, first_ingredient_name:last_ingredient_name]
  
  df_gathered <- df %>% 
    select_(
      to_select
    ) %>% 
    gather(
      key = hops,
      value = hops_nme,
      hops_name_1:hops_name_13
    ) %>% 
    mutate(
      count = 1
    ) 
  df_gathered
}
beer_gathered <- gather_ingredients(bne_slice)


# bne_slice_hops$hops_nme <- factor(bne_slice_hops$hops_nme) # check out levels
# bne_slice_hops$hops_nme <- as.character(bne_slice_hops$hops_nme)

spread_ingredients <- function(df) {
  df_spread <- df %>% 
    mutate(
      row = 1:nrow(bne_slice_hops)        # add a unique idenfitier for each row. we'll drop this later
    ) %>%                                 # see hadley's comment on https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr
    spread(
      key = hops_nme,
      value = count
    ) 
}

beer_spread <- spread_ingredients(beer_gathered)

select_beer_spread <- function(df) {
  
  
  df %>% 
    select(
      name:style_collapsed, Ahtanum:Zythos
    )
}


# take out all rows that have no ingredients specified at all
inds_to_remove <- apply(beer_spread[, first_ingredient_index:last_ingredient_index], 
             1, function(x) all(is.na(x)))
beer_spread_no_na <- beer_spread[ !inds_to_remove, ]


groupers <- c("name", "style", "style_collapsed")
groupers_indices <- which(groupers %in% colnames(beer_spread_no_na))
max_grouper_index <- max(groupers_indices)
  
ingredients_per_beer <- beer_spread_no_na %>% 
  group_by(name, style, style_collapsed) %>% 
  summarise_all(                            # summarises all non-grouping columns
    sum, na.rm = TRUE
    # n = count()
  ) %>% 
  mutate(
    total = rowSums(.[2:ncol(.)])
  )

ingredients_per_style <- ingredients_per_beer %>% 
  ungroup() %>% 
  select(-c(name, style)) %>% 
  group_by(style_collapsed) %>% 
  summarise_all(
    sum, na.rm = TRUE
  ) %>%
  mutate(
    total_hops = rowSums(.[2:ncol(.)])
  ) %>% 
  arrange(
    desc(total_hops)
  )


