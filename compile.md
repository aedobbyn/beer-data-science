# Data Science Musings on Beer
`r format(Sys.time(), '%B %d, %Y')`  





* Main question
    * Are there natural clusters in beer that are defined by styles? Or are style boundaries more or less arbitrary?
      * Unsupervised (k-means) clustering based on 
        * ABV (alcohol by volume), IBU (international bitterness units), SRM (measure of color)
        * Style centers defined by mean of ABV, IBU, and SRM
      * Neural net 
        * Can we predict a beer's style based on certain characteristics of the beer?
      
* Answer
    * Looks more or less fluid: beer attributes aren't great predictors of style
    * The glass a beer is served in is a much better predictor of its style than actual characteristics of the beer like ABV and even the number of different types of hops it contains

![](./taps.jpg)

### General Workflow

* Hit the BreweryDB API to iteratively pull in all beers and their ingredients
    * Dump them into a MySQL database along with other things we'd want like breweries and glassware
* Unnest the JSON response including all the ingredients columns
* Create a `style_collapsed` column
    * Look for main style strings like `Pale Ale` and chop out everything else
    * Further collpase styles that are similar like Hefeweizen and Wit into Wheat
* Unnest the ingredients `hops` and `malts` into a sparse matrix
    * Individual ingredients as columns, beers as rows; cell gets a 1 if ingredient is present and 0 otherwise 

* Data courtesy of [BreweryDB](http://www.brewerydb.com/developers)
    * Special thanks to [Kris Kroksi](https://kro.ski/) for data ideation and beer




**Getting Beer**



* The BreweryDB API returns a certain number of results per page; if we want 
* So, we hit the BreweryDB API and ask for `1:number_of_pages`
    * We can change `number_of_pages` to, e.g., 3 if we only want the first 3 pages
    * If there's only one page (as is the case for the glassware endpoing), numberOfPages won't be returned, so in this case we set number_of_pages to 1
* The `addition` parameter can be an empty string if nothing else is needed


```r
base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="

paginated_request <- function(ep, addition) {    
  full_request <- NULL
  first_page <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                , "&p=1"))
  number_of_pages <- ifelse(!(is.null(first_page$numberOfPages)), 
                            first_page$numberOfPages, 1)      

    for (page in 1:number_of_pages) {                               
    this_request <- fromJSON(paste0(base_url, "/", ep, "/", key_preface, key
                                    , "&p=", page, addition),
                             flatten = TRUE) 
    this_req_unnested <- unnest_it(this_request)    #  <- request unnested here
    print(this_req_unnested$currentPage)
    full_request <- bind_rows(full_request, this_req_unnested[["data"]])
  }
  full_request
} 

all_beer_raw <- paginated_request("beers", "&withIngredients=Y")
```



* Function for unnesting JSON used inside `paginated_request()` below
    + Takes the column named `name` nested within a column in the data portion of the response
        + If the `name` column doesn't exist, it takes the first nested column
* We use something similar to unnest ingredient like all of a beer's hops and malts into a long string contained in `hops_name` and `malt_name`


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
  unnested
}
```



**Collapse Styles**

* Save the most popular styles in `keywords`
* Loop through each keyword
    * For each beer, `grep` through its style column to see if it contains any one of these keywords
    * If it does, give it that keyword in a new column `style_collapsed`
* If a beer's name matches multiple keywords, e.g., American Double India Pale Ale would match Double India Pale Ale, India Pale Ale, and Pale Ale, its `style_collapsed` is the **last** of those that appear in keywords 
    * This is why keywords are intentionally ordered from most general to most specific
    * So in the case of an case of American Double India Pale Ale: since Double India Pale Ale appears in `keywords` after India Pale Ale and Pale Ale, an American Double India Pale Ale would get a `style_collapsed` of Double India Pale Ale
* If no keyword is contained in `style`, `style_collapsed` is just whatever's in `style`; in other words, it doesn't get collpsed into a bigger bucket
    * This isn't a huge problem because we'll pare down to just the most popular styles later, however we could think about creating a catchall "Other" level for `style_collapsed`


```r
collapse_styles <- function(df) {
  keywords <- c("Lager", "Pale Ale", "India Pale Ale", "Double India Pale Ale", "India Pale Lager", "Hefeweizen", "Barrel-Aged","Wheat", "Pilsner", "Pilsener", "Amber", "Golden", "Blonde", "Brown", "Black", "Stout", "Porter", "Red", "Sour", "Kölsch", "Tripel", "Bitter", "Saison", "Strong Ale", "Barley Wine", "Dubbel", "Altbier")
  
  for (beer in 1:nrow(df)) {
    if (grepl(paste(keywords, collapse="|"), df$style[beer])) {    
      for (keyword in keywords) {         
        if(grepl(keyword, df$style[beer]) == TRUE) {
          df$style_collapsed[beer] <- keyword    
        }                         
      } 
    } else {
      df$style_collapsed[beer] <- as.character(df$style[beer])       
    }
    print(df$style_collapsed[beer])
  }
  return(df)
}
```

* Then we collapse further; right now we just combine all wheaty bears into Wheat by `fct_collapse`ing those levels



**Split out Ingredients**

* When we unnested ingredients, we just concatenated all of the ingredients for a given beer into a long string
* If we want, we can split out the ingredients that were concatenated in `<ingredient>_name` with this `split_ingredients` function
* This takes a vector of `ingredients_to_split`, so e.g. `c("hops_name", "malt_name")` and creates one column for each type of ingredient (`hops_name_1`, `hops_name_2`, etc.)

* We `str_split` on the ingredient and get a list back
* We find the max number of instances of an ingredient per beer, which will be the number of columns we're adding
* For each new column we need, we create it, initialize it with NAs, and name it
* Then for each element in our list of split up ingredients, if it exists, we add it to the correct column in our df


```r
split_ingredients <- function(df, ingredients_to_split) {
  
  ncol_df <- ncol(df)
  
  for (ingredient in ingredients_to_split) {

    ingredient_split <- str_split(df[[ingredient]], ", ")    
    num_new_cols <- max(lengths(ingredient_split))    
  
    for (num in 1:num_new_cols) {
      
      this_col <- ncol_df + 1         
      
      df[, this_col] <- NA
      names(df)[this_col] <- paste0(ingredient, "_", num)
      ncol_df <- ncol(df)             
      for (row in seq_along(ingredient_split)) {          
        if (!is.null(ingredient_split[[row]][num])) {        
          df[row, this_col] <- ingredient_split[[row]][num]
        }
      }
      df[[names(df)[this_col]]] <- factor(df[[names(df)[this_col]]])
    }
    
    ncol_df <- ncol(df)
  }
  return(df)
}
```



Head of the clustering data

|name                                                         |style                                              |styleId |style_collapsed       | abv|  ibu| srm|
|:------------------------------------------------------------|:--------------------------------------------------|:-------|:---------------------|---:|----:|---:|
|"Ah Me Joy" Porter                                           |Robust Porter                                      |19      |Porter                | 5.4| 51.0|  40|
|"Bison Eye Rye" Pale Ale &#124; 2 of 4 Part Pale Ale Series  |American-Style Pale Ale                            |25      |Pale Ale              | 5.8| 51.0|   8|
|"Dust Up" Cloudy Pale Ale &#124; 1 of 4 Part Pale Ale Series |American-Style Pale Ale                            |25      |Pale Ale              | 5.4| 54.0|  11|
|"God Country" Kolsch                                         |German-Style Kölsch / Köln-Style Kölsch            |45      |Kölsch                | 5.6| 28.2|   5|
|"Jemez Field Notes" Golden Lager                             |Golden or Blonde Ale                               |36      |Blonde                | 4.9| 20.0|   5|
|#10 Hefewiezen                                               |South German-Style Hefeweizen / Hefeweissbier      |48      |Wheat                 | 5.1| 11.0|   4|
|#9                                                           |American-Style Pale Ale                            |25      |Pale Ale              | 5.1| 20.0|   9|
|#KoLSCH                                                      |German-Style Kölsch / Köln-Style Kölsch            |45      |Kölsch                | 4.8| 27.0|   3|
|'Inappropriate' Cream Ale                                    |American-Style Cream Ale or Lager                  |109     |Lager                 | 5.3| 18.0|   5|
|'tis the Saison                                              |French & Belgian-Style Saison                      |72      |Saison                | 7.0| 30.0|   7|
|(306) URBAN WHEAT BEER                                       |Belgian-Style White (or Wit) / Belgian-Style Wheat |65      |Wheat                 | 5.0| 20.0|   9|
|(512) Bruin (A.K.A. Brown Bear)                              |American-Style Brown Ale                           |37      |Brown                 | 7.6| 30.0|  21|
|(512) FOUR                                                   |Strong Ale                                         |14      |Strong Ale            | 7.5| 35.0|   8|
|(512) IPA                                                    |American-Style India Pale Ale                      |30      |India Pale Ale        | 7.0| 65.0|   8|
|(512) Pale                                                   |American-Style Pale Ale                            |25      |Pale Ale              | 6.0| 30.0|   7|
|(512) SIX                                                    |Belgian-Style Dubbel                               |58      |Dubbel                | 7.5| 25.0|  28|
|(512) THREE                                                  |Belgian-Style Tripel                               |59      |Tripel                | 9.5| 22.0|  10|
|(512) THREE (Cabernet Barrel Aged)                           |Belgian-Style Tripel                               |59      |Tripel                | 9.5| 22.0|  40|
|(512) TWO                                                    |Imperial or Double India Pale Ale                  |31      |Double India Pale Ale | 9.0| 99.0|   9|
|(512) White IPA                                              |American-Style India Pale Ale                      |30      |India Pale Ale        | 5.3| 55.0|   4|


**Find the Most Popualar Styles**


```r
# Pare down to only cases where style is not NA
beer_dat_pared <- beer_dat[complete.cases(beer_dat$style), ]

# Arrange beer dat by style popularity
style_popularity <- beer_dat_pared %>% 
  group_by(style) %>% 
  count() %>% 
  arrange(desc(n))
style_popularity

# Add a column that scales popularity
style_popularity <- bind_cols(style_popularity, 
                               n_scaled = as.vector(scale(style_popularity$n)))

# Find styles that are above a z-score of 0
popular_styles <- style_popularity %>% 
  filter(n_scaled > 0)

# Pare dat down to only beers that fall into those styles
popular_beer_dat <- beer_dat_pared %>% 
  filter(
    style %in% popular_styles$style
  ) %>% 
  droplevels() %>% 
  as_tibble() 
nrow(popular_beer_dat)

# Find the centers (mean abv, ibu, srm) of the most popular styles
style_centers <- popular_beer_dat %>% 
  group_by(style_collapsed) %>% 
  add_count() %>% 
  summarise(
    mean_abv = mean(abv, na.rm = TRUE),
    mean_ibu = mean(ibu, na.rm = TRUE), 
    mean_srm = mean(srm, na.rm = TRUE),
    n = median(n, na.rm = TRUE)          # Median here only for summarise. Should be just the same as n
  ) %>% 
  arrange(desc(n)) %>% 
  drop_na() %>% 
  droplevels()
```


Compare popular styles      


|style_collapsed          |  mean_abv| mean_ibu|  mean_srm|    n|
|:------------------------|---------:|--------:|---------:|----:|
|India Pale Ale           |  6.578468| 66.04268|  9.989313| 6524|
|Pale Ale                 |  5.695480| 40.86930|  8.890306| 4280|
|Stout                    |  7.991841| 43.89729| 36.300000| 4238|
|Wheat                    |  5.158040| 17.47168|  5.861842| 3349|
|Double India Pale Ale    |  8.930599| 93.48142| 11.006873| 2525|
|Red                      |  5.742565| 33.81127| 16.178862| 2521|
|Lager                    |  5.453718| 30.64361|  8.457447| 2230|
|Saison                   |  6.400189| 27.25114|  7.053476| 2167|
|Blonde                   |  5.595298| 22.39432|  5.625000| 2044|
|Porter                   |  6.182049| 33.25369| 32.197605| 1973|
|Brown                    |  6.159212| 32.21577| 23.592000| 1462|
|Pilsener                 |  5.227593| 33.51346|  4.413462| 1268|
|Specialty Beer           |  6.446402| 33.77676| 15.520548| 1044|
|Bitter                   |  5.322364| 38.28175| 12.460526|  939|
|Fruit Beer               |  5.195222| 19.24049|  8.666667|  905|
|Herb and Spice Beer      |  6.621446| 27.77342| 18.166667|  872|
|Sour                     |  6.224316| 18.88869| 10.040816|  797|
|Strong Ale               |  8.826425| 36.74233| 22.547945|  767|
|Tripel                   |  9.029775| 32.51500|  7.680556|  734|
|Black                    |  6.958714| 65.50831| 31.080000|  622|
|Barley Wine              | 10.781600| 74.04843| 19.561404|  605|
|Kölsch                   |  4.982216| 23.37183|  4.371795|  593|
|Barrel-Aged              |  9.002506| 39.15789| 18.133333|  540|
|Other Belgian-Style Ales |  7.516318| 37.55812| 17.549020|  506|
|Pumpkin Beer             |  6.712839| 23.48359| 17.918033|  458|
|Dubbel                   |  7.509088| 25.05128| 22.940000|  399|
|Scotch Ale               |  7.620233| 26.36909| 24.222222|  393|
|German-Style Doppelbock  |  8.045762| 28.88692| 25.696970|  376|
|Fruit Cider              |  6.205786| 25.60000| 12.000000|  370|
|German-Style Märzen      |  5.746102| 25.63796| 14.322581|  370|


## Unsupervised Clustering 
* Pare down to beers that have ABV, IBU, and SRM
* K-means cluster beers based on these predictors


**Do Clustering**

* Use only the top beer styles
* Split off the predictors, ABV, IBU, and SRM
* Take out NAs, and scale the data
    * NB: There are not not very many beers have SRM so we may not want to omit based on it
* Take out some outliers
  * Beers have to have an ABV between 3 and 20 and an IBU less than 200
  

```r
beer_for_clustering <- popular_beer_dat %>% 
  select(name, style, styleId, style_collapsed,
         abv, ibu, srm) %>%       
  na.omit() %>% 
  filter(
    abv < 20 & abv > 3
  ) %>%
  filter(
    ibu < 200
  )

beer_for_clustering_predictors <- beer_for_clustering %>% 
  select(abv, ibu, srm) %>%
  rename(
    abv_scaled = abv,
    ibu_scaled = ibu,
    srm_scaled = srm
    ) %>% scale() %>% 
  as_tibble()
```

And do the clustering


```r
set.seed(9)
clustered_beer_out <- kmeans(x = beer_for_clustering_predictors, centers = 10, trace = TRUE)

clustered_beer <- as_tibble(data.frame(cluster_assignment = factor(clustered_beer_out$cluster), 
                            beer_for_clustering_outcome, beer_for_clustering_predictors,
                            beer_for_clustering %>% select(abv, ibu, srm)))
```


A table of cluster counts broken down by style

|                         |  1|   2|   3|   4|   5|   6|   7|  8|  9| 10|
|:------------------------|--:|---:|---:|---:|---:|---:|---:|--:|--:|--:|
|Barley Wine              |  7|   0|   0|   0|   2|   0|  19| 15|  2|  0|
|Barrel-Aged              |  5|   3|   2|   4|   1|   2|   1|  1|  4|  0|
|Bitter                   |  1|  28|   0|  25|   2|  13|   0|  0|  0|  1|
|Black                    |  0|   0|   4|   1|   0|   0|   0|  0|  2| 36|
|Blonde                   | 21|  18|   1|   3|   1| 115|   0|  0|  1|  0|
|Brown                    |  1|   1|  20|  68|   2|   7|   1|  1|  6|  3|
|Double India Pale Ale    |  5|   0|   0|   0|  38|   0| 174|  6|  0|  9|
|Dubbel                   |  8|   0|   1|  14|   1|   0|   0|  0| 16|  1|
|Fruit Beer               |  5|   2|   2|   6|   4|  36|   0|  1|  0|  0|
|Fruit Cider              |  0|   0|   0|   0|   0|   1|   0|  0|  0|  0|
|German-Style Doppelbock  |  7|   0|   1|   4|   0|   0|   0|  0| 16|  1|
|German-Style Märzen      |  0|   2|   1|  15|   0|  12|   0|  0|  0|  0|
|Herb and Spice Beer      |  5|   4|   8|  11|   6|  13|   0|  1|  6|  1|
|India Pale Ale           |  2|  93|   1|   6| 397|   6|  27|  0|  0| 26|
|Kölsch                   |  0|   3|   0|   1|   1|  67|   0|  0|  0|  0|
|Lager                    |  5|  21|   3|  17|  20|  90|   2|  0|  0|  4|
|Other Belgian-Style Ales |  6|   5|   4|   7|   8|   3|   1|  0|  4|  1|
|Pale Ale                 | 11| 221|   1|  30|  32|  50|   0|  0|  1|  3|
|Pilsener                 |  1|  39|   0|   1|   3|  46|   1|  0|  0|  1|
|Porter                   |  0|   1| 102|  29|   0|   0|   0|  0| 11|  3|
|Pumpkin Beer             |  9|   3|   5|  18|   0|   7|   0|  0|  4|  0|
|Red                      |  2|  36|  14| 127|  10|  29|   3|  0|  1|  6|
|Saison                   | 35|  44|   2|   6|   2|  48|   0|  0|  2|  0|
|Scotch Ale               |  7|   1|   4|   9|   0|   0|   0|  0| 12|  0|
|Sour                     |  1|   4|   1|   2|   1|  17|   0|  0|  2|  0|
|Specialty Beer           | 11|   5|   8|  13|   5|  15|   1|  0|  6|  1|
|Stout                    |  2|   3|  91|   2|   0|   1|   0| 24| 22| 19|
|Strong Ale               | 21|   0|   2|   2|   0|   0|   4|  4| 22|  2|
|Tripel                   | 59|   1|   0|   0|   0|   0|   2|  0|  2|  1|
|Wheat                    |  9|  14|   0|   6|   4| 228|   0|  0|  0|  0|


A couple plots of the same thing


```r
clustered_beer_plot_abv_ibu <- ggplot(data = clustered_beer, aes(x = abv, y = ibu, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Cluster Assignment")
clustered_beer_plot_abv_ibu
```

![](compile_files/figure-html/unnamed-chunk-11-1.png)<!-- -->

```r
clustered_beer_plot_abv_srm <- ggplot(data = clustered_beer, aes(x = abv, y = srm, colour = cluster_assignment)) + 
  geom_jitter() + theme_minimal()  +
  ggtitle("k-Means Clustering of Beer by ABV, IBU, SRM") +
  labs(x = "ABV", y = "SRM") +
  labs(colour = "Cluster Assignment")
clustered_beer_plot_abv_srm
```

![](compile_files/figure-html/unnamed-chunk-11-2.png)<!-- -->


### Now add in the style centers (means) for collapsed styles


```r
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
```

```
## Warning: Ignoring unknown parameters: label.size
```

```r
abv_ibu_clusters_vs_style_centers
```

![](compile_files/figure-html/unnamed-chunk-12-1.png)<!-- -->




# Neural Net

* Can ABV, IBU, and SRM be used in a neural net to predict `style` or `style_collapsed`?


```r
library(neuralnet)
library(nnet)
library(caret)

# split into training and test sets
beer_train <- sample_n(popular_beer_dat, 3000)
beer_test <- popular_beer_dat %>% filter(! (id %in% beer_train$id))


beer_necessities_train <- sample_n(beer_necessities, 21102)
beer_necessities_test <- beer_necessities %>% filter(! (id %in% beer_necessities_train$id))



# build multinomail neural net
nn_mod <- multinom(style ~ abv + srm + ibu, 
                   data = beer_train, maxit=500, trace=T)
nn_mod

# same model on style_collapsed
nn_collapsed <- multinom(style_collapsed ~ abv + srm + ibu, 
                   data = beer_necessities_train, maxit=500, trace=T)
nn_collapsed


# which variables are the most important in the neural net?
most_important_vars <- varImp(nn_mod)
# most_important_vars

# which variables are the most important in the neural net?
most_important_vars_collapsed <- varImp(nn_collapsed)
# most_important_vars_collapsed
```


Accuracy 

```r
# how accurate is the model?
# preds
nn_preds <- predict(nn_mod, type="class", newdata = beer_test)
nn_preds_collapsed <- predict(nn_collapsed, type="class", newdata = beer_necessities_test)


# accuracy
postResample(beer_test$style, nn_preds)
postResample(beer_necessities$style_collapsed, nn_preds_collapsed)
```


### Ingredients


```r
clustered_beer_necessities <- clustered_beer %>% 
  inner_join(beer_necessities)
```

```
## Joining, by = c("name", "style", "styleId", "style_collapsed", "abv", "ibu", "srm")
```

```
## Warning: Column `style` joining factors with different levels, coercing to
## character vector
```

```
## Warning: Column `styleId` joining factors with different levels, coercing
## to character vector
```

```
## Warning: Column `style_collapsed` joining factors with different levels,
## coercing to character vector
```



* `ingredient_want`: this can be `hops`, `malt`, or other ingredients like `yeast` if we pull that in
* `grouper`: can be a vector of one or more things to group by 

* Once ingredients have been split out from the concatenated string into columns like `malt_name_1`, `malt_name_2`, etc., we need to find the range of these columns; there will be a different number of malt columns than hops columns, for instance
    * The first one will be `<ingredient>_name_1` 
        * From this we can find the index of this column 
    * We get the name of last one with the `get_last_ing_name_col` function
* Then we save a vector of all the ingredient column names in `ingredient_colnames`
    * We make this a global variable because it will stay constant even if the indices change
    
* `to_keep_col_names` is a vector of all non-ingredient column names


* Inside `gather_ingredients` we:
    * Take out superflous column names that are not in `to_keep_col_names` or one of the ingredient columns
    * Find what the new ingredient column indices are, since they'll have changed after we pared down
    * Actually do the gathering: lump all of the ingredient columns (e.g., `hops_name_1`) into one long column, `ing_keys` and all the actual ingredient names (e.g., Cascade) into `ing_names`


* Get a vector of all ingredient levels and take out the one that's an empty string
* We'll use this vector of ingredient levels in `select_spread_cols()` below
    
* Then we spread
* We take what was previously the `value` in our gathered dataframe, the actual ingredient names (Cascade, Centennial) and make that our `key`; it'll form the new column names
    * The new `value` is `value` is count; it'll populate the row cells
        * If a given row has a certain ingredient, it gets a 1 in the corresponding cell, an NA otherwise
* We add a unique idenfitier for each row with `row`, which we'll drop later (see [Hadley's SO comment](https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr))



```r
pick_ingredient_get_beer <- function (ingredient_want, df, grouper) {
  ingredient_want <- ingredient_want
  
  get_last_ing_name_col <- function(df) {
    for (col in names(df)) {
      if (grepl(paste(ingredient_want, "_name_", sep = ""), col) == TRUE) {
        name_last_ing_col <- col
      }
    }
    return(name_last_ing_col)
  }
  
  # First ingredient
  first_ingredient_name <- paste(ingredient_want, "_name_1", sep="")
  first_ingredient_index <- which(colnames(clustered_beer_necessities)==first_ingredient_name)
  
  # Last ingredient
  last_ingredient_name <- get_last_ing_name_col(clustered_beer_necessities)
  last_ingredient_index <- which(colnames(clustered_beer_necessities)==last_ingredient_name)
  
  # Vector of all the ingredient column names
  ingredient_colnames <- names(clustered_beer_necessities)[first_ingredient_index:last_ingredient_index]
  
  # Non-ingredient column names we want to keep
  to_keep_col_names <- c("cluster_assignment", "name", "abv", "ibu", "srm", "style", "style_collapsed")

  gather_ingredients <- function(df, cols_to_gather) {
    to_keep_indices <- which(colnames(df) %in% to_keep_col_names)
    
    selected_df <- df[, c(to_keep_indices, first_ingredient_index:last_ingredient_index)]
    
    new_ing_indices <- which(colnames(selected_df) %in% cols_to_gather)    # indices will have changed since we pared down 
    
    df_gathered <- selected_df %>%
      gather_(
        key_col = "ing_keys",
        value_col = "ing_names",
        gather_cols = colnames(selected_df)[new_ing_indices]
      ) %>%
      mutate(
        count = 1
      )
    df_gathered
  }
  beer_gathered <- gather_ingredients(clustered_beer_necessities, ingredient_colnames)  # ingredient colnames defined above function
  
  # get a vector of all ingredient levels
  beer_gathered$ing_names <- factor(beer_gathered$ing_names)
  ingredient_levels <- levels(beer_gathered$ing_names) 
  
  # take out the level that's just an empty string
  # first, get all indices in ingredient_levels except for the one that's an empty string
  to_keep_levels <- !(c(1:length(ingredient_levels)) %in% which(ingredient_levels == ""))
  # then pare down ingredient_levels to only those indices
  ingredient_levels <- ingredient_levels[to_keep_levels]
  
  beer_gathered$ing_names <- as.character(beer_gathered$ing_names)
  
  spread_ingredients <- function(df) {
    df_spread <- df %>% 
      mutate(
        row = 1:nrow(df)        # add a unique idenfitier for each row. we'll drop this later
      ) %>%                                 # see hadley's comment on https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr
      spread(
        key = ing_names,
        value = count
      ) 
    return(df_spread)
  }
  
  beer_spread <- spread_ingredients(beer_gathered)
  
  select_spread_cols <- function(df) {
    to_keep_col_indices <- which(colnames(df) %in% to_keep_col_names)
    to_keep_ingredient_indices <- which(colnames(df) %in% ingredient_levels)
    
    to_keep_inds_all <- c(to_keep_col_indices, to_keep_ingredient_indices)
    
    new_df <- df %>% 
      select_(
        .dots = to_keep_inds_all
      )
    return(new_df)
  }
  beer_spread_selected <- select_spread_cols(beer_spread)
  
  
  # take out all rows that have no ingredients specified at all
  inds_to_remove <- apply(beer_spread_selected[, first_ingredient_index:last_ingredient_index], 
                          1, function(x) all(is.na(x)))
  beer_spread_no_na <- beer_spread_selected[ !inds_to_remove, ]
  
  
  get_ingredients_per_grouper <- function(df, grouper = "name") {
    df_grouped <- df %>%
      ungroup() %>% 
      group_by_(grouper)
    
    not_for_summing <- which(colnames(df_grouped) %in% to_keep_col_names)
    max_not_for_summing <- max(not_for_summing)
    
    per_grouper <- df_grouped %>% 
      select(-c(abv, ibu, srm)) %>%    # taking out temporarily
      summarise_if(
        is.numeric,              # need to make sure not summing abv, ibu, and srm with something like ! (names(.) %in% c("abv","ibu","srm")) or check that index > max_not_for_summing
        sum, na.rm = TRUE
        # -c(abv, ibu, srm)
      ) %>%
      mutate(
        total = rowSums(.[(max_not_for_summing + 1):ncol(.)], na.rm = TRUE)    
      )
    
    # send total to the second position
    per_grouper <- per_grouper %>% 
      select(
        name, total, everything()
      )
    
    # replace total column with more descriptive name
    names(per_grouper)[which(names(per_grouper) == "total")] <- paste0("total_", ingredient_want)
    
    return(per_grouper)
  }
  
  ingredients_per_grouper <- get_ingredients_per_grouper(beer_spread_selected, grouper)
  
}
```


* Now run the function with `ingredient_want` as first hops, then malt
* Then join the resulting dataframes and remove/reorder some columns


```r
# hops
ingredients_per_beer_hops <- pick_ingredient_get_beer(ingredient_want = "hops", 
                                                      clustered_beer_necessities, 
                                                      grouper = c("name", "style_collapsed"))
```

```
## Warning: attributes are not identical across measure variables; they will
## be dropped
```

```r
# malts
ingredients_per_beer_malt <- pick_ingredient_get_beer(ingredient_want = "malt", 
                                                      clustered_beer_necessities, 
                                                      grouper = c("name", "style_collapsed"))
```

```
## Warning: attributes are not identical across measure variables; they will
## be dropped
```

```r
# join em
beer_ingredients_join_first_ingredient <- left_join(clustered_beer_necessities, ingredients_per_beer_hops,
                                                    by = "name")
beer_ingredients_join <- left_join(beer_ingredients_join_first_ingredient, ingredients_per_beer_malt,
                                   by = "name")


# take out some unnecessary columns
unnecessary_cols <- c("styleId", "abv_scaled", "ibu_scaled", "srm_scaled", 
                      "hops_id", "malt_id", "glasswareId", "style.categoryId")
beer_ingredients_join <- beer_ingredients_join[, (! names(beer_ingredients_join) %in% unnecessary_cols)]

# if we also want to take out any of the malt_name_1, malt_name_2, etc. columns
more_unnecessary <- c("hops_name_|malt_name_")
beer_ingredients_join <- 
  beer_ingredients_join[, (! grepl(more_unnecessary, names(beer_ingredients_join)) == TRUE)]


# reorder columns a bit
beer_ingredients_join <- beer_ingredients_join %>% 
  select(
    id, name, total_hops, total_malt, everything(), -description
  )
```




Now we're left with something of a sparse matrix of all the ingredients compared to all the beers

|id     |name                                                         | total_hops| total_malt|cluster_assignment |style                                              |style_collapsed       | abv|  ibu| srm|glass   |hops_name                                      |malt_name                                                                      | Aged / Debittered Hops (Lambic)| Ahtanum| Alchemy| Amarillo| Apollo| Aramis| Azacca| Bravo| Brewer's Gold| Calypso| Cascade| Celeia| Centennial| Challenger| Chinook| Citra| Cluster| Columbus| Comet| Crystal| CTZ| East Kent Golding| El Dorado| Falconer's Flight| Fuggle (American)| Fuggle (English)| Fuggles| Galaxy| Galena| German Magnum| German Mandarina Bavaria| German Perle| German Polaris| German Tradition| Glacier| Golding (American)| Green Bullet| Hallertau Hallertauer Tradition| Hallertau Northern Brewer| Hallertauer (American)| Hallertauer Hersbrucker| Hops| Horizon| Jarrylo| Kent Goldings| Lemon Drop| Liberty| Magnum| Marynka| Mosaic| Motueka| Mount Hood| Nelson Sauvin| New Zealand Motueka| Northdown| Northern Brewer (American)| Nugget| Orbit| Pacific Jade| Pacifica| Palisades| Perle (American)| Phoenix| Saaz (American)| Saaz (Czech)| Saphir (German Organic)| Simcoe| Sorachi Ace| Southern Cross| Spalt| Spalt Select| Spalt Spalter| Sterling| Strisselspalt| Styrian Goldings| Summit| Target| Tettnang Tettnanger| Tettnanger (American)| Topaz| Tradition| Ultra| Warrior| Willamette| Zeus| Zythos| Abbey Malt| Acidulated Malt| Amber Malt| Aromatic Malt| Asheburne Mild Malt| Barley - Flaked| Barley - Malted| Barley - Roasted| Biscuit Malt| Black Malt| Black Malt - Debittered| Black Patent| Bonlander| Brown Malt| Brown Sugar| Cane Sugar| CaraAmber| Carafa I| Carafa II| Carafa III| CaraFoam| CaraHell| Caramel/Crystal Malt| Caramel/Crystal Malt - Dark| Caramel/Crystal Malt - Heritage| Caramel/Crystal Malt - Light| Caramel/Crystal Malt - Medium| Caramel/Crystal Malt - Organic| Caramel/Crystal Malt 10L| Caramel/Crystal Malt 120L| Caramel/Crystal Malt 150L| Caramel/Crystal Malt 15L| Caramel/Crystal Malt 20L| Caramel/Crystal Malt 300L| Caramel/Crystal Malt 30L| Caramel/Crystal Malt 40L| Caramel/Crystal Malt 45L| Caramel/Crystal Malt 50L| Caramel/Crystal Malt 55L| Caramel/Crystal Malt 60L| Caramel/Crystal Malt 75L| Caramel/Crystal Malt 80L| CaraMunich| CaraMunich II| CaraMunich III| CaraPils/Dextrin Malt| CaraRed| CaraStan| CaraVienne Malt| Carolina Rye Malt| Cherrywood Smoke Malt| Chocolate Malt| Corn - Flaked| Corn Grits| Crisp 77| Crystal 77| Extra Special Malt| Gladfield Pale| Golden Promise| Harrington 2-Row Base Malt| Honey| Honey Malt| Malted Rye| Maris Otter| Melanoidin Malt| Midnight Wheat| Mild Malt| Munich Malt| Munich Malt - Organic| Munich Malt - Type I| Munich Malt - Type II| Munich Malt 20L| Munich Malt 40L| Munich Wheat| Oats - Flaked| Oats - Malted| Oats - Rolled| Oats - Steel Cut (Pinhead Oats)| Pale Chocolate Malt| Pale Malt| Pale Malt - Organic| Palev| Pilsner Malt| Rahr 2-Row Malt| Rahr Special Pale| Rice - Hulls| Roast Malt| Rye - Flaked| Rye Malt| Samuel Adams two-row pale malt blend| Six-Row Pale Malt| Smoked Malt| Special B Malt| Special Roast| Sugar (Albion)| Two-Row Barley Malt| Two-Row Pale Malt| Two-Row Pale Malt - Organic| Two-Row Pale Malt - Toasted| Two-Row Pilsner Malt| Victory Malt| Vienna Malt| Wheat - Flaked| Wheat - Raw| Wheat - Red| Wheat - Torrified| Wheat Malt| Wheat Malt - White| White Wheat| Wyermann Vienna|
|:------|:------------------------------------------------------------|----------:|----------:|:------------------|:--------------------------------------------------|:---------------------|---:|----:|---:|:-------|:----------------------------------------------|:------------------------------------------------------------------------------|-------------------------------:|-------:|-------:|--------:|------:|------:|------:|-----:|-------------:|-------:|-------:|------:|----------:|----------:|-------:|-----:|-------:|--------:|-----:|-------:|---:|-----------------:|---------:|-----------------:|-----------------:|----------------:|-------:|------:|------:|-------------:|------------------------:|------------:|--------------:|----------------:|-------:|------------------:|------------:|-------------------------------:|-------------------------:|----------------------:|-----------------------:|----:|-------:|-------:|-------------:|----------:|-------:|------:|-------:|------:|-------:|----------:|-------------:|-------------------:|---------:|--------------------------:|------:|-----:|------------:|--------:|---------:|----------------:|-------:|---------------:|------------:|-----------------------:|------:|-----------:|--------------:|-----:|------------:|-------------:|--------:|-------------:|----------------:|------:|------:|-------------------:|---------------------:|-----:|---------:|-----:|-------:|----------:|----:|------:|----------:|---------------:|----------:|-------------:|-------------------:|---------------:|---------------:|----------------:|------------:|----------:|-----------------------:|------------:|---------:|----------:|-----------:|----------:|---------:|--------:|---------:|----------:|--------:|--------:|--------------------:|---------------------------:|-------------------------------:|----------------------------:|-----------------------------:|------------------------------:|------------------------:|-------------------------:|-------------------------:|------------------------:|------------------------:|-------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|----------:|-------------:|--------------:|---------------------:|-------:|--------:|---------------:|-----------------:|---------------------:|--------------:|-------------:|----------:|--------:|----------:|------------------:|--------------:|--------------:|--------------------------:|-----:|----------:|----------:|-----------:|---------------:|--------------:|---------:|-----------:|---------------------:|--------------------:|---------------------:|---------------:|---------------:|------------:|-------------:|-------------:|-------------:|-------------------------------:|-------------------:|---------:|-------------------:|-----:|------------:|---------------:|-----------------:|------------:|----------:|------------:|--------:|------------------------------------:|-----------------:|-----------:|--------------:|-------------:|--------------:|-------------------:|-----------------:|---------------------------:|---------------------------:|--------------------:|------------:|-----------:|--------------:|-----------:|-----------:|-----------------:|----------:|------------------:|-----------:|---------------:|
|b7SfHG |"Ah Me Joy" Porter                                           |          0|          0|3                  |Robust Porter                                      |Porter                | 5.4| 51.0|  40|NA      |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|PBEXhV |"Bison Eye Rye" Pale Ale &#124; 2 of 4 Part Pale Ale Series  |          0|          0|2                  |American-Style Pale Ale                            |Pale Ale              | 5.8| 51.0|   8|NA      |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|AXmvOd |"Dust Up" Cloudy Pale Ale &#124; 1 of 4 Part Pale Ale Series |          0|          0|2                  |American-Style Pale Ale                            |Pale Ale              | 5.4| 54.0|  11|NA      |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|Hr5A0t |"God Country" Kolsch                                         |          0|          0|6                  |German-Style Kölsch / Köln-Style Kölsch            |Kölsch                | 5.6| 28.2|   5|NA      |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|mrVjY4 |"Jemez Field Notes" Golden Lager                             |          0|          0|6                  |Golden or Blonde Ale                               |Blonde                | 4.9| 20.0|   5|NA      |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|xFM8w5 |#10 Hefewiezen                                               |          0|          0|6                  |South German-Style Hefeweizen / Hefeweissbier      |Wheat                 | 5.1| 11.0|   4|Pint    |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|hB0QeO |#9                                                           |          1|          2|6                  |American-Style Pale Ale                            |Pale Ale              | 5.1| 20.0|   9|Pint    |Apollo, Cascade                                |Caramel/Crystal Malt, Pale Malt                                                |                               0|       0|       0|        0|      1|      0|      0|     0|             0|       0|       1|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    1|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         1|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|m8f62Y |#KoLSCH                                                      |          0|          0|6                  |German-Style Kölsch / Köln-Style Kölsch            |Kölsch                | 4.8| 27.0|   3|Pilsner |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|35lHUq |'Inappropriate' Cream Ale                                    |          0|          0|6                  |American-Style Cream Ale or Lager                  |Lager                 | 5.3| 18.0|   5|Pint    |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|qbRV90 |'tis the Saison                                              |          0|          0|2                  |French & Belgian-Style Saison                      |Saison                | 7.0| 30.0|   7|Pint    |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|qhaIVA |(306) URBAN WHEAT BEER                                       |          0|          0|6                  |Belgian-Style White (or Wit) / Belgian-Style Wheat |Wheat                 | 5.0| 20.0|   9|NA      |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|VwR7Xg |(512) Bruin (A.K.A. Brown Bear)                              |          1|          4|4                  |American-Style Brown Ale                           |Brown                 | 7.6| 30.0|  21|Pint    |Fuggle (American)                              |Caramel/Crystal Malt, Chocolate Malt, Munich Malt, Two-Row Pale Malt - Organic |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 1|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    1|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              1|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           1|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           1|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|oJFZwK |(512) FOUR                                                   |          3|          4|1                  |Strong Ale                                         |Strong Ale            | 7.5| 35.0|   8|Pint    |East Kent Golding, Fuggle (English), Northdown |Caramel/Crystal Malt, Chocolate Malt, Maris Otter, Wheat Malt                  |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 1|         0|                 0|                 0|                1|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         1|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    1|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              1|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           1|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          1|                  0|           0|               0|
|ezGh5N |(512) IPA                                                    |          3|          3|5                  |American-Style India Pale Ale                      |India Pale Ale        | 7.0| 65.0|   8|Pint    |Columbus, Glacier, Simcoe                      |Caramel/Crystal Malt, Two-Row Pale Malt - Organic, Wheat Malt                  |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        1|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       1|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      1|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    1|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           1|                           0|                    0|            0|           0|              0|           0|           0|                 0|          1|                  0|           0|               0|
|2fXsvw |(512) Pale                                                   |          2|          3|2                  |American-Style Pale Ale                            |Pale Ale              | 6.0| 30.0|   7|Pint    |Amarillo, Mosaic, Nugget                       |Caramel/Crystal Malt, Two-Row Pale Malt - Organic, Wheat Malt                  |                               0|       0|       0|        1|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      1|       0|          0|             0|                   0|         0|                          0|      1|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    1|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           1|                           0|                    0|            0|           0|              0|           0|           0|                 0|          1|                  0|           0|               0|
|9O3QPg |(512) SIX                                                    |          2|          3|9                  |Belgian-Style Dubbel                               |Dubbel                | 7.5| 25.0|  28|Tulip   |Northdown, Saaz (American)                     |CaraMunich II, Pale Malt - Organic, Special B Malt                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         1|                          0|      0|     0|            0|        0|         0|                0|       0|               1|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             1|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   1|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              1|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|A78JSF |(512) THREE                                                  |          1|          3|1                  |Belgian-Style Tripel                               |Tripel                | 9.5| 22.0|  10|Pint    |Golding (American)                             |Oats - Malted, Pilsner Malt, Wheat Malt                                        |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  1|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             1|             0|                               0|                   0|         0|                   0|     0|            1|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          1|                  0|           0|               0|
|WKSYBT |(512) THREE (Cabernet Barrel Aged)                           |          0|          0|9                  |Belgian-Style Tripel                               |Tripel                | 9.5| 22.0|  40|NA      |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|
|X4KcGF |(512) TWO                                                    |          5|          3|7                  |Imperial or Double India Pale Ale                  |Double India Pale Ale | 9.0| 99.0|   9|Pint    |Columbus, Glacier, Horizon, Nugget, Simcoe     |Caramel/Crystal Malt, Two-Row Pale Malt - Organic, Wheat Malt                  |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        1|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       1|                  0|            0|                               0|                         0|                      0|                       0|    0|       1|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      1|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      1|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    1|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           1|                           0|                    0|            0|           0|              0|           0|           0|                 0|          1|                  0|           0|               0|
|bXwskR |(512) White IPA                                              |          0|          0|2                  |American-Style India Pale Ale                      |India Pale Ale        | 5.3| 55.0|   4|Pint    |NA                                             |NA                                                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|          0|               0|          0|             0|                   0|               0|               0|                0|            0|          0|                       0|            0|         0|          0|           0|          0|         0|        0|         0|          0|        0|        0|                    0|                           0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|          0|             0|              0|                     0|       0|        0|               0|                 0|                     0|              0|             0|          0|        0|          0|                  0|              0|              0|                          0|     0|          0|          0|           0|               0|              0|         0|           0|                     0|                    0|                     0|               0|               0|            0|             0|             0|             0|                               0|                   0|         0|                   0|     0|            0|               0|                 0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|                   0|                 0|                           0|                           0|                    0|            0|           0|              0|           0|           0|                 0|          0|                  0|           0|               0|

<!-- Per `style_collapsed` -->
<!-- ```{r} -->
<!-- kable(ingredients_per_style_collapsed[1:20, ]) -->
<!-- ``` -->






### Updated neural net with ingredients


![](./pour.jpg)



