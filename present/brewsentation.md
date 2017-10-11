Beer-in-Hand Data Science
========================================================
author: Amanda Dobbyn
date: 
autosize: true

<style>
  .title-slide {
     background-image: url(http://bitpine.com/av/storage/d6883b03/avfb6baf1401d03eb2b7d.jpg);
      background-position: center center;
      background-attachment: fixed;
      background-repeat: no-repeat;
      background-size: 100% 100%;
   }
  

  .cheers {
      background-image: url(https://static.independent.co.uk/s3fs-public/styles/article_small/public/thumbnails/image/2016/12/30/17/beer-istock-izusek.jpg);
      background-position: center center;
      background-attachment: fixed;
      background-repeat: no-repeat;
      background-size: 100% 100%;
      color: white;
      background:transparent;
    }
    
  .cheers .reveal .state-background {
      background-image: url(http://bitpine.com/av/storage/d6883b03/avfb6baf1401d03eb2b7d.jpg);
      background-position: center center;
      background-attachment: fixed;
      background-repeat: no-repeat;
      background-size: 100% 100%;
      color: white;
      <!-- background:transparent; -->
    }
    
  .section .reveal .state-background {
      background-image: url(http://bitpine.com/av/storage/d6883b03/avfb6baf1401d03eb2b7d.jpg);
      background-position: center center;
      background-attachment: fixed;
      background-repeat: no-repeat;
      background-size: 100% 100%;
  }

  td{
    font-size: 2pt;
    padding: 0px;
    cellpadding="0";
    cellspacing="0"
  }
  th {
    font-size: 2pt;
    height: 10px;
    font-weight: bold;
    text-align: right;
    background-color: #989da5;
  }
  table { 
    border-spacing: 0px;
    border-collapse: collapse;
  }
  
  .small-code pre code {
    font-size: 1em;
  }
  
  .footer {
    color: black; 
    position: fixed; top: 90%;
    margin: top: 20%;
    text-align:center; width:100%;
}

  .midcenter {
      position: fixed;
      top: 50%;
      left: 50%;
      background-color:transparent;
  }
  
  .leftcenter {
      position: fixed;
      top: 15%;
      left: 5%;
      right: 1%; 
      background-color:transparent;
  }
</style>








First things first
========================================================
navigation:section

Who am I?
- UChicago '15, go Maroons
- Met Angela when she joined this bunch of goons:

<div class="midcenter" style="height: 70%; width: "70%">
<img src="./img/supersnatch.jpg"></img>
</div>

<!-- ![uchi_ultimate](./img/supersnatch.jpg) -->

- Now at [Earlybird Software](http://earlybird.co/)

<br>

Where's the code at?
Code at: <https://github.com/aedobbyn/beer-data-science>


How did this come about?
========================================================
- Over a Friday afternoon beverage in the office discussing an ideal beer flavor profile visualizer
    - How do you represent *"hoppy, for a Kölsch"*?
    
    
How did this come about?
========================================================
`Beer = water + malt + hops + yeast + sometimes other stuff like fruit`
- We categorize it into different styles based on 
  - Type and ratio of ingredients
  - How the beer is made (e.g., how long and at what temperature it's brewed)
  - Squishy regional differences 
  

How did this come about?
========================================================

BUT
- *How well do styles actually demarcate the beer landscape?*
  - Is there actually more inter-style variation than intra-style variation?
  - Is there a better way to categorize beers into groups?

In other words, we're asking, are beer styles just a social construct?


The Order of Things, theoretically
========================================================

![get_beers](./img/magnificent-chart-of-beer.jpg)


Implications
========================================================


* If styles do demarcate the beer landscape well, we should expect to see distinct **clusters** dominated mostly by beers classified into a *single* style

* It should also be easy to **predict** style from the other variables

This all assumes the variables we have (more on those in a sec) can account for most of the variance between styles.


*The stakes could not be higher*.



Step 1: GET Beer
========================================================
### The age-old dilemma


From where?
[BreweryDB](http://www.brewerydb.com/developers/docs).

![get_beers](./img/get_beers.jpg)

***

![get_beers](./img/example_beer.jpg)


Step 1: GET Beer
========================================================
class: small-code

We'll use the `fromJSON()` function from the `jsonlite` package to actually send the requests.


```r
base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="

paginated_request <- function(ep, addition, trace_progress = TRUE) {    
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
    
    if(trace_progress == TRUE) {message(paste0("Page ", this_req_unnested$currentPage))} # if TRUE, print the page we're on
    
    full_request <- bind_rows(full_request, this_req_unnested[["data"]])
  }
  return(full_request)
} 

all_beer_raw <- paginated_request("beers", "&withIngredients=Y")
```


What have we got?
========================================================


|id     |name                                     |style                                              |style_collapsed       |glass | abv| ibu| srm|hops_name                                  |malt_name                                                                     |
|:------|:----------------------------------------|:--------------------------------------------------|:---------------------|:-----|---:|---:|---:|:------------------------------------------|:-----------------------------------------------------------------------------|
|X4KcGF |(512) TWO                                |Imperial or Double India Pale Ale                  |Double India Pale Ale |Pint  | 9.0|  99|   9|Columbus, Glacier, Horizon, Nugget, Simcoe |Caramel/Crystal Malt, Two-Row Pale Malt - Organic, Wheat Malt                 |
|USaRyl |(512) Whiskey Barrel Double Pecan Porter |Wood- and Barrel-Aged Strong Beer                  |Barrel-Aged           |Pint  | 9.5|  30|  NA|Glacier                                    |Black Malt, Caramel/Crystal Malt, Chocolate Malt, Two-Row Pale Malt - Organic |
|bXwskR |(512) White IPA                          |American-Style India Pale Ale                      |India Pale Ale        |Pint  | 5.3|  55|   4|NA                                         |NA                                                                            |
|XnPVIo |(512) Wild Bear                          |Specialty Beer                                     |Specialty Beer        |Tulip | 8.5|   9|  NA|NA                                         |NA                                                                            |
|QLp4mV |(512) Wit                                |Belgian-Style White (or Wit) / Belgian-Style Wheat |Wheat                 |Pint  | 5.1|  10|   5|Golding (American)                         |Oats - Malted, Two-Row Pale Malt - Organic, Wheat Malt - White                |
|tWuIyV |(714): Blond Ale                         |Golden or Blonde Ale                               |Blonde                |NA    | 4.8|  NA|  NA|NA                                         |NA                                                                            |



What have we got?
========================================================

<div class="footer" style="font-size:80%; margin-bottom:0%">
What we have <em>not</em> got: flavor profiles (fruity, hoppy, piney) and ratings.</div>

<br> 
* 63,495 distinct beers
* Info about the beer:
  * ABV: alcohol by volume
  * IBU: International Biterness Units (really)
  * SRM: [a measure of color](http://www.twobeerdudes.com/beer/srm)
  * Ingredients
      * Hops, malts
      
***

![plot of chunk unnamed-chunk-2](brewsentation-figure/unnamed-chunk-2-1.png)




Where did we put it?
========================================================

![local_db](./img/local_db.jpg)

***

MySQL. 

* This allows us to
   * Easily update the data if anything changes
   * Others easy access to the data if they want to build an app using it



Step 2: Breathe sigh of relief, Collapse
========================================================
class: small-code


```r
keywords <- c("Lager", "Pale Ale", "India Pale Ale", "Double India Pale Ale", "India Pale Lager", "Hefeweizen", "Barrel-Aged","Wheat", "Pilsner", "Pilsener", "Amber", "Golden", "Blonde", "Brown", "Black", "Stout", "Imperial Stout", "Fruit", "Porter", "Red", "Sour", "Kölsch", "Tripel", "Bitter", "Saison", "Strong Ale", "Barley Wine", "Dubbel")
```



```r
collapse_styles <- function(df, trace_progress = TRUE) {
  
  df[["style_collapsed"]] <- vector(length = nrow(df))
  
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
    if(trace_progress == TRUE) {message(paste0("Collapsing this ", df$style[beer], " to: ", df$style_collapsed[beer]))}
  }
  return(df)
}
```

Collapsing in Action
========================================================

We've set `trace_progress = TRUE`

![get_beers](./img/collapse_styles.jpg)

***
* Keywords are ordered from most general to most specific
  * If a beer's name matches multiple keywords, its `style_collapsed` is the **last** of those that appear in keyword 
    
    
`American-Style Pale Ale`  ➡  `Pale Ale`

`American-Style India Pale Ale`  ➡  `India Pale Ale`



Popular Styles
========================================================
* Let's focus on just beers in the few main styles

* So we'll pare down to only the popular kids
   * Those with above the mean number of beers in their style (z-score > 0)
   * (Of course, this is just a reflection of the number of different beers we get from BreweryDB that are classified into that style, not a measure of popular consumption)
   
* And then get a sense of where those styles fall in relation to one another
    * Style "centers" = mean ABV, IBU, and SRM of each style







Popular Styles
========================================================
class: small-code

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> Collapsed Style </th>
   <th style="text-align:right;"> Mean ABV </th>
   <th style="text-align:right;"> Mean IBU </th>
   <th style="text-align:right;"> Mean SRM </th>
   <th style="text-align:right;"> Numer of Beers </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> India Pale Ale </td>
   <td style="text-align:right;"> 6.58 </td>
   <td style="text-align:right;"> 66.04 </td>
   <td style="text-align:right;"> 9.99 </td>
   <td style="text-align:right;"> 6524 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pale Ale </td>
   <td style="text-align:right;"> 5.70 </td>
   <td style="text-align:right;"> 40.87 </td>
   <td style="text-align:right;"> 8.89 </td>
   <td style="text-align:right;"> 4280 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Stout </td>
   <td style="text-align:right;"> 7.99 </td>
   <td style="text-align:right;"> 43.90 </td>
   <td style="text-align:right;"> 36.30 </td>
   <td style="text-align:right;"> 4238 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Wheat </td>
   <td style="text-align:right;"> 5.16 </td>
   <td style="text-align:right;"> 17.47 </td>
   <td style="text-align:right;"> 5.86 </td>
   <td style="text-align:right;"> 3349 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Double India Pale Ale </td>
   <td style="text-align:right;"> 8.93 </td>
   <td style="text-align:right;"> 93.48 </td>
   <td style="text-align:right;"> 11.01 </td>
   <td style="text-align:right;"> 2525 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Red </td>
   <td style="text-align:right;"> 5.74 </td>
   <td style="text-align:right;"> 33.81 </td>
   <td style="text-align:right;"> 16.18 </td>
   <td style="text-align:right;"> 2521 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Lager </td>
   <td style="text-align:right;"> 5.45 </td>
   <td style="text-align:right;"> 30.64 </td>
   <td style="text-align:right;"> 8.46 </td>
   <td style="text-align:right;"> 2230 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Saison </td>
   <td style="text-align:right;"> 6.40 </td>
   <td style="text-align:right;"> 27.25 </td>
   <td style="text-align:right;"> 7.05 </td>
   <td style="text-align:right;"> 2167 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Blonde </td>
   <td style="text-align:right;"> 5.60 </td>
   <td style="text-align:right;"> 22.39 </td>
   <td style="text-align:right;"> 5.62 </td>
   <td style="text-align:right;"> 2044 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Porter </td>
   <td style="text-align:right;"> 6.18 </td>
   <td style="text-align:right;"> 33.25 </td>
   <td style="text-align:right;"> 32.20 </td>
   <td style="text-align:right;"> 1973 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Brown </td>
   <td style="text-align:right;"> 6.16 </td>
   <td style="text-align:right;"> 32.22 </td>
   <td style="text-align:right;"> 23.59 </td>
   <td style="text-align:right;"> 1462 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pilsener </td>
   <td style="text-align:right;"> 5.23 </td>
   <td style="text-align:right;"> 33.51 </td>
   <td style="text-align:right;"> 4.41 </td>
   <td style="text-align:right;"> 1268 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Specialty Beer </td>
   <td style="text-align:right;"> 6.45 </td>
   <td style="text-align:right;"> 33.78 </td>
   <td style="text-align:right;"> 15.52 </td>
   <td style="text-align:right;"> 1044 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bitter </td>
   <td style="text-align:right;"> 5.32 </td>
   <td style="text-align:right;"> 38.28 </td>
   <td style="text-align:right;"> 12.46 </td>
   <td style="text-align:right;"> 939 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Fruit Beer </td>
   <td style="text-align:right;"> 5.20 </td>
   <td style="text-align:right;"> 19.24 </td>
   <td style="text-align:right;"> 8.67 </td>
   <td style="text-align:right;"> 905 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Herb and Spice Beer </td>
   <td style="text-align:right;"> 6.62 </td>
   <td style="text-align:right;"> 27.77 </td>
   <td style="text-align:right;"> 18.17 </td>
   <td style="text-align:right;"> 872 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sour </td>
   <td style="text-align:right;"> 6.22 </td>
   <td style="text-align:right;"> 18.89 </td>
   <td style="text-align:right;"> 10.04 </td>
   <td style="text-align:right;"> 797 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Strong Ale </td>
   <td style="text-align:right;"> 8.83 </td>
   <td style="text-align:right;"> 36.74 </td>
   <td style="text-align:right;"> 22.55 </td>
   <td style="text-align:right;"> 767 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Tripel </td>
   <td style="text-align:right;"> 9.03 </td>
   <td style="text-align:right;"> 32.52 </td>
   <td style="text-align:right;"> 7.68 </td>
   <td style="text-align:right;"> 734 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Black </td>
   <td style="text-align:right;"> 6.96 </td>
   <td style="text-align:right;"> 65.51 </td>
   <td style="text-align:right;"> 31.08 </td>
   <td style="text-align:right;"> 622 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Barley Wine </td>
   <td style="text-align:right;"> 10.78 </td>
   <td style="text-align:right;"> 74.05 </td>
   <td style="text-align:right;"> 19.56 </td>
   <td style="text-align:right;"> 605 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Kölsch </td>
   <td style="text-align:right;"> 4.98 </td>
   <td style="text-align:right;"> 23.37 </td>
   <td style="text-align:right;"> 4.37 </td>
   <td style="text-align:right;"> 593 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Barrel-Aged </td>
   <td style="text-align:right;"> 9.00 </td>
   <td style="text-align:right;"> 39.16 </td>
   <td style="text-align:right;"> 18.13 </td>
   <td style="text-align:right;"> 540 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Other Belgian-Style Ales </td>
   <td style="text-align:right;"> 7.52 </td>
   <td style="text-align:right;"> 37.56 </td>
   <td style="text-align:right;"> 17.55 </td>
   <td style="text-align:right;"> 506 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pumpkin Beer </td>
   <td style="text-align:right;"> 6.71 </td>
   <td style="text-align:right;"> 23.48 </td>
   <td style="text-align:right;"> 17.92 </td>
   <td style="text-align:right;"> 458 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Dubbel </td>
   <td style="text-align:right;"> 7.51 </td>
   <td style="text-align:right;"> 25.05 </td>
   <td style="text-align:right;"> 22.94 </td>
   <td style="text-align:right;"> 399 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Scotch Ale </td>
   <td style="text-align:right;"> 7.62 </td>
   <td style="text-align:right;"> 26.37 </td>
   <td style="text-align:right;"> 24.22 </td>
   <td style="text-align:right;"> 393 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> German-Style Doppelbock </td>
   <td style="text-align:right;"> 8.05 </td>
   <td style="text-align:right;"> 28.89 </td>
   <td style="text-align:right;"> 25.70 </td>
   <td style="text-align:right;"> 376 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Fruit Cider </td>
   <td style="text-align:right;"> 6.21 </td>
   <td style="text-align:right;"> 25.60 </td>
   <td style="text-align:right;"> 12.00 </td>
   <td style="text-align:right;"> 370 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> German-Style Märzen </td>
   <td style="text-align:right;"> 5.75 </td>
   <td style="text-align:right;"> 25.64 </td>
   <td style="text-align:right;"> 14.32 </td>
   <td style="text-align:right;"> 370 </td>
  </tr>
</tbody>
</table>



What's in a Predictor?
========================================================
To the main question: do styles truly define distinct pockets of beer?

If so, we could expect styles to align with **clusters** generated using an unsupervised learning algorithm. 


##### Inputs
* Only directly controlled by a brewer **before** a beer is brewed
    * Hops, malts

##### Outputs
* Only measured **after** a beer been brewed
    * ABV, IBU, SRM
    
##### Style-Defined
* Dependent entirely on style




What's in a Predictor?
========================================================

Style-Defined: 👎   predictor  

Outputs: 👍  predictor  

Inputs: 🤷🏻‍♂️  predictor  



Clustering: the function
========================================================
class: small-code


```r
set.seed(9)

do_cluster <- function (df, vars, to_cluster_on, n_centers = 5) {
  df_for_clustering <- df %>% select(!!vars) %>% na.omit()

  # Scale the ones to be scaled and append _scaled to their names
  df_vars_scale <- df_for_clustering %>% select(!!to_scale) %>%
    scale() %>% as_tibble()
  names(df_vars_scale) <- names(df_vars_scale) %>% stringr::str_c("_scaled")

  # Do the clustering on the scaled data
  clusters_out <- kmeans(x = df_vars_scale, centers = n_centers, trace = FALSE)

  # Combine cluster assignment, scaled data, and unscaled rest of data
  clustered_df <- bind_cols(
    cluster_assignment = factor(clusters_out$cluster),   # Cluster assignment
    df_vars_scale,
    df_for_clustering
  )

  return(clustered_df)
}
```


Clustering: Run It
========================================================

* Cluster the beers and stitch together the cluster assignments with the original data


```r
to_include <- c("id", "name", "style", "style_collapsed", "abv", "ibu", "srm")
to_cluster_on <- c("abv", "ibu", "srm")

clustered_beer <- do_cluster(beer_necessities, to_include, to_cluster_on)
```


Clustering: Output
========================================================


|Cluster Assignment | ABV Scaled| IBU Scaled| SRM Scaled|ID     |Name                                                         |Style                                              |Style Collapsed       | ABV|  IBU| SRM|
|:------------------|----------:|----------:|----------:|:------|:------------------------------------------------------------|:--------------------------------------------------|:---------------------|---:|----:|---:|
|1                  |  0.2659786| -0.6403452|  2.1973592|tmEthz |"Admiral" Stache                                             |Baltic-Style Porter                                |Porter                | 7.0| 23.0|  37|
|1                  | -0.5491578|  0.4345392|  2.4813777|b7SfHG |"Ah Me Joy" Porter                                           |Robust Porter                                      |Porter                | 5.4| 51.0|  40|
|5                  | -0.3453737|  0.4345392| -0.5481524|PBEXhV |"Bison Eye Rye" Pale Ale &#124; 2 of 4 Part Pale Ale Series  |American-Style Pale Ale                            |Pale Ale              | 5.8| 51.0|   8|
|5                  | -0.5491578|  0.5497053| -0.2641340|AXmvOd |"Dust Up" Cloudy Pale Ale &#124; 1 of 4 Part Pale Ale Series |American-Style Pale Ale                            |Pale Ale              | 5.4| 54.0|  11|
|2                  | -0.4472658| -0.4407238| -0.8321709|Hr5A0t |"God Country" Kolsch                                         |German-Style Kölsch / Köln-Style Kölsch            |Kölsch                | 5.6| 28.2|   5|
|2                  | -0.8038879| -0.7555114| -0.8321709|mrVjY4 |"Jemez Field Notes" Golden Lager                             |Golden or Blonde Ale                               |Blonde                | 4.9| 20.0|   5|
|2                  | -0.7019959| -1.1010099| -0.9268437|xFM8w5 |#10 Hefewiezen                                               |South German-Style Hefeweizen / Hefeweissbier      |Wheat                 | 5.1| 11.0|   4|
|2                  | -0.7019959| -0.7555114| -0.4534796|hB0QeO |#9                                                           |American-Style Pale Ale                            |Pale Ale              | 5.1| 20.0|   9|
|2                  | -0.8548340| -0.4867903| -1.0215165|m8f62Y |#KoLSCH                                                      |German-Style Kölsch / Köln-Style Kölsch            |Kölsch                | 4.8| 27.0|   3|
|2                  | -0.6001038| -0.8322888| -0.8321709|35lHUq |'Inappropriate' Cream Ale                                    |American-Style Cream Ale or Lager                  |Lager                 | 5.3| 18.0|   5|
|2                  |  0.2659786| -0.3716241| -0.6428253|qbRV90 |'tis the Saison                                              |French & Belgian-Style Saison                      |Saison                | 7.0| 30.0|   7|
|2                  | -0.7529419| -0.7555114| -0.4534796|qhaIVA |(306) URBAN WHEAT BEER                                       |Belgian-Style White (or Wit) / Belgian-Style Wheat |Wheat                 | 5.0| 20.0|   9|
|1                  | -0.2434817| -0.1412917|  0.6825942|tciJOF |(512) ALT                                                    |German-Style Altbier                               |Altbier               | 6.0| 36.0|  21|
|1                  |  0.5716547| -0.3716241|  0.6825942|VwR7Xg |(512) Bruin (A.K.A. Brown Bear)                              |American-Style Brown Ale                           |Brown                 | 7.6| 30.0|  21|
|5                  |  0.5207087| -0.1796805| -0.5481524|oJFZwK |(512) FOUR                                                   |Strong Ale                                         |Strong Ale            | 7.5| 35.0|   8|
|5                  |  0.2659786|  0.9719813| -0.5481524|ezGh5N |(512) IPA                                                    |American-Style India Pale Ale                      |India Pale Ale        | 7.0| 65.0|   8|
|2                  |  0.7754388| -0.6787339| -0.5481524|s8rdpK |(512) ONE                                                    |Belgian-Style Pale Strong Ale                      |Strong Ale            | 8.0| 22.0|   8|
|2                  | -0.2434817| -0.3716241| -0.6428253|2fXsvw |(512) Pale                                                   |American-Style Pale Ale                            |Pale Ale              | 6.0| 30.0|   7|
|1                  |  0.5207087| -0.5635677|  1.3453039|9O3QPg |(512) SIX                                                    |Belgian-Style Dubbel                               |Dubbel                | 7.5| 25.0|  28|
|3                  |  1.5396292| -0.6787339| -0.3588068|A78JSF |(512) THREE                                                  |Belgian-Style Tripel                               |Tripel                | 9.5| 22.0|  10|
|3                  |  1.5396292| -0.6787339|  2.4813777|WKSYBT |(512) THREE (Cabernet Barrel Aged)                           |Belgian-Style Tripel                               |Tripel                | 9.5| 22.0|  40|
|4                  |  1.2848991|  2.2771980| -0.4534796|X4KcGF |(512) TWO                                                    |Imperial or Double India Pale Ale                  |Double India Pale Ale | 9.0| 99.0|   9|
|5                  | -0.6001038|  0.5880941| -0.9268437|bXwskR |(512) White IPA                                              |American-Style India Pale Ale                      |India Pale Ale        | 5.3| 55.0|   4|
|2                  | -0.7019959| -1.1393986| -0.8321709|QLp4mV |(512) Wit                                                    |Belgian-Style White (or Wit) / Belgian-Style Wheat |Wheat                 | 5.1| 10.0|   5|
|2                  | -1.0586181| -0.7939001| -0.9268437|thTbY7 |(904) Weissguy                                               |South German-Style Hefeweizen / Hefeweissbier      |Wheat                 | 4.4| 19.0|   4|
|2                  | -0.6510499| -0.1796805| -0.5481524|EPnv3B |(916)                                                        |American-Style Pale Ale                            |Pale Ale              | 5.2| 35.0|   8|
|2                  | -0.0906436| -0.6019565| -0.0747884|QT9hB8 |+1 Pumpkin                                                   |Pumpkin Beer                                       |Pumpkin Beer          | 6.3| 24.0|  13|
|5                  |  0.6735468|  1.5478122| -0.8321709|btwcy1 |077XX India Pale Ale                                         |Imperial or Double India Pale Ale                  |Double India Pale Ale | 7.8| 80.0|   5|
|5                  |  1.2339530|  0.2042068| -0.8321709|FWiYZi |08.08.08 Vertical Epic Ale                                   |Belgian-Style Pale Ale                             |Pale Ale              | 8.9| 45.0|   5|
|5                  | -0.4982118|  0.6264828| -0.4534796|M6vu9P |10 Blocks South                                              |American-Style Pale Ale                            |Pale Ale              | 5.5| 56.0|   9|



<!-- Clusterfun with Shiny Embed -->
<!-- ======================================================== -->
<!-- ```{r, echo = FALSE, eval=TRUE} -->
<!-- shinyAppDir( -->
<!--   system.file("/Users/amanda/Desktop/Projects/beer_data_science/present/clusterfun", package="shiny"), -->
<!--   options=list( -->
<!--     width="100%", height="100%" -->
<!--   ) -->
<!-- ) -->


<!-- ``` -->

Clusterfun with Shiny: UI
========================================================
class: small-code 


```r
sidebarLayout(
    sidebarPanel(
      h4("Control Panel"),

      checkboxInput("show_all", "Show all styles", TRUE),      
      checkboxInput("show_centers", "Show style centers", FALSE),
      numericInput("num_clusters", "Number of Clusters:", starting_n_clusters),
      
      checkboxGroupInput("cluster_on", "Choose variables to cluster on: ",
                         c("ABV (alcohol)" = "abv", 
                           "IBU (bitterness)" = "ibu", 
                           "SRM (color)" ="srm", 
                           "Total number of hops" = "total_hops", 
                           "Total number of malts" = "total_malt"),
                         selected = c("abv", "ibu", "srm")),
      
      checkboxGroupInput("response_vars", "Choose response variable(s): ",
                         c("Collapsed style" = "style_collapsed",
                           "Specific style" = "style"
                         ),
                         selected = c("style_collapsed")),
      
      conditionalPanel(
        condition = "input.show_all == false",
        selectInput("style_collapsed", "Collapsed Style:",
                    style_names)
        )
    ),
```



Clusterfun with Shiny: Server
========================================================
class: small-code 


```r
  output$cluster_plot <- renderPlot({
  
    # If our checkbox is checked saying we do want style centers, show them. Else, don't.
    if (input$show_centers == TRUE & input$show_all == FALSE) {
      
      this_style_center <- reactive({style_centers %>% filter(style_collapsed == input$style_collapsed)})
      
      ggplot() +
        geom_point(data = this_style_data(),
                   aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
        geom_point(data = this_style_center(),
                   aes(mean_abv, mean_ibu), colour = "black") +
        geom_text_repel(data = this_style_center(),
                        aes(mean_abv, mean_ibu, label = input$style_collapsed),
                        box.padding = unit(0.45, "lines"),
                        family = "Calibri") +
        ggtitle("k-Means Clustered Beer") +
        labs(x = "ABV", y = "IBU") +
        labs(colour = "Cluster Assignment") +
        theme_minimal() +
        theme(legend.position="none")
    } else if  # ....... etc., etc.
```



Clusterfun with Shiny
========================================================

![clusterfun](./img/clusterfun.jpg)

<https://amandadobbyn.shinyapps.io/clusterfun/>



Narrowing In
========================================================

<div class="footer" style="font-size:80%;">
Not bad.</div>

<br> 
If we focus in on 5 distinct styles and cluster them into 5 clusters, will each style be siphoned off into their own cluster?


    
***







![plot of chunk cluster_certain_styles](brewsentation-figure/cluster_certain_styles-1.png)


And now for something completely different
========================================================
<div class="midcenter" style="width:90%; height:90%; margin-right:30%"> <img src="./img/now_for_something_completely_different.gif"></img></div>

...a quick dive into hops


Hops
========================================================
incremental:true

<!-- ![mad_hops](./img/mad_hops.jpg) -->

<div class="midcenter" style="margin-left:-300px; margin-top:-300px;">
<img src="./img/mad_hops.jpg"></img>
</div>



Hops
========================================================
incremental:true

No, not those hops!

![fresh_hops](./img/fresh_hops.jpg)

These hops ☝️

*** 

Hops, *noun*: it's what makes it bitter and flavorful.

Our question: do more *kinds* of hops generally make a beer more bitter?
(Note that this is different than the *amount* of hops poured into a beer.)


How do hops affect ABV and IBU?
========================================================
class: small-code

Let's munge a bit.


```r
# Gather up all the hops columns into one called `hop_name`
beer_necessities_hops_gathered <- beer_necessities %>%
  gather(
    hop_key, hop_name, hops_name_1:hops_name_13
  ) %>% as_tibble()

# Filter to just those beers that have at least one hop
beer_necessities_w_hops <- beer_necessities_hops_gathered %>% 
  filter(!is.na(hop_name)) %>% 
  filter(!hop_name == "")

beer_necessities_w_hops$hop_name <- factor(beer_necessities_w_hops$hop_name)
```


How do hops effect ABV and IBU?
========================================================
class: small-code

```r
# For all hops, find the number of beers they're in as well as those beers' mean IBU and ABV
hops_beer_stats <- beer_necessities_w_hops %>% 
  ungroup() %>% 
  group_by(hop_name) %>% 
  summarise(
    mean_ibu = mean(ibu, na.rm = TRUE), 
    mean_abv = mean(abv, na.rm = TRUE),
    n = n()
  ) %>% 
  arrange(desc(n))

# Pare to hops that are used in at least 50 beers
pop_hops_beer_stats <- hops_beer_stats[hops_beer_stats$n > 50, ] 

# Keep just beers that contain these most popular hops
beer_necessities_w_popular_hops <- beer_necessities_w_hops %>% 
  filter(hop_name %in% pop_hops_beer_stats$hop_name) %>% 
  droplevels()

pop_hops_display <- pop_hops_beer_stats %>% 
    rename(
    `Hop` = hop_name,
    `Mean IBU` = mean_ibu,
    `Mean ABV` = mean_abv,
    `N Beers with this Hop` = n
  )
```


How do hops effect ABV and IBU?
========================================================

|Hop Name                   | Mean IBU| Mean ABV| Number Beers Containing this Hop|
|:--------------------------|--------:|--------:|--------------------------------:|
|Cascade                    | 51.92405| 6.510729|                              445|
|Centennial                 | 63.96526| 7.081883|                              243|
|Chinook                    | 60.86871| 7.043439|                              194|
|Simcoe                     | 64.07211| 6.877394|                              191|
|Columbus                   | 63.74483| 6.953846|                              183|
|Amarillo                   | 61.36053| 6.959264|                              163|
|Citra                      | 59.60000| 6.733290|                              157|
|Willamette                 | 39.61078| 7.014657|                              133|
|Nugget                     | 52.23810| 6.383119|                              114|
|Magnum                     | 48.71596| 6.926852|                              109|
|East Kent Golding          | 38.51875| 6.347386|                               89|
|Perle (American)           | 32.03947| 6.251744|                               88|
|Hallertauer (American)     | 23.92388| 5.658537|                               83|
|Mosaic                     | 56.81818| 6.977465|                               71|
|Northern Brewer (American) | 39.48475| 6.473944|                               71|
|Mount Hood                 | 37.83500| 6.550000|                               68|
|Warrior                    | 59.13043| 6.983115|                               62|
|Saaz (American)            | 30.69778| 6.248333|                               60|
|Fuggles                    | 40.75581| 6.772143|                               59|
|Tettnanger (American)      | 30.27551| 6.016780|                               59|
|Sterling                   | 35.41860| 6.024259|                               55|

***


![plot of chunk abv_ibu_hopsize](brewsentation-figure/abv_ibu_hopsize-1.png)



How do hops effect ABV and IBU?
========================================================
incremental: true
class: small-code

![plot of chunk unnamed-chunk-11](brewsentation-figure/unnamed-chunk-11-1.png)

If nothing else, we learned that there is a strain of hops called Fuggle. So that's a win.

***
Is it significant?






















```
Error in function_list[[i]](value) : 
  could not find function "capitalize_df"
```
