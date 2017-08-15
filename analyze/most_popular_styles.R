# most popular beers
# may want to cluster the remaining into one of these groups down the road

# source("./analyze/munge.R")
source("/Users/amanda/Desktop/Projects/beer_data_science/read_from_db.R")  # using absolute path
# here so that shiny app can source this from inside a different directory than this file
library(forcats)

# beer_dat <- dbGetQuery(con, "select * from all_beers")

beer_dat <- beer_necessities

# # set types
# beer_dat$style <- factor(beer_dat$style)
# beer_dat$styleId <- factor(beer_dat$styleId)  
# beer_dat$glass <- factor(beer_dat$glass)
# 
# beer_dat$ibu <- as.numeric(beer_dat$ibu)
# beer_dat$srm <- as.numeric(beer_dat$srm)
# beer_dat$abv <- as.numeric(beer_dat$abv)


# pare down to only cases where style is not NA
beer_dat_pared <- beer_dat[complete.cases(beer_dat$style), ]


# ------------------ pare to most popular styles ---------------

# arrange beer dat by style popularity
style_popularity <- beer_dat_pared %>% 
  group_by(style) %>% 
  count() %>% 
  arrange(desc(n))
style_popularity

# and add a column that scales it
style_popularity <- bind_cols(style_popularity, 
                               n_scaled = as.vector(scale(style_popularity$n)))


# find styles that are above a z-score of 0
popular_styles <- style_popularity %>% 
  filter(n_scaled > 0)

# pare dat down to only beers that fall into those styles
popular_beer_dat <- beer_dat_pared %>% 
  filter(
    style %in% popular_styles$style
  ) %>% 
  droplevels() %>% 
  as_tibble() 
nrow(popular_beer_dat)

# find the centers (mean abv, ibu, srm) of the most popular styles
style_centers <- popular_beer_dat %>% 
  group_by(style_collapsed) %>% 
  add_count() %>% 
  summarise(
    mean_abv = mean(abv, na.rm = TRUE),
    mean_ibu = mean(ibu, na.rm = TRUE), 
    mean_srm = mean(srm, na.rm = TRUE),
    n = median(n, na.rm = TRUE)          # median here only for summarise. should be just the same as n
  ) %>% 
  arrange(desc(n)) %>% 
  drop_na() %>% 
  droplevels()
  

# Give some nicer names
style_centers_rename <- style_centers %>% 
  rename(
    `Collapsed Style` = style_collapsed,
    `Mean ABV` = mean_abv,
    `Mean IBU` = mean_ibu,
    `Mean SRM` = mean_srm,
    `Numer of Beers` = n
  )



