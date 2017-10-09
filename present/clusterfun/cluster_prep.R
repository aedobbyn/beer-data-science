

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

set_col_types <- function(df) {
  for(col_name in names(df)) {
    if (grepl(("hops_name|malt_name|style|glass"), col_name) == TRUE) {
      df[[col_name]] <- factor(df[[col_name]])
    } else if (grepl(("abv|ibu|srm|total"), col_name) == TRUE) {
      df[[col_name]] <- as.numeric(df[[col_name]])
    }
    df <- as_tibble(df)
  }
  return(df)
}


# Set types 
style_centers <- set_col_types(style_centers)
popular_beer_dat <- set_col_types(popular_beer_dat)
beer_totals <- set_col_types(beer_totals)








