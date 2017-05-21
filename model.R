
source("./munge.r")

beer_dat <- dbGetQuery(con, "select * from all_beers")

# factors that could predict style
predictors <- c("abv", "glass", "srm", "ibu")


library(neuralnet)

# may want to use ids for these instead
beer_dat$style <- factor(beer_dat$style)
beer_dat$glass <- factor(beer_dat$glass)
beer_dat$srm <- as.numeric(beer_dat$glass)



# linear model
m_1 <- glm(styleId ~ abv + glass + srm + ibu, data = beer_dat)
summary(m_1)
