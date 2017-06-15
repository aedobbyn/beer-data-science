
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
# http://api.brewerydb.com/v2/beers/?key=[yourkeyhere]

endpoints <- c("beers", "breweries", "categories", "events",
                    "featured", "features", "fluidsizes", "glassware",
                    "locations", "guilds", "heartbeat", "ingredients",
                    "search", "search/upc", "socialsites", "styles")

single_param_endpoints <- c("beer", "brewery", "category", "event",
                          "feature", "glass", "guild", "hop", "ingredient",
                          "location", "socialsite", "style", "menu")





# ----------- multiple pagination
# find the total number of pages and use that to loop through

source("./munge.R")   # for unnest_it()

# including ingredients in here and flattening
# full url: http://api.brewerydb.com/v2/beers/?key=29db4ead6450247d3e56108b2559071a&withIngredients=Y

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


first_p <- paginated_request("glassware", "")
