

library(tidyverse)

library(shiny)

source("../read_from_db.R")

want_styles <- beer_necessities %>% 
  group_by(style_collapsed) %>% 
  tally(., sort = TRUE) %>% 
  droplevels() %>% 
  filter(n > 1000)

to_plot <- beer_necessities[which(!is.na(beer_necessities$abv) & !is.na(beer_necessities$style_collapsed)), ] %>% 
  filter(style_collapsed %in% want_styles$style_collapsed) %>% 
  filter(abv < 30) %>% 
  droplevels()



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  cluster_on <- reactive({input$cluster_on})
  
  response_vars <- reactive({input$response_vars})
  
  foo <- reactive({ to_plot %>%
    select(response_vars(), cluster_on()) %>%
    na.omit() })
   
  output$my_plot <- renderPlot({
    
    this_binwidth <- input$binwidth
    
    ggplot(data = to_plot, aes(x = abv, fill = style_collapsed)) +
      geom_histogram(binwidth = this_binwidth)
    
  })
  
  output$text <- renderText({names(foo())})
  
  output$table <- renderTable({foo()})
  
})


