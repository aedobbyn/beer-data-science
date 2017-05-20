
# Documentation
# http://www.brewerydb.com/developers/docs

library(tidyverse)
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

# ----------------------------------------------------------------



# --------------- splice these out into their own getting functions -------------

# create functions to create functions for getting all data for a single endpoint
single_endpoint_request_funcs <- function(ep) {
    this_request <- function() { fromJSON(paste0(base_url, "/", ep, "/", key_preface, key)) }
    this_request
}

# this is only the first page

# using single_endpoint_request_funcs, create a function to get all beers and save all
# the beers in an object
get_beers <- single_endpoint_request_funcs("beers")
all_beer <- get_beers()

get_breweries <- single_endpoint_request_funcs("breweries")
all_breweries <- get_breweries()

get_glassware <- single_endpoint_request_funcs("glassware")
all_glassware <- get_glassware()

# names are nested within the data, e.g.
# all_breweries[["data"]][["name"]]



# ----------- multiple pagination


paginated_request <- function(ep) {
  full_request <- unnested_beer[["data"]]
  for (page in 1:3) {
    this_request <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                    , "&p=", page)) 
    this_req_unnested <- unnest_it(this_request)
    full_request <- bind_rows(full_request, this_req_unnested[["data"]])
  }
} 

paginated_get_beers <- paginated_request("beers")

more_beers <- paginated_get_beers()



# -------------------







# -----------------------------------
# specify a single id
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







