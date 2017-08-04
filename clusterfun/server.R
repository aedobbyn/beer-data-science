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
  
  df_for_clustering <- reactive({ beer_totals %>%
      select(response_vars(), cluster_on()) %>%
      filter(
        abv < 20 & abv > 3    # Only keep beers with ABV between 3 and 20 and an IBU less than 200
      ) %>%
      filter(
        ibu < 200    
      ) %>% 
      na.omit() })
  
  df_preds <- reactive({ df_for_clustering() %>%
      select(cluster_on()) %>%
      scale() %>%
      as_tibble()
  })
  
  
  df_outcome <- reactive({ df_for_clustering() %>%
      select(response_vars()) %>%
      na.omit()
  })
  
  n_centers <- reactive({input$num_clusters})
  
  cluster_it <- function() {
    clustered_df_out <- reactive({ kmeans(x = df_preds(), centers = n_centers(), trace = FALSE) })
    
    clustered_df <- reactive({ as_tibble(data.frame(
      cluster_assignment = factor(clustered_df_out()$cluster),
      df_for_clustering())) })
    
  }
  
  # All data with all styles
  this_style_data_pre <- cluster_it()
  
  # Truncate total_hops and total_malt to ints
  integerize_ingredients <- function(df) {
    
    for (i in seq_along(names(df))) {
      if (names(df[, i]) %in% c("total_hops", "total_malt")) {
        # df[, i] <- df[, i] %>% unlist() %>% round(digits = 0)
        df[, i] <- df[, i] %>% unlist() %>%  round(digits = 0) %>% as.integer()
        
      }
    }
    return(df)
  }
  
  
  # this_style_data_raw <- cluster_it()
  # 
  # observeEvent(input$filter_outliers, {
  #   this_style_data_pre <- this_style_data_raw() %>% 
  #     filter(
  #       abv < 20 & abv > 3    # Only keep beers with ABV between 3 and 20 and an IBU less than 200
  #     ) %>%
  #     filter(
  #       ibu < 200    
  #     )
  # })
  
  
  # Pared to a single style
  this_style_data <- reactive({ this_style_data_pre() %>% filter(style_collapsed == input$style_collapsed) })


  # not currently behaving as desired 
  rename_cols <- function(df) {
    
    orig_names <- c("cluster_assignment", "style_collapsed", "style",
                    "abv", "ibu", "srm", "total_hops", "total_malt")
    
    new_names <- c("Cluster Assignment", "Collapsed Style", "Style",
                   "ABV", "IBU", "SRM", "Total N Hops", "Total N Malts")
    
    name_indices <- which(input$cluster_on %in% orig_names)
    
    names(df)[name_indices] <- new_names[name_indices]
    
    return(df)
  }


  
  this_style_data_pre_format <- reactive({ this_style_data_pre() %>% integerize_ingredients() })
  
  this_style_data_format <- reactive({ this_style_data() %>% integerize_ingredients() })
  
  
  
  output$cluster_plot <- renderPlot({
  
    # if our checkbox is checked saying we do want style centers, show them. else, don't.
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
  
  
  
  output$this_style_data <- renderTable({
    
    colnames = c("Cluster Assignment", "Collapsed Style", "Style",
                 "ABV", "IBU", "SRM", "Total N Hops", "Total N Malts") 
    
    if (input$show_all == TRUE) {
      this_style_data_pre_format() } else {
        this_style_data_format()
      }
  })
  
  
})
