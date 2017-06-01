
source("./most_popular_styles.R")


ggplot(data = beer_necessities[1:200, ], aes(x = abv, y = ibu, colour = style_collapsed)) +
  geom_point()


dIPAs <- cluster_dat %>% 
  filter(
    style_collapsed == "Double India Pale Ale"
  )

ggplot(data = dIPAs, aes(x = abv, y = ibu, colour = cluster_assignment)) +
  geom_point() %>% 
  scale_fill_discrete("Cluster Assignment")


# - take out unpopular styles not by an absolute number but by st. dev or somethings


# plot 
# - how styles compare to clusters
# - mean of each style






clustered_beer <- clustered_beer %>% 
  drop_na() %>% 
  droplevels()

style_centers <- clustered_beer %>% 
  group_by(style_collapsed) %>% 
  summarise(
    mean_abv = mean(abv, na.rm = TRUE),
    mean_ibu = mean(ibu, na.rm = TRUE), 
    mean_srm = mean(srm, na.rm = TRUE)
  ) %>% 
  drop_na() %>% 
  droplevels(.)


centers_abv_ibu <- ggplot(data = style_centers, aes(mean_abv, mean_ibu, colour = style_collapsed)) +
  geom_point()

centers_srm_ibu <- ggplot(data = style_centers, aes(mean_srm, mean_ibu, colour = style_collapsed)) +
  geom_point()







library(ggrepel)
abv_ibu_clusters_vs_style_centers <- ggplot() +   
  geom_point(data = clustered_beer, 
             aes(x = abv, y = ibu, colour = cluster_assignment)) +
  geom_point(data = style_centers,
             aes(mean_abv, mean_ibu), colour = "black") +
  geom_text_repel(data = style_centers, aes(mean_abv, mean_ibu, label = style_collapsed), 
                  box.padding = unit(0.45, "lines"),
                  family = "Courier",
                  label.size = 0.3) +
  theme_bw()
abv_ibu_clusters_vs_style_centers


