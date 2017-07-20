
# lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)


library(shiny)
library(shinythemes)

source("../cluster.R")
# source("../most_popular_styles.R")


shinyServer(function(input, output) {
  

  output$cluster_plot <- renderPlot({
    
    cluster_it <- function(df_preds, n_centers) {
      set.seed(9)
      clustered_df_out <- kmeans(x = df_preds$preds, centers = n_centers, trace = FALSE)
      
      clustered_df <- as_tibble(data.frame(
        cluster_assignment = factor(clustered_df_out$cluster),
        df_preds$outcome, df_preds$preds,
        df_preds$df_for_clustering %>% select(abv, ibu, srm)))
      
      return(clustered_df)
    }
    
    this_style_data <- cluster_it(df_preds = cluster_prep, n_centers = input$num_clusters) %>%
      filter(style_collapsed == input$style_collapsed)
    
    this_style_center <- style_centers %>% filter(style_collapsed == input$style_collapsed) 
    
    if (input$show_centers == TRUE) {
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
