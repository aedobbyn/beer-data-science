
library(shiny)

style_names <- levels(clustered_beer$style_collapsed)
names(style_names) <- levels(clustered_beer$style_collapsed)


# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  theme = shinytheme("spacelab"),
  
  titlePanel("Clustered Beer"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("style_collapsed", "Collapsed Style:",
                  style_names),
      
      numericInput("num_clusters", "Number of Clusters:", 4),
      
      checkboxInput("show_centers", "Show style centers", FALSE)
    ),
    
    mainPanel(
       plotOutput("cluster_plot"),
       
       tableOutput("this_style_data")
    )
  )
))
