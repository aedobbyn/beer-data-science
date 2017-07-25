
library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(rdrop2)
library(shiny)
library(shinythemes)

source("./cluster_prep.R")


# ------ Molly Idea ----
# It’d be fun if you could also look at individual beers (maybe with tooltips), 
# or maybe even search for particular beers. You could then report how close a particular beer
# is to the center of its cluster (i.e. how much of an IPA a particular IPA is).


# so that we don't have to name each of the styles inside selectInput with 
# something like (list("Blonde" = "Blonde", "Pale Ale" = "Pale Ale" ... ))
style_names <- levels(popular_beer_dat$style_collapsed)
names(style_names) <- levels(popular_beer_dat$style_collapsed)


keywords <- c("Lager", "Pale Ale", "India Pale Ale", "Double India Pale Ale", "India Pale Lager", "Hefeweizen", "Barrel-Aged","Wheat", "Pilsner", "Pilsener", "Amber", "Golden", "Blonde", "Brown", "Black", "Stout", "Porter", "Red", "Sour", "Kölsch", "Tripel", "Bitter", "Saison", "Strong Ale", "Barley Wine", "Dubbel", "Altbier")

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  theme = shinytheme("spacelab"),
  
  titlePanel("Clusterfun with Beer"),
  p("All beer data sourced from the BreweryDB API. To drill down into a certain style, uncheck the 'Show all styles'
  checkbox and choose a beer style from the dropdown. Rerun the algorithm using any number of cluster
  centers by changing the Number of Clusters."),
  br(),
  p("More info and code at "), a("https://github.com/aedobbyn/beer-data-science/blob/master/compile.md"),
  br(),
  br(),
  # p("Beers were collapsed into these styles using this function:"),
  # br(),
  # pre(renderText("../keywords.txt")),
  # br(),
  # br(),

 
  sidebarLayout(
    sidebarPanel(
      checkboxInput("show_all", "Show all styles", TRUE),
      
      numericInput("num_clusters", "Number of Clusters:", 4),
      
      checkboxInput("show_centers", "Show style centers", FALSE),
      
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
                         selected = c("name", "style", "style_collapsed")),
      
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
