

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Beer Explorer"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
       sliderInput("binwidth",
                   "Binwidth:",
                   min = 0.5,
                   max = 3,
                   value = 1)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("my_plot")
    )
  )
))
