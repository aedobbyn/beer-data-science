
# kmeans

# select only predictor and outcome columns, take out NAs, and scale the data
beer_for_clustering <- beer_dat %>% 
  select(style, styleId, abv, ibu, srm) %>% 
  na.omit()

# beer_for_clustering <- beer_for_clustering %>% scale(abv, ibu, srm)

# separate into predictors and outcomes and scale the predictors
beer_for_clustering_predictors <- beer_for_clustering %>% select(abv, ibu, srm) %>% scale()
beer_for_clustering_outcome <- beer_for_clustering %>% select(style, styleId)

set.seed(9)
clustered_beer_out <- kmeans(x = beer_for_clustering_predictors, centers = 5, trace = TRUE)

clustered_beer <- bind_cols(cluster_assignment = clustered_beer_out$cluster, 
                            beer_for_clustering_outcome, beer_for_clustering_predictors)
# clustered_beer_clusters <- clustered_beer_out$cluster

clustered_beer_plot <- ggplot(clustered_beer, aes())


