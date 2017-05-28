# most popular beers
# may want to cluster the remaining into one of these groups down the road

source("./munge.R")
library(forcats)

beer_dat <- dbGetQuery(con, "select * from all_beers")

beer_dat <- beer_necessities

# set types
beer_dat$style <- factor(beer_dat$style)
beer_dat$styleId <- factor(beer_dat$styleId)  
beer_dat$glass <- factor(beer_dat$glass)

beer_dat$ibu <- as.numeric(beer_dat$ibu)
beer_dat$srm <- as.numeric(beer_dat$srm)
beer_dat$abv <- as.numeric(beer_dat$abv)


# pare down to only cases where style is not NA
beer_dat_pared <- beer_dat[complete.cases(beer_dat$style), ]


# ------------------ pare to most popular styles ---------------

# arrange beer dat by style popularity
style_popularity <- beer_dat_pared %>% 
  group_by(style) %>% 
  count() %>% 
  arrange(desc(n))
style_popularity


# n beer instances per style
# n_beers_per_style <- beer_dat_pared %>% group_by(style) %>% count() 

style_popularity <- bind_cols(style_popularity, 
                               n_scaled = as.vector(scale(style_popularity$n)))


# keep only styles that have >50 beers in their style
# comes out to 47 styles
popular_styles <- style_popularity %>% 
  filter(n_scaled > 0)

# pare dat down to only beers that fall into those styles
popular_beer_dat <- beer_dat_pared %>% 
  filter(
    style %in% popular_styles$style
  ) %>% 
  droplevels()
nrow(popular_beer_dat)




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

popular_beer_dat <- collapse_styles(popular_beer_dat)
popular_beer_dat <- popular_beer_dat %>% droplevels()

beer_necessities <- collapse_styles(beer_necessities)   

beer_necessities <- as_tibble(beer_necessities)



# collapse some more
popular_beer_dat$style_collapsed <- popular_beer_dat$style_collapsed %>%
  fct_collapse(
    "Wheat" = c("Hefeweizen", "Wheat"),
    "Pilsener" = c("Pilsner", "American-Style Pilsener") # pilsener = pilsner = pils
  )




