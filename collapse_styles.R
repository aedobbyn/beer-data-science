


# ------------------ collapse styles ---------------
# create a new column that merges styles that contain certain keywords into the same style

# most general to most specific such that if something has india pale ale it will be
# characterized as india pale ale not just pale ale
collapse_styles <- function(df) {
  keywords <- c("Lager", "Pale Ale", "India Pale Ale", "Double India Pale Ale", "India Pale Lager", "Hefeweizen", "Barrel-Aged",
                "Wheat", "Pilsner", "Pilsener", "Amber", "Golden", "Blonde", "Brown", "Black", "Stout", "Porter",
                "Red", "Sour", "Kölsch", "Tripel", "Bitter", "Saison", "Strong Ale", "Barley Wine", "Dubbel",
                "Altbier")
  
  for (beer in 1:nrow(df)) {
    if (grepl(paste(keywords, collapse="|"), popular_beer_dat$style[beer])) {    # if one of the keywords exists in the style
      for (keyword in keywords) {         # loop through the keywords to see which one it matches
        if(grepl(keyword, df$style[beer]) == TRUE) {
          df$style_collapsed[beer] <- keyword    # if we have a match assign the keyword to that row's style_collpased
        }                         # if multiple matches, it gets the later one in keywords
      } 
    } else {
      df$style_collapsed[beer] <- as.character(df$style[beer])       # else style_collapsed is just style
    }
    print(df$style_collapsed[beer])
  }
  return(df)
}

# collapse styles, drop newly unused levels
popular_beer_dat <- collapse_styles(popular_beer_dat)
popular_beer_dat <- popular_beer_dat %>% droplevels(style_collapsed) %>% as_tibble()

clustered_beer$style_collapsed <- "x"
clustered_beer <- collapse_styles(clustered_beer)
clustered_beer$style_collapsed <- factor(clustered_beer$style_collapsed)
clustered_beer <- droplevels(clustered_beer)$style_collapsed %>% as_tibble() 
clustered_beer <- clustered_beer %>% 
  filter(
    !(style_collapsed == "x")
  )

beer_necessities <- collapse_styles(beer_necessities) 
beer_necessities <- droplevels(beer_necessities)$style_collapsed %>% as_tibble()



# collapse some more
collapse_further <- function(df) {
  df[["style_collapsed"]] <- df[["style_collapsed"]] %>%
    fct_collapse(
      "Wheat" = c("Hefeweizen", "Wheat"),
      "Pilsener" = c("Pilsner", "American-Style Pilsener") # pilsener = pilsner = pils
    )
}


beer_necessities$style_collapsed <- beer_necessities$style_collapsed %>%
  fct_collapse(
    "Wheat" = c("Hefeweizen", "Wheat"),
    "Pilsener" = c("Pilsner", "American-Style Pilsener") # pilsener = pilsner = pils
  )