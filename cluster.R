
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
beer_for_clustering_predictors <- beer_for_clustering %>% select(abv, ibu) %>% rename(
  abv_scaled = abv,
  ibu_scaled = ibu
  # srm_scaled = srm
  ) %>% scale() 
  
beer_for_clustering_outcome <- beer_for_clustering %>% select(style, styleId)


# do clustering
set.seed(9)
clustered_beer_out <- kmeans(x = beer_for_clustering_predictors, centers = 10, trace = TRUE)

clustered_beer <- as_tibble(data.frame(cluster_assignment = factor(clustered_beer_out$cluster), 
                            beer_for_clustering_outcome, beer_for_clustering_predictors,
                            beer_for_clustering %>% select(abv, ibu, srm)))



# the three combinations of plots
clustered_beer_plot_abv_ibu <- ggplot(data = clustered_beer, aes(x = abv, y = ibu, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU") +
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





# cluster 1
cluster_1 <- clustered_beer %>% filter(cluster_assignment == "1")
cluster_1

cluster_6 <- clustered_beer %>% filter(cluster_assignment == "6")
cluster_6

cluster_9 <- clustered_beer %>% filter(cluster_assignment == "9")
cluster_9





# tsne

colors = rainbow(length(unique(ab$Shrt_Desc)))
names(colors) = unique(ab$Shrt_Desc)

ecb = function (x,y) { 
  plot(x,t='n'); 
  text(x, labels=ab$Shrt_Desc, col=colors[ab$Shrt_Desc]) }

tsne_ab = tsne(ab[,3:6], epoch_callback = ecb, perplexity=20)


