# read from db

drv <- dbDriver("RMySQL")
con <- dbConnect(RMySQL::MySQL(), dbname="brewery_db", host='localhost', port=3306, user="root")

beer_necessities <- dbReadTable(con, "beer_necessities")

# set types
beer_necessities$style <- factor(beer_necessities$style)
beer_necessities$styleId <- factor(beer_necessities$styleId)
beer_necessities$glass <- factor(beer_necessities$glass)

beer_necessities$ibu <- as.numeric(beer_necessities$ibu)
beer_necessities$srm <- as.numeric(beer_necessities$srm)
beer_necessities$abv <- as.numeric(beer_necessities$abv)

beer_necessities$style_collapsed <- factor(beer_necessities$style_collapsed)

beer_necessities$hops_name <- factor(beer_necessities$hops_name)
beer_necessities$malt_name <- factor(beer_necessities$malt_name)

beer_necessities$hops_id <- factor(beer_necessities$hops_id)
beer_necessities$malt_id <- factor(beer_necessities$malt_id)





