
# source("./most_popular_styles.R")
# source("./cluster.R")


ggplot(data = beer_necessities[1:200, ], aes(x = abv, y = ibu, colour = style_collapsed)) +
  geom_point()


dIPAs_clusters <- clustered_beer %>% 
  filter(
    style_collapsed == "Double India Pale Ale"
  )

ggplot(data = dIPAs_clusters, aes(x = abv, y = ibu, colour = cluster_assignment)) +
  geom_point()





clustered_beer <- clustered_beer %>% 
  drop_na() %>% 
  droplevels()

clustered_style_centers <- clustered_beer %>%             #### these style_centers different from style_centers in run_it.R
  group_by(style_collapsed) %>% 
  summarise(
    mean_abv = mean(abv, na.rm = TRUE),
    mean_ibu = mean(ibu, na.rm = TRUE), 
    mean_srm = mean(srm, na.rm = TRUE)
  ) %>% 
  drop_na() %>% 
  droplevels(.)

# popular style centers: abv and ibu
centers_abv_ibu <- ggplot(data = clustered_style_centers, aes(mean_abv, mean_ibu, colour = style_collapsed)) +
  geom_point()
centers_abv_ibu

# popular style centers: srm and ibu
centers_srm_ibu <- ggplot(data = clustered_style_centers, aes(mean_srm, mean_ibu, colour = style_collapsed)) +
  geom_point()





library(ggrepel)
abv_ibu_clusters_vs_style_centers <- ggplot() +   
  geom_point(data = clustered_beer, 
             aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
  geom_point(data = style_centers,
             aes(mean_abv, mean_ibu), colour = "black") +
  geom_text_repel(data = style_centers, aes(mean_abv, mean_ibu, label = style_collapsed), 
                  box.padding = unit(0.45, "lines"),
                  family = "Calibri",
                  label.size = 0.3) +
  ggtitle("Popular Styles vs. k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Cluster Assignment") +
  theme_bw()
abv_ibu_clusters_vs_style_centers




# # take out some abv and ibu outliers from the clustered beer data
# clustered_beer_no_outliers <- clustered_beer %>% 
#   filter(
#    abv_scaled < 5 & abv_scaled > -2    # take out the nonalcoholic beers
#   ) %>% 
#   filter(
#     ibu_scaled < 5
#   )

# colors are clusters
ggplot() +   
  geom_point(data = clustered_beer, 
             aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
  geom_point(data = style_centers,
             aes(mean_abv, mean_ibu), colour = "black") +
  geom_text_repel(data = style_centers, aes(mean_abv, mean_ibu, label = style_collapsed), 
                  box.padding = unit(0.45, "lines"),
                  family = "Calibri",
                  label.size = 0.3) +
  ggtitle("Popular Styles vs. k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Cluster Assignment") +
  theme_bw()



styles_to_keep <- c("Blonde", "India Pale Ale", "Stout", "Tripel", "Wheat")
clustered_beer_certain_styles <- clustered_beer %>% 
  filter(
   style_collapsed %in% styles_to_keep 
  )

style_centers_certain_styles <- style_centers %>% 
  filter(
    style_collapsed %in% styles_to_keep 
  )


# clusters defined by shapes
# colors for styles
sparser_cluster_plot <- ggplot() +   
  geom_point(data = clustered_beer_certain_styles, 
             aes(x = abv, y = ibu,
                 # shape = cluster_assignment,
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
sparser_cluster_plot


# faceted plot of certain styles broken down by cluster
by_style_plot <- ggplot() +   
  geom_point(data = clustered_beer_certain_styles, 
             aes(x = abv, y = ibu,
                 colour = cluster_assignment), alpha = 0.5) +
  facet_grid(. ~ style_collapsed) +
  geom_point(data = style_centers_certain_styles,
             aes(mean_abv, mean_ibu), colour = "black", shape = 5) +
  ggtitle("Selected Styles Cluster Assignment") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Cluster") +
  theme_bw()
by_style_plot






library(plot3D)
library(scatterplot3d)
three_d <- scatterplot3d(x = beer_dat_pared$abv[1:500], y = beer_dat_pared$ibu[1:500], 
                  z = beer_dat_pared$srm[1:500])

three_d




# source("./munge_ingredients.R")
# # --- centers of each style
# # size of dot is number of beers per that style
# style_summary <- inner_join(style_centers, hops_by_style, by = "style_collapsed")
# style_summary$style_collapsed <- factor(style_summary$style_collapsed)
# 
# ggplot(style_summary) +
#   geom_point(aes(mean_abv, mean_ibu, colour = style_collapsed, size = n))
# 
# 
# # hops in hops_name_1 of double IPAs
# dIPAs_hops <- hops_join %>% 
#   filter(
#     style_collapsed == "Double India Pale Ale"
#   )
# 
# dIPAs_hops$hops_name_1 <- factor(dIPAs_hops$hops_name_1) %>% droplevels() 
# dIPAs_hops <- dIPAs_hops[!is.na(dIPAs_hops$hops_name_1), ]
# 
# ggplot(dIPAs_hops) +
#   geom_point(aes(abv, ibu, colour = hops_name_1))




# ----------- more hops -> higher ibu?? -----------

hops_ibu_lm <- lm(ibu ~ total_hops, data = beer_ingredients_join)

ggplot(data = beer_ingredients_join, aes(total_hops, ibu)) +
  geom_point(aes(total_hops, ibu, colour = style_collapsed)) +
  geom_smooth(method = lm, se = FALSE, colour = "black") +
  theme_minimal()



ggplot(data = beer_ingredients_join[which(beer_ingredients_join$total_hops >= 2
                                          & beer_ingredients_join$total_hops < 8), ], aes(total_hops, ibu)) +
  geom_jitter(aes(total_hops, ibu, colour = style_collapsed)) +
  geom_smooth(method = lm, se = FALSE, colour = "black") + theme_minimal()
