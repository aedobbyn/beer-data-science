# source("./run_it.R")

# source("./read_from_db.R")
source("./most_popular_styles.R")

library(NbClust)


# ------------------- kmeans ------------

# only using top beer styles
# select only predictor and outcome columns, take out NAs, and scale the data
beer_for_clustering <- popular_beer_dat %>% 
  select(name, style, styleId, style_collapsed,
         abv, ibu, srm) %>%       # not very many beers have SRM so may not want to omit based on it...
  na.omit() %>% 
  filter(
    abv < 20 & abv > 3
  ) %>%
  filter(
    ibu < 200
  )

beer_for_clustering_predictors <- beer_for_clustering %>% 
  select(abv, ibu, srm) %>%
  rename(
    abv_scaled = abv,
    ibu_scaled = ibu,
    srm_scaled = srm
    ) %>% scale() %>% 
  as_tibble()

# # take out outliers
# beer_for_clustering <- beer_for_clustering_w_scaled %>% 
#   filter(
#     abv_scaled < 5 & abv_scaled > -2    # take out the nonalcoholic beers
#   ) %>%
#   filter(
#     ibu_scaled < 5
#   )
  
# beer_for_clustering <- bind_cols(beer_for_clustering, beer_for_clustering_w_scaled)


# beer_for_clustering_predictors <- beer_for_clustering %>% 
#   select(
#     abv_scaled, ibu_scaled, srm_scaled
#   )

# # separate into predictors and outcomes and scale the predictors
# beer_for_clustering_predictors_w_outliers <- beer_for_clustering %>% select(abv, ibu, srm) %>% rename(
#   abv_scaled = abv,
#   ibu_scaled = ibu,
#   srm_scaled = srm
#   ) %>% scale() %>% 
#   as_tibble()
   

# take out some abv and ibu outliers from the clustered beer data


# filter(
# !(ibu > 300)      # take out outliers
# ) %>% 
# filter(
#   !(abv > 20)
# )


beer_for_clustering_outcome <- beer_for_clustering %>% select(name, style, styleId, style_collapsed)



# what's the optimal number of clusters?

# nb <- NbClust(beer_for_clustering_predictors, distance = "euclidean",
#               min.nc = 2, max.nc = 15, method = "kmeans")
# hist(nb$Best.nc[1,], breaks = max(na.omit(nb$Best.nc[1,])))




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
cluster_table_counts <- table(style = clustered_beer$style_collapsed, cluster = clustered_beer$cluster_assignment)

# cb_spread <- clustered_beer %>% select(
#   cluster_assignment, style
# ) %>% group_by(cluster_assignment) %>%
#   spread(key = cluster_assignment, value = style, convert = TRUE)










# tsne
# library(tsne)
# 
# cb <- clustered_beer %>% sample_n(100)
# 
# colors = rainbow(length(unique(cb$style)))
# names(colors) = unique(cb$style)
# 
# ecb = function (x,y) { 
#   plot(x,t='n'); 
#   text(x, labels=cb$style, col=colors[cb$style]) }
# 
# tsne_beer = tsne(cb[,4:6], epoch_callback = ecb, perplexity=20)
# 
# 





# ---------- functionize --------

source("./most_popular_styles.R")

library(NbClust)

# only using top beer styles
# select only predictor and outcome columns, take out NAs, and scale the data

cluster_it <- function(df, preds, to_scale, resp, n_centers) {
  df_for_clustering <- df %>%
    select_(.dots = c(response_vars, cluster_on)) %>%
    na.omit() %>%
    filter(
      abv < 20 & abv > 3
    ) %>%
    filter(
      ibu < 200
    )

  df_all_preds <- df_for_clustering %>%
    select_(.dots = preds)

  df_preds_scale <- df_all_preds %>%
    select_(.dots = to_scale) %>%
    rename(
      abv_scaled = abv,
      ibu_scaled = ibu,
      srm_scaled = srm
    ) %>%
    scale() %>%
    as_tibble()

  df_preds <- bind_cols(df_preds_scale, df_all_preds[, (!names(df_all_preds) %in% to_scale)])

  df_outcome <- df_for_clustering %>%
    select_(.dots = resp) %>%
    na.omit()

  set.seed(9)
  clustered_df_out <- kmeans(x = df_preds, centers = n_centers, trace = TRUE)

  clustered_df <- as_tibble(data.frame(
    cluster_assignment = factor(clustered_df_out$cluster),
    df_outcome, df_preds,
    df_for_clustering %>% select(abv, ibu, srm)))

  return(clustered_df)
}


# ----------- main clustering into 10 clusters -------

cluster_on <- c("abv", "ibu", "srm")
to_scale <- c("abv", "ibu", "srm")
response_vars <- c("name", "style", "styleId", "style_collapsed")


clustered_beer <- cluster_it(df = popular_beer_dat,
                             preds = cluster_on,
                             to_scale = to_scale,
                             resp = response_vars,
                             n_centers = 10)





# ----------------- pared styles -----------------

styles_to_keep <- c("Blonde", "India Pale Ale", "Stout", "Tripel", "Wheat")
bn_certain_styles <- beer_ingredients_join %>%
  filter(
    style_collapsed %in% styles_to_keep
  )

cluster_on <- c("abv", "ibu", "srm", "total_hops", "total_malt")
to_scale <- c("abv", "ibu", "srm")
response_vars <- c("name", "style", "style_collapsed")

certain_styles_clustered <- cluster_it(df = bn_certain_styles,
                                 preds = cluster_on,
                                 to_scale = to_scale,
                                 resp = response_vars,
                                 n_centers = 5)




table(style = certain_styles_clustered$style_collapsed, cluster = certain_styles_clustered$cluster_assignment)

ggplot() +
  geom_point(data = certain_styles_clustered,
             aes(x = abv, y = ibu,
                 shape = cluster_assignment,
                 colour = style_collapsed), alpha = 0.5) +
  geom_point(data = style_centers_certain_styles,
             aes(mean_abv, mean_ibu), colour = "black") +
  geom_text_repel(data = style_centers_certain_styles,
                  aes(mean_abv, mean_ibu, label = style_collapsed),
                  box.padding = unit(0.45, "lines"),
                  family = "Calibri",
                  label.size = 0.3) +
  ggtitle("Selected Styles (colors) matched with Cluster Assignments (shapes)") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Style") +
  theme_bw()

