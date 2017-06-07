
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
unnested[["data"]]$hops_name <- "Not available"
unnested[["data"]]$hops_id <- "Not available"
unnested[["data"]]$malt_name <- "Not available"
unnested[["data"]]$malt_id <- "Not available"

for (row in 1:nrow(unnested[["data"]])) {
  if (!is.null(unnested[["data"]][["ingredients.hops"]][[row]][["name"]]) | 
      !is.null(unnested[["data"]][["ingredients.malt"]][[row]][["name"]])) {
    unnested[["data"]][["hops_name"]][[row]] <- paste(unnested[["data"]][["ingredients.hops"]][[row]][["name"]],
                                                      collapse = ", ")
    unnested[["data"]][["hops_id"]][[row]] <- paste(unnested[["data"]][["ingredients.hops"]][[row]][["id"]],
                                                      collapse = ", ")
    
    unnested[["data"]][["malt_name"]][[row]] <- paste(unnested[["data"]][["ingredients.malt"]][[row]][["name"]],
                                                      collapse = ", ")
    unnested[["data"]][["malt_id"]][[row]] <- paste(unnested[["data"]][["ingredients.malt"]][[row]][["id"]],
                                                      collapse = ", ")
  }
  # unnested[["data"]][["hops_id"]] <- unnested[["data"]][["ingredients"]][[row]][["hops"]][["id"]]
}
View(unnested$data)


unnested[["data"]][["malt_name"]] <- df[["data"]][["ingredients"]][[3]][["malt"]][["name"]]
unnested[["data"]][["malt_id"]] <- df[["data"]][["ingredients"]][[3]][["malt"]][["id"]]



############################


# unnesting w unnest doesn't do much

fully_unnested <- unnest(beer_w_ingredients$data$ingredients.hops)

fully_unnested <- flatten(beer_w_ingredients$data)
str(fully_unnested)





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







to_name <- c("a", "b", "c")

my_f <- function() {
  all_names <- list()
  
  for (i in to_name) {
    this_key <- paste0("key_", i)

    this_value <- paste0("value_", i)

    assign(this_key, this_value, envir = .GlobalEnv)

    all_names <- c(all_names, this_key)
  }
  return(all_names)
}

my_f()




simple_request_funcs <- function() {
  all_funcs <- list()
  
  for (ep in single_param_endpoints) {
    this_name <- paste0("get_", ep)
    
    this_func <- (function(id) { 
      fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
    })
    
    out <- assign(this_name, this_func, envir = .GlobalEnv) 
    
    all_funcs <- c(all_funcs, out)
    
  }
  all_funcs
}

simple_request_funcs()

get_beer("HZ9xM2")




simple_request_funcs <- function() {
  all_funcs <- list()
  
  for (ep in single_param_endpoints) {
    func_ <- function(id, ep) {
        fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
      }
    
    all_funcs <- c(all_funcs, func_)
  }
  all_funcs
}

simple_request_funcs()

func_beer <- partial(func_, ep = "beer")
func_beer("HZ9xM2")












to_name <- c("a", "b", "c")

create_funcs <- function() {
  all_funcs <- list()
  
  for (name in to_name) {
    this_key <- paste0("func_", name)
    
    this_value <<- function(x) { 
      paste0("key_name:  ", name, " -----  value_x: ", x)
    }
    assign(this_key, this_value, envir = .GlobalEnv) 
    
    all_funcs <- c(all_funcs, this_key)
  }
  return(all_funcs)
}

create_funcs()

func_a("foo")  # key_name:  c -----  value_x: foo
func_b("bar")  # key_name:  c -----  value_x: bar





create_objects <- function() {
  all_objs <- list()
  
  for (name in to_name) {
    this_key <- paste0("key_", name)
    
    this_value <- paste0("value_", name)
    
    assign(this_key, this_value, envir = .GlobalEnv)
    
    all_objs <- c(all_objs, this_key)
  }
  return(all_objs)
}

create_objects()

key_a  # value_a
key_b  # value_b
key_c  # value_c












to_name <- c("a", "b", "c")

func_ <- function(x, key_name) {
  paste0("key_name:  ", key_name, " -----  value_x: ", x)
}

func_a <- partial(func_, key_name = "a")

create_funcs <- function() {
  all_funcs <- list()
  
  for (name in to_name) {
    
    func_ <- function(x) { 
      paste0("key_name:  ", name, " -----  value_x: ", x)
    }
    
    all_funcs <- c(all_funcs, partial(func_, name = name, envir = .GlobalEnv))
  }
  return(all_funcs)
}

create_funcs()

func_a("foo")  # key_name:  c -----  value_x: foo
func_b("bar")  # key_name:  c -----  value_x: bar








# ---------- db updates -------------

# ------ working on insert statement -------
test <- data.frame(list(test = c(rep("baz", 1))))
test_2 <- data.frame(list(test = c(rep("bars", 14))))
test_4 <- data.frame(list(test_4 = c(rep("foo", 14))))

insert_query <- paste("INSERT INTO glassware (test_2) VALUES(", paste(test, collapse = ","), ")")
insert_query

test_one <- data.frame(list(test = "foo"))
insert_one_query <- paste("INSERT INTO glassware (test) VALUES(", test_one, ")")
insert_one_query


dbSendStatement(con, insert_query)
dbSendStatement(con, insert_one_query)


gware <- dbReadTable(con, "glassware")
gware


dbWriteTable(con, "glassware", test_3, append = TRUE, rownames = FALSE)



db_write_table(con, "all_glassware", test_2)


dbSendStatement(con, "ALTER TABLE glassware ADD test_4 TEXT")
dbWriteTable(con, "glassware", test_4, overwrite = TRUE, rownames = FALSE)






# -- this seems like the best solution but doesn't work
test_4 <- data.frame(list(test_4 = c(rep("bar", 14))))
update_query <- paste("UPDATE glassware SET test_4 = (", paste(test_4, collapse = ","), ")")
update_query
dbSendQuery(con, update_query)


# this works, though
update_query <- paste("UPDATE glassware SET test_4 = ", "\"foo\"")
update_query
dbSendQuery(con, update_query)



# this works, though
update_query <- paste("UPDATE glassware SET test_4 = ", "\"foo\"")
update_query
dbSendQuery(con, update_query)


update_query <- paste("UPDATE glassware SET test_4 = ", c("\"foo\", \"baz\""))
update_query
dbSendQuery(con, update_query)





names(beer_necessities)
head(beer_necessities$hops_id)


beer_nec_ingredients <- beer_necessities


library(stringr)


add_new_cols <- function(df) {
  ncol_df <- ncol(df)
  
  hops_split <- str_split(df[["hops_name"]], ", ")
  num_new_cols <- max(lengths(hops_split))
  # print(paste0("number new cols is: ", num_new_cols))
  
  new_col_names <- vector()
  
  for (num in 1:num_new_cols) {
    this_col <- ncol_df + 1
    
    df[, this_col] <- "foo"
    names(df)[this_col] <- paste0("hop_", num)
    # new_col_names <- c(new_col_names, names(df[, this_col]))
    # print(paste0("column names: ", new_col_names))
    ncol_df <- ncol(df)
  }
  
  # return(new_col_names)
  return(df)
}

add_new_cols(sbn)

sbn_added <- add_new_cols(sbn)
View(sbn_added)

names(sbn_added)[20] <- paste0("hop_", "4")


hops_split <- str_split(df[["hops_name"]], ", ")
num_new_cols <- max(lengths(hops_split))

split_sbn <- separate(data = sbn_added,
                      col = hops_name, into = setdiff(names(sbn_added), names(sbn)), sep = ", ")
View(split_sbn)






  
split_ingredients <- function(df) {
  ncol_df <- ncol(df)
  
  # df[, ncol_df + 1] <- NULL
  
  hops_split <- str_split(df[["hops_name"]], ", ")
  num_new_cols <- max(lengths(hops_split))
  
  new_col_names <- vector()
  
  for (num in num_new_cols) {
    df[, ncol_df + num] <- NULL
    names(df[, ncol_df + num]) <- paste0("hop_", num)
    new_col_names <- c(new_col_names, names(df[, ncol_df + num]))
  }
  new_cols <- names(df)
  
  split_sbn <- separate(data = df,
                        col = hops_name, into = c("hop_1", "hop_2", "hop_3", "hop_4"), sep = ", ")
  
  
  
  for (h in hops_split) {
    df[, ]
  }
}

sbn <- simple_beer_necessities

split_sbn <- do.call("rbind", str_split(sbn$hops_name, ", "))
split_sbn <- data.frame(apply(split_sbn, 2, as.character))







names(splitdat) = paste("trial", 1:4, sep = "")


hops_split <- str_split(simple_beer_necessities[100:105, ][["hops_name"]], ", ")

hops_split_unnest <- unnest(hops_split)

for (i in hops_split) {
  print(length(i))
}

max(length(hops_split[]))






# --- split hops out
split_sbn <- separate(data = simple_beer_necessities[100:105, ],
                      col = hops_name, into = c("hop_1", "hop_2", "hop_3", "hop_4"), sep = ", ")



# if need to fix duped names (second set gets .1 after the name), replace the .1 with nothing using
names(bn) <- str_replace_all(names(bn), "(\\.1)", "")


