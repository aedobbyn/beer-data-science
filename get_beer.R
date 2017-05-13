
# Documentation
# http://www.brewerydb.com/developers/docs

library(tidyjson)
library(jsonlite)
library(httr)

source("./key.R")

base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="


request <- "/beer/oeGSxs"
naughty_nienty <- fromJSON(paste0(base_url, request, key_preface, key))


endpoints <- c("beers", "breweries", "categories", "events",
                    "featured", "features", "fluidsizes", "glassware",
                    "locations", "guilds", "heartbeat", "ingredients",
                    "search", "search/upc", "socialsites", "styles")

single_param_endpoints <- c("beer", "brewery", "category", "event",
                          "feature", "glass", "guild", "ingredient",
                          "location", "socialsite", "style", "menu")


construct_request <- function(endpoint, id) {
  request <- fromJSON(paste0(base_url, "/", endpoint, "/", id, key_preface, key))
  return(request)
}

construct_request("brewery", "KR4X6i")
construct_request("hop", "84")
construct_request("beer", "oeGSxs")


single_endpoint_request <- function() {
  all_requests <- vector()
  for (i in endpoints) {
    this_request <- paste0(base_url, "/", i, "/", key_preface, key)
    all_requests <- c(all_requests, this_request)
  }
  all_requests
}

single_endpoint_request()


single_endpoint_request_funcs <- function(ep) {
  # for (i in endpoints) {
    this_request <- function() { fromJSON(paste0(base_url, "/", ep, "/", key_preface, key)) }
    this_request
  # }
  # this_request
}

get_breweries <- single_endpoint_request_funcs("breweries")
get_breweries()


power <- function(ep) {
  function(i) {
    x ^ exponent
  }
}

square <- power(2)
square(2)


power <- function(exponent) {
  function(x) {
    x ^ exponent
  }
}

square <- power(2)
square(2)



simple_request_funcs <- function(ep) {
  # for (i in endpoints) {
  this_request <- function(id) { 
    fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
    }
  this_request
  # }
  # this_request
}

get_breweries <- simple_request_funcs("beer")
get_breweries("oeGSxs")

get_hops <- simple_request_funcs("hop")
get_hops("84")



myf <- function(x) {
  innerf <- function(x) assign("Global.res", x^2, envir = .GlobalEnv)
  innerf(x+1)
}
myf(3)




# same as
# naughty_nienty <- fromJSON("http://api.brewerydb.com/v2/beer/oeGSxs/?key=2302d0ab728f1b1aa664b9db6585885b")

# also same as 
# naughty_nienty <- content(GET("http://api.brewerydb.com/v2/beer/oeGSxs/?key=2302d0ab728f1b1aa664b9db6585885b&format=json"))



# can't get all beers because not premium?
all_beers <- fromJSON("http://api.brewerydb.com/v2/beers/?key=2302d0ab728f1b1aa664b9db6585885b")


hop_84 <- fromJSON("http://api.brewerydb.com/v2/hop/84/?key=2302d0ab728f1b1aa664b9db6585885b")

hop_84 <- fromJSON("http://api.brewerydb.com/v2/hop/84/?key=2302d0ab728f1b1aa664b9db6585885b")

