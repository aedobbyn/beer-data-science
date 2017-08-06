

rename_cols <- function(df) {
  
  orig_names <- c("cluster_assignment", "style_collapsed", "style",
                  "abv", "ibu", "srm", "total_hops", "total_malt")
  
  new_names <- c("Cluster Assignment", "Collapsed Style", "Style",
                 "ABV", "IBU", "SRM", "Total N Hops", "Total N Malts")
  
  # name_df <- list(orig_names = orig_names, new_names = new_names) %>% as_tibble()
  
  name_indices <- which(input$cluster_on %in% orig_names)
  
  names(df)[name_indices] <- new_names[name_indices]
  
  
  return(df)
  
  
  # for (i in seq_along(names(df))) {
  #   if (names(df)[i] %in% name_df$orig_names) {
  #     names(df)[i] <- name_df$new_names[i]
  #   }
  # }
  # return(df)
}
