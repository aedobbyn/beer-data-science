

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


# set types
beer_totals$style <- factor(beer_totals$style)
beer_totals$glass <- factor(beer_totals$glass)

beer_totals$ibu <- as.numeric(beer_totals$ibu)
beer_totals$srm <- as.numeric(beer_totals$srm)
beer_totals$abv <- as.numeric(beer_totals$abv)
beer_totals$total_hops <- as.numeric(beer_totals$total_hops)
beer_totals$total_malt <- as.numeric(beer_totals$total_malt)

beer_totals$style_collapsed <- factor(beer_totals$style_collapsed)

beer_totals$hops_name <- factor(beer_totals$hops_name)
beer_totals$malt_name <- factor(beer_totals$malt_name)



# response_vars <- c("name", "style", "style_collapsed")









