

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(rdrop2)
library(shiny)
library(shinythemes)

beer_totals <- read_csv("./data/beer_totals.csv")
style_centers <- read_csv("./data/style_centers.csv")
popular_beer_dat <- read_csv("./data/popular_beer_dat.csv")

factorize_cols <- function(df) {
  for(col_name in names(df)) {
    if (grepl(("hops_name_|malt_name_|style|glass"), col_name) == TRUE) {
      df[[col_name]] <- factor(df[[col_name]])
    } else if (grepl(("abv|ibu|srm|total"), col_name) == TRUE) {
      df[[col_name]] <- as.numeric(df[[col_name]])
    }
    df <- as_tibble(df)
  }
  return(df)
}

style_centers <- factorize_cols(style_centers)
popular_beer_dat <- factorize_cols(popular_beer_dat)
beer_totals <- factorize_cols(beer_totals)



# response_vars <- c("name", "style", "style_collapsed")










