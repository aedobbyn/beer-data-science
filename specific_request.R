# specific requests

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



# -------------- add an addition, e.g. ingredients --------
request_w_additions <- function(ep, addition) {
  this_request <- function() { fromJSON(paste0(base_url, "/", ep, 
                                               "/", key_preface, key, addition),
                                        flatten = TRUE) }
  this_request
}

get_beers_w_ingredients <- request_w_additions("beers", "&withIngredients=Y")
beer_w_ingredients <- get_beers_w_ingredients()


# unnest ingredients without first unnesting all data
# unlike unnest_ingredients, if you don't unnest everything first with unnest_it()
# then the argument is the full json response so you need to work with df[["data]] rather than just df

unnest_just_ingredients <- function(df) {
  df[["data"]]$hops_name <- "Not available"
  df[["data"]]$hops_id <- "Not available"
  df[["data"]]$malt_name <- "Not available"
  df[["data"]]$malt_id <- "Not available"
  
  for (row in 1:nrow(df[["data"]])) {
    if (!is.null(df[["data"]][["ingredients.hops"]][[row]][["name"]]) | 
        !is.null(df[["data"]][["ingredients.malt"]][[row]][["name"]])) {
      df[["data"]][["hops_name"]][[row]] <- paste(df[["data"]][["ingredients.hops"]][[row]][["name"]],
                                                        collapse = ", ")
      df[["data"]][["hops_id"]][[row]] <- paste(df[["data"]][["ingredients.hops"]][[row]][["id"]],
                                                      collapse = ", ")
      
      df[["data"]][["malt_name"]][[row]] <- paste(df[["data"]][["ingredients.malt"]][[row]][["name"]],
                                                        collapse = ", ")
      df[["data"]][["malt_id"]][[row]] <- paste(df[["data"]][["ingredients.malt"]][[row]][["id"]],
                                                      collapse = ", ")
    }
  }
  return(df)
}


beer_w_ingredients_unnested <- unnest_just_ingredients(beer_w_ingredients)





