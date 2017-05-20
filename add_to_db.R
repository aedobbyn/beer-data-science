# add to mysql db

source("./munge.R")

#### -------------------- MySQL ----------------------- ####
library(RMySQL)

drv <- dbDriver("RMySQL")
con <- dbConnect(RMySQL::MySQL(), dbname="brewery_db", host='localhost', port=3306, user="root")

    
dbWriteTable(con, "beers", 
             value = unnested$data, append = TRUE, row.names = FALSE)


dbWriteTable(con, "breweries", 
             value = unnested$data, append = TRUE, row.names = FALSE)

