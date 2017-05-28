



ggplot(data = beer_necessities[1:200, ], aes(x = abv, y = ibu, colour = style_collapsed)) +
  geom_point()


dIPAs <- cluster_dat %>% 
  filter(
    style_collapsed == "Double India Pale Ale"
  )

ggplot(data = dIPAs, aes(x = abv, y = ibu, colour = cluster_assignment)) +
  geom_point()


# - take out unpopular styles not by an absolute number but by st. dev or somethings


# plot 
# - how styles compare to clusters
# 

