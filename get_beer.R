
# Documentation
# http://www.brewerydb.com/developers/docs

library(tidyjson)
library(jsonlite)    # fromJSON() is the same as content(GET())
library(httr)

# gather the three global variables used in all requests
source("./key.R")
base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="


endpoints <- c("beers", "breweries", "categories", "events",
                    "featured", "features", "fluidsizes", "glassware",
                    "locations", "guilds", "heartbeat", "ingredients",
                    "search", "search/upc", "socialsites", "styles")

single_param_endpoints <- c("beer", "brewery", "category", "event",
                          "feature", "glass", "guild", "hop", "ingredient",
                          "location", "socialsite", "style", "menu")



# vector of all possible single endpoint requests
single_endpoint_request <- function() {
  all_requests <- vector()
  for (i in endpoints) {
    this_request <- paste0(base_url, "/", i, key_preface, key)
    all_requests <- c(all_requests, this_request)
  }
  all_requests
}

single_endpoint_request()


send_request <- function() {
  for (i in endpoints[1]) {
    this_request <- paste0(base_url, "/", i, key_preface, key)
    print(this_request)
    this_data <- fromJSON(this_request)
  }
  this_data$data
}

send_request()

single_endpoint_request()

# ----------------------------------------------------------------





# --------------- splice these out into their own getting functions -------------
# these won't work until have premium
# e.g.
all_beers <- fromJSON("http://api.brewerydb.com/v2/beers/?key=2302d0ab728f1b1aa664b9db6585885b")

# but in theory
single_endpoint_request_funcs <- function(ep) {
    this_request <- function() { fromJSON(paste0(base_url, "/", ep, "/", key_preface, key)) }
    this_request
}

get_breweries <- single_endpoint_request_funcs("breweries")

all_breweries <- get_breweries()
brewery_names <- all_breweries[["data"]][["name"]]

get_beers <- single_endpoint_request_funcs("beers")
all_beer <- get_beers()



# this will work, however, since we're only asking for a single beer
simple_request_funcs <- function(endpoint_name) {
  this_request <- function(id) {
    fromJSON(paste0(base_url, "/", endpoint_name, "/", id, "/", key_preface, key))
  }
  this_request
}

get_beer <- simple_request_funcs("beer")
get_beer("oeGSxs")

get_hops <- simple_request_funcs("hop")
get_hops("84")







