
library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  theme = shinytheme("spacelab"),
  
  titlePanel("Clustered Beer"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("style_collapsed", "Collapsed Style:",
                  list("Blonde" = "Blonde", 
                       "Brown" = "Brown", 
                       "Double India Pale Ale" = "Double India Pale Ale",
                       "Red" = "Red",
                       "Stout" = "Stout")),
      
      numericInput("num_clusters", "Number of Clusters:", 4)
      
      # checkboxInput("show_centers", "Show style centers", FALSE)
    ),
    
    mainPanel(
       plotOutput("cluster_plot"),
       
       tableOutput("this_style_data")
    )
  )
))
