# munge

source("./get_beer.R")

all_beer_unnested <- str(all_beer$data)


# write a function that essentially does this
# all_beer$data$glass <- all_beer$data$glass$name
# for all columns that are nested

# this takes the column named "name" nested within a column in the data portion of the response
# if the "name" column doesn't exist, it passes. should come up with a conditional so it take id if name doesn't exist or something
unnest_it <- function(df) {
  unnested <- df
  for(col in seq_along(df$data)) {
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

