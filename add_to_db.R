# add to mysql db

source("./munge.R")

#### -------------------- MySQL ----------------------- ####
library(RMySQL)

drv <- dbDriver("RMySQL")
con <- dbConnect(RMySQL::MySQL(), dbname="brewery_db", host='localhost', port=3306, user="root")

    
dbWriteTable(con, "beers", 
             value = unnested_beer$data, append = TRUE, row.names = FALSE)


dbWriteTable(con, "breweries", 
             value = unnested_breweries$data, append = TRUE, row.names = FALSE)


dbWriteTable(con, "glassware", 
             value = unnested_glassware$data, append = TRUE, row.names = FALSE)


