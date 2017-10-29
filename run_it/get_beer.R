
# Documentation
# http://www.brewerydb.com/developers/docs

library(tidyverse)
library(tidyjson)
library(jsonlite)    # fromJSON() is the same as content(GET())
library(httr)

source("./analyze/unnest.R")   # for unnest_it()

# gather the three global variables used in all requests
source("./run_it/key.R")
base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="

# canonical get all beers api call
# http://api.brewerydb.com/v2/beers/?key=[yourkeyhere]

endpoints <- c("beers", "breweries", "categories", "events",
                "featured", "features", "fluidsizes", "glassware",
                "locations", "guilds", "heartbeat", "ingredients",
                "search", "search/upc", "socialsites", "styles")


# ----------- multiple pagination
# find the total number of pages and use that to loop through

# including ingredients in here and flattening
# full url: http://api.brewerydb.com/v2/beers/?key=<yourkeyhere>a&withIngredients=Y

paginated_request <- function(ep, addition) {
  full_request <- NULL
  first_page <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                , "&p=1"))
  number_of_pages <- ifelse(!(is.null(first_page$numberOfPages)), 
                            first_page$numberOfPages, 1)      # if there's only one page (like for glassware), 
                                                              # numberOfPages won't be returned, so we set number_of_pages to 1

    for (page in 1:number_of_pages) {                               # change number_of_pages to 3 if only want first 3 pages
    this_request <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                    , "&p=", page, addition),
                             flatten = TRUE) 
    this_req_unnested <- unnest_it(this_request)    #  <- request unnested here
    print(this_req_unnested$currentPage)
    full_request <- bind_rows(full_request, this_req_unnested[["data"]])
  }
  full_request
} 

# ---- Examples for running: ----
# Get all beers
# beer_necessities <- paginated_request(ep = "beers", addition = "&withIngredients=Y")

# Get all glassware (example of endpoint with only one page)
# all_glassware <- paginated_request("glassware", "") 

