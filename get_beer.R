
# Documentation
# http://www.brewerydb.com/developers/docs

library(tidyjson)
library(jsonlite)
library(httr)

key <- "2302d0ab728f1b1aa664b9db6585885b"

brewery_db <- handle(paste0("http://api.brewerydb.com/v2", key))
add_key <- paste0("/?key=", key)
GET(handle = brewery_db, path = "/beer/oeGSxs", add_headers())

GET(handle = brewery_db, path = "/beer/oeGSxs")

GET("http://api.brewerydb.com/v2/?key=2302d0ab728f1b1aa664b9db6585885b&beers")


request <- paste0("http://api.brewerydb.com/v2/?key=", key, "&format=json", "/beer/oeGSxs")


one_beer <- GET(request)
one_beer


fromJSON(paste0("http://api.brewerydb.com/v2/beers/?key=2302d0ab728f1b1aa664b9db6585885b"))

fromJSON(request)



a_beer <- GET("http://api.brewerydb.com/v2/beer/oeGSxs/?key=2302d0ab728f1b1aa664b9db6585885b")



GET("http://api.brewerydb.com/v2/?key=2302d0ab728f1b1aa664b9db6585885b", path = "beers", verbose())

GET("http://api.brewerydb.com/v2/?key=2302d0ab728f1b1aa664b9db6585885b", query = "Goosinator", verbose())




GET("http://google.com/", path = "search", query = list(q = "Goosinator"))


big_request <- paste0("http://api.brewerydb.com/v2/?key=", key, "&beers")


all_beers <- GET(big_request)
all_beers







fromJSON("http://api.brewerydb.com/v2/beer/oeGSxs/?key=2302d0ab728f1b1aa664b9db6585885b")



