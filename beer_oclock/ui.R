

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
                   value = 1),
       
       checkboxGroupInput("cluster_on", "Choose variables to cluster on: ",
                          c("ABV (alcohol)" = "abv", 
                            "IBU (bitterness)" = "ibu", 
                            "SRM (color)" ="srm", 
                            "Total number of hops" = "total_hops", 
                            "Total number of malts" = "total_malt"),
                          selected = c("abv", "ibu", "srm")),
       
       checkboxGroupInput("response_vars", "Choose response variable(s): ",
                          c("Name" = "name",
                            "Style" = "style",
                            "Collapsed style" = "style_collapsed"),
                          selected = c("name", "style", "style_collapsed"))
    ),
    
    
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("my_plot"),
       textOutput("text")
    )
  )
))
