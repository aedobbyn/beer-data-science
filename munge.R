# munge

source("./get_beer.R")

all_beer_unnested <- str(all_beer$data)



all_beer$data$glass <- all_beer$data$glass$id

unnested_beer <- all_beer

unnest_beer <- function() {
  for(col in seq_along(all_beer$data)) {
    if(! is.null(ncol(all_beer[["data"]][[col]]))) {
      print(all_beer[["data"]][[col]][["name"]])
      unnested_beer[["data"]][[col]] <- all_beer[["data"]][[col]][["name"]]
    }
  }
  unnested_beer
}

unnested <- unnest_beer()
head(unnested[["data"]])






unnest_beer <- function() {
  # unnested_beer <- all_beer
  # for(col in all_beer$data) {
  #   # print(col)
    # print(names(all_beer$data[col]))
    if(! is.null(ncol(all_beer[["data"]][[]]))) {
      # print(ncol(all_beer$data[[col]]))
      print(all_beer[["data"]][[col]]$name)
      # print(all_beer[["data"]][[col]][1])
      unnested_beer[["data"]][[col]] <- all_beer[["data"]][[col]]$name
    }
    # print(ncol(all_beer$data[col]))
  }
  unnested_beer
}

unnested <- unnest_beer()
unnested

