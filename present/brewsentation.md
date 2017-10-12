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
  
  .very-small-code pre code {
    font-size: .7em;
  }
  
  .very-small-code-transparent {
    background-image: url(http://bitpine.com/av/storage/d6883b03/avfb6baf1401d03eb2b7d.jpg);
    background-position: center center;
    background-attachment: fixed;
    background-repeat: no-repeat;
    background-size: 100% 100%;
    color: white;
    border-style: none;
    background-size: 100% auto;
  }
  
  .very-small-code-transparent .reveal .state-background {
    background-image: url(http://bitpine.com/av/storage/d6883b03/avfb6baf1401d03eb2b7d.jpg);
    background-position: center center;
    background-attachment: fixed;
    background-repeat: no-repeat;
    background-size: 100% 100%;
    color: white;
    border-style: none;
    background-size: 100% auto;
  }
  
  .very-small-code-transparent pre code {
    font-size: .7em;
    background: transparent;
    border-style: none;
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
incremental:true
*Who am I?*

UChicago '15
![uchi_ultimate](./img/supersnatch.jpg)
<small> ^ Angela not yet pictured </small>


***
<br> 

Now at [Earlybird Software](http://earlybird.co/)
![eb](./img/eb_planning.jpg)


First things first
========================================================
incremental:false

*Where's the code at?*
- Code at: <https://github.com/aedobbyn/beer-data-science>
    - Includes writeup, Shiny app, and step-by-step scripts for getting and munging data

***
![git_cat](./img/gitcat.png)


How did this come about?
========================================================
- Typical Friday afternoon office conversation
    - How do you architect the ideal beer flavor profile visualizer?
        - In particular, how do you represent *"hoppy, for a Kölsch"*?
    
- Does the style Kölsch even describe a tangibly different subset of beer that would be distinguishable in a blind taste test from other styles?
    
How did this come about?
========================================================
`Beer = water + malt + hops + yeast + sometimes other stuff like fruit`
- We categorize it into different styles based on 
  - Type and ratio of ingredients
  - How the beer is made (e.g., how long and at what temperature it's brewed)
  - Regional/historical differences 
  

How did this come about?
========================================================

BUT
- *How well do styles actually demarcate the beer landscape?*
  - Is there actually more inter-style variation than intra-style variation?
  - Is there a more empiricially accurate way to categorize beers into super-groups?

In other words, we're asking: are beer styles just a social construct?


The Order of Things, theoretically
========================================================

<center>![order_of_things](./img/magnificent-chart-of-beer.jpg)<center>


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
[BreweryDB](http://www.brewerydb.com/developers/docs), an online database of beers with a public API.

![get_beers](./img/get_beers.jpg)

***

![get_beers](./img/example_beer.jpg)


Quick funciton factory
========================================================
class:small-code

Using `purrr::walk()` and `assign()` we can create functions to GET any beer, brewery, category, etc. if we know its ID.


```r
base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="

endpoints <- c("beer", "brewery", "category", "event", "feature", "glass", "guild", "hop", "ingredient", "location", "socialsite", "style", "menu")

# Base function
get_ <- function(id, ep) {
  jsonlite::fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
}

# Create new get_<ep> functions
endpoints %>% walk(~ assign(x = paste0("get_", .x),
                             value = partial(get_, ep = .x),
                             envir = .GlobalEnv))
```

Now we have the functions `get_beer()`, `get_brewery()`, `get_category()`, etc. in our global environment.

Testing testing
========================================================
class:small-code

We get a 200 success response and a nested list of all the data associated with this hop that `fromJSON` converted from, well, JSON into a nested list.


```r
get_hop("3")
```

```
$message
[1] "READ ONLY MODE: Request Successful"

$data
$data$id
[1] 3

$data$name
[1] "Ahtanum"

$data$description
[1] "An open-pollinated aroma variety developed in Washington, Ahtanum is used for its distinctive, somewhat Cascade-like aroma and for moderate bittering."

$data$countryOfOrigin
[1] "US"

$data$alphaAcidMin
[1] 5.7

$data$betaAcidMin
[1] 5

$data$betaAcidMax
[1] 6.5

$data$humuleneMin
[1] 16

$data$humuleneMax
[1] 20

$data$caryophylleneMin
[1] 9

$data$caryophylleneMax
[1] 12

$data$cohumuloneMin
[1] 30

$data$cohumuloneMax
[1] 35

$data$myrceneMin
[1] 50

$data$myrceneMax
[1] 55

$data$farneseneMax
[1] 1

$data$category
[1] "hop"

$data$categoryDisplay
[1] "Hops"

$data$createDate
[1] "2013-06-24 16:07:26"

$data$updateDate
[1] "2013-06-24 16:10:37"

$data$country
$data$country$isoCode
[1] "US"

$data$country$name
[1] "UNITED STATES"

$data$country$displayName
[1] "United States"

$data$country$isoThree
[1] "USA"

$data$country$numberCode
[1] 840

$data$country$createDate
[1] "2012-01-03 02:41:33"



$status
[1] "success"
```


Now with beer
========================================================
class:very-small-code

What does the data look like when we request a certain beer?


```r
get_beer("GZQpRX")
```

```
$message
[1] "READ ONLY MODE: Request Successful"

$data
$data$id
[1] "GZQpRX"

$data$name
[1] "Alpha King"

$data$nameDisplay
[1] "Alpha King"

$data$description
[1] "A bold yet balanced American Pale Ale with slight caramel sweetness and aggressive citrus hoppiness. This is our flagship beer."

$data$abv
[1] "6.7"

$data$ibu
[1] "68"

$data$glasswareId
[1] 5

$data$srmId
[1] 21

$data$availableId
[1] 1

$data$styleId
[1] 25

$data$isOrganic
[1] "N"

$data$labels
$data$labels$icon
[1] "https://s3.amazonaws.com/brewerydbapi/beer/GZQpRX/upload_t1NkG7-icon.png"

$data$labels$medium
[1] "https://s3.amazonaws.com/brewerydbapi/beer/GZQpRX/upload_t1NkG7-medium.png"

$data$labels$large
[1] "https://s3.amazonaws.com/brewerydbapi/beer/GZQpRX/upload_t1NkG7-large.png"


$data$status
[1] "verified"

$data$statusDisplay
[1] "Verified"

$data$createDate
[1] "2012-01-03 02:42:40"

$data$updateDate
[1] "2017-01-10 21:43:48"

$data$glass
$data$glass$id
[1] 5

$data$glass$name
[1] "Pint"

$data$glass$createDate
[1] "2012-01-03 02:41:33"


$data$srm
$data$srm$id
[1] 21

$data$srm$name
[1] "21"

$data$srm$hex
[1] "952D00"


$data$available
$data$available$id
[1] 1

$data$available$name
[1] "Year Round"

$data$available$description
[1] "Available year round as a staple beer."


$data$style
$data$style$id
[1] 25

$data$style$categoryId
[1] 3

$data$style$category
$data$style$category$id
[1] 3

$data$style$category$name
[1] "North American Origin Ales"

$data$style$category$createDate
[1] "2012-03-21 20:06:45"


$data$style$name
[1] "American-Style Pale Ale"

$data$style$shortName
[1] "American Pale"

$data$style$description
[1] "American pale ales range from deep golden to copper in color. The style is characterized by fruity, floral and citrus-like American-variety hop character producing medium to medium-high hop bitterness, flavor, and aroma. Note that the \"traditional\" style of this beer has its origins with certain floral, fruity, citrus-like, piney, resinous, or sulfur-like American hop varietals. One or more of these hop characters is the perceived end, but the perceived hop characters may be a result of the skillful use of hops of other national origins. American pale ales have medium body and low to medium maltiness. Low caramel character is allowable. Fruity-ester flavor and aroma should be moderate to strong. Diacetyl should be absent or present at very low levels. Chill haze is allowable at cold temperatures."

$data$style$ibuMin
[1] "30"

$data$style$ibuMax
[1] "42"

$data$style$abvMin
[1] "4.5"

$data$style$abvMax
[1] "5.6"

$data$style$srmMin
[1] "6"

$data$style$srmMax
[1] "14"

$data$style$ogMin
[1] "1.044"

$data$style$fgMin
[1] "1.008"

$data$style$fgMax
[1] "1.014"

$data$style$createDate
[1] "2012-03-21 20:06:45"

$data$style$updateDate
[1] "2015-04-07 15:25:18"



$status
[1] "success"
```

***

Let's unnest just the fourth element of the `data` part of the response. This is the beer's `description`. 

```r
get_beer("GZQpRX")$data$description
```

```
[1] "A bold yet balanced American Pale Ale with slight caramel sweetness and aggressive citrus hoppiness. This is our flagship beer."
```

Or in other words:

```r
get_beer("GZQpRX")[["data"]][4][[1]]
```

```
[1] "A bold yet balanced American Pale Ale with slight caramel sweetness and aggressive citrus hoppiness. This is our flagship beer."
```


Now with beer
========================================================
class:very-small-code

Other things are more deeply nested. In these cases, we really only care about the name portion.


```r
get_beer("GZQpRX")$data$style$name
```

```
[1] "American-Style Pale Ale"
```


***

Rather than the entire response:


```r
get_beer("GZQpRX")$data$style
```

```
$id
[1] 25

$categoryId
[1] 3

$category
$category$id
[1] 3

$category$name
[1] "North American Origin Ales"

$category$createDate
[1] "2012-03-21 20:06:45"


$name
[1] "American-Style Pale Ale"

$shortName
[1] "American Pale"

$description
[1] "American pale ales range from deep golden to copper in color. The style is characterized by fruity, floral and citrus-like American-variety hop character producing medium to medium-high hop bitterness, flavor, and aroma. Note that the \"traditional\" style of this beer has its origins with certain floral, fruity, citrus-like, piney, resinous, or sulfur-like American hop varietals. One or more of these hop characters is the perceived end, but the perceived hop characters may be a result of the skillful use of hops of other national origins. American pale ales have medium body and low to medium maltiness. Low caramel character is allowable. Fruity-ester flavor and aroma should be moderate to strong. Diacetyl should be absent or present at very low levels. Chill haze is allowable at cold temperatures."

$ibuMin
[1] "30"

$ibuMax
[1] "42"

$abvMin
[1] "4.5"

$abvMax
[1] "5.6"

$srmMin
[1] "6"

$srmMax
[1] "14"

$ogMin
[1] "1.044"

$fgMin
[1] "1.008"

$fgMax
[1] "1.014"

$createDate
[1] "2012-03-21 20:06:45"

$updateDate
[1] "2015-04-07 15:25:18"
```




Unnesting
========================================================
class:small-code

So, we'll unravel the `data` part of the response, grab whatever we want there, and glue it together into a dataframe. 

If the particular list item we're unnesting has a `name` portion (like `$style$name`), great, we'll grab that for the column. Otherwise, we'll take whatever's first.


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

Note that this is a `for` loop so it's pretty slow 😔.

Paginating the Request
========================================================
class: small-code

We find out how many pages there are total and then send requests and unnest each until we hit `number_of_pages`.


```r
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

beer_necessities <- paginated_request("beers", "&withIngredients=Y")
```


Quick note on Ingredients
========================================================
class:small-code
Do they warrant their own columns? I took a few apporaches this question:

* Concatenated into a single string during the unnesting process
  * `hop_name` and `malt_name`
* Split out into one hop per column and one malt per column
  * `hops_name_1`, `hops_name_2`, etc. using this funciton  ↪
* Sparse dataframe with each type of hop (like Cascade, Fuggle, etc.) as its own column 
  * Value is either 1 or 0 

This gives people a few options for working with ingredients.

***


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

![plot of chunk unnamed-chunk-10](brewsentation-figure/unnamed-chunk-10-1.png)




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
* Let's further reduce the levels in our outcome variable by focusing on only popular styles
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

***

From this we can plot the centers of each style.

![plot of chunk unnamed-chunk-12](brewsentation-figure/unnamed-chunk-12-1.png)


To the main question
========================================================
*Do styles truly define distinct pockets of beer?*

If they do, we could expect styles to align with **clusters** generated using an unsupervised learning algorithm. 

* k-means
    * Takes numeric inputs splits for each observation and splits those observations into `k` clusters (we choose `k`)
    * Goal is to minimize the sum of squares between each datapoint and its assigned cluster center

<small>Note that we'll have to throw away rows that contain `NA` values in any of the variables we're using.</small>

What variables should we include?


What's in a Predictor?
========================================================
incremental:false

*A heuristic I used*:

##### Outputs
* Only measured **after** a beer been brewed
    * ABV, IBU, SRM
    
##### Style-Defined
* Dependent entirely on style
  * Serving glass

##### Inputs
* Only directly controlled by a brewer **before** a beer is brewed
    * Hops, malts


***

<br> 
<br> 

👍  predictor  

<br> 
<br> 
<br> 

👎   predictor  

<br> 

🤷🏼‍♀️  predictor because chicken and egg problem  
    <small> Do brewers assign style first and then choose which ingredients to add, or vice versa? 🐣 </small>


Clustering: Let's have a function
========================================================
class: small-code





```r
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

We don't need to specify an outcome variable because this is unsupervised.


Clustering: Run It
========================================================
class: small-code

Cluster the beers and stitch together the cluster assignments with the original data


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


Clustering: Plot
========================================================
class:very-small-code

We've got three main dimensions: ABV, IBU, and SRM. We'll plot color against alcohol here.


<img src="brewsentation-figure/cluster_srm_ibu-1.png" title="plot of chunk cluster_srm_ibu" alt="plot of chunk cluster_srm_ibu" style="display: block; margin: auto;" />

***

Here I've trimmed outliers with this function (you can grab it from my [`dobtools`](https://github.com/aedobbyn/dobtools) package on GitHub.)


```r
trim_outliers <- function(df, cutoff = 1.96, exclude = NULL, keep_scaled = TRUE){

  to_scale <- names(df)[!names(df) %in% exclude]

  df_scaled <- df %>%
    select(!!to_scale) %>%
    transmute_if(
      is.numeric, scale
    )
  names(df_scaled) <- names(df_scaled) %>% stringr::str_c("_scaled")

  df_out <- bind_cols(df_scaled, df)

  df_out_trimmed <- df_out %>%
    filter_at(
      .vars = vars(contains("_scaled")),
      .vars_predicate = all_vars(. < abs(cutoff))
    )

  if(keep_scaled == FALSE) {
    df_out_trimmed <- df_out_trimmed %>% select(!!names(df))
  }

  return(df_out_trimmed)
}
```



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

<small><https://amandadobbyn.shinyapps.io/clusterfun/></small></center>

<center>![clusterfun](./img/clusterfun.jpg)




Narrowing In
========================================================




<br> 
If we focus in on 5 distinct styles and cluster them into 5 clusters, will each style be siphoned off into their own cluster?


|               |   1|  2|   3|   4|  5|
|:--------------|---:|--:|---:|---:|--:|
|Blonde         | 131| 17|   4|   1|  7|
|India Pale Ale |  43|  1| 468|  11| 54|
|Stout          |   6| 10|   3| 180|  5|
|Tripel         |   1| 57|   1|   3|  3|
|Wheat          | 289|  9|   6|   5| 12|


    
***



![plot of chunk cluster_certain_styles](brewsentation-figure/cluster_certain_styles-1.png)

<!-- Not bad; without some taste data or other ingredients, it would be difficult to distinguish wheat beers and blonde ales. -->


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

Hops `\häps\`, *n*: 1. It's what makes beer bitter and flavorful.

<br>

Our question: do more *kinds* of hops generally make a beer more bitter?

<small>(This is different than the total *quantity* of hops poured into a beer.)</small>


Hops Munge
========================================================
class: small-code

Let's munge a bit. We'll need to split out ingredients from one column into many. 


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


Hops Munge
========================================================
class: very-small-code

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
    `N Beers` = n
  )
```


What's the hop landscape look like?
========================================================

|Hop               | Mean IBU| Mean ABV| N Beers|
|:-----------------|--------:|--------:|-------:|
|Cascade           | 51.92405| 6.510729|     445|
|Centennial        | 63.96526| 7.081883|     243|
|Chinook           | 60.86871| 7.043439|     194|
|Simcoe            | 64.07211| 6.877394|     191|
|Columbus          | 63.74483| 6.953846|     183|
|Amarillo          | 61.36053| 6.959264|     163|
|Citra             | 59.60000| 6.733290|     157|
|Willamette        | 39.61078| 7.014657|     133|
|Nugget            | 52.23810| 6.383119|     114|
|Magnum            | 48.71596| 6.926852|     109|
|East Kent Golding | 38.51875| 6.347386|      89|

***


|Hop                        | Mean IBU| Mean ABV| N Beers|
|:--------------------------|--------:|--------:|-------:|
|Perle (American)           | 32.03947| 6.251744|      88|
|Hallertauer (American)     | 23.92388| 5.658537|      83|
|Mosaic                     | 56.81818| 6.977465|      71|
|Northern Brewer (American) | 39.48475| 6.473944|      71|
|Mount Hood                 | 37.83500| 6.550000|      68|
|Warrior                    | 59.13043| 6.983115|      62|
|Saaz (American)            | 30.69778| 6.248333|      60|
|Fuggles                    | 40.75581| 6.772143|      59|
|Tettnanger (American)      | 30.27551| 6.016780|      59|



What's the hop landscape look like?
========================================================
incremental: true
class: small-code


<img src="brewsentation-figure/unnamed-chunk-21-1.png" title="plot of chunk unnamed-chunk-21" alt="plot of chunk unnamed-chunk-21" style="display: block; margin: auto;" />

^ Note that there is actually, irl, a strain of hops called Fuggle.



How do hops affect bitterness?
========================================================
class:small-code
incremental:true

![plot of chunk unnamed-chunk-22](brewsentation-figure/unnamed-chunk-22-1.png)

Is the relationship significant?

***



```r
hops_ibu_lm <- lm(ibu ~ total_hops, data = beer_dat %>% filter(total_hops > 0)) %>% broom::tidy() %>% dobtools::style_lm()
```


```
    Variable Estimate Std.Error P.Value
1 Total Hops    8.635     0.488       0
```

<small>We can expect an increase in around 9 IBU for every 1 extra hop.</small>

Okay back on track!

![onward](./img/onward.gif)




Prediction
========================================================
If beers are well-defined by their styles we should be able to predict style reasonably well using our other available variables.

I used a random forest and a multinomial neural network. We'll go through the neural net.


Prediction: Neural Net
========================================================

* Package: `nnet`
* Outcome variable: `style` or `style_collapsed`

**What we'll do**
* Feed it a dataframe, an outcome variable, and a set of predictor variables
* It will train it 80%, test on 20%
    * From this, we can get a measure of accuracy
    
    
Neural Net: the Function
========================================================
class: small-code





```r
run_neural_net <- function(df, outcome, predictor_vars) {
  out <- list(outcome = outcome)
  
  # Create a new column outcome; default to style
  if (outcome == "style_collapsed") {
    df[["outcome"]] <- df[["style_collapsed"]]
  } else {
    df[["outcome"]] <- df[["style"]]
  }

  cols_to_keep <- c("outcome", predictor_vars)
  
  df <- df %>%
    select_(.dots = cols_to_keep) %>%
    mutate(row = 1:nrow(df)) %>% 
    droplevels()

  # Select 80% of the data for training
  df_train <- sample_n(df, nrow(df)*(0.8))
  
  # The rest is for testing
  df_test <- df %>%
    filter(! (row %in% df_train$row)) %>%
    select(-row)
```

***


```r
  df_train <- df_train %>%
    select(-row)
  
  # Build multinomail neural net
  nn <- multinom(outcome ~ .,
                 data = df_train, maxit=500, trace=TRUE)

  # Which variables are the most important in the neural net?
  most_important_vars <- varImp(nn)

  # How accurate is the model? 
  nn_preds <- predict(nn, type="class", newdata = df_test)
  nn_accuracy <- postResample(df_test$outcome, nn_preds)

  out <- list(out, nn = nn, 
              most_important_vars = most_important_vars,
              df_test = df_test,
              nn_preds = nn_preds,
              nn_accuracy = nn_accuracy)

  return(out)
}
```


Neural Net: Run It
========================================================
class: small-code


```r
p_vars <- c("total_hops", "total_malt", "abv", "ibu", "srm")

nn_collapsed_out <- run_neural_net(df = beer_dat %>% drop_na(!!p_vars), outcome = "style_collapsed", 
                         predictor_vars = p_vars, trace=TRUE)
```

```
# weights:  210 (174 variable)
initial  value 10693.364568 
iter  10 value 9007.861736
iter  20 value 8383.735156
iter  30 value 8154.843641
iter  40 value 8017.693678
iter  50 value 7670.274347
iter  60 value 7507.313838
iter  70 value 7307.286325
iter  80 value 7103.609163
iter  90 value 6802.044987
iter 100 value 6634.900333
iter 110 value 6543.160440
iter 120 value 6441.293317
iter 130 value 6404.665876
iter 140 value 6384.745396
iter 150 value 6379.883760
iter 160 value 6379.179600
iter 170 value 6378.814775
iter 180 value 6378.691773
iter 190 value 6378.660759
iter 200 value 6378.646203
iter 210 value 6378.605387
final  value 6378.598978 
converged
```


Neural Net: Evaluate
========================================================
How'd we do? 


```r
nn_collapsed_out$nn_accuracy
```

```
 Accuracy     Kappa 
0.4002541 0.3449254 
```

Not terrible given we've got 30 collapsed styles; chance would be 3.3%.

***

What's most important?


```r
nn_collapsed_out$most_important_vars
```

```
             Overall
total_hops 56.351555
total_malt 34.265706
abv        33.059746
ibu         3.205657
srm         3.907766
```

Neural Net: Glass
========================================================
class:small-code
What happens if we add in glass, a style-dependent attribute, as a predictor?


```r
p_vars_add_glass <- c("total_hops", "total_malt", "abv", "ibu", "srm", "glass")

nn_collapsed_out_add_glass <- run_neural_net(df = beer_dat %>% drop_na(!!p_vars_add_glass), outcome = "style_collapsed", predictor_vars = p_vars_add_glass, trace=FALSE)
```

***


```
 Accuracy     Kappa 
0.4409800 0.3956737 
```


```
                             Overall
total_hops                 68.423878
total_malt                 70.768022
abv                        33.886420
ibu                         3.474262
srm                         4.295299
glassGoblet               276.438250
glassMug                  282.545603
glassOversized Wine Glass 150.329838
glassPilsner              195.777265
glassPint                 236.818240
glassSnifter              259.878825
glassStange               503.267705
glassThistle              414.189924
glassTulip                244.696154
glassWeizen               150.845423
glassWilli                260.117329
```


So what's the answer?
========================================================
*Are beer styles a useful construct to use as a proxy for natural clusters in beer?*

I'd give it a fuzzy yes.

Fuzzy because:
* We couldn't do better than ~40% accuracy
* We had a lot of missing predictors

Unknowns:
* Was our style collapsing scheme successful in putting beers in the "right" buckets?
* Would taste-related information have been a useful variable?


So what's the answer?
========================================================

![plot of chunk unnamed-chunk-31](brewsentation-figure/unnamed-chunk-31-1.png)

***

* At least on these two dimensions, higher-alcohol and -bitterness styles are more visually distinguishable on these two axes
* No clear super-groups that are independent of style



Future Directions
========================================================
In no particular order, some thoughts I've had plus suggestions from others:

* Join on other data
  * e.g., Untappd or something scraped from the interwebs that provides ratings and flavor profiles
* Beer consumption: how is this trending over time, for each style?
    * What drives the trend? Supply or demand?
        * Do brewers brew more sours causing people buy more of them or do people start liking sours and cause brewers to brew more?
* Shiny features:
    * Beer searchability
    * Tooltips over each point on hover
* Hierarchical clustering; what style is the mother of all styles?
* Some funky algorithm to generate new beer names


Cheers, all!
========================================================
class: very-small-code-transparent  


```
R version 3.3.3 (2017-03-06)
Platform: x86_64-apple-darwin13.4.0 (64-bit)
Running under: macOS Sierra 10.12.6

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
 [1] bindrcpp_0.2    emo_0.0.0.9000  caret_6.0-76    lattice_0.20-35
 [5] nnet_7.3-12     feather_0.3.1   forcats_0.2.0   dplyr_0.7.2    
 [9] purrr_0.2.3     readr_1.1.1     tidyr_0.6.3     tibble_1.3.4   
[13] tidyverse_1.1.1 dobtools_0.1.0  ggrepel_0.6.5   ggplot2_2.2.1  
[17] jsonlite_1.5    broom_0.4.2     knitr_1.17     

loaded via a namespace (and not attached):
 [1] nlme_3.1-131          pbkrtest_0.4-7        lubridate_1.6.0      
 [4] RColorBrewer_1.1-2    httr_1.3.1            tools_3.3.3          
 [7] backports_1.1.0       R6_2.2.2              rpart_4.1-11         
[10] Hmisc_4.0-3           lazyeval_0.2.0        mgcv_1.8-17          
[13] colorspace_1.3-2      gridExtra_2.2.1       mnormt_1.5-5         
[16] rvest_0.3.2           quantreg_5.29         htmlTable_1.9        
[19] SparseM_1.74          xml2_1.1.1            labeling_0.3         
[22] scales_0.5.0          checkmate_1.8.3       psych_1.7.5          
[25] stringr_1.2.0         digest_0.6.12         foreign_0.8-69       
[28] minqa_1.2.4           base64enc_0.1-3       pkgconfig_2.0.1      
[31] htmltools_0.3.6       lme4_1.1-13           highr_0.6            
[34] htmlwidgets_0.9       rlang_0.1.2.9000      readxl_1.0.0         
[37] rstudioapi_0.7.0-9000 shiny_1.0.5.9000      bindr_0.1            
[40] acepack_1.4.1         ModelMetrics_1.1.0    car_2.1-5            
[43] magrittr_1.5          Formula_1.2-2         Matrix_1.2-8         
[46] Rcpp_0.12.13          munsell_0.4.3         stringi_1.1.5        
[49] MASS_7.3-47           plyr_1.8.4            grid_3.3.3           
[52] parallel_3.3.3        crayon_1.3.4          miniUI_0.1.1         
[55] haven_1.1.0           splines_3.3.3         hms_0.3              
[58] ranger_0.8.0          stats4_3.3.3          reshape2_1.4.2       
[61] codetools_0.2-15      glue_1.1.1            evaluate_0.10.1      
[64] latticeExtra_0.6-28   data.table_1.10.4     modelr_0.1.1         
[67] nloptr_1.0.4          httpuv_1.3.5.9000     foreach_1.4.3        
[70] MatrixModels_0.4-1    cellranger_1.1.0      gtable_0.2.0         
[73] assertthat_0.2.0      mime_0.5              xtable_1.8-2         
[76] survival_2.41-3       iterators_1.0.8       cluster_2.0.5        
```






