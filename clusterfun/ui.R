
library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(rdrop2)
library(shiny)
library(shinythemes)

source("./cluster_prep.R")
source("./keywords.txt")

# Specify starting number of clusters
starting_n_clusters <- 5


# For a list of styles to display in the dropdown, use all style_collapsed levels from popular_beer_dat
# This so that we don't have to name each of the styles inside selectInput with 
# something like (list("Blonde" = "Blonde", "Pale Ale" = "Pale Ale" ... ))
style_names <- levels(popular_beer_dat$style_collapsed)
names(style_names) <- levels(popular_beer_dat$style_collapsed)


# Build the page
shinyUI(fluidPage(
  
  theme = shinytheme("spacelab"),
  
  titlePanel("Beer Exploration in Style"),
  
  fluidRow(
      column(width = 12,
             br(),
             p("This tool was developed to visualize how well natural clusters in beer match up with beer style boundaries."),
             
             p('The graph below depicts the results of running an unsupervised k-means clustering algorithm on 
                 beers based on the variables selected below.'),
             
             p(strong("Only rules are that you must cluster on at least ABV and IBU; 
                        the only required outcome variable is collapsed style.")),
             
             br(),  
             
             p("All beer data sourced from the", a(href = "http://www.brewerydb.com/developers", "BreweryDB API."), "For more 
                 info and code, see: ", a(href = "https://github.com/aedobbyn/beer-data-science/blob/master/compile.md", 
                                          "the full report.")),
             br()
      )
  ),
  
  sidebarLayout(
    sidebarPanel(
      h4("Control Panel"),

      checkboxInput("show_all", "Show all styles", TRUE),      
      
      checkboxInput("show_centers", "Show style centers", FALSE),
      
      numericInput("num_clusters", "Number of Clusters:", starting_n_clusters),
      
      checkboxGroupInput("cluster_on", "Choose variables to cluster on: ",
                         c("ABV (alcohol)" = "abv", 
                           "IBU (bitterness)" = "ibu", 
                           "SRM (color)" ="srm", 
                           "Total number of hops" = "total_hops", 
                           "Total number of malts" = "total_malt"),
                         selected = c("abv", "ibu", "srm")),
      
      checkboxGroupInput("response_vars", "Choose response variable(s): ",
                         c("Collapsed style" = "style_collapsed",
                           "Specific style" = "style",
                           "Name" = "name"
                         ),
                         selected = c("style", "style_collapsed")),
      
      conditionalPanel(
        condition = "input.show_all == false",
        selectInput("style_collapsed", "Collapsed Style:",
                    style_names)
        
        )
    ),
    
    mainPanel(
       plotOutput("cluster_plot", width = "100%")
    )
  ),
  
  fluidRow(
    column(width = 12, 
           
           h5("How to work the controls"),
           
           tags$ul(
             
             tags$li('You can see how well styles match up to clusters by checking 
                     "Show style centers"; the label will show you where the typical beer in a certain style sits.'),
             
             tags$li('To filter the graph down to a certain style and see whether most of the beers in that style fall 
                     into a certain cluster, uncheck the "Show all styles"
                     checkbox and choose a beer style from the dropdown. (Note that this does not re-run the algorithm on 
                     a new dataset of just the beers in that style -- it always clusters on all beers.)'),
             
             tags$li("We've started off with", starting_n_clusters, "clusters, but you can rerun the algorithm using any number of clusters
                     by changing the Number of Clusters.")
             
             ) 
           )
         ),
  
  br(),
  br(),
  br(),
  
    fluidRow(
      column(width = 12, 
             
        hr(),
        
        h2("Data"),
        
        tableOutput("this_style_data")
      )
    )
  
  ))
