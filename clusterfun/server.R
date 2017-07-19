
library(shiny)

source("../cluster.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
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
