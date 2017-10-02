Beer-in-Hand Data Science
========================================================
author: Amanda Dobbyn
date: 
autosize: true
transition: zoom






Motivation
========================================================

### Are beer styles just a social construct?

Code at: <https://github.com/aedobbyn/beer-data-science>


The beer landscape
========================================================

![plot of chunk unnamed-chunk-1](present-figure/unnamed-chunk-1-1.png)


Step 1: GET Beer
========================================================


```r
unnest_it <- function(df) {
  unnested <- df
  for(col in seq_along(df[["data"]])) {
    if(! is.null(ncol(df[["data"]][[col]]))) {
      if(! is.null(df[["data"]][[col]][["name"]])) {
        unnested[["data"]][[col]] <- df[["data"]][[col]][["name"]]
      } else {
        unnested[["data"]][[col]] <- df[["data"]][[col]][[1]]
      }
    }
  }
  return(unnested)
}
```















