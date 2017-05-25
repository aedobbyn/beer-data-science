# munge

source("./get_beer.R")

all_beer_unnested <- str(all_beer$data)


# write a function that essentially does this
# all_beer$data$glass <- all_beer$data$glass$name
# for all columns that are nested

# this takes the column named "name" nested within a column in the data portion of the response
# if the "name" column doesn't exist, it takes the first nested column

# this function written before ingredients were requested in url and flatten = TRUE was inluded in fromJSON
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

unnested_beer <- unnest_it(all_beer)
head(unnested_beer[["data"]])

unnested_breweries <- unnest_it(all_breweries)
head(unnested_breweries[["data"]])

unnested_glassware <- unnest_it(all_glassware)
head(unnested_glassware[["data"]])

all_beer <- unnest_it(all_beer)



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


all_beer <- unnest_ingredients(all_beer_raw)




# keep only columns we care about
all_beer <- all_beer %>% 
  rename(
    glass = glass.name,
    srm = srm.name,
    style = style.name
  ) %>% select(
    id, name, description, abv, ibu, srm, glass, 
    hops_name, hops_id, malt_name, malt_id,
    glasswareId, styleId, style.categoryId
  )


