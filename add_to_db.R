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
             value = beer_necessities, append = TRUE, row.names = FALSE)




# ------ working on insert statement -------
test <- data.frame(list(test = c(rep("baz", 1))))
test_2 <- data.frame(list(test = c(rep("bars", 14))))
insert_query <- paste("INSERT INTO glassware (test_2) VALUES(", paste(test, collapse = ","), ")")
insert_query

update_query <- paste("UPDATE glassware SET test_2 = (", paste(test_2$test, collapse = ","), ")")
update_query

test_one <- data.frame(list(test = "foo"))
insert_one_query <- paste("INSERT INTO glassware (test) VALUES(", test_one, ")")
insert_one_query


dbSendStatement(con, insert_query)
dbSendStatement(con, insert_one_query)

dbSendStatement(con, update_query)


gware <- dbReadTable(con, "glassware")
gware


dbWriteTable(con, "glassware", test_2, append = FALSE)


