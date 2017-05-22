
source("./munge.r")

library(neuralnet)
library(nnet)
library(caret)



beer_dat <- dbGetQuery(con, "select * from all_beers")

# factors that could predict style
predictors <- c("abv", "glass", "srm", "ibu")



# may want to use ids for these instead
beer_dat$style <- factor(beer_dat$style)
beer_dat$styleId <- factor(beer_dat$styleId)  
beer_dat$glass <- factor(beer_dat$glass)

beer_dat$ibu <- as.numeric(beer_dat$ibu)
beer_dat$srm <- as.numeric(beer_dat$srm)
beer_dat$abv <- as.numeric(beer_dat$abv)



# pare down to only cases where style is not NA
beer_dat_pared <- beer_dat[complete.cases(beer_dat$style), ]

# linear model
m_1 <- glm(style ~ abv + srm + ibu, data = beer_dat_pared)
summary(m_1)





# pare to most popular styles
# may want to cluster the remaining into one of these groups down the road

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





# neural nets

nn_mod <- multinom(style ~ abv + srm + ibu, size = 2,
                   data = popular_beer_dat, maxit=500, trace=T)
nn_mod


# which variables are the most important?

most_important_vars <- varImp(nn_mod)



