
library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(rdrop2)
library(shiny)
library(shinythemes)

beer_totals <- read_csv("./data/beer_totals.csv")
style_centers <- read_csv("./data/style_centers.csv")
popular_beer_dat <- read_csv("./data/popular_beer_dat.csv")


# so that we don't have to name each of the styles inside selectInput with 
# something like (list("Blonde" = "Blonde", "Pale Ale" = "Pale Ale" ... ))
style_names <- levels(popular_beer_dat$style_collapsed)
names(style_names) <- levels(popular_beer_dat$style_collapsed)


keywords <- c("Lager", "Pale Ale", "India Pale Ale", "Double India Pale Ale", "India Pale Lager", "Hefeweizen", "Barrel-Aged","Wheat", "Pilsner", "Pilsener", "Amber", "Golden", "Blonde", "Brown", "Black", "Stout", "Porter", "Red", "Sour", "Kölsch", "Tripel", "Bitter", "Saison", "Strong Ale", "Barley Wine", "Dubbel", "Altbier")

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  theme = shinytheme("spacelab"),
  
  titlePanel("Clusterfun with Beer"),
  p("Beers from the BreweryDB API. To drill down into a certain style, uncheck the 'Show all styles'
  checkbox and choose a beer style from the dropdown. Rerun the algorithm using any number of cluster
  centers by changing the Number of Clusters."),
  br(),
  # p("Beers were collapsed into these styles using this function:"),
  # br(),
  # pre(renderText("../keywords.txt")),
  # br(),
  # br(),

 
  sidebarLayout(
    sidebarPanel(
      checkboxInput("show_all", "Show all styles", FALSE),
      
      numericInput("num_clusters", "Number of Clusters:", 4),
      
      checkboxInput("show_centers", "Show style centers", FALSE),
      
      conditionalPanel(
        condition = "input.show_all == false",
        selectInput("style_collapsed", "Collapsed Style:",
                    style_names)
      )
      
      
    ),
    
    mainPanel(
       plotOutput("cluster_plot"),
       
       tableOutput("this_style_data")
    )
  )
))
