
# Documentation
# http://www.brewerydb.com/developers/docs

library(tidyjson)
library(jsonlite)
library(httr)

key <- "2302d0ab728f1b1aa664b9db6585885b"

brewery_db <- handle(paste0("http://api.brewerydb.com/v2"))
add_key <- paste0("/?key=", key)
GET(handle = brewery_db, path = "/beer/oeGSxs", add_headers())

GET(handle = brewery_db, path = "/beer/oeGSxs")


base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="


request <- "/beer/oeGSxs"
naughty_nienty <- fromJSON(paste0(base_url, request, key_preface, key))



# same as
# naughty_nienty <- fromJSON("http://api.brewerydb.com/v2/beer/oeGSxs/?key=2302d0ab728f1b1aa664b9db6585885b")

# also same as 
# naughty_nienty <- content(GET("http://api.brewerydb.com/v2/beer/oeGSxs/?key=2302d0ab728f1b1aa664b9db6585885b&format=json"))



# can't get all beers because not premium?
all_beers <- fromJSON("http://api.brewerydb.com/v2/beers/?key=2302d0ab728f1b1aa664b9db6585885b")


hop_84 <- fromJSON("http://api.brewerydb.com/v2/hop/84/?key=2302d0ab728f1b1aa664b9db6585885b")


