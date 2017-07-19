
library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Clustered Beer"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      selectInput("style_collapsed", "Collapsed Style:",
                  list("Blonde" = "Blonde", 
                       "Brown" = "Brown", 
                       "Double India Pale Ale" = "Double India Pale Ale",
                       "Red" = "Red",
                       "Stout" = "Stout")),
      
      selectInput("num_clusters", "Number of Clusters:", 
                  list("1" = "1",
                       "2" = "2",
                       "10" = "10"))
      
      # checkboxInput("show_centers", "Show style centers", FALSE)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("cluster_plot")
    )
  )
))
