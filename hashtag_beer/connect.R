library(RMySQL)
library(dbplyr)
library(feather)

db_pw <- decrypt_kc_pw("hashtag_beer_db_pw")

sql <- 
"select posts.`short_code`, posts.`comment_count`, posts.like_count, tags.tag, post_tag.`post_id`, post_tag.`tag_id` from posts
left join post_tag on posts.id = post_tag.`post_id`
left join tags on tags.id = post_tag.tag_id;"

con <- dbConnect(RMySQL::MySQL(), dbname = "hashtag_beer", host = "localhost", port = 3306, 
                 user = "root", password = db_pw)


hashtag_beer <- dbGetQuery(con, sql) %>% as_tibble()
# don't really need post_id and tag_id
hashtag_beer <- hashtag_beer %>% select(-post_id, -tag_id)


# dbClearResult(hashtag_beer)
# dbClearResult(dbListResults(con)[[1]])


hashtag_pairwise <- hashtag_beer %>% 
  # group_by(short_code) %>% 
  pairwise_count(tag, short_code) %>% 
  arrange(desc(n))

hashtag_pairwise_cor <- hashtag_beer %>%
  pairwise_cor(tag, short_code) %>% 
  arrange(desc(n))

hashtag_pairwise_unique <- hashtag_pairwise %>% 
  mutate (rn = row_number()) %>% 
  filter(rn %% 2 == 0) %>% 
  select(-rn)

hashtag_graph <- hashtag_pairwise %>%
  filter(n > 50) %>% 
  graph_from_data_frame()

hashtag_graph %>% 
  ggraph(layout = "fr") +
  geom_edge_link(show.legend = FALSE) +
  geom_edge_link(alpha = 0.2, show.legend = FALSE) +    # aes(edge_width = n)
  geom_node_point(color = "lightblue", size = 5) +
  geom_node_text(aes(label = name), repel = TRUE) +
  theme_void()

