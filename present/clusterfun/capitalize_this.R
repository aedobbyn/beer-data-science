

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

capitalize_this <- function(df, ...) {
  out <- vector()
  for (i in names(df)) {
    if (i == "abv") {
      i <- "ABV"
    } else if (i == "ibu") {
      i <- "IBU"
    } else if (i == "srm") {
      i <- "SRM"
    } else if (grepl(pattern = "_", x = i) == TRUE) {
      i <- simpleCap(gsub(x = i, pattern = "_", replacement = " "))
    } else {
      i <- capitalize(i)
    }
    out <- c(out, i)
  }
  names(df) <- out
  df
}
