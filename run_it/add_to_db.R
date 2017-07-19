# add to mysql db

source("./munge.R")

#### -------------------- MySQL ----------------------- ####
library(RMySQL)

drv <- dbDriver("RMySQL")
con <- dbConnect(RMySQL::MySQL(), dbname="brewery_db", host='localhost', port=3306, user="root")

    
dbWriteTable(con, "all_beers", 
             value = unnested_beer$data, append = TRUE, row.names = FALSE)


dbWriteTable(con, "breweries", 
             value = unnested_breweries$data, append = TRUE, row.names = FALSE)


dbWriteTable(con, "all_glassware", 
             value = all_glassware, append = TRUE, row.names = FALSE)

dbWriteTable(con, "beer_necessities", 
             value = beer_necessities, overwrite = TRUE, row.names = FALSE)

dbWriteTable(con, "simple_beer_necessities", 
             value = simple_beer_necessities, append = TRUE, row.names = FALSE)


dbWriteTable(con, "beer_dat", 
             value = beer_dat, append = TRUE, row.names = FALSE)

dbWriteTable(con, "beer_totals", 
             value = beer_totals, append = TRUE, row.names = FALSE)




# ------------- write to csv

write_csv(beer_necessities, "./beer_necessities.csv", append = FALSE, na = "")




