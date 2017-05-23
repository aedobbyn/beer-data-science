
# kmeans

# select only predictor and outcome columns, take out NAs, and scale the data
beer_for_clustering <- beer_dat %>% 
  select(style, styleId, abv, ibu, srm) %>% 
  na.omit() %>% 
  filter(
    !(ibu > 300)     # take out the outlier with ibu of 1000
  )

# beer_for_clustering <- beer_for_clustering %>% scale(abv, ibu, srm)

# separate into predictors and outcomes and scale the predictors
beer_for_clustering_predictors <- beer_for_clustering %>% select(abv, ibu, srm) %>% scale()
beer_for_clustering_outcome <- beer_for_clustering %>% select(style, styleId)

set.seed(9)
clustered_beer_out <- kmeans(x = beer_for_clustering_predictors, centers = 3, trace = TRUE)

clustered_beer <- as_tibble(data.frame(cluster_assignment = factor(clustered_beer_out$cluster), 
                            beer_for_clustering_outcome, beer_for_clustering_predictors))
# clustered_beer_clusters <- clustered_beer_out$cluster


# the three combinations of plots
clustered_beer_plot_abv_ibu <- ggplot(data = clustered_beer, aes(x = abv, y = ibu, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "IBU") 
clustered_beer_plot_abv_ibu

clustered_beer_plot_abv_srm <- ggplot(data = clustered_beer, aes(x = abv, y = srm, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "SRM") 
clustered_beer_plot_abv_srm

clustered_beer_plot_ibu_srm <- ggplot(data = clustered_beer, aes(x = ibu, y = srm, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "IBU", y = "SRM") 
clustered_beer_plot_ibu_srm







find_outlier <- beer_for_clustering %>% 
  arrange(desc(ibu)) %>% 
  select(style, ibu)

head(find_outlier)
