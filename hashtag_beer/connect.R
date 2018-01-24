library(RMySQL)
library(dbplyr)

source("./db_pw.Rdata")

db_pw <- decrypt_kc_pw("hashtag_beer_db_pw")


sql <- 
"select posts.`short_code`, posts.`comment_count`, posts.like_count, tags.tag, post_tag.`post_id`, post_tag.`tag_id` from posts
left join post_tag on posts.id = post_tag.`post_id`
left join tags on tags.id = post_tag.tag_id;"

con <- dbConnect(RMySQL::MySQL(), dbname = "hashtag_beer", host = "localhost", port = 3306, 
                 user = "root", password = db_pw)


hashtag_beer <- hashtag_beer %>% as_tibble()


# dbClearResult(hashtag_beer)
# dbClearResult(dbListResults(con)[[1]])


