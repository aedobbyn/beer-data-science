# if need to close some connections
# lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(rdrop2)
library(shiny)
library(shinythemes)


source("./cluster_prep.R")



shinyServer(function(input, output) {
  
  cluster_on <- reactive({input$cluster_on})
  
  response_vars <- reactive({input$response_vars})
  
  prep_clusters <- reactive({ function(df, preds, to_scale, resp) {
    df_for_clustering <- df %>%
      select_(.dots = c(resp, preds)) %>%
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
        ibu_scaled = ibu
        # srm_scaled = srm
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
  })
  
  cluster_prep <- prep_clusters(df = beer_totals,
                                preds = cluster_on(),
                                to_scale = cluster_on(),
                                resp = response_vars())
  
  
  
  output$cluster_plot <- renderPlot({
    
    
    
    
    # cluster data prepared in cluster.R
    # our same clustering function
    cluster_it <- function(df_preds, n_centers) {
      clustered_df_out <- kmeans(x = df_preds$preds, centers = n_centers, trace = FALSE)
      
      clustered_df <- as_tibble(data.frame(
        cluster_assignment = factor(clustered_df_out$cluster),
        df_preds$outcome, df_preds$preds,
        df_preds$df_for_clustering %>% select(cluster_on())))
      
      return(clustered_df)
    }
  
    
    # cluster the data with a number of centers specified by the user and filter to just the style
    # specified
    
    if (input$show_all == FALSE) {
      this_style_data <- cluster_it(df_preds = cluster_prep, n_centers = input$num_clusters) %>%
        filter(style_collapsed == input$style_collapsed)
      this_style_center <- style_centers %>% filter(style_collapsed == input$style_collapsed)
    } else {
      this_style_data <- cluster_it(df_preds = cluster_prep, n_centers = input$num_clusters)
      this_style_center <- style_centers 
    }
    
    
    
    
    # if our checkbox is checked saying we do want style centers, show them. else, don't.
    if (input$show_centers == TRUE & input$show_all == FALSE) {
      ggplot() +   
        geom_point(data = this_style_data,
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        geom_point(data = this_style_center,
                   aes(mean_abv, mean_ibu), colour = "black") +
        geom_text_repel(data = this_style_center,
                        aes(mean_abv, mean_ibu, label = input$style_collapsed),
                        box.padding = unit(0.45, "lines"),
                        family = "Calibri") +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal() 
    } else if (input$show_centers == TRUE & input$show_all == TRUE) {
      ggplot() +   
        geom_point(data = this_style_data,
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        geom_point(data = style_centers,
                   aes(mean_abv, mean_ibu), colour = "black") +
        geom_text_repel(data = this_style_center,
                        aes(mean_abv, mean_ibu, label = style_collapsed),
                        box.padding = unit(0.45, "lines"),
                        family = "Calibri") +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal()
    } else {
      ggplot() +   
        geom_point(data = this_style_data,
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal() 
    }
    
    
    
  })
  
})
