
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

# canonical get all beers api call
# http://api.brewerydb.com/v2/beers/?key=29db4ead6450247d3e56108b2559071a

endpoints <- c("beers", "breweries", "categories", "events",
                    "featured", "features", "fluidsizes", "glassware",
                    "locations", "guilds", "heartbeat", "ingredients",
                    "search", "search/upc", "socialsites", "styles")

single_param_endpoints <- c("beer", "brewery", "category", "event",
                          "feature", "glass", "guild", "hop", "ingredient",
                          "location", "socialsite", "style", "menu")


# ---- build functions for requesting just a single beer, brewery, menu, etc. (from single_param_endpoints)
# uses purrr::partial 

build_single_arg_requests <- function() {
  all_funcs <- list()
  
  for (ep in single_param_endpoints) {
    get_ <- function(id, ep) {
      fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
    }
    
    this_func <- partial(get_, ep = ep, envir = .GlobalEnv)

    all_funcs <- c(all_funcs, this_func)

    }
  all_funcs
}

build_single_arg_requests()
get_beer("HZ9xM2")
this_func


# actually make the functions
get_beer <- partial(get_, ep = "beer")
get_brewery <- partial(get_, ep = "brewery")

# example use case
get_beer("HZ9xM2")

get_event("1")


# ----------- multiple pagination
# find the total number of pages and use that to loop through

source("./munge.R")   # for unnest_it()

# including ingredients in here and flattening
# full url: http://api.brewerydb.com/v2/beers/?key=29db4ead6450247d3e56108b2559071a&withIngredients=Y

paginated_request <- function(ep, addition) {
  full_request <- NULL
  first_page <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                , "&p=1"))
  number_of_pages <- first_page$numberOfPages
  for (page in 1:number_of_pages) {    
    this_request <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                    , "&p=", page, addition),
                             flatten = TRUE) 
    this_req_unnested <- unnest_it(this_request)
    print(this_req_unnested$currentPage)
    full_request <- bind_rows(full_request, this_req_unnested[["data"]])
  }
  full_request
} 

all_beer_raw <- paginated_request("beers", "&withIngredients=Y")

all_breweries <- paginated_request("breweries", "")  # if no addition desired, just add empty string











