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

bne_slice <- beer_necessities_expanded %>% 
  select(
    -c(id, description, abv, ibu, srm, glass, hops_id, malt_id, glasswareId, styleId, style.categoryId)
  ) %>% 
  as_tibble()


bne_slice_hops <- bne_slice %>% 
  select(
    name, style, style_collapsed, hops_name_1:hops_name_13
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
    name:style_collapsed, Admiral:Zythos
  )
View(bne_slice_spread_hops)

bne_slice_spread_hops_group <- bne_slice_spread_hops %>% 
  group_by(name, style, style_collapsed) %>% 
  summarise_all(                            # summarises all non-grouping columns
    sum, na.rm = TRUE
  )
View(bne_slice_spread_hops_group)

hops_by_style <- bne_slice_spread_hops_group %>% 
  ungroup() %>% 
  select(-c(name, style)) %>% 
  group_by(style_collapsed) %>% 
  summarise_all(
    sum, na.rm = TRUE
  )
View(hops_by_style)











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
    row = 1:nrow(bne_slice_hops)        # add a unique idenfitier for row
  ) %>%  
  spread(
    key = malt_nme,
    value = count
  ) %>% 
  select(
    name:style_collapsed, `Aromatic Malt`:`Wheat Malt - White`
  )
View(bne_slice_spread_malt)

bne_slice_spread_malt_group <- bne_slice_spread_malt %>% 
  group_by(name, style, style_collapsed) %>% 
  summarise_all(                            
    sum, na.rm = TRUE
  )
View(bne_slice_spread_malt_group)


malt_by_style <- bne_slice_spread_malt_group %>% 
  ungroup() %>% 
  select(-c(name, style)) %>% 
  group_by(style_collapsed) %>% 
  summarise_all(
    sum, na.rm = TRUE
  )
View(malt_by_style)

