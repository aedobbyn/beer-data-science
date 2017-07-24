

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


# factorize_ingredients <- function(df) {
#   for(col_name in names(df)) {
#     if (grepl(("hops_name_|malt_name_|style|glass"), col_name) == TRUE) {
#       df[[col_name]] <- factor(df[[col_name]])
#     }
#   }
#   return(df)
# }
# 
# beer_totals <- factorize_ingredients(beer_totals)





prep_clusters <- function(df, preds, to_scale, resp) {
  df_for_clustering <- df %>%
    select_(.dots = c(response_vars, cluster_on)) %>%
    na.omit() %>%
    filter(
      abv < 20 & abv > 3    # Only keep beers with ABV between 3 and 20 and an IBU less than 200
    ) %>%
    filter(
      ibu < 200    
    )
  
  df_all_preds <- df_for_clustering %>%
    select_(.dots = preds)
  
  df_preds_scale <- df_all_preds %>%
    select_(.dots = to_scale) %>%
    rename(
      abv_scaled = abv,
      ibu_scaled = ibu,
      srm_scaled = srm
    ) %>%
    scale() %>%
    as_tibble()
  
  df_preds <- bind_cols(df_preds_scale, df_all_preds[, (!names(df_all_preds) %in% to_scale)])
  
  df_outcome <- df_for_clustering %>%
    select_(.dots = resp) %>%
    na.omit()
  
  cluster_prep_out <- list(df_for_clustering = df_for_clustering, preds = df_preds, outcome = df_outcome)
  
  return(cluster_prep_out)
}

cluster_on <- c("abv", "ibu", "srm", "total_hops", "total_malt")
to_scale <- c("abv", "ibu", "srm", "total_hops", "total_malt")
response_vars <- c("name", "style", "style_collapsed")

cluster_prep <- prep_clusters(df = beer_totals,
                              preds = cluster_on,
                              to_scale = to_scale,
                              resp = response_vars)






