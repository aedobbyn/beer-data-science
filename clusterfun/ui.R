
library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(rdrop2)
library(shiny)
library(shinythemes)

source("./cluster_prep.R")
source("./keywords.txt")

starting_n_clusters <- 5



# so that we don't have to name each of the styles inside selectInput with 
# something like (list("Blonde" = "Blonde", "Pale Ale" = "Pale Ale" ... ))
style_names <- levels(popular_beer_dat$style_collapsed)
names(style_names) <- levels(popular_beer_dat$style_collapsed)

shinyUI(fluidPage(
  
  theme = shinytheme("spacelab"),
  
  titlePanel("Cluster in Style"),
  p("This tool was developed to explore how closely natural clusters in beer (as determined by 
    measures like ABV and IBU) match up with those beers' styles. In other words, how well do style boundaries
mirror the objective qualities of beers?"),
  
  p('The graph below depicts the results of running an unsupervised k-means clustering algorithm on 
beers based on the variables selected below.'),
  
  br(),
  
  h5("How to work the controls:"),
  
  tags$ul(
    tags$li('You can see how well styles match up to clusters by checking 
"Show style centers"; the label will show you where the typical beer in a certain style sits.'),
  
    tags$li('To filter the graph down to a certain style and see whether most of the beers in that style fall 
  into a certain cluster, uncheck the "Show all styles"
  checkbox and choose a beer style from the dropdown. (Note that this does not re-run the algorithm on 
    a new dataset of just the beers in that style -- it always clusters on all beers.)'),
  
    tags$li("We've started off with", starting_n_clusters, "clusters, but you can rerun the algorithm using any number of clusters
by changing the Number of Clusters.")
  
  ), 
  br(),
  p(strong("Only rules are that you must cluster on at least ABV and IBU (because that's what we're graphing); 
           the only required outcome variable is collapsed style.")),
  
  br(),  br(),

  p("All beer data sourced from the", a(href = "http://www.brewerydb.com/developers", "BreweryDB API."), "For more 
    info and code, see: ", a(href = "https://github.com/aedobbyn/beer-data-science/blob/master/compile.md", 
                                       "the full report.")),
  br(),
  br(),
  br(),
  
  
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
        
        # actionButton("filter_outliers", "Remove Outliers")
      )
      
      
    ),
    
    mainPanel(

       plotOutput("cluster_plot"),
       
       br(), br(),
       br(), br(),
       br(),
       hr(),
       h2("Data"),
       
       tableOutput("this_style_data")
       
    )
  )
  ))
