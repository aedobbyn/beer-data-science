
library(tsne)
library(NbClust)


# ------------------- kmeans ------------

# only using top beer styles
# select only predictor and outcome columns, take out NAs, and scale the data
beer_for_clustering <- popular_beer_dat %>% 
  select(style, styleId, abv, ibu, srm) %>% 
  na.omit() %>% 
  filter(
    !(ibu > 300)      # take out outliers
  ) %>% 
  filter(
    !(abv > 20)
  )


# separate into predictors and outcomes and scale the predictors
beer_for_clustering_predictors <- beer_for_clustering %>% select(abv, ibu, srm) %>% rename(
  abv_scaled = abv,
  ibu_scaled = ibu,
  srm_scaled = srm
  ) %>% scale() 
  
beer_for_clustering_outcome <- beer_for_clustering %>% select(style, styleId)



# what's the optimal number of clusters?

# nb <- NbClust(beer_for_clustering_predictors, distance = "euclidean", 
#               min.nc=2, max.nc=15, method = "kmeans", 
#               index = "alllong", alphaBeale = 0.1)
# hist(nb$Best.nc[1,], breaks = max(na.omit(nb$Best.nc[1,])))
# 
# 
# num_clust <- NbClust(beer_for_clustering_predictors, min.nc = 2,
#                      max.nc = 15,   # set max number of clusters to less than number of groups
#                      method = "average")



# do clustering
set.seed(9)
clustered_beer_out <- kmeans(x = beer_for_clustering_predictors, centers = 10, trace = TRUE)

clustered_beer <- as_tibble(data.frame(cluster_assignment = factor(clustered_beer_out$cluster), 
                            beer_for_clustering_outcome, beer_for_clustering_predictors,
                            beer_for_clustering %>% select(abv, ibu, srm)))



# the three combinations of plots
clustered_beer_plot_abv_ibu <- ggplot(data = clustered_beer, aes(x = abv, y = ibu, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Cluster Assignment")
clustered_beer_plot_abv_ibu

clustered_beer_plot_abv_srm <- ggplot(data = clustered_beer, aes(x = abv, y = srm, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "SRM") +
  labs(colour = "Cluster Assignment")
clustered_beer_plot_abv_srm

clustered_beer_plot_ibu_srm <- ggplot(data = clustered_beer, aes(x = ibu, y = srm, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "IBU", y = "SRM") +
  labs(colour = "Cluster Assignment")
clustered_beer_plot_ibu_srm





# take a look at individual clusters
cluster_1 <- clustered_beer %>% filter(cluster_assignment == "1")
cluster_1

cluster_6 <- clustered_beer %>% filter(cluster_assignment == "6")
cluster_6

cluster_9 <- clustered_beer %>% filter(cluster_assignment == "9")
cluster_9


# see how styles clustered themselves

# table of counts
table(style = clustered_beer$style, cluster = clustered_beer$cluster_assignment)

cb_spread <- clustered_beer %>% select(
  cluster_assignment, style
) %>% group_by(cluster_assignment) %>%
  spread(key = cluster_assignment, value = style, convert = TRUE)


# tsne
cb <- clustered_beer %>% sample_n(100)

colors = rainbow(length(unique(cb$style)))
names(colors) = unique(cb$style)

ecb = function (x,y) { 
  plot(x,t='n'); 
  text(x, labels=cb$style, col=colors[cb$style]) }

tsne_beer = tsne(cb[,4:6], epoch_callback = ecb, perplexity=20)


