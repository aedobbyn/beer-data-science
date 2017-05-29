# munge

# source("./get_beer.R")


# write a function that essentially does this
# all_beer$data$glass <- all_beer$data$glass$name
# for all columns that are nested

# this takes the column named "name" nested within a column in the data portion of the response
# if the "name" column doesn't exist, it takes the first nested column

# ~ ~ this function used inside paginated_request()
unnest_it <- function(df) {
  unnested <- df
  for(col in seq_along(df[["data"]])) {
    if(! is.null(ncol(df[["data"]][[col]]))) {
      if(! is.null(df[["data"]][[col]][["name"]])) {
        unnested[["data"]][[col]] <- df[["data"]][[col]][["name"]]
      } else {
        unnested[["data"]][[col]] <- df[["data"]][[col]][[1]]
      }
    }
  }
  unnested
}


# ------------ unnest ingredients ---------
# this df has to come from a request with &withIngredients=Y attached, and with flatten = TRUE included in the fromJSON function

# if either the name in ingredients.hops or malt is available, we know id is also available
# add a new column that extracts the name out of the list_col and saves it in that new column. if there are multiple
# hop names, they're separated by commas

unnest_ingredients <- function(df) {
  df$hops_name <- NA
  df$hops_id <- NA
  df$malt_name <- NA
  df$malt_id <- NA
  
  for (row in 1:nrow(df)) {
    if (!is.null(df[["ingredients.hops"]][[row]][["name"]]) | 
        !is.null(df[["ingredients.malt"]][[row]][["name"]])) {
      
      df[["hops_name"]][[row]] <- paste(df[["ingredients.hops"]][[row]][["name"]],
                                                        collapse = ", ")
      df[["hops_id"]][[row]] <- paste(df[["ingredients.hops"]][[row]][["id"]],
                                                      collapse = ", ")
      
      df[["malt_name"]][[row]] <- paste(df[["ingredients.malt"]][[row]][["name"]],
                                                        collapse = ", ")
      df[["malt_id"]][[row]] <- paste(df[["ingredients.malt"]][[row]][["id"]],
                                                      collapse = ", ")
    }
  }
  return(df)
}




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

# beer_w_ingredients_unnested <- unnest_just_ingredients(beer_w_ingredients)

