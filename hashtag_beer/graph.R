library(igraph)
library(ggraph)

# verts <- all_clean %>% 
#   select(tag, term, val) %>% 
#   filter(val > 20)
# 
# graph <- all_clean %>% 
#   graph_from_data_frame(vertices = val)


all_clean_graph <- all_clean %>%
  select(tag, term, val) %>% 
  filter(val > 3) %>% 
  graph_from_data_frame()

all_clean_graph %>% 
  ggraph(layout = "fr") +
  geom_edge_link(show.legend = FALSE) +
  geom_edge_link(aes(edge_width = val), alpha = 0.5, show.legend = FALSE) +
  geom_node_point(color = "lightblue", size = 5) +
  geom_node_text(aes(label = name), repel = TRUE) +
  theme_void()
