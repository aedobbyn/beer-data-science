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
  
<<<<<<< HEAD
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
    
    
=======
    df_for_clustering <- reactive({ beer_totals %>%
      select(response_vars(), cluster_on()) %>%
        filter(
          abv < 20 & abv > 3    # Only keep beers with ABV between 3 and 20 and an IBU less than 200
        ) %>%
        filter(
          ibu < 200    
        ) %>% 
      na.omit() })
    
    # if (abv %in% cluster_on()) {
    #   df_for_clustering <- df_for_clustering %>%
    #     filter(
    #       abv < 20 & abv > 3    # Only keep beers with ABV between 3 and 20 and an IBU less than 200
    #     )
    # }
    # 
    # if (ibu %in% cluster_on()) {
    #   df_for_clustering <- df_for_clustering %>%
    #     filter(
    #       ibu < 200
    #     )
    # }
>>>>>>> dev
    
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
  
<<<<<<< HEAD
    
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
    
    
=======
  
  this_style_data_pre <- cluster_it()
  
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
  
  this_style_data <- reactive({ this_style_data_pre() %>% filter(style_collapsed == input$style_collapsed) })
  
  
  
  
  # reactive({
  #   this_style_data <- ifelse(input$show_all == FALSE, this_style_data_pre() %>%
  #                       filter(style_collapsed == input$style_collapsed), 
  #                              this_style_data_pre())
  # })
  
  
  # reactive({ if (input$show_all == FALSE) {
  #     # this_style_data_pre <- cluster_it(input$num_clusters)
  #     this_style_data <- this_style_data_pre() %>%
  #       filter(style_collapsed == input$style_collapsed) 
  # 
  #     # this_style_center <- reactive({ style_centers %>% filter(style_collapsed == input$style_collapsed) })
  # 
  #   } else {
  #     this_style_data <- this_style_data_pre()
  # 
  #     # this_style_center <- style_centers
  #   }
  # })

  output$cluster_plot <- renderPlot({
>>>>>>> dev
    
    
  # 
  # 
  #   # cluster the data with a number of centers specified by the user and filter to just the style
  #   # specified
  # 
  #   if (input$show_all == FALSE) {
  #     this_style_data_pre <- cluster_it(n_centers = input$num_clusters) 
  #     this_style_data <- this_style_data_pre() %>%
  #       filter(style_collapsed == input$style_collapsed)
  # 
  #     this_style_center <- style_centers %>% filter(style_collapsed == input$style_collapsed)
  # 
  #   } else {
  #     this_style_data <- cluster_it(n_centers = input$num_clusters)
  # 
  #     this_style_center <- style_centers
  #   }
  # 
  # 
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
    
    if (input$show_all == TRUE) {
    this_style_data_pre() } else {
      this_style_data()
    }
  })

  
})
