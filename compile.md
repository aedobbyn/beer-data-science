# Data Science Musings on Beer
`r format(Sys.time(), '%B %d, %Y')`  





* Main question
    * Are there natural clusters in beer that are defined by styles? Or are style boundaries more or less arbitrary?
      * Unsupervised (k-means) clustering based on 
        * ABV (alcohol by volume), IBU (international bitterness units), SRM (measure of color)
        * Style centers defined by mean of ABV, IBU, and SRM
      * Neural net 
        * Can we predict a beer's style based on a number of attributes we 
      
* Answer
    * Looks more or less fluid: there aren't really pockets centered around a style
  

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

![](./taps.jpg)


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

![](compile_files/figure-html/unnamed-chunk-11-1.png)<!-- -->![](compile_files/figure-html/unnamed-chunk-11-2.png)<!-- -->


### Now add in the style centers (means) for collapsed styles

![](compile_files/figure-html/unnamed-chunk-12-1.png)<!-- -->




# Neural Net

* Can ABV, IBU, and SRM be used in a neural net to predict `style` or `style_collapsed`?


```
## 
## Attaching package: 'neuralnet'
```

```
## The following object is masked from 'package:dplyr':
## 
##     compute
```

```
## Loading required package: lattice
```

```
## 
## Attaching package: 'caret'
```

```
## The following object is masked from 'package:purrr':
## 
##     lift
```

```
## Warning in multinom(style ~ abv + srm + ibu, data = beer_train, maxit =
## 500, : groups 'Belgian-Style Blonde Ale' 'Fruit Cider' 'Herb and Spice
## Beer' 'Ordinary Bitter' 'Wood- and Barrel-Aged Beer' are empty
```

```
## # weights:  210 (164 variable)
## initial  value 766.222272 
## iter  10 value 597.495200
## iter  20 value 574.755181
## iter  30 value 544.658986
## iter  40 value 531.502759
## iter  50 value 516.746052
## iter  60 value 487.978464
## iter  70 value 449.470688
## iter  80 value 426.069663
## iter  90 value 404.941533
## iter 100 value 373.895730
## iter 110 value 356.526756
## iter 120 value 346.562146
## iter 130 value 342.765472
## iter 140 value 339.653571
## iter 150 value 337.815755
## iter 160 value 336.651480
## iter 170 value 336.128968
## iter 180 value 336.021964
## iter 190 value 335.987293
## iter 200 value 335.966918
## iter 210 value 335.951441
## iter 220 value 335.931329
## iter 230 value 335.910488
## iter 240 value 335.892223
## iter 250 value 335.887267
## iter 260 value 335.885324
## iter 270 value 335.882759
## iter 280 value 335.880758
## iter 290 value 335.878723
## iter 300 value 335.876919
## iter 310 value 335.876264
## iter 320 value 335.875948
## iter 330 value 335.875635
## iter 330 value 335.875635
## final  value 335.875635 
## converged
```

```
## Call:
## multinom(formula = style ~ abv + srm + ibu, data = beer_train, 
##     maxit = 500, trace = T)
## 
## Coefficients:
##                                                    (Intercept)         abv
## American-Style Barley Wine Ale                      -36.601366   4.2656737
## American-Style Black Ale                            -50.116734 -16.0173032
## American-Style Brown Ale                            -23.539038   3.3037348
## American-Style Cream Ale or Lager                     4.714746   1.6863181
## American-Style Imperial Stout                       -56.612270   1.9158787
## American-Style India Pale Ale                       -12.891516   0.8481676
## American-Style Lager                                 -2.812598   1.0242742
## American-Style Pale Ale                              -6.640340   0.9786344
## American-Style Pilsener                              19.884903  -5.5490872
## American-Style Premium Lager                         25.792198  -6.6821803
## American-Style Sour Ale                              -6.581725   2.2360543
## American-Style Stout                                -18.125035   2.1811436
## Belgian-Style Dark Strong Ale                       -26.223272   4.3952080
## Belgian-Style Dubbel                                -24.173591   4.0198400
## Belgian-Style Pale Ale                              -21.018802   2.0424494
## Belgian-Style Tripel                                -27.289024   5.1163911
## Belgian-Style White (or Wit) / Belgian-Style Wheat   -3.589719   1.8497253
## Berliner-Style Weisse (Wheat)                        -0.476907   0.9083563
## Brown Porter                                        -13.096523   0.7199319
## Extra Special Bitter                                 -7.233744  -0.6866503
## French & Belgian-Style Saison                       -12.617696   3.3528317
## Fruit Beer                                          -10.823401   1.8852713
## German-Style Doppelbock                             -25.485296   4.0215547
## German-Style Kölsch / Köln-Style Kölsch              -2.598662   1.2336799
## German-Style Märzen                                  -8.158632   1.8648957
## German-Style Pilsener                                -4.382119   1.0550621
## Golden or Blonde Ale                                 -4.287852   1.4083026
## Imperial or Double India Pale Ale                   -33.546809   2.8918992
## Irish-Style Red Ale                                  -2.962251   0.4073989
## Light American Wheat Ale or Lager with Yeast        -13.786799   2.6862626
## Oatmeal Stout                                       -23.068787   1.0913599
## Other Belgian-Style Ales                            -29.546108   4.3894143
## Pumpkin Beer                                        -10.998401   2.2524789
## Robust Porter                                       -31.006887   1.8279612
## Rye Ale or Lager with or without Yeast              -23.458841   2.5298327
## Scotch Ale                                          -25.266278   3.9504400
## Session India Pale Ale                               12.813474  -4.8086600
## South German-Style Hefeweizen / Hefeweissbier        -1.920481   1.6157114
## Specialty Beer                                       -9.538765   1.6235603
## Strong Ale                                          -29.848546   4.2574791
## Sweet or Cream Stout                                -26.998779   2.2937106
##                                                             srm
## American-Style Barley Wine Ale                     -0.080437232
## American-Style Black Ale                            2.216290865
## American-Style Brown Ale                            0.152563159
## American-Style Cream Ale or Lager                  -2.277367017
## American-Style Imperial Stout                       0.941123150
## American-Style India Pale Ale                      -0.146640783
## American-Style Lager                               -0.334072676
## American-Style Pale Ale                            -0.279188758
## American-Style Pilsener                            -0.576719174
## American-Style Premium Lager                        0.530462785
## American-Style Sour Ale                            -0.577600316
## American-Style Stout                                0.291460182
## Belgian-Style Dark Strong Ale                      -0.001738636
## Belgian-Style Dubbel                                0.104054588
## Belgian-Style Pale Ale                             -0.039649226
## Belgian-Style Tripel                               -1.007468211
## Belgian-Style White (or Wit) / Belgian-Style Wheat -0.363900973
## Berliner-Style Weisse (Wheat)                      -0.516225292
## Brown Porter                                        0.244219722
## Extra Special Bitter                               -0.055737111
## French & Belgian-Style Saison                      -0.768066883
## Fruit Beer                                          0.032397635
## German-Style Doppelbock                             0.127963199
## German-Style Kölsch / Köln-Style Kölsch            -0.833948273
## German-Style Märzen                                -0.156256915
## German-Style Pilsener                              -0.623959060
## Golden or Blonde Ale                               -0.354156239
## Imperial or Double India Pale Ale                  -0.134132708
## Irish-Style Red Ale                                -0.041682962
## Light American Wheat Ale or Lager with Yeast       -0.222204369
## Oatmeal Stout                                       0.439956384
## Other Belgian-Style Ales                           -0.245417866
## Pumpkin Beer                                       -0.004037413
## Robust Porter                                       0.515995951
## Rye Ale or Lager with or without Yeast             -0.014048032
## Scotch Ale                                         -0.027588832
## Session India Pale Ale                             -0.247159270
## South German-Style Hefeweizen / Hefeweissbier      -0.438331181
## Specialty Beer                                     -0.091150946
## Strong Ale                                         -0.210523217
## Sweet or Cream Stout                                0.453770600
##                                                              ibu
## American-Style Barley Wine Ale                      0.2187462015
## American-Style Black Ale                            1.5141756326
## American-Style Brown Ale                            0.0002142517
## American-Style Cream Ale or Lager                  -0.1785433249
## American-Style Imperial Stout                       0.3740933761
## American-Style India Pale Ale                       0.3035421462
## American-Style Lager                               -0.0152641327
## American-Style Pale Ale                             0.1775608008
## American-Style Pilsener                             0.2193152478
## American-Style Premium Lager                       -0.3645968135
## American-Style Sour Ale                            -0.0506795646
## American-Style Stout                               -0.0811585731
## Belgian-Style Dark Strong Ale                      -0.1312843807
## Belgian-Style Dubbel                               -0.1462150075
## Belgian-Style Pale Ale                              0.2287592520
## Belgian-Style Tripel                                0.0082217912
## Belgian-Style White (or Wit) / Belgian-Style Wheat -0.1422756071
## Berliner-Style Weisse (Wheat)                      -0.0971725886
## Brown Porter                                        0.1314943116
## Extra Special Bitter                                0.3067561107
## French & Belgian-Style Saison                      -0.0015704399
## Fruit Beer                                         -0.0404700756
## German-Style Doppelbock                            -0.1292722650
## German-Style Kölsch / Köln-Style Kölsch             0.0773804892
## German-Style Märzen                                -0.0512373694
## German-Style Pilsener                               0.1157871170
## Golden or Blonde Ale                                0.0383142673
## Imperial or Double India Pale Ale                   0.3575231747
## Irish-Style Red Ale                                 0.0214079413
## Light American Wheat Ale or Lager with Yeast        0.0143457470
## Oatmeal Stout                                       0.1413541449
## Other Belgian-Style Ales                            0.1209861246
## Pumpkin Beer                                       -0.1043526591
## Robust Porter                                       0.1946430169
## Rye Ale or Lager with or without Yeast              0.2281879989
## Scotch Ale                                         -0.0056043873
## Session India Pale Ale                              0.3561610811
## South German-Style Hefeweizen / Hefeweissbier      -0.1560850327
## Specialty Beer                                      0.0735303106
## Strong Ale                                          0.1541534567
## Sweet or Cream Stout                                0.0125157291
## 
## Residual Deviance: 671.7513 
## AIC: 999.7513
```

```
## Warning in multinom(style_collapsed ~ abv + srm + ibu, data =
## beer_necessities_train, : groups 'Adambier' 'American-Style Malt Liquor'
## 'Apple Wine' 'Bamberg-Style Bock Rauchbier' 'Bamberg-Style Helles
## Rauchbier' 'Belgian-Style Gueuze Lambic' 'Common Cider' 'Common Perry'
## 'Cyser (Apple Melomel)' 'Dry Mead' 'Dutch-Style Kuit, Kuyt or Koyt' 'Energy
## Enhanced Malt Beverage' 'English Cider' 'French Cider' 'Fruit Cider'
## 'German-Style Eisbock' 'German-Style Leichtbier' 'Ginjo Beer or Sake-Yeast
## Beer' 'Metheglin' 'Mixed Culture Brett Beer' 'New England Cider' 'Non-
## Alcoholic (Beer) Malt Beverages' 'Open Category Mead' 'Other Fruit Melomel'
## 'Other Specialty Cider or Perry' 'Pyment (Grape Melomel)' 'Scottish-Style
## Light Ale' 'Semi-Sweet Mead' 'South German-Style Kristall Weizen / Kristall
## Weissbier' 'Sweet Mead' 'Traditional Perry' are empty
```

```
## # weights:  385 (304 variable)
## initial  value 6450.551051 
## iter  10 value 5407.336147
## iter  20 value 5133.291581
## iter  30 value 4942.956697
## iter  40 value 4871.020552
## iter  50 value 4773.588628
## iter  60 value 4702.315976
## iter  70 value 4609.653813
## iter  80 value 4524.332985
## iter  90 value 4421.075194
## iter 100 value 4334.479457
## iter 110 value 4248.032949
## iter 120 value 4159.071340
## iter 130 value 4011.567449
## iter 140 value 3916.086495
## iter 150 value 3854.744865
## iter 160 value 3797.660971
## iter 170 value 3756.648181
## iter 180 value 3714.854079
## iter 190 value 3691.586458
## iter 200 value 3660.004566
## iter 210 value 3644.776061
## iter 220 value 3634.346008
## iter 230 value 3625.705677
## iter 240 value 3620.453976
## iter 250 value 3617.827110
## iter 260 value 3615.123292
## iter 270 value 3613.415937
## iter 280 value 3612.145878
## iter 290 value 3611.498825
## iter 300 value 3611.075040
## iter 310 value 3610.651053
## iter 320 value 3610.185216
## iter 330 value 3610.008095
## iter 340 value 3609.885366
## iter 350 value 3609.816557
## iter 360 value 3609.762982
## iter 370 value 3609.694181
## iter 380 value 3609.661070
## iter 390 value 3609.638680
## iter 400 value 3609.614240
## iter 410 value 3609.580007
## iter 420 value 3609.534709
## iter 430 value 3609.497419
## iter 440 value 3609.452277
## iter 450 value 3609.429924
## iter 460 value 3609.403149
## iter 470 value 3609.383473
## iter 480 value 3609.376739
## iter 490 value 3609.373559
## iter 500 value 3609.371219
## final  value 3609.371219 
## stopped after 500 iterations
```

```
## Call:
## multinom(formula = style_collapsed ~ abv + srm + ibu, data = beer_necessities_train, 
##     maxit = 500, trace = T)
## 
## Coefficients:
##                                                           (Intercept)
## Amber                                                      6.78445551
## American-Style Märzen / Oktoberfest                        2.85464152
## Bamberg-Style Märzen Rauchbier                             0.23084971
## Bamberg-Style Weiss (Smoke) Rauchbier (Dunkel or Helles)   1.16033974
## Barley Wine                                              -11.90440926
## Barrel-Aged                                               -7.82672435
## Belgian-style Fruit Beer                                   4.70921618
## Belgian-Style Fruit Lambic                                -8.27460710
## Belgian-Style Lambic                                       2.49913373
## Belgian-Style Quadrupel                                  -10.40324093
## Belgian-Style Table Beer                                   5.85551179
## Bitter                                                     3.61986438
## Black                                                     -9.25991915
## Blonde                                                     4.78687069
## Braggot                                                   -5.80724136
## Brett Beer                                               -12.83483607
## Brown                                                     -0.03093849
## California Common Beer                                     3.21432532
## Chili Pepper Beer                                          3.74972216
## Chocolate / Cocoa-Flavored Beer                           -1.23420750
## Coffee-Flavored Beer                                      -6.85280264
## Contemporary Gose                                          9.58353336
## Dark American-Belgo-Style Ale                            -14.75660891
## Dortmunder / European-Style Export                         0.97884421
## Double India Pale Ale                                    -11.23938537
## Dubbel                                                    -3.78914154
## English-Style Dark Mild Ale                               16.08422274
## English-Style Pale Mild Ale                               10.25533657
## English-Style Summer Ale                                  11.03061144
## European-Style Dark / Münchner Dunkel                      3.16815119
## Field Beer                                                -0.58233960
## Flavored Malt Beverage                                    -5.40773732
## French-Style Bière de Garde                               -4.85826695
## Fresh "Wet" Hop Ale                                       -2.63074449
## Fruit Beer                                                 6.15407770
## German-Style Doppelbock                                   -6.69165116
## German-Style Heller Bock/Maibock                          -2.81527502
## German-Style Leichtes Weizen / Weissbier                   1.92237113
## German-Style Märzen                                        3.49512613
## German-Style Oktoberfest / Wiesen (Meadow)                 0.47122924
## German-Style Rye Ale (Roggenbier) with or without Yeast    7.03253918
## German-Style Schwarzbier                                  -0.56696197
## Gluten-Free Beer                                           5.59850794
## Grodziskie                                                14.86961758
## Herb and Spice Beer                                       -1.74704145
## Historical Beer                                            0.04190628
## India Pale Ale                                             0.01517886
## Kellerbier (Cellar beer) or Zwickelbier - Ale              9.47214834
## Kölsch                                                     7.64019557
## Lager                                                      3.14906182
## Leipzig-Style Gose                                         8.36279822
## Münchner (Munich)-Style Helles                             7.35076039
## Old Ale                                                  -11.23916062
## Other Belgian-Style Ales                                  -3.67242471
## Pale Ale                                                   4.30274142
## Pale American-Belgo-Style Ale                             -3.16884814
## Pilsener                                                   2.55292217
## Porter                                                    -4.48751288
## Pumpkin Beer                                              -1.27068047
## Red                                                       -0.02594817
## Saison                                                     1.34616544
## Scotch Ale                                                -8.33543869
## Scottish-Style Export Ale                                 -1.61581242
## Scottish-Style Heavy Ale                                  -9.62037569
## Session Beer                                              10.29903489
## Sour                                                       0.52896225
## South German-Style Bernsteinfarbenes Weizen / Weissbier    2.35110372
## South German-Style Dunkel Weizen / Dunkel Weissbier        1.66536073
## South German-Style Weizenbock / Weissbock                 -3.38364438
## Specialty Beer                                            -2.06833032
## Stout                                                    -11.79138930
## Strong Ale                                                -7.86245170
## Traditional German-Style Bock                             -1.57290303
## Tripel                                                    -5.34972244
## Wheat                                                      9.06517063
## Wild Beer                                                 -3.20961725
##                                                                  abv
## Amber                                                    -0.87910606
## American-Style Märzen / Oktoberfest                       0.34979450
## Bamberg-Style Märzen Rauchbier                            0.43832805
## Bamberg-Style Weiss (Smoke) Rauchbier (Dunkel or Helles) -0.27648665
## Barley Wine                                               1.84965231
## Barrel-Aged                                               1.55132171
## Belgian-style Fruit Beer                                  0.44745880
## Belgian-Style Fruit Lambic                                1.40279662
## Belgian-Style Lambic                                      1.81723144
## Belgian-Style Quadrupel                                   1.86315128
## Belgian-Style Table Beer                                 -0.07254224
## Bitter                                                   -0.24874937
## Black                                                     0.21863802
## Blonde                                                    0.67067807
## Braggot                                                   1.77708720
## Brett Beer                                                1.70032246
## Brown                                                     0.35246289
## California Common Beer                                   -0.81013958
## Chili Pepper Beer                                         0.06252898
## Chocolate / Cocoa-Flavored Beer                           0.27424335
## Coffee-Flavored Beer                                      0.67632212
## Contemporary Gose                                        -0.56297458
## Dark American-Belgo-Style Ale                             0.98193764
## Dortmunder / European-Style Export                        0.61072510
## Double India Pale Ale                                     1.44806504
## Dubbel                                                    1.32866146
## English-Style Dark Mild Ale                              -3.71574521
## English-Style Pale Mild Ale                              -1.55466120
## English-Style Summer Ale                                 -1.47915350
## European-Style Dark / Münchner Dunkel                    -0.17155103
## Field Beer                                                0.83996005
## Flavored Malt Beverage                                    5.11875661
## French-Style Bière de Garde                               1.38604085
## Fresh "Wet" Hop Ale                                       0.64701086
## Fruit Beer                                                0.02167250
## German-Style Doppelbock                                   1.44186265
## German-Style Heller Bock/Maibock                          1.07188826
## German-Style Leichtes Weizen / Weissbier                  0.83829033
## German-Style Märzen                                      -0.10544940
## German-Style Oktoberfest / Wiesen (Meadow)                0.77030076
## German-Style Rye Ale (Roggenbier) with or without Yeast  -1.33320905
## German-Style Schwarzbier                                 -0.11867949
## Gluten-Free Beer                                          0.06690661
## Grodziskie                                               -2.26582518
## Herb and Spice Beer                                       0.99010928
## Historical Beer                                           0.53769720
## India Pale Ale                                            0.10525698
## Kellerbier (Cellar beer) or Zwickelbier - Ale            -0.62993132
## Kölsch                                                   -0.03937179
## Lager                                                     0.53711927
## Leipzig-Style Gose                                       -0.02363246
## Münchner (Munich)-Style Helles                           -0.15789407
## Old Ale                                                   1.80813642
## Other Belgian-Style Ales                                  1.09210359
## Pale Ale                                                  0.08343313
## Pale American-Belgo-Style Ale                             0.09172367
## Pilsener                                                  0.97746280
## Porter                                                    0.53862356
## Pumpkin Beer                                              1.02760416
## Red                                                       0.57755898
## Saison                                                    0.99445705
## Scotch Ale                                                1.46199714
## Scottish-Style Export Ale                                 0.74491962
## Scottish-Style Heavy Ale                                  1.64881019
## Session Beer                                             -1.80033440
## Sour                                                      1.11739312
## South German-Style Bernsteinfarbenes Weizen / Weissbier   0.95898537
## South German-Style Dunkel Weizen / Dunkel Weissbier       0.42578147
## South German-Style Weizenbock / Weissbock                 1.47320584
## Specialty Beer                                            1.23998453
## Stout                                                     0.93631064
## Strong Ale                                                1.72036090
## Traditional German-Style Bock                             0.87355711
## Tripel                                                    1.76327067
## Wheat                                                     0.13972087
## Wild Beer                                                 0.80198641
##                                                                   srm
## Amber                                                     0.031255197
## American-Style Märzen / Oktoberfest                      -0.073421365
## Bamberg-Style Märzen Rauchbier                            0.045755754
## Bamberg-Style Weiss (Smoke) Rauchbier (Dunkel or Helles)  0.136085432
## Barley Wine                                              -0.045201713
## Barrel-Aged                                               0.034536700
## Belgian-style Fruit Beer                                 -0.471245148
## Belgian-Style Fruit Lambic                                0.125861907
## Belgian-Style Lambic                                     -0.566197696
## Belgian-Style Quadrupel                                   0.064530342
## Belgian-Style Table Beer                                 -0.399637346
## Bitter                                                   -0.017387991
## Black                                                     0.231174348
## Blonde                                                   -0.430829759
## Braggot                                                  -0.264473607
## Brett Beer                                               -0.304900924
## Brown                                                     0.086900200
## California Common Beer                                    0.047177674
## Chili Pepper Beer                                        -0.233596543
## Chocolate / Cocoa-Flavored Beer                           0.050866786
## Coffee-Flavored Beer                                      0.159912425
## Contemporary Gose                                         0.042105057
## Dark American-Belgo-Style Ale                             0.143246461
## Dortmunder / European-Style Export                       -0.411095347
## Double India Pale Ale                                    -0.201557750
## Dubbel                                                    0.047905242
## English-Style Dark Mild Ale                               0.337611195
## English-Style Pale Mild Ale                               0.137499513
## English-Style Summer Ale                                 -0.222136414
## European-Style Dark / Münchner Dunkel                     0.079014313
## Field Beer                                               -0.200681922
## Flavored Malt Beverage                                    0.808290181
## French-Style Bière de Garde                              -0.050598824
## Fresh "Wet" Hop Ale                                      -0.149764828
## Fruit Beer                                               -0.051703470
## German-Style Doppelbock                                   0.074023282
## German-Style Heller Bock/Maibock                         -0.078989644
## German-Style Leichtes Weizen / Weissbier                 -0.639887120
## German-Style Märzen                                       0.031485691
## German-Style Oktoberfest / Wiesen (Meadow)               -0.104106018
## German-Style Rye Ale (Roggenbier) with or without Yeast  -0.018075623
## German-Style Schwarzbier                                  0.178455887
## Gluten-Free Beer                                         -1.235774510
## Grodziskie                                               -0.760465681
## Herb and Spice Beer                                      -0.013869923
## Historical Beer                                           0.014021537
## India Pale Ale                                           -0.115329821
## Kellerbier (Cellar beer) or Zwickelbier - Ale            -0.667033998
## Kölsch                                                   -0.505118060
## Lager                                                    -0.091218388
## Leipzig-Style Gose                                       -0.225823155
## Münchner (Munich)-Style Helles                           -0.149263855
## Old Ale                                                   0.036615644
## Other Belgian-Style Ales                                  0.035747609
## Pale Ale                                                 -0.158645951
## Pale American-Belgo-Style Ale                            -0.319474201
## Pilsener                                                 -0.663826748
## Porter                                                    0.202237645
## Pumpkin Beer                                             -0.003873822
## Red                                                       0.021601889
## Saison                                                   -0.220952852
## Scotch Ale                                                0.103014947
## Scottish-Style Export Ale                                 0.008004364
## Scottish-Style Heavy Ale                                  0.058224453
## Session Beer                                             -0.431073285
## Sour                                                     -0.022872632
## South German-Style Bernsteinfarbenes Weizen / Weissbier  -0.576252620
## South German-Style Dunkel Weizen / Dunkel Weissbier       0.095961865
## South German-Style Weizenbock / Weissbock                -0.208931963
## Specialty Beer                                           -0.066087174
## Stout                                                     0.274266898
## Strong Ale                                               -0.005585901
## Traditional German-Style Bock                             0.042026044
## Tripel                                                   -0.194396969
## Wheat                                                    -0.223649771
## Wild Beer                                                -0.271439857
##                                                                    ibu
## Amber                                                    -1.086682e-01
## American-Style Märzen / Oktoberfest                      -1.155545e-01
## Bamberg-Style Märzen Rauchbier                           -2.011351e-01
## Bamberg-Style Weiss (Smoke) Rauchbier (Dunkel or Helles) -1.194426e-01
## Barley Wine                                              -3.092253e-03
## Barrel-Aged                                              -6.148506e-02
## Belgian-style Fruit Beer                                 -2.480969e-01
## Belgian-Style Fruit Lambic                               -1.978310e-01
## Belgian-Style Lambic                                     -9.427069e-01
## Belgian-Style Quadrupel                                  -1.091181e-01
## Belgian-Style Table Beer                                 -9.589716e-02
## Bitter                                                   -1.164255e-02
## Black                                                     6.108172e-02
## Blonde                                                   -1.011486e-01
## Braggot                                                  -1.856168e-01
## Brett Beer                                                3.500311e-02
## Brown                                                    -4.895033e-02
## California Common Beer                                    2.446326e-03
## Chili Pepper Beer                                        -6.543680e-02
## Chocolate / Cocoa-Flavored Beer                          -5.789379e-02
## Coffee-Flavored Beer                                     -2.298112e-02
## Contemporary Gose                                        -3.765272e-01
## Dark American-Belgo-Style Ale                             5.410388e-02
## Dortmunder / European-Style Export                       -9.637932e-02
## Double India Pale Ale                                     8.342151e-02
## Dubbel                                                   -1.538359e-01
## English-Style Dark Mild Ale                              -3.290653e-01
## English-Style Pale Mild Ale                              -2.310817e-01
## English-Style Summer Ale                                 -6.968223e-02
## European-Style Dark / Münchner Dunkel                    -1.263866e-01
## Field Beer                                               -8.155592e-02
## Flavored Malt Beverage                                   -8.704089e+00
## French-Style Bière de Garde                              -1.037638e-01
## Fresh "Wet" Hop Ale                                       1.211334e-02
## Fruit Beer                                               -2.058551e-01
## German-Style Doppelbock                                  -1.008509e-01
## German-Style Heller Bock/Maibock                         -7.417531e-02
## German-Style Leichtes Weizen / Weissbier                 -1.554726e-01
## German-Style Märzen                                      -1.066307e-01
## German-Style Oktoberfest / Wiesen (Meadow)               -1.414804e-01
## German-Style Rye Ale (Roggenbier) with or without Yeast  -5.961408e-02
## German-Style Schwarzbier                                 -7.827876e-02
## Gluten-Free Beer                                         -4.041218e-02
## Grodziskie                                               -1.270179e-02
## Herb and Spice Beer                                      -8.440343e-02
## Historical Beer                                          -1.402774e-01
## India Pale Ale                                            7.423169e-02
## Kellerbier (Cellar beer) or Zwickelbier - Ale            -1.257223e-01
## Kölsch                                                   -7.926624e-02
## Lager                                                    -7.270023e-02
## Leipzig-Style Gose                                       -2.883220e-01
## Münchner (Munich)-Style Helles                           -1.542969e-01
## Old Ale                                                  -5.474956e-02
## Other Belgian-Style Ales                                 -9.455204e-02
## Pale Ale                                                  2.154753e-05
## Pale American-Belgo-Style Ale                             8.143202e-02
## Pilsener                                                 -5.256129e-02
## Porter                                                   -3.295409e-02
## Pumpkin Beer                                             -1.370215e-01
## Red                                                      -3.058574e-02
## Saison                                                   -8.822316e-02
## Scotch Ale                                               -9.806664e-02
## Scottish-Style Export Ale                                -1.660923e-01
## Scottish-Style Heavy Ale                                 -7.444515e-02
## Session Beer                                              6.615682e-02
## Sour                                                     -2.264244e-01
## South German-Style Bernsteinfarbenes Weizen / Weissbier  -2.399839e-01
## South German-Style Dunkel Weizen / Dunkel Weissbier      -2.574169e-01
## South German-Style Weizenbock / Weissbock                -1.664591e-01
## Specialty Beer                                           -1.040340e-01
## Stout                                                     1.463928e-02
## Strong Ale                                               -6.133773e-02
## Traditional German-Style Bock                            -1.434498e-01
## Tripel                                                   -8.305720e-02
## Wheat                                                    -2.030913e-01
## Wild Beer                                                -2.096066e-02
## 
## Residual Deviance: 7218.742 
## AIC: 7826.742
```

```
##        Overall
## abv 117.874770
## srm  16.719668
## ibu   7.084952
```

```
##      Overall
## abv 72.93710
## srm 15.85187
## ibu 17.70964
```

```
##  Accuracy     Kappa 
## 0.3606397 0.3184760
```

```
##    Accuracy       Kappa 
##  0.06354873 -0.00283939
```


### Ingredients




```r
get_last_ing_name_col <- function(df) {
  for (col in names(df)) {
    if (grepl(paste(ingredient_want, "_name_", sep = ""), col) == TRUE) {
      name_last_ing_col <- col
    }
  }
  return(name_last_ing_col)
}
```


**Gather some global variables**

* We set `ingredient_want` at the outset: this can be `hops`, `malt`, or other ingredients like `yeast` if we pull that in
* Once ingredients have been split out from the concatenated string into columns like `malt_name_1`, `malt_name_2`, etc., we need to find the range of these columns; there will be a different number of malt columns than hops columns, for instance
    * The first one will be `<ingredient>_name_1` 
        * From this we can find the index of this column 
    * We get the name of last one with the `get_last_ing_name_col` function
* Then we save a vector of all the ingredient column names in `ingredient_colnames`
    * We make this a global variable because it will stay constant even if the indices change
    
* `to_keep_col_names` is a vector of all non-ingredient column names


```r
# Data
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

```r
# Ingredient we want to spread out
ingredient_want <- "hops"

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
```

**Gather**

* Inside `gather_ingredients` we:
    * Take out superflous column names that are not in `to_keep_col_names` or one of the ingredient columns
    * Find what the new ingredient column indices are, since they'll have changed after we pared down
    * Actually do the gathering: lump all of the ingredient columns (e.g., `hops_name_1`) into one long column, `ing_keys` and all the actual ingredient names (e.g., Cascade) into `ing_names`
    


```r
gather_ingredients <- function(df, cols_to_gather) {
  to_keep_indices <- which(colnames(df) %in% to_keep_col_names)
  
  selected_df <- df[, c(to_keep_indices, first_ingredient_index:last_ingredient_index)]
  
  new_ing_indices <- which(colnames(selected_df) %in% cols_to_gather)    
  
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
beer_gathered <- gather_ingredients(clustered_beer_necessities, ingredient_colnames)  
```

* Get a vector of all ingredient levels and take out the one that's an empty string
* We'll use this vector of ingredient levels in `select_spread_cols()` below

```r
beer_gathered$ing_names <- factor(beer_gathered$ing_names)
ingredient_levels <- levels(beer_gathered$ing_names)

to_keep_levels <- !(c(1:length(ingredient_levels)) %in% which(ingredient_levels == ""))
ingredient_levels <- ingredient_levels[to_keep_levels]

beer_gathered$ing_names <- as.character(beer_gathered$ing_names)
```


**Spread**
* We take what was previously the `value` in our gathered dataframe, the actual ingredient names (Cascade, Centennial) and make that our `key`; it'll form the new column names
    * The new `value` is `value` is count; it'll populate the row cells
        * If a given row has a certain ingredient, it gets a 1 in the corresponding cell, an NA otherwise
* We add a unique idenfitier for each row with `row`, which we'll drop later (see [Hadley's SO comment](https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr))


```r
spread_ingredients <- function(df) {
  df_spread <- df %>% 
    mutate(
      row = 1:nrow(df)        
    ) %>%                   
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


# Can specify multiple groupers
get_ingredients_per_grouper <- function(df, grouper) {
  df_grouped <- df %>%
    ungroup() %>% 
    group_by_(grouper)
    
  not_for_summing <- which(colnames(df_grouped) %in% to_keep_col_names)
  max_not_for_summing <- max(not_for_summing)   # find the first ingredient column we want to sum over
  
  per_grouper <- df_grouped %>% 
    select(-c(abv, ibu, srm)) %>% 
    summarise_if(
      is.numeric,
      sum, na.rm = TRUE
    ) %>%
    mutate(
      total = rowSums(.[(max_not_for_summing + 1):ncol(.)], na.rm = TRUE)    
    )
  
  return(per_grouper)
}
ingredients_per_beer <- get_ingredients_per_grouper(beer_spread_selected, c("name", "style_collapsed"))

ingredients_per_style_collapsed <- get_ingredients_per_grouper(beer_spread_selected, "style_collapsed")
```


Now we're left with something of a sparse matrix of all the ingredients compared to all the beers

|name                                                        | Aged / Debittered Hops (Lambic)| Ahtanum| Alchemy| Amarillo| Apollo| Aramis| Azacca| Bravo| Brewer's Gold| Calypso| Cascade| Celeia| Centennial| Challenger| Chinook| Citra| Cluster| Columbus| Comet| Crystal| CTZ| East Kent Golding| El Dorado| Falconer's Flight| Fuggle (American)| Fuggle (English)| Fuggles| Galaxy| Galena| German Magnum| German Mandarina Bavaria| German Perle| German Polaris| German Tradition| Glacier| Golding (American)| Green Bullet| Hallertau Hallertauer Tradition| Hallertau Northern Brewer| Hallertauer (American)| Hallertauer Hersbrucker| Hops| Horizon| Jarrylo| Kent Goldings| Lemon Drop| Liberty| Magnum| Marynka| Mosaic| Motueka| Mount Hood| Nelson Sauvin| New Zealand Motueka| Northdown| Northern Brewer (American)| Nugget| Orbit| Pacific Jade| Pacifica| Palisades| Perle (American)| Phoenix| Saaz (American)| Saaz (Czech)| Saphir (German Organic)| Simcoe| Sorachi Ace| Southern Cross| Spalt| Spalt Select| Spalt Spalter| Sterling| Strisselspalt| Styrian Goldings| Summit| Target| Tettnang Tettnanger| Tettnanger (American)| Topaz| Tradition| Ultra| Warrior| Willamette| Zeus| Zythos| total|
|:-----------------------------------------------------------|-------------------------------:|-------:|-------:|--------:|------:|------:|------:|-----:|-------------:|-------:|-------:|------:|----------:|----------:|-------:|-----:|-------:|--------:|-----:|-------:|---:|-----------------:|---------:|-----------------:|-----------------:|----------------:|-------:|------:|------:|-------------:|------------------------:|------------:|--------------:|----------------:|-------:|------------------:|------------:|-------------------------------:|-------------------------:|----------------------:|-----------------------:|----:|-------:|-------:|-------------:|----------:|-------:|------:|-------:|------:|-------:|----------:|-------------:|-------------------:|---------:|--------------------------:|------:|-----:|------------:|--------:|---------:|----------------:|-------:|---------------:|------------:|-----------------------:|------:|-----------:|--------------:|-----:|------------:|-------------:|--------:|-------------:|----------------:|------:|------:|-------------------:|---------------------:|-----:|---------:|-----:|-------:|----------:|----:|------:|-----:|
|¡Ándale! Pale Ale                                           |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     0|
|'Inappropriate' Cream Ale                                   |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     0|
|'tis the Saison                                             |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     0|
|‘39 Red IPA                                                 |                               0|       0|       0|        0|      0|      0|      0|     1|             0|       0|       1|      0|          0|          0|       0|     0|       0|        1|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     3|
|"Ah Me Joy" Porter                                          |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     0|
|"Bison Eye Rye" Pale Ale &#124; 2 of 4 Part Pale Ale Series |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     0|

Per `style_collapsed`

|style_collapsed          | Aged / Debittered Hops (Lambic)| Ahtanum| Alchemy| Amarillo| Apollo| Aramis| Azacca| Bravo| Brewer's Gold| Calypso| Cascade| Celeia| Centennial| Challenger| Chinook| Citra| Cluster| Columbus| Comet| Crystal| CTZ| East Kent Golding| El Dorado| Falconer's Flight| Fuggle (American)| Fuggle (English)| Fuggles| Galaxy| Galena| German Magnum| German Mandarina Bavaria| German Perle| German Polaris| German Tradition| Glacier| Golding (American)| Green Bullet| Hallertau Hallertauer Tradition| Hallertau Northern Brewer| Hallertauer (American)| Hallertauer Hersbrucker| Hops| Horizon| Jarrylo| Kent Goldings| Lemon Drop| Liberty| Magnum| Marynka| Mosaic| Motueka| Mount Hood| Nelson Sauvin| New Zealand Motueka| Northdown| Northern Brewer (American)| Nugget| Orbit| Pacific Jade| Pacifica| Palisades| Perle (American)| Phoenix| Saaz (American)| Saaz (Czech)| Saphir (German Organic)| Simcoe| Sorachi Ace| Southern Cross| Spalt| Spalt Select| Spalt Spalter| Sterling| Strisselspalt| Styrian Goldings| Summit| Target| Tettnang Tettnanger| Tettnanger (American)| Topaz| Tradition| Ultra| Warrior| Willamette| Zeus| Zythos| total|
|:------------------------|-------------------------------:|-------:|-------:|--------:|------:|------:|------:|-----:|-------------:|-------:|-------:|------:|----------:|----------:|-------:|-----:|-------:|--------:|-----:|-------:|---:|-----------------:|---------:|-----------------:|-----------------:|----------------:|-------:|------:|------:|-------------:|------------------------:|------------:|--------------:|----------------:|-------:|------------------:|------------:|-------------------------------:|-------------------------:|----------------------:|-----------------------:|----:|-------:|-------:|-------------:|----------:|-------:|------:|-------:|------:|-------:|----------:|-------------:|-------------------:|---------:|--------------------------:|------:|-----:|------------:|--------:|---------:|----------------:|-------:|---------------:|------------:|-----------------------:|------:|-----------:|--------------:|-----:|------------:|-------------:|--------:|-------------:|----------------:|------:|------:|-------------------:|---------------------:|-----:|---------:|-----:|-------:|----------:|----:|------:|-----:|
|Barley Wine              |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          1|          0|       3|     1|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      1|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       1|          0|    0|      0|     7|
|Barrel-Aged              |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       1|      1|          0|          0|       0|     0|       0|        1|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                1|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     4|
|Bitter                   |                               0|       0|       0|        1|      0|      0|      0|     0|             0|       0|       1|      0|          0|          0|       1|     0|       0|        0|     0|       0|   0|                 2|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       1|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          1|    0|      0|     6|
|Black                    |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       1|      0|          1|          0|       1|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      1|       0|      0|       0|          0|             0|                   0|         0|                          1|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                1|      1|      0|                   0|                     0|     0|         0|     0|       0|          1|    0|      0|     8|
|Blonde                   |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       1|   0|                 0|         0|                 0|                 1|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  1|            0|                               0|                         0|                      0|                       1|    0|       0|       0|             1|          0|       1|      1|       1|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       1|      0|           0|              0|     0|            1|             0|        1|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|    11|
|Brown                    |                               0|       0|       0|        0|      0|      0|      0|     0|             1|       0|       4|      0|          0|          1|       0|     0|       0|        0|     0|       0|   0|                 1|         0|                 0|                 1|                0|       0|      0|      0|             1|                        0|            0|              0|                0|       1|                  1|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      1|       0|      0|       0|          1|             0|                   0|         0|                          1|      1|     0|            2|        2|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     2|     0|         1|     0|       0|          1|    0|      0|    23|
|Double India Pale Ale    |                               0|       1|       0|        7|      1|      0|      0|     3|             0|       1|       9|      0|         13|          0|       5|     5|       0|       10|     0|       0|   1|                 0|         0|                 0|                 0|                0|       0|      1|      0|             0|                        0|            0|              1|                0|       1|                  0|            0|                               0|                         0|                      0|                       0|    0|       1|       0|             0|          0|       0|      3|       0|      3|       0|          1|             1|                   0|         0|                          0|      3|     0|            2|        0|         1|                0|       0|               0|            0|                       0|      4|           1|              0|     0|            0|             0|        0|             0|                0|      1|      0|                   0|                     0|     0|         0|     0|       1|          0|    0|      1|    73|
|Dubbel                   |                               1|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         1|                          0|      0|     0|            0|        0|         0|                0|       0|               1|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     2|
|Fruit Beer               |                               0|       0|       0|        1|      0|      0|      0|     0|             0|       0|       1|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      1|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      1|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     3|
|Fruit Cider              |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     0|
|German-Style Doppelbock  |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       1|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          1|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                1|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     3|
|German-Style Märzen      |                               0|       0|       0|        0|      1|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      2|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          1|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     3|
|Herb and Spice Beer      |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       2|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  1|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      2|       0|      0|       0|          1|             0|                   0|         0|                          1|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     1|            0|             1|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          1|    0|      0|    10|
|India Pale Ale           |                               0|       5|       0|       15|      2|      0|      0|     4|             0|       0|      33|      0|         23|          0|      15|    13|       1|       16|     1|       2|   1|                 0|         2|                 3|                 0|                0|       2|      1|      1|             0|                        1|            0|              0|                0|       2|                  1|            0|                               0|                         0|                      1|                       0|    0|       1|       1|             0|          0|       0|      5|       0|      7|       3|          0|             4|                   1|         0|                          1|      1|     0|            2|        0|         2|                0|       0|               0|            0|                       1|     19|           0|              1|     0|            0|             0|        1|             0|                0|      6|      1|                   0|                     0|     2|         2|     0|       3|          2|    1|      1|   191|
|Kölsch                   |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             1|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          1|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             2|        0|             0|                0|      0|      0|                   0|                     1|     0|         0|     0|       0|          0|    0|      0|     5|
|Lager                    |                               0|       0|       0|        1|      0|      0|      0|     0|             0|       0|       3|      0|          3|          0|       1|     2|       0|        2|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         1|                      3|                       1|    2|       0|       0|             0|          0|       1|      1|       0|      0|       0|          1|             0|                   0|         0|                          0|      2|     0|            0|        0|         0|                1|       0|               2|            1|                       0|      2|           0|              0|     0|            0|             0|        1|             2|                0|      0|      0|                   1|                     1|     0|         1|     1|       0|          1|    0|      1|    38|
|Other Belgian-Style Ales |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       0|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      0|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          0|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                0|      0|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|     0|
|Pale Ale                 |                               0|       0|       0|        3|      1|      1|      1|     0|             0|       1|      25|      0|          6|          0|       6|     5|       1|        3|     0|       1|   0|                 0|         1|                 1|                 0|                0|       2|      2|      2|             0|                        0|            0|              0|                0|       0|                  0|            0|                               0|                         0|                      0|                       1|    0|       0|       1|             0|          0|       0|      3|       0|      2|       1|          0|             0|                   0|         0|                          1|      1|     0|            0|        0|         1|                1|       0|               2|            0|                       0|      4|           0|              0|     0|            0|             0|        0|             0|                2|      2|      0|                   0|                     0|     0|         1|     0|       0|          1|    0|      1|    82|
|Pilsener                 |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       0|      0|          0|          0|       0|     0|       1|        0|     0|       0|   0|                 0|         0|                 0|                 0|                0|       0|      0|      1|             0|                        0|            1|              0|                0|       0|                  0|            0|                               1|                         0|                      2|                       1|    0|       0|       0|             0|          0|       0|      1|       0|      0|       0|          1|             0|                   0|         0|                          0|      0|     0|            0|        0|         0|                0|       0|               2|            0|                       1|      0|           0|              0|     0|            0|             1|        1|             0|                0|      0|      0|                   1|                     1|     0|         0|     0|       0|          0|    0|      0|    16|
|Porter                   |                               0|       0|       0|        0|      0|      0|      0|     0|             0|       0|       2|      1|          0|          0|       0|     0|       0|        1|     0|       0|   0|                 2|         0|                 0|                 0|                0|       1|      0|      0|             0|                        0|            0|              0|                0|       1|                  0|            0|                               0|                         0|                      0|                       0|    0|       0|       0|             0|          0|       0|      0|       0|      0|       0|          1|             0|                   0|         0|                          2|      0|     0|            0|        0|         0|                0|       0|               0|            0|                       0|      0|           0|              0|     0|            0|             0|        0|             0|                1|      1|      0|                   0|                     0|     0|         0|     0|       0|          0|    0|      0|    13|


<!-- All hops types -->

<!-- ```{r} -->
<!-- kable(all_hops_levels) -->
<!-- ``` -->

<!-- All malt types -->
<!-- ```{r} -->
<!-- kable(all_malt_levels) -->
<!-- ``` -->





### Updated neural net with ingredients



