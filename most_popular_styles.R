# most popular beers
# may want to cluster the remaining into one of these groups down the road

source("./munge.R")

beer_dat <- dbGetQuery(con, "select * from all_beers")

# set types
beer_dat$style <- factor(beer_dat$style)
beer_dat$styleId <- factor(beer_dat$styleId)  
beer_dat$glass <- factor(beer_dat$glass)

beer_dat$ibu <- as.numeric(beer_dat$ibu)
beer_dat$srm <- as.numeric(beer_dat$srm)
beer_dat$abv <- as.numeric(beer_dat$abv)


# pare down to only cases where style is not NA
beer_dat_pared <- beer_dat[complete.cases(beer_dat$style), ]

# pare to most popular styles

# arrange beer dat by style popularity
style_popularity <- beer_dat_pared %>% 
  group_by(style) %>% 
  count() %>% 
  arrange(desc(n))
style_popularity

# keep only styles that have >50 beers in their style
# comes out to 56 styles
popular_styles <- style_popularity %>% 
  filter(n > 50)

# pare dat down to only beers that fall into those styles
popular_beer_dat <- beer_dat_pared %>% 
  filter(
    style %in% popular_styles$style
  ) %>% 
  droplevels()
nrow(popular_beer_dat)


