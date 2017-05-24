
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




# ---------------- add in withIngredients

request_w_additions <- function(ep, addition) {
  this_request <- function() { fromJSON(paste0(base_url, "/", ep, "/", key_preface, key, addition)) }
  print(this_request)
  this_request
}

get_beers_w_ingredients <- request_w_additions("beers", "&withIngredients=Y")
beer_w_ingredients <- get_beers_w_ingredients()
str(beer_w_ingredients)




unnest_ingredients <- function(df) {
  unnested <- df
  for(col in seq_along(df[["data"]])) {
    if(! is.null(ncol(df[["data"]][[col]]))) {
      
      if (df[["data"]][col] == "ingredients") {
        unnested[["data"]][["hops_name"]] <- df[["data"]][["ingredients"]][[3]][["hops"]][["name"]]
        unnested[["data"]][["hops_id"]] <- df[["data"]][["ingredients"]][[3]][["hops"]][["id"]]
        
        unnested[["data"]][["malt_name"]] <- df[["data"]][["ingredients"]][[3]][["malt"]][["name"]]
        unnested[["data"]][["malt_id"]] <- df[["data"]][["ingredients"]][[3]][["malt"]][["id"]]
        
        # unnested[["data"]][["yeast_name"]] <- df[["data"]][["ingredients"]][["yeast"]][["name"]]
        # unnested[["data"]][["yeast_id"]] <- df[["data"]][["ingredients"]][["yeast"]][["id"]]
        
      } else if(! is.null(df[["data"]][[col]][["name"]])) {
        unnested[["data"]][[col]] <- df[["data"]][[col]][["name"]]
        
      } else {
        unnested[["data"]][[col]] <- df[["data"]][[col]][[1]]
      }
    }
  }
  unnested
}


beer_w_ingredients_unnested <- unnest_ingredients(beer_w_ingredients)


for (i in 1:length(baz$nutrients)) {
  for (j in 1:4) {
    # for (j in 1:nrow(nutrients)) {
    baz$nutrients[[i]]$gm[j] <- as.character(baz$nutrients[[i]]$gm[j])
    baz$nutrients[[i]]$value[j] <- as.character(baz$nutrients[[i]]$value[j])
  }
}

# --------- try to unnest just hops and malts

head(beer_w_ingredients[["data"]][["ingredients"]][["hops"]][[3]][["name"]])
head(beer_w_ingredients[["data"]][["ingredients"]][["malt"]][[3]][["name"]])


unnested <- beer_w_ingredients
unnested[["data"]]$hops_name <- "x"
for (row in 1:nrow(unnested[["data"]])) {
  unnested[["data"]]$hops_name <- unnested[["data"]][["ingredients"]][[row]][["hops"]][["name"]]
  # unnested[["data"]][["hops_id"]] <- unnested[["data"]][["ingredients"]][[row]][["hops"]][["id"]]
}


unnested[["data"]][["malt_name"]] <- df[["data"]][["ingredients"]][[3]][["malt"]][["name"]]
unnested[["data"]][["malt_id"]] <- df[["data"]][["ingredients"]][[3]][["malt"]][["id"]]



############################







srms <- beer_dat %>% 
  group_by(srm) %>% 
  count() %>% 
  arrange(desc(srm))
srms


# turn page into a while loop

paginated_request <- function(ep) {
  full_request <- NULL
  first_page <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                , "&p=1"))
  number_of_pages <- first_page$numberOfPages
  for (page in 1263:number_of_pages) {    ############ use a while loop instead
    this_request <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                    , "&p=", page)) 
    this_req_unnested <- unnest_it(this_request)
    print(this_req_unnested$currentPage)
    full_request <- bind_rows(full_request, this_req_unnested[["data"]])
  }
  full_request
} 

test_all_beer <- paginated_request("beers")










