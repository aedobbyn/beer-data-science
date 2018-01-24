library(tidyverse)
library(stringr)
library(glue)
library(tidytext)
library(jsonlite)
library(widyr)

# beer_hashtags_raw <- readLines("./other/insta/hashtag-data/beer.txt")
# ipa_hashtags_raw <- readLines("./other/insta/hashtag-data/ipa.txt")

read_raw <- function(dir) {
  file_names <- list.files(dir)
  file_names_full <- dir %>% str_c(file_names)
  object_names <<- file_names %>% 
    str_replace_all("\\.txt", "") %>% str_c("_hashtags_raw_2")
  
  for (i in seq_along(object_names)) {
    assign(object_names[i], readLines(file_names_full[i]), 
           envir = .GlobalEnv)
    print(glue("Reading in {object_names[i]}"))
  }
}

read_raw("./other/insta/hashtag-data/")


munge_hashtag <- function(raw, term = NULL) {
  
  clean <- raw %>% 
    str_replace_all(pattern = "\\[", replacement = "") %>% 
    str_replace_all(pattern = "\\]", replacement = "") %>% 
    as_tibble() %>% 
    separate(value, into = c("tag", "val"), sep = "=>")
  
  clean$val <- as.numeric(clean$val)
  
  if (is.null(term)) {
    term <- clean$tag[1]
  }
  
  clean <- clean %>% 
    mutate(
      term = term
    )
    
  return(clean)
}


beer_clean <- munge_hashtag(beer_hashtags_raw, term = "beer")
ipa_clean <- munge_hashtag(ipa_hashtags_raw, term = "ipa")


all_clean <- bind_rows(beer_clean, ipa_clean)

all_clean[1, 1] <- "beer"
all_clean$tag <- trimws(all_clean$tag)

all_clean_tfidf <- all_clean %>% 
  # group_by(term) %>% 
  # count()
  bind_tf_idf(tag, term, val) %>% 
  ungroup() %>% 
  arrange(desc(tf_idf))



all_clean_pairwise_counts <- all_clean %>% 
  pairwise_count(tag, term, val) %>% 
  arrange(desc(n))





# Expand
all_clean_expanded_nested <- all_clean %>% 
  rowwise() %>% 
  mutate(
    each_tag = rep(tag, val) %>% list(),
    occurrence = seq(val) %>% list()
  )

all_clean_expanded <- all_clean_expanded_nested %>% 
  unnest() 

all_clean_expanded %>% 
  # group_by(tag) %>% 
  widyr::pairwise_count(each_tag, term, val) %>% 
  arrange(desc(n))



beer_all_hashtags <- read_lines("./other/insta/beertags.js")
fromJSON(beer_all_hashtags, flatten = TRUE)



