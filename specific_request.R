# specific requests

# ~ ~ this somewhat deprecated: see construct_funcs.R for better solution to single_endpoint_request_funcs()

endpoints <- c("beers", "breweries", "categories", "events",
               "featured", "features", "fluidsizes", "glassware",
               "locations", "guilds", "heartbeat", "ingredients",
               "search", "search/upc", "socialsites", "styles")

single_param_endpoints <- c("beer", "brewery", "category", "event",
                            "feature", "glass", "guild", "hop", "ingredient",
                            "location", "socialsite", "style", "menu")


# vector of all possible single endpoint requests (e.g., all beers, all breweries)
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



# --------------- get a single page for a given endpoint -------------

# create functions to create functions for getting all data for a single endpoint
single_endpoint_request_funcs <- function(ep, page) {
  this_request <- function() { fromJSON(paste0(base_url, "/", ep, "/", key_preface, key,
                                               "&p=", page)) }
  this_request
}


# using single_endpoint_request_funcs, create a function to get all beers and save all
# the beers in an object
get_beers <- single_endpoint_request_funcs("beers", "3")
beer_page_3 <- get_beers()

get_breweries <- single_endpoint_request_funcs("breweries", "14")
breweries_page_14 <- get_breweries()




# -----------------------------------
# these use endpoint_name from single_param_endpoints and an id
# specify a single id
simple_request_funcs <- function(endpoint_name) {
  this_request <- function(id) {
    fromJSON(paste0(base_url, "/", endpoint_name, "/", id, "/", key_preface, key))
  }
  this_request
}

get_beer <- simple_request_funcs("beer")
get_beer("oeGSxs")

get_hop <- simple_request_funcs("hop")
get_hop("84")


# # ------ pre-stack overflow thougths on how to do this (now superceded by construct_funcs.R) ------
# build_single_arg_requests <- function() {
#   all_funcs <- list()
# 
#   for (ep in single_param_endpoints) {
#     get_ <- function(id, ep) {
#       fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
#     }
# 
#     this_func <- partial(get_, ep = ep, envir = .GlobalEnv)
# 
#     all_funcs <- c(all_funcs, this_func)
# 
#   }
#   all_funcs
# }
# build_single_arg_requests()



# -------------- add an addition, e.g. ingredients --------
request_w_additions <- function(ep, addition) {
  this_request <- function() { fromJSON(paste0(base_url, "/", ep, 
                                               "/", key_preface, key, addition),
                                        flatten = TRUE) }
  this_request
}

get_beers_w_ingredients <- request_w_additions("beers", "&withIngredients=Y")
beer_w_ingredients <- get_beers_w_ingredients()





