

source("../most_popular_styles.R")
source("../cluster.R")

library(shiny)

# so that we don't have to name each of the styles inside selectInput with 
# something like (list("Blonde" = "Blonde", "Pale Ale" = "Pale Ale" ... ))
style_names <- levels(popular_beer_dat$style_collapsed)
names(style_names) <- levels(popular_beer_dat$style_collapsed)


# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  theme = shinytheme("spacelab"),
  
  titlePanel("Clustered Beer"),
  p("Choose the beer style you'd like to see and the number of clusters you "),
  
  sidebarLayout(
    sidebarPanel(
      checkboxInput("show_all", "Show all styles", TRUE),
      
      numericInput("num_clusters", "Number of Clusters:", 4),
      
      
      
      conditionalPanel(
        condition = "input.show_all == false",
        selectInput("style_collapsed", "Collapsed Style:",
                    style_names)
      ),
      
      checkboxInput("show_centers", "Show style centers", FALSE)
    ),
    
    mainPanel(
       plotOutput("cluster_plot"),
       
       tableOutput("this_style_data")
    )
  )
))
