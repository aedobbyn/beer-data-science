# if need to close some connections
# lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(rdrop2)
library(shiny)
library(shinythemes)
library(Hmisc)


source("./cluster_prep.R")
source("./capitalize_this.R")
source("./integerize_ingredients.R")


shinyServer(function(input, output) {
  
  # ------------------------------ Munge -----------------------------
  
  # Grab user-defined variables to cluster on, response variables, and number of clusters
  cluster_on <- reactive({input$cluster_on})
  response_vars <- reactive({input$response_vars})
  n_centers <- reactive({input$num_clusters})
  
  # Create a dataframe from beer_totals and omit everything with an NA in either cluster_on columns
  # or response_var columns. 
  df_for_clustering <- reactive({ beer_totals %>%
      select(response_vars(), cluster_on()) %>%
      filter(
        abv < 20 & abv > 3    # Only keep beers with ABV between 3 and 20 and an IBU less than 200
      ) %>%
      filter(
        ibu < 200    
      ) %>% 
      na.omit() })
  
  # Get a dataframe of only the predictors and scale
  df_preds <- reactive({ df_for_clustering() %>%
      select(cluster_on()) %>%
      scale() 
  })
  
  # Split out the response variables 
  df_outcome <- reactive({ df_for_clustering() %>%
      select(response_vars())
  })
  
  # ------------------------------ Cluster -----------------------------
  
  # Function for doing the clustering on the scaled predictors with number of centers defined by user
  # Glue the cluster assignments to the original df_for_clustering 
  cluster_it <- function() {
    clustered_df_out <- reactive({ kmeans(x = df_preds(), centers = n_centers(), trace = FALSE) })
    
    clustered_df <- reactive({ as_tibble(data.frame(
      cluster_assignment = factor(clustered_df_out()$cluster),
      df_for_clustering())) })
    
  }
  
  # Get a clustered dataframe with all styles
  this_style_data_pre <- cluster_it()
  
  # If user decides to filter to a single style, pare it down to just that style
  this_style_data <- reactive({ this_style_data_pre() %>% filter(style_collapsed == input$style_collapsed) })
  
  # Format correctly
  # These functions sourced in above
  this_style_data_pre_format <- reactive({ this_style_data_pre() %>% integerize_ingredients() %>% capitalize_this() })
  this_style_data_format <- reactive({ this_style_data() %>% integerize_ingredients() %>% capitalize_this() })
  
  
  # ------------------------------ Plot -----------------------------

  # Create the plot
  # Account for all eventualities 
  output$cluster_plot <- renderPlot({
  
    # If our checkbox is checked saying we do want style centers, show them. Else, don't.
    if (input$show_centers == TRUE & input$show_all == FALSE) {
      
      this_style_center <- reactive({style_centers %>% filter(style_collapsed == input$style_collapsed)})
      
      ggplot() +
        geom_point(data = this_style_data(),
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        geom_point(data = this_style_center(),
                   aes(mean_abv, mean_ibu), colour = "black") +
        geom_text_repel(data = this_style_center(),
                        aes(mean_abv, mean_ibu, label = input$style_collapsed),
                        box.padding = unit(0.45, "lines"),
                        family = "Calibri") +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal()
    } else if (input$show_centers == TRUE & input$show_all == TRUE) {
      
      ggplot() +
        geom_point(data = this_style_data_pre(),
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        geom_point(data = style_centers,
                   aes(mean_abv, mean_ibu), colour = "black") +
        geom_text_repel(data = style_centers,
                        aes(mean_abv, mean_ibu, label = style_collapsed),
                        box.padding = unit(0.45, "lines"),
                        family = "Calibri") +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal()
    } else if (input$show_centers == FALSE & input$show_all == TRUE) {
      
      this_style_center <- reactive({style_centers %>% filter(style_collapsed == input$style_collapsed)})
      
      ggplot() +
        geom_point(data = this_style_data_pre(),
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal()
    } else {
      
      this_style_center <- reactive({style_centers %>% filter(style_collapsed == input$style_collapsed)})
      
      ggplot() +
        geom_point(data = this_style_data(),
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal()
    }
    
  })
  
  # Get a table of data
  output$this_style_data <- renderTable({
    
    colnames = c("Cluster Assignment", "Collapsed Style", "Style",
                 "ABV", "IBU", "SRM", "Total N Hops", "Total N Malts") 
    
    if (input$show_all == TRUE) {
      this_style_data_pre_format() } else {
        this_style_data_format()
      }
  })
  
})
