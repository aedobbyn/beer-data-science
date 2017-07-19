
library(shiny)

source("../cluster.R")




# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
    cluster_it <- function(df_preds, n_centers) {
    set.seed(9)
    clustered_df_out <- kmeans(x = df_preds$preds, centers = n_centers, trace = FALSE)
    
    clustered_df <- as_tibble(data.frame(
      cluster_assignment = factor(clustered_df_out$cluster),
      df_preds$outcome, df_preds$preds,
      df_preds$df_for_clustering %>% select(abv, ibu, srm)))
    
    return(clustered_df)
  }
  
  reactive ({ clustered_beer <- cluster_it(df_preds = cluster_prep, n_centers = input$num_clusters) })
  
  

  output$cluster_plot <- renderPlot({
    
    this_style_data <- clustered_beer %>% filter(style_collapsed == input$style_collapsed) 
    this_style_center <- style_centers %>% filter(style_collapsed == input$style_collapsed) 
    
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
    
  })
  
})
