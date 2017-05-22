
source("./get_beer.R")

# --------- all the same ---------

# same as
# naughty_nienty <- fromJSON("http://api.brewerydb.com/v2/beer/oeGSxs/?key=29db4ead6450247d3e56108b2559071a")

# also same as 
# naughty_nienty <- content(GET("http://api.brewerydb.com/v2/beer/oeGSxs/?key=2302d0ab728f1b1aa664b9db6585885b&format=json"))

request <- "/beer/oeGSxs"
naughty_nienty <- fromJSON(paste0(base_url, request, key_preface, key))



# ---------------
# simple request constructor function for single_param_endpoints
construct_request <- function(endpoint, id) {
  request <- fromJSON(paste0(base_url, "/", endpoint, "/", id, key_preface, key))
  return(request)
}

construct_request("brewery", "KR4X6i")
construct_request("hop", "84")
construct_request("beer", "oeGSxs")




# try to use assign to dynamically name functions based on their endpoint name 
simple_request_funcs <- function() {
  for (ep in single_param_endpoints) {
    # ep <- (ep, envir = globalenv())
    # this_request <- function(id) {
    name <- paste0("get_", ep)
    print(name)
    new_func <- assign(name, function(ep = ep, id) { 
      fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
    },       envir = .GlobalEnv, inherits = TRUE) 
    # fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
    # }
    # this_request
  }
  # new_func
  new_func
}

simple_request_funcs()



# same deal except using assign to assign the result of the query
send_request <- function() {
  
  for (i in endpoints[1]) {
    name <- paste0("bar_", i)
    # print(name)
    
    this_request <- paste0(base_url, "/", i, key_preface, key)
    this_data <- fromJSON(this_request)
    assign(dQuote(name), this_data, envir = .GlobalEnv)
    # print(head(boop))
    print(name)
    name
    # print(head(name[["data"]][["name"]]))
    # this_data
  }
  # return(head(name[["data"]][["name"]]))
}

send_request()


# ------------------------------------------------------

# get_beers <- simple_request_funcs("beer")
get_beer("oeGSxs")
get_breweries()

get_hop("84")


for(i in 1:6) { #-- Create objects  'r.1', 'r.2', ... 'r.6' --
  nam <- paste("r", i, sep = ".")
  assign(nam, 1:i)
}


myf <- function(x) {
  innerf <- function(x) assign("Global.res", x^2, envir = .GlobalEnv)
  innerf(x+1)
}
myf(3)
Global.res
















single_endpoint_paginated <- function(ep) {
  full_request <- all_beer[["data"]]
  for (page in 1:10) {
    this_request <- function() { fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                                 , "&p=", page)) }
    print(this_request)
    full_request <- rbind(full_request, this_request[["data"]])
  }
  full_request
}

# this is only the first page

# using single_endpoint_request_funcs, create a function to get all beers and save all
# the beers in an object
get_beers_paginated <- single_endpoint_paginated("beers")
really_all_beer <- get_beers_paginated()


for (page in 1:3) {
  full_request <- unnested_beer[["data"]]
  this_request <- fromJSON(paste0(base_url, "/", "beers", "/", key_preface, key
                                               , "&p=", page)) 
  this_req_unnested <- unnest_it(this_request)
  full_request <- bind_rows(full_request, this_req_unnested[["data"]])
}







