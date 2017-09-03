# Beer-in-Hand Data Science










***

For some interactive clustering, check out the [Shiny app](https://amandadobbyn.shinyapps.io/clusterfun/) built from the same dataset.



# Motivation and Overview

This is a first pass exploration of different aspects of beer. The 63,000 or so beers worth of data data was collected via the [BreweryDB](http://www.brewerydb.com/developers) API. Special thanks to [Kris Kroski](https://kro.ski/) for data ideation and co-membership in the honourable Workplace Beer Consortium.

The main question this analysis is meant to tackle is: are beer styles actually indicative of shared attributes of the beers within that style? Or are style boundaries more or less arbitrary? Is an IPA an IPA because it's really distinguishable as such from other beers, or is it an IPA because that's what it says on the label? I took two approaches to answer this question: unsupervised clustering and supervised prediction. 

**Clustering and Prediction**

Both of these approaches used a set of predictor variables like ABV (alcohol by volume), IBU (international bitterness units), SRM ([a measure of color](http://www.twobeerdudes.com/beer/srm)) as well as ingredients like hops and malts to quantify how similar or different beers were from one another.

For the clustering portion, I removed each beer's style label and ran a k-means algorithm to assign beers to clusters. The algorithm did this by using certain of these predictors to cluster the beers by minimizing the distance between the center of each cluster in multi-demensional space. The cluster assignments were then compared to the distribution of beers in each style to see whether most beers in a certain style tended to fall into the same cluster. The goal of the prediction section is similar but the approach is different. Here, the style labels were kept in the dataset and used to train a neural net and a random forest on the same set of predictors with the explict goal of using the predictor variables to correctly classify beers into their correct styles. I was interested in how well these models were able to predict style from objective measures like alcohol content and bitterness. My thinking went that if the accuracy of the model is low, that should speak less to the quality of the model than to the fuziness of style boundaries. In other words, if a model has trouble categorizing beers into the correct style, then either a) we are missing several important variables that *are* quite predictive of style, or b) the assignment of styles to beers is more random than systematic.

**What to Expect**

This document gets very much in the weeds in the hopes that anyone else interested in using the same tools to explore questions about beer will be able to easily hit the ground running. It begins with an explanation of how I sourced beer data from BreweryDB, cleaned that data, and stuck the parts of it I wanted in a database. (These are just the highlights; the code actually executed in this document queries that database by sourcing the file `read_from_db.R`, also in this repo, rather than hitting the BreweryDB API. This is done for expediency's sake. The code below detailing how to actually get the beer data, run in full in `run_it.R`, takes some time to execute.)

We then move into clustering and prediction. Below is a more detailed overview of the general workflow. Please send any and all suggestions, beer donations, and ideas for building upon this analysis and my way.

But first, a density plot of the alcohol vs. bitterness landscape, colored by style. What follows is something of a sanity check that our interpetation of this plot is more or less accurate. What I mean by that is that this plot shows two dimensions of a beer landscape of styles that are both somewhat distinct and somewhat overlapping. From this plot I wouldn't expect perfect matches between clusters and styles, nor perfect prediction accuracy from either of our classification models.


![](compile_files/figure-html/density_abv_ibu-1.png)<!-- -->


Finally, a minor note: a few ancillary functions here make use of a [package of helper functions](https://github.com/aedobbyn/dobtools) I've developed. This can be downloaded with `library("devtools"); install_github('aedobbyn/dobtools')`. All of these functions here should be preceded with `dobtools::` but you can of course attach the package with `library(dobtools)` if you like.


### Workflow

**1. Get and Prepare**

The first step here is to hit the BreweryDB API and iteratively pull in all beers and their ingredients. We unnest the JSON responses, including all the ingredients columns (hops and malts), and dump this all into a MySQL database.

Next, we create a `style_collapsed` column to reduce the number of levels of our outcome variable, style. We do this by `grep`ing through each beer's assigned style to determine if that style contains a keyword that qualifies it to be rolled into a collapsed style; if it does, it gets that keyword in a `style_collapsed` column. Otherwise, its uncommon style name is also its `style_collapsed` name.

Finally we unnest the ingredients `hops` and `malts` into a wide, sparse dataframe. Individual ingredients (e.g., Cascade Hops, ) now each occupy their own columns, with each beer still in its own row. A cell gets a 1 if that particular ingredient is present in the beer and a 0 otherwise. This allows us more granularity in our investiation into ingredients' effects on both style and bitterness, occasioning a short foray into hops.

**2. Short foray into hops**

We take a quick detour to look at what the most popular hops are and what the relationship is between hops and bitterness. As the number of distinct types of hops in a beer increases, does its IBU also tend to increase?


**3. Infer**

Back to the question at hand: are styles more arbitrary than not? To operationalize that we ask, if we naively cluster beer based on the numerical attributes available to us, how snugly will distinct styles fit into distinct clusters? We can imagine that if beers in different styles were very different from one another then the clusters assigned to beers would reflect that separation. So, we use k-means clustering on ABV, IBU, SRM, and ingredients to partition the dataset into ten clusters. Next, to simplify things and make the numer of clusters and number of styles equivalent, we filter the dataset to just five selected styles and cluster that into five clusters. 

Then we flip the question slightly and ask: are objective measures of a beer good predictors of its style? To answer it, we feed those objective measures into a random forest and a neural net to try to predict `style` and `style_collapsed`. Again, the main predictors are ABV, IBU, SRM, total number of hops, and total number of malts. We do use the sparser dataframe of all individual types of ingredients to see if that improves the accuracy of the model. Finally, the glass a beer is served in is also considered. 


### Predictor Discussion
The question of what should be a predictor variable for style is a bit murky here. Using characteristics of a beer that are defined *by* its style to predict style would seem to be cheating in a way. In my opinion, a style-defined attribute like glass type is clearly a bad candidate to be a predictor variable because it is determined entirely by the style the beer has been assigned to. That is, it's an attribute of a particular style rather than of any given beer.

In determining which attributes are and aren't fair game to use as predictors of style, we can think about "inputs" to a beer as the only things that can be directly controlled by a brewer before a beer is brewed and "outputs" as characteristics of a beer that can only be measured once the beer has already been brewed. By that defintion, the only inputs we have in our dataset are ingredients: hops and malts. While these certainly have an effect on flavor profile, you could make an argument that they're not good predictor variables because a beer's style is settled on before its recipe is written. If that is the case then style likely determines at least in part which ingredients are added to the beer. 

To my mind, the best candidates for predictor variables are ABV, IBU, and SRM. In the context of the input-output paradigm, these are outputs of a beer because they can only be exactly determined once a beer is brewed. They certainly all meaningfully define it. While ABV is correlated with both IBU and SRM, you could make the argument that the three are theoretically orthogonal to each other. 


### Provisional Answer
Thus far, the answer to the question seems to be that the beer landscape is more of a spectrum than a collection of neatly differentiated styles. That is, style seems to be a construct with little relationship to meaningful attributes of beer.

Beer-intrinsic features like bitterness aren't great predictors of style. We could only reach around 30-40% accuracy with a neural net and a random forest, even using all the possible ingredient data available at the most granular level. In fact, including such sparse ingredient data actually proved detrimental to the accuracy of the model, perhaps because it encouraged overfitting.

The relative importance of different variables depended on the prediction method used. Though one style-defined attribute, the glass a beer is served in, did increase the accuracy of prediction substantially, it still didn't push the model accuracy above 50%. 

Of course it's important to note that other important aspects of the flavor, body, smell, etc. of the beers could not be considered because this data is was available from BreweryDB. Such a publicly-available database of flavor profiles for beers would certainly enrich this analysis and likely make the prediction task much easier.


![](../img/such_taps.jpg)



***


## Get and Prepare Data

**GETting beer (the age-old dilemma)**

All of the beer data was sourced from BreweryDB, a service that allows developers to request up-to-date beer data from the database of 

In order to do that yourself, the first step is to create your BreweryDB API key. Once you have that in hand, you can supply the API with a request and receive a JSON response in return. The function below allows you to specify an endpoint and any additional requests to the URL. You can find a list of available endpoints in the [BreweryDB documentation](http://www.brewerydb.com/developers/docs). You'll want to set the `key` variable used inside the `paginated_request()` function to the API key you create.


```r
base_url <- "http://api.brewerydb.com/v2"
key_preface <- "/?key="
```

The API returns 50 results per page so if we want more than just the first 50 results, we'll have to string a bunch of responses together end to end. For a given endpoint, the API response will specify the total number of pages for that output in `numberOfPages`. So, we use the function below to hit the BreweryDB API and ask for `1:number_of_pages`. This way, if we only want the first 3 pages, say, we can change `number_of_pages` to 3. 

In the case that the response contains only one page (as is the case for the glassware endpoint), `numberOfPages` won't be returned, so we'll set our `number_of_pages` to 1. The `addition` parameter can be an empty string if nothing else is needed.


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

all_beer_raw <- paginated_request("beers", "&withIngredients=Y")
```



If you want to request information associated with a single entity ID, you can use this little function factory here to create functions to GET any beer, brewery, category, etc. if you know its ID.


```r
endpoints <- c("beer", "brewery", "category", "event",
              "feature", "glass", "guild", "hop", "ingredient",
              "location", "socialsite", "style", "menu")

# Base function
get_ <- function(id, ep) {
  fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
}

# For each of the endoints, pipe each endpoint through
# as .x, so both as the second half of the get_<ep> function name
# and the second argument of the get_ function defined above (so the ep in the fromJSON() call) 
endpoints %>% walk(~ assign(x = paste0("get_", .x),
                             value = partial(get_, ep = .x),
                             envir = .GlobalEnv))
```

Now for instance we can get all the information on a single brewery from just its ID (only first part of response shown):

```r
get_hop("3")$data %>% head()
```

```
## $id
## [1] 3
## 
## $name
## [1] "Ahtanum"
## 
## $description
## [1] "An open-pollinated aroma variety developed in Washington, Ahtanum is used for its distinctive, somewhat Cascade-like aroma and for moderate bittering."
## 
## $countryOfOrigin
## [1] "US"
## 
## $alphaAcidMin
## [1] 5.7
## 
## $betaAcidMin
## [1] 5
```


Now that we've got all our raw data, we'll have to unnest it properly. We'll use this function `unnest_it()` inside `paginated_request()`. It takes the column named `name` nested within a column in the data portion of the response. (You'll see above that was "Ahtanum.") If the `name` column doesn't exist, it takes the first nested column.

We use something similar to unnest ingredients like all of a beer's hops and malts into a comma-delimited string contained in `hops_name` and `malt_name`.


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

Cool. So we'll save our new dataframe as `beer_necessities` and do some further processing on it.


**Collapse Styles**

It'll be useful to reduce the number of levels in our outcome variable, style. To that end, we create a new variable, `style_collapsed` that uses keywords inside a style's name to lump it into a broader category. This way we can use the text of the styles themselves to define broader styles with more beers in them than are otherwise available from the API. 

The way we'll do this is we'll save our overarching collapsed styles in the vector `keywords`. 

```r
keywords <- c("Lager", "Pale Ale", "India Pale Ale", "Double India Pale Ale", "India Pale Lager", "Hefeweizen", "Barrel-Aged","Wheat", "Pilsner", "Pilsener", "Amber", "Golden", "Blonde", "Brown", "Black", "Stout", "Imperial Stout", "Fruit", "Porter", "Red", "Sour", "Kölsch", "Tripel", "Bitter", "Saison", "Strong Ale", "Barley Wine", "Dubbel")

keyword_df <- as_tibble(list(`Main Styles` = keywords))
# kable(keyword_df)
```


Then we loop through each keyword. For each beer in our dataset, we `grep` through its style name to see if it contains any one of these keywords. If it does, give it that keyword in a new column `style_collapsed`. 

Importantly, if a beer's name matches multiple keywords, e.g., American Double India Pale Ale would match Double India Pale Ale, India Pale Ale, and Pale Ale, its `style_collapsed` is the **last** of those that appear in keyword; this is why keywords are intentionally ordered from most general to most specific. So in the case of an case of American Double India Pale Ale, since Double India Pale Ale appears in `keywords` after India Pale Ale and Pale Ale, an American Double India Pale Ale would get a `style_collapsed` of Double India Pale Ale.

If a beer's `style` doesn't contain any of the keywords, its `style_collapsed` is the same as its `style`; in other words, it doesn't get collpsed into a bigger bucket. This isn't a huge problem because we'll pare the data down to just the most popular styles later. (However, we could think about throwing them all into a catchall "Other" level.)
  

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


Then we'll collapse a few styles even further based on some knowledge of beer similarity. For now, all this means is that we'll combine all wheaty bears into Wheat and Pils-like beers into Pilsener (with two e's) by `fct_collapse`ing those levels. I'd be interested to hear if people think we should also collapse other similar styles. Or, on the other hand, are there collapsed styles that are too broad?


```r
collapse_further <- function(df) {
  df[["style_collapsed"]] <- df[["style_collapsed"]] %>%
    fct_collapse(
      "Wheat" = c("Hefeweizen", "Wheat"),
      "Pilsener" = c("Pilsner", "American-Style Pilsener") # pilsener == pilsner == pils
    )
  return(df)
}
```



**Split out Ingredients**

When we unnested ingredients from the raw JSON, we simply concatenated all of the ingredients for a given beer into a long, comma-separated string. That's what populates the `hops_name` and `malt_name` columns. It could be useful to split out these ingredients with this `split_ingredients` function.

This takes a vector of `ingredients_to_split`, so e.g. `c("hops_name", "malt_name")` and creates one column for each type of ingredient (`hops_name_1`, `hops_name_2`, etc.). It's flexible enough to adapt if the data in BreweryDB changes and a beer now has 15 hops where originally the maximum number of hops a beer had was 10.


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


We'll take a look at our new column names of our dataframe, `beer_necessities` of 63495 rows and 39 columns:

```r
names(beer_necessities)
```

```
##  [1] "id"               "name"             "description"     
##  [4] "style"            "abv"              "ibu"             
##  [7] "srm"              "glass"            "hops_name"       
## [10] "hops_id"          "malt_name"        "malt_id"         
## [13] "glasswareId"      "styleId"          "style.categoryId"
## [16] "style_collapsed"  "hops_name_1"      "hops_name_2"     
## [19] "hops_name_3"      "hops_name_4"      "hops_name_5"     
## [22] "hops_name_6"      "hops_name_7"      "hops_name_8"     
## [25] "hops_name_9"      "hops_name_10"     "hops_name_11"    
## [28] "hops_name_12"     "hops_name_13"     "malt_name_1"     
## [31] "malt_name_2"      "malt_name_3"      "malt_name_4"     
## [34] "malt_name_5"      "malt_name_6"      "malt_name_7"     
## [37] "malt_name_8"      "malt_name_9"      "malt_name_10"
```


For prettier dataset printing, we'll define a quick function that we'll use in conjunction with `purrr::map()` and `dobtools::cap_it()` on a vector of column names and soemtimes all the rows in a column. 
The `cap_it()` function from the dobtools package will capitalize the first letter of each word in each string it's provided and split on underscores and periods. That way we can transform column names like `foo_bar` into `Foo Bar`. The only wrinkle is that column names `abv`, `ibu`, `srm`, and `id` need to be in all caps instead of just their first letter being capitalized. Both `cap_it()` and this new function we'll define, `beer_caps()`, operate on a single element so we'll use them with `map()` to iterate and then finally pass the result through `as_vector()` to turn the result from a list back into a vector.


```r
beer_caps <- function(to_cap) {
  if(to_cap %in% c("abv", "ibu", "srm", "id",
                 "Abv", "Ibu", "Srm", "Id")) {
  to_cap <- to_cap %>% toupper()
  } else {
     to_cap <- to_cap              
  }
  return(to_cap)
}
```

We can do this with the `beer_necessities` column names vector:

```r
names(beer_necessities) %>% map(cap_it) %>% map(beer_caps) %>% as_vector() 
```

```
##  [1] "ID"               "Name"             "Description"     
##  [4] "Style"            "ABV"              "IBU"             
##  [7] "SRM"              "Glass"            "Hops Name"       
## [10] "Hops Id"          "Malt Name"        "Malt Id"         
## [13] "GlasswareId"      "StyleId"          "Style CategoryId"
## [16] "Style Collapsed"  "Hops Name 1"      "Hops Name 2"     
## [19] "Hops Name 3"      "Hops Name 4"      "Hops Name 5"     
## [22] "Hops Name 6"      "Hops Name 7"      "Hops Name 8"     
## [25] "Hops Name 9"      "Hops Name 10"     "Hops Name 11"    
## [28] "Hops Name 12"     "Hops Name 13"     "Malt Name 1"     
## [31] "Malt Name 2"      "Malt Name 3"      "Malt Name 4"     
## [34] "Malt Name 5"      "Malt Name 6"      "Malt Name 7"     
## [37] "Malt Name 8"      "Malt Name 9"      "Malt Name 10"
```

We've covered our bases with `beer_caps()` by also including "Abv", "Ibu", "Srm" in the `if` statement so that we can safely call `beer_caps()` before or after `cap_it()` and end up with the same result.


Now we'll want to get a sense of the distribution and spread of beers in our dataset. First off, we'll ask: which collapsed styles do the majority of beers in the database fall into?


**Find the Most Popualar Styles**

We find the mean ABV, IBU, and SRM per collapsed style and arrange collapsed styles by the number of beers that fall into them. (Of course, the collapsed style that a beer falls into is dependent on how we collapse styles; if we looped all Double IPAs in with IPAs then the category IPA would be much bigger than it is if we keep the two separate.)

Then we'll drop beers that belong to styles that are below the mean popularity.


```r
library(forcats)

# Pare down to only cases where style is not NA
beer_dat_pared <- beer_necessities[complete.cases(beer_necessities$style), ]

# Arrange by style popularity
style_popularity <- beer_dat_pared %>% 
  group_by(style) %>% 
  count() %>% 
  arrange(desc(n))

# Add a column that z-scores popularity
style_popularity <- bind_cols(style_popularity, 
                               n_scaled = as.vector(scale(style_popularity$n)))

# Find styles that are above a z-score of 0 (the mean)
popular_styles <- style_popularity %>% 
  filter(n_scaled > 0)

# Pare dat down to only beers that fall into those styles, so styles that are above mean popularity
popular_beer_dat <- beer_dat_pared %>% 
  filter(
    style %in% popular_styles$style
  ) %>% 
  droplevels() %>% 
  as_tibble() 
```


We're left with 45871 in our dataset of just beers that fall into the popular styles, down from 63495 in the original dataset.)


Now we can find what I'm calling the "style centers" for each of these most popular styles. The center is defined by the mean ABV, mean IBU, and mean SRM of all of the beers in that style. 

You'll notice that there are beers with a `style_collapsed` that are not in one of the keywords (e.g., Pumpkin beer). Styles that appear here that did not appear in the keywords that we collapsed to are the most popular styles that did not contain one of those keywords. Recall that if a keyword did not appear in a style name, its `style_collapsed` was made the same as its `style`.


```r
# Find the centers (mean ABV, IBU, SRM) of the most popular styles
style_centers <- popular_beer_dat %>% 
  group_by(style_collapsed) %>% 
  add_count() %>% 
  summarise(
    mean_abv = mean(abv, na.rm = TRUE) %>% round(., digits = 2),
    mean_ibu = mean(ibu, na.rm = TRUE) %>% round(., digits = 2), 
    mean_srm = mean(srm, na.rm = TRUE) %>% round(., digits = 2),
    n = median(n, na.rm = TRUE)          # Median here only for summarise. Should be just the same as n
  ) %>% 
  arrange(desc(n)) %>% 
  drop_na() %>% 
  droplevels()

# Give some nicer names
style_centers_rename <- style_centers %>% 
  rename(
    `Collapsed Style` = style_collapsed,
    `Mean ABV` = mean_abv,
    `Mean IBU` = mean_ibu,
    `Mean SRM` = mean_srm,
    `Numer of Beers` = n
  )
```


Take a look at the table, ordered by number of beers in that style, descending.      


|Collapsed Style          | Mean ABV| Mean IBU| Mean SRM| Numer of Beers|
|:------------------------|--------:|--------:|--------:|--------------:|
|India Pale Ale           |     6.58|    66.04|     9.99|           6524|
|Pale Ale                 |     5.70|    40.87|     8.89|           4280|
|Stout                    |     7.99|    43.90|    36.30|           4238|
|Wheat                    |     5.16|    17.47|     5.86|           3349|
|Double India Pale Ale    |     8.93|    93.48|    11.01|           2525|
|Red                      |     5.74|    33.81|    16.18|           2521|
|Lager                    |     5.45|    30.64|     8.46|           2230|
|Saison                   |     6.40|    27.25|     7.05|           2167|
|Blonde                   |     5.60|    22.39|     5.62|           2044|
|Porter                   |     6.18|    33.25|    32.20|           1973|
|Brown                    |     6.16|    32.22|    23.59|           1462|
|Pilsener                 |     5.23|    33.51|     4.41|           1268|
|Specialty Beer           |     6.45|    33.78|    15.52|           1044|
|Bitter                   |     5.32|    38.28|    12.46|            939|
|Fruit Beer               |     5.20|    19.24|     8.67|            905|
|Herb and Spice Beer      |     6.62|    27.77|    18.17|            872|
|Sour                     |     6.22|    18.89|    10.04|            797|
|Strong Ale               |     8.83|    36.74|    22.55|            767|
|Tripel                   |     9.03|    32.52|     7.68|            734|
|Black                    |     6.96|    65.51|    31.08|            622|
|Barley Wine              |    10.78|    74.05|    19.56|            605|
|Kölsch                   |     4.98|    23.37|     4.37|            593|
|Barrel-Aged              |     9.00|    39.16|    18.13|            540|
|Other Belgian-Style Ales |     7.52|    37.56|    17.55|            506|
|Pumpkin Beer             |     6.71|    23.48|    17.92|            458|
|Dubbel                   |     7.51|    25.05|    22.94|            399|
|Scotch Ale               |     7.62|    26.37|    24.22|            393|
|German-Style Doppelbock  |     8.05|    28.89|    25.70|            376|
|Fruit Cider              |     6.21|    25.60|    12.00|            370|
|German-Style Märzen      |     5.75|    25.64|    14.32|            370|



***





**Get Granular with Ingredients**

The lifecycle of ingredients in our data munging process thus far has been to first unnest them from the raw JSON into a long string contained in `hops_name` and `malt_name`. Next each ingredient in each of those columns was split out into `hops_name_1`, `hops_name_2`, etc.

To get more granular with ingredients, we can further split out each individual ingredient name (here we're talking name as in Citra hops) into its own column. If a beer or style contains that ingredient, its row gets a 1 in that ingredient column and a 0 otherwise.

From this, we can find the total number of hops and malts per beer. Of course, there's no particular reason why we couldn't have gotten that from the `hops_name_1`, `hops_name_2` step. 



The function below takes a dataframe and two other parameters set at the outset: `ingredient_want`, which can be `hops`, `malt`, or other ingredients like `yeast` if we pull that in, and `grouper` which can be a vector of one or more things to group by, like beer `id` or `style`. (Careful with using `name` as a grouper as multiple beers have the same name; beer ID is of course unique.) Your `grouper` will be whatever you're grouping by in rows. If it's `style` and your `ingredient_want` is `malt` you'll get all the malts in columns and all the styles in rows.

Here we'll get both and join the resulting dataframes by beer ID.

More information on what the funciton is doing at each point in the comments.


```r
pick_ingredient_get_beer <- function (ingredient_want, df, grouper) {
  
  # ----------------------- Setup --------------------------- #
  # We've already split ingredient number names out from the concatenated string into columns like `malt_name_1`,
  # `malt_name_2`, etc. We need to find the range of these columns; there will be a different number of malt
  # columns than hops columns, for instance. The first one will be `<ingredient>_name_1` and from this we can find
  # the index of this column in our dataframe. We get the name of last one with the `get_last_ing_name_col()`
  # function. Then we save a vector of all the ingredient column names in `ingredient_colnames`. It will stay
  # constant even if the indices change when we select out certain columns. 
  
  # First ingredient
  first_ingredient_name <- paste(ingredient_want, "_name_1", sep="")
  first_ingredient_index <- which(colnames(df)==first_ingredient_name)
  
  # Get the last ingredient
  get_last_ing_name_col <- function(df) {
    for (col in names(df)) {
      if (grepl(paste(ingredient_want, "_name_", sep = ""), col) == TRUE) {
        name_last_ing_col <- col
      }
    }
    return(name_last_ing_col)
  }
  
  # Last ingredient
  last_ingredient_name <- get_last_ing_name_col(df)
  last_ingredient_index <- which(colnames(df)==last_ingredient_name)
  
  # Vector of all the ingredient column names
  ingredient_colnames <- names(df)[first_ingredient_index:last_ingredient_index]
  
  # Non-ingredient column names we want to keep
  to_keep_col_names <- c("id", "cluster_assignment", "name", "abv", "ibu", "srm", "style", "style_collapsed")
  
  # -------------------------------------------------------------------------------# 
  
  # Inside `gather_ingredients()` we take out superflous column names that are not in `to_keep_col_names` or one 
  # of the ingredient columns, find what the new ingredient column indices are, since they'll have changed after 
  # we pared down and then gather all of the ingredient columns (e.g., `hops_name_1`) into one long column, 
  # `ing_keys` and all the actual ingredient names (e.g., Cascade) into `ing_names`.
  
  # ----------------------------- Gather columns --------------------------------- #
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
    return(df_gathered)
  }
  beer_gathered <- gather_ingredients(df, ingredient_colnames)  # ingredient colnames defined above function
  # ------------------------------------------------------------------------------- # 
  
  # Next we get a vector of all ingredient levels and take out the one that's an empty string and 
  # use this vector of ingredient levels in `select_spread_cols()` below

  # Get a vector of all ingredient levels
  beer_gathered$ing_names <- factor(beer_gathered$ing_names)
  ingredient_levels <- levels(beer_gathered$ing_names) 
  
  # Take out the level that's just an empty string
  to_keep_levels <- !(c(1:length(ingredient_levels)) %in% which(ingredient_levels == ""))
  ingredient_levels <- ingredient_levels[to_keep_levels]
  
  beer_gathered$ing_names <- as.character(beer_gathered$ing_names)
  
  # ----------------------------------------------------------------------------- # 
  
  # Then we spread the ingredient names: we take what was previously the `value` in our gathered dataframe, the
  # actual ingredient names (Cascade, Centennial) and make that our `key`; it'll form the new column names. The
  # new `value` is `value` is count; it'll populate the row cells. If a given row has a certain ingredient, it
  # gets a 1 in the corresponding cell, an NA otherwise. 
  # We add a unique idenfitier for each row with `row`, which we'll drop later (see [Hadley's SO
  # comment](https://stackoverflow.com/questions/25960394/unexpected-behavior-with-tidyr)).

  
  # ------------------------------- Spread columns -------------------------------- #
  spread_ingredients <- function(df) {
    df_spread <- df %>% 
      mutate(
        row = 1:nrow(df)        # Add a unique idenfitier for each row which we'll need in order to spread; we'll drop this later
      ) %>%                                 
      spread(
        key = ing_names,
        value = count
      ) 
    return(df_spread)
  }
  beer_spread <- spread_ingredients(beer_gathered)
  # ------------------------------------------------------------------------------- # 

  
  # ------------------------- Select only certain columns ------------------------- #
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
  # ------------------------------------------------------------------------------- # 

  # Take out all rows that have no ingredients specified at all
  inds_to_remove <- apply(beer_spread_selected[, first_ingredient_index:last_ingredient_index], 
                          1, function(x) all(is.na(x)))
  beer_spread_no_na <- beer_spread_selected[ !inds_to_remove, ]
  
  
  # ----------------- Group ingredients by the grouper specified ------------------- #
  # Then we do the final step and group by the groupers.
  
  get_ingredients_per_grouper <- function(df, grouper = grouper) {
    df_grouped <- df %>%
      ungroup() %>% 
      group_by_(grouper)
    
    not_for_summing <- which(colnames(df_grouped) %in% to_keep_col_names)
    max_not_for_summing <- max(not_for_summing)
    
    per_grouper <- df_grouped %>% 
      select(-c(abv, ibu, srm)) %>%    # taking out temporarily
      summarise_if(
        is.numeric,              
        sum, na.rm = TRUE
      ) %>%
      mutate(
        total = rowSums(.[(max_not_for_summing + 1):ncol(.)], na.rm = TRUE)    
      )
    
    # Send total to the second position
    per_grouper <- per_grouper %>% 
      select(
        id, total, everything()
      )
    
    # Replace total column with more descriptive name: total_<ingredient>
    names(per_grouper)[which(names(per_grouper) == "total")] <- paste0("total_", ingredient_want)
    
    return(per_grouper)
  }
  # ------------------------------------------------------------------------------- # 
  
  ingredients_per_grouper <- get_ingredients_per_grouper(beer_spread_selected, grouper)
  return(ingredients_per_grouper)
}
```


Now we run the function with `ingredient_want` as first hops, and then malt. Then we join the resulting dataframes and remove/reorder some columns.


```r
# Run the entire function with ingredient_want set to hops, grouping by name
ingredients_per_beer_hops <- pick_ingredient_get_beer(ingredient_want = "hops", 
                                                      beer_necessities, 
                                                      grouper = c("id"))

# Same for malt
ingredients_per_beer_malt <- pick_ingredient_get_beer(ingredient_want = "malt", 
                                                      beer_necessities, 
                                                      grouper = c("id"))

# Join those on our original dataframe by name
beer_ingredients_join_first_ingredient <- left_join(beer_necessities, ingredients_per_beer_hops,
                                                    by = "id")
beer_ingredients_join_all <- left_join(beer_ingredients_join_first_ingredient, ingredients_per_beer_malt,
                                   by = "id")


# Take out some unnecessary columns
unnecessary_cols <- c("styleId", "abv_scaled", "ibu_scaled", "srm_scaled", 
                      "hops_id", "malt_id", "glasswareId", "style.categoryId")
beer_ingredients_join_all <- beer_ingredients_join_all[, (! names(beer_ingredients_join_all) %in% unnecessary_cols)]


# If we also want to take out any of the malt_name_1, malt_name_2, etc. columns we can do this with a grep
more_unnecessary <- c("hops_name_|malt_name_")
beer_ingredients_join_all <- 
  beer_ingredients_join_all[, (! grepl(more_unnecessary, names(beer_ingredients_join_all)) == TRUE)]

# Reorder columns a bit
beer_ingredients_join_all <- beer_ingredients_join_all %>% 
  select(
    id, name, total_hops, total_malt, everything(), -description
  )

# Keep only beers that fall into a style_collapsed bucket
# We're not filtering by levels in beer_necessities$style_collapsed because those levels contain more than what's in just the keywords of collapse_styles()
beer_dat_sparse <- beer_ingredients_join_all %>% 
  filter(
    style_collapsed %in% levels(style_centers$style_collapsed)
  ) %>% 
  droplevels()

# And get a df that includes total_hops and total_malt but not all the other ingredient columns
beer_totals_all <- beer_ingredients_join_all %>% 
  select(
    id, name, total_hops, total_malt, style, style_collapsed,
    abv, ibu, srm, glass, hops_name, malt_name
  )

# And just styles in style_collapsed
beer_dat <- beer_dat_sparse %>% 
  filter(
    style_collapsed %in% levels(style_centers$style_collapsed)
  ) %>% 
  droplevels()
```


  
  
  

Now we're left with something of a sparse matrix of all the ingredients compared to all the beers. Scroll right to see the extent of the granularity this affords us.

For instance, if certain hops or malts are very predictive of style, we can incorporate this easily into a model.


```r
kable(beer_dat_sparse[1:10, ])
```



|id     |name                                                        | total_hops| total_malt|style                         |   abv| ibu| srm|glass |hops_name                         |malt_name                                                   |style_collapsed | #06300| Admiral| Aged / Debittered Hops (Lambic)| Ahtanum| Alchemy| Amarillo| Amarillo Gold| Apollo| Aquila| Aramis| Argentine Cascade| Athanum| Aurora| Australian Dr. Rudi| Azacca| Azzeca| Belma| Bobek| Bramling Cross| Bravo| Brewer's Gold| Brewer's Gold (American)| Calypso| Cascade| Celeia| Centennial| Challenger| Chinook| Citra| Cluster| Cobb| Columbus| Columbus (Tomahawk)| Comet| Crystal| CTZ| Delta| East Kent Golding| El Dorado| Ella| Enigma| Equinox| Eureka| Experimental 05256| Experimental 06277| Falconer's Flight| First Gold| French Strisserspalt| French Triskel| Fuggle (American)| Fuggle (English)| Fuggles| Galaxy| Galena| German Magnum| German Mandarina Bavaria| German Opal| German Perle| German Polaris| German Select| German Tradition| Glacier| Golding (American)| Green Bullet| Hallertau Hallertauer Mittelfrüher| Hallertau Hallertauer Tradition| Hallertau Northern Brewer| Hallertauer (American)| Hallertauer Herkules| Hallertauer Hersbrucker| Hallertauer Perle| Hallertauer Select| Helga| Hop Extract| Hops| Horizon| Huell Melon| Idaho 7| Jarrylo| Kent Goldings| Kohatu| Lemon Drop| Liberty| Magnum| Marynka| Meridian| Millenium| Mosaic| Motueka| Mount Hood| Mt. Rainier| Nelson Sauvin| New Zealand Hallertauer| New Zealand Motueka| New Zealand Sauvin| Newport| Noble| Northdown| Northern Brewer (American)| Nugget| Orbit| Pacific Gem| Pacific Jade| Pacifica| Palisades| Perle (American)| Phoenix| Pilgrim| Premiant| Pride of Ringwood| Rakau| Revolution| Saaz (American)| Saaz (Czech)| Santiam| Saphir (German Organic)| Simcoe| Sladek (Saaz)| Sorachi Ace| Southern Cross| Sovereign| Spalt| Spalt Select| Spalt Spalter| Sterling| Sticklebract| Strisselspalt| Styrian Aurora| Styrian Bobeks| Styrian Goldings| Summit| Super Galena| Target| Tettnang Tettnanger| Tettnanger (American)| Tomahawk| Topaz| Tradition| Ultra| Vanguard| Vic Secret| Waimea| Wakatu| Warrior| Willamette| Yakima Willamette| Zeus| Zythos| Abbey Malt| Acidulated Malt| Amber Malt| Aromatic Malt| Asheburne Mild Malt| Bamberg Smoked Malt| Barley - Black| Barley - Flaked| Barley - Lightly Roasted| Barley - Malted| Barley - Raw| Barley - Roasted| Barley - Roasted/De-husked| Beechwood Smoked| Belgian Pale| Belgian Pilsner| Biscuit Malt| Black Malt| Black Malt - Debittered| Black Malt - Organic| Black Patent| Black Roast| Blackprinz Malt| Blue Agave Nectar| Blue Corn| Bonlander| Briess 2-row Chocolate Malt| Briess Blackprinz Malt| British Pale Malt| Brown Malt| Brown Sugar| Buckwheat - Roasted| C-15| Canada 2-Row Silo| Cane Sugar| Cara Malt| CaraAmber| CaraAroma| CaraBrown| Carafa I| Carafa II| Carafa III| Carafa Special| CaraFoam| CaraHell| Caramel/Crystal Malt| Caramel/Crystal Malt - Dark| Caramel/Crystal Malt - Extra Dark| Caramel/Crystal Malt - Heritage| Caramel/Crystal Malt - Light| Caramel/Crystal Malt - Medium| Caramel/Crystal Malt - Organic| Caramel/Crystal Malt 10L| Caramel/Crystal Malt 120L| Caramel/Crystal Malt 150L| Caramel/Crystal Malt 15L| Caramel/Crystal Malt 20L| Caramel/Crystal Malt 300L| Caramel/Crystal Malt 30L| Caramel/Crystal Malt 40L| Caramel/Crystal Malt 45L| Caramel/Crystal Malt 50L| Caramel/Crystal Malt 55L| Caramel/Crystal Malt 60L| Caramel/Crystal Malt 70L| Caramel/Crystal Malt 75L| Caramel/Crystal Malt 80L| Caramel/Crystal Malt 85L| Caramel/Crystal Malt 8L| Caramel/Crystal Malt 90L| CaraMunich| CaraMunich 120L| CaraMunich 20L| CaraMunich 40L| CaraMunich 60L| CaraMunich I| CaraMunich II| CaraMunich III| CaraPils/Dextrin Malt| CaraRed| CaraRye| CaraStan| CaraVienne Malt| CaraWheat| Carolina Rye Malt| Cereal| Cherry Smoked| Cherrywood Smoke Malt| Chit Malt| Chocolate Malt| Chocolate Rye Malt| Chocolate Wheat Malt| Coffee Malt| Corn| Corn - Field| Corn - Flaked| Corn Grits| Crisp 120| Crisp 77| Crystal 77| Dark Chocolate| Dememera Sugar| Dextrin Malt| Dextrose Syrup| Extra Special Malt| Fawcett Crystal Rye| Fawcett Rye| German Cologne| Gladfield Pale| Glen Eagle Maris Otter| Golden Promise| Harrington 2-Row Base Malt| High Fructose Corn Syrup| Honey| Honey Malt| Hugh Baird Pale Ale Malt| Kiln Amber| Lactose| Lager Malt| Malt Extract| Malted Rye| Malto Franco-Belge Pils Malt| Maple Syrup| Maris Otter| Melanoidin Malt| Metcalfe| Midnight Wheat| Mild Malt| Millet| Munich Malt| Munich Malt - Dark| Munich Malt - Light| Munich Malt - Organic| Munich Malt - Smoked| Munich Malt - Type I| Munich Malt - Type II| Munich Malt 10L| Munich Malt 20L| Munich Malt 40L| Munich Wheat| Oats - Flaked| Oats - Golden Naked| Oats - Malted| Oats - Rolled| Oats - Steel Cut (Pinhead Oats)| Oats - Toasted| Pale Chocolate Malt| Pale Malt| Pale Malt - Halcyon| Pale Malt - Optic| Pale Malt - Organic| Pale Wheat| Palev| Pearl Malt| Peated Malt - Smoked| Piloncillo| Pilsner Malt| Pilsner Malt - Organic| Rahr 2-Row Malt| Rahr Special Pale| Rauchmalz| Rice| Rice - Flaked| Rice - Hulls| Rice - Red| Rice - White| Roast Malt| Rye - Flaked| Rye Malt| Samuel Adams two-row pale malt blend| Six-Row Pale Malt| Smoked Malt| Special B Malt| Special Roast| Special W Malt| Spelt Malt| Sugar (Albion)| Toasted Malt| Torrefied Wheat| Two-Row Barley Malt| Two-Row Pale Malt| Two-Row Pale Malt - Organic| Two-Row Pale Malt - Toasted| Two-Row Pilsner Malt| Two-Row Pilsner Malt - Belgian| Two-Row Pilsner Malt - Germany| Victory Malt| Vienna Malt| Weyermann Rye| Wheat - Flaked| Wheat - Raw| Wheat - Red| Wheat - Toasted| Wheat - Torrified| Wheat Malt| Wheat Malt - Dark| Wheat Malt - German| Wheat Malt - Light| Wheat Malt - Organic| Wheat Malt - Red| Wheat Malt - Smoked| Wheat Malt - White| White Wheat| Wyermann Vienna|
|:------|:-----------------------------------------------------------|----------:|----------:|:-----------------------------|-----:|---:|---:|:-----|:---------------------------------|:-----------------------------------------------------------|:---------------|------:|-------:|-------------------------------:|-------:|-------:|--------:|-------------:|------:|------:|------:|-----------------:|-------:|------:|-------------------:|------:|------:|-----:|-----:|--------------:|-----:|-------------:|------------------------:|-------:|-------:|------:|----------:|----------:|-------:|-----:|-------:|----:|--------:|-------------------:|-----:|-------:|---:|-----:|-----------------:|---------:|----:|------:|-------:|------:|------------------:|------------------:|-----------------:|----------:|--------------------:|--------------:|-----------------:|----------------:|-------:|------:|------:|-------------:|------------------------:|-----------:|------------:|--------------:|-------------:|----------------:|-------:|------------------:|------------:|----------------------------------:|-------------------------------:|-------------------------:|----------------------:|--------------------:|-----------------------:|-----------------:|------------------:|-----:|-----------:|----:|-------:|-----------:|-------:|-------:|-------------:|------:|----------:|-------:|------:|-------:|--------:|---------:|------:|-------:|----------:|-----------:|-------------:|-----------------------:|-------------------:|------------------:|-------:|-----:|---------:|--------------------------:|------:|-----:|-----------:|------------:|--------:|---------:|----------------:|-------:|-------:|--------:|-----------------:|-----:|----------:|---------------:|------------:|-------:|-----------------------:|------:|-------------:|-----------:|--------------:|---------:|-----:|------------:|-------------:|--------:|------------:|-------------:|--------------:|--------------:|----------------:|------:|------------:|------:|-------------------:|---------------------:|--------:|-----:|---------:|-----:|--------:|----------:|------:|------:|-------:|----------:|-----------------:|----:|------:|----------:|---------------:|----------:|-------------:|-------------------:|-------------------:|--------------:|---------------:|------------------------:|---------------:|------------:|----------------:|--------------------------:|----------------:|------------:|---------------:|------------:|----------:|-----------------------:|--------------------:|------------:|-----------:|---------------:|-----------------:|---------:|---------:|---------------------------:|----------------------:|-----------------:|----------:|-----------:|-------------------:|----:|-----------------:|----------:|---------:|---------:|---------:|---------:|--------:|---------:|----------:|--------------:|--------:|--------:|--------------------:|---------------------------:|---------------------------------:|-------------------------------:|----------------------------:|-----------------------------:|------------------------------:|------------------------:|-------------------------:|-------------------------:|------------------------:|------------------------:|-------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|------------------------:|-----------------------:|------------------------:|----------:|---------------:|--------------:|--------------:|--------------:|------------:|-------------:|--------------:|---------------------:|-------:|-------:|--------:|---------------:|---------:|-----------------:|------:|-------------:|---------------------:|---------:|--------------:|------------------:|--------------------:|-----------:|----:|------------:|-------------:|----------:|---------:|--------:|----------:|--------------:|--------------:|------------:|--------------:|------------------:|-------------------:|-----------:|--------------:|--------------:|----------------------:|--------------:|--------------------------:|------------------------:|-----:|----------:|------------------------:|----------:|-------:|----------:|------------:|----------:|----------------------------:|-----------:|-----------:|---------------:|--------:|--------------:|---------:|------:|-----------:|------------------:|-------------------:|---------------------:|--------------------:|--------------------:|---------------------:|---------------:|---------------:|---------------:|------------:|-------------:|-------------------:|-------------:|-------------:|-------------------------------:|--------------:|-------------------:|---------:|-------------------:|-----------------:|-------------------:|----------:|-----:|----------:|--------------------:|----------:|------------:|----------------------:|---------------:|-----------------:|---------:|----:|-------------:|------------:|----------:|------------:|----------:|------------:|--------:|------------------------------------:|-----------------:|-----------:|--------------:|-------------:|--------------:|----------:|--------------:|------------:|---------------:|-------------------:|-----------------:|---------------------------:|---------------------------:|--------------------:|------------------------------:|------------------------------:|------------:|-----------:|-------------:|--------------:|-----------:|-----------:|---------------:|-----------------:|----------:|-----------------:|-------------------:|------------------:|--------------------:|----------------:|-------------------:|------------------:|-----------:|---------------:|
|cBLTUw |"18" Imperial IPA 2                                         |          0|          0|American-Style Imperial Stout | 11.10|  NA|  33|Pint  |NA                                |NA                                                          |Stout           |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|ZsQEJt |"633" American Pale Ale                                     |          0|          0|American-Style Pale Ale       |  6.33|  25|  NA|NA    |NA                                |NA                                                          |Pale Ale        |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|tmEthz |"Admiral" Stache                                            |          2|          4|Baltic-Style Porter           |  7.00|  23|  37|Pint  |Perle (American), Saaz (American) |Barley - Malted, Chocolate Malt, Munich Malt, Oats - Flaked |Porter          |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                1|       0|       0|        0|                 0|     0|          0|               1|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               1|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              1|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           1|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             1|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|b7SfHG |"Ah Me Joy" Porter                                          |          0|          0|Robust Porter                 |  5.40|  51|  40|NA    |NA                                |NA                                                          |Porter          |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|zcJMId |"Alternating Currant" Sour                                  |          0|          0|American-Style Sour Ale       |  4.80|  12|  NA|NA    |NA                                |NA                                                          |Sour            |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|UM8GL6 |"B" Street Pineapple Blonde                                 |          0|          0|Golden or Blonde Ale          |  4.60|  NA|   5|NA    |NA                                |NA                                                          |Blonde          |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|NIaY9C |"B.B. Rodriguez" Double Brown                               |          0|          0|American-Style Brown Ale      |  8.50|  30|  NA|NA    |NA                                |NA                                                          |Brown           |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|PBEXhV |"Bison Eye Rye" Pale Ale &#124; 2 of 4 Part Pale Ale Series |          0|          0|American-Style Pale Ale       |  5.80|  51|   8|NA    |NA                                |NA                                                          |Pale Ale        |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|wRmmdv |"California Crude" Black IPA                                |          0|          0|American-Style Black Ale      |  7.60|  80|  NA|NA    |NA                                |NA                                                          |Black           |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|
|EPYNpW |"C’est Noir" Imperial Stout                                 |          0|          0|British-Style Imperial Stout  | 10.80|  70|  NA|NA    |NA                                |NA                                                          |Stout           |      0|       0|                               0|       0|       0|        0|             0|      0|      0|      0|                 0|       0|      0|                   0|      0|      0|     0|     0|              0|     0|             0|                        0|       0|       0|      0|          0|          0|       0|     0|       0|    0|        0|                   0|     0|       0|   0|     0|                 0|         0|    0|      0|       0|      0|                  0|                  0|                 0|          0|                    0|              0|                 0|                0|       0|      0|      0|             0|                        0|           0|            0|              0|             0|                0|       0|                  0|            0|                                  0|                               0|                         0|                      0|                    0|                       0|                 0|                  0|     0|           0|    0|       0|           0|       0|       0|             0|      0|          0|       0|      0|       0|        0|         0|      0|       0|          0|           0|             0|                       0|                   0|                  0|       0|     0|         0|                          0|      0|     0|           0|            0|        0|         0|                0|       0|       0|        0|                 0|     0|          0|               0|            0|       0|                       0|      0|             0|           0|              0|         0|     0|            0|             0|        0|            0|             0|              0|              0|                0|      0|            0|      0|                   0|                     0|        0|     0|         0|     0|        0|          0|      0|      0|       0|          0|                 0|    0|      0|          0|               0|          0|             0|                   0|                   0|              0|               0|                        0|               0|            0|                0|                          0|                0|            0|               0|            0|          0|                       0|                    0|            0|           0|               0|                 0|         0|         0|                           0|                      0|                 0|          0|           0|                   0|    0|                 0|          0|         0|         0|         0|         0|        0|         0|          0|              0|        0|        0|                    0|                           0|                                 0|                               0|                            0|                             0|                              0|                        0|                         0|                         0|                        0|                        0|                         0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                        0|                       0|                        0|          0|               0|              0|              0|              0|            0|             0|              0|                     0|       0|       0|        0|               0|         0|                 0|      0|             0|                     0|         0|              0|                  0|                    0|           0|    0|            0|             0|          0|         0|        0|          0|              0|              0|            0|              0|                  0|                   0|           0|              0|              0|                      0|              0|                          0|                        0|     0|          0|                        0|          0|       0|          0|            0|          0|                            0|           0|           0|               0|        0|              0|         0|      0|           0|                  0|                   0|                     0|                    0|                    0|                     0|               0|               0|               0|            0|             0|                   0|             0|             0|                               0|              0|                   0|         0|                   0|                 0|                   0|          0|     0|          0|                    0|          0|            0|                      0|               0|                 0|         0|    0|             0|            0|          0|            0|          0|            0|        0|                                    0|                 0|           0|              0|             0|              0|          0|              0|            0|               0|                   0|                 0|                           0|                           0|                    0|                              0|                              0|            0|           0|             0|              0|           0|           0|               0|                 0|          0|                 0|                   0|                  0|                    0|                0|                   0|                  0|           0|               0|





***

Now that the munging is done, onto the main question: is style a good proxy for drawing meaningful distinctions between different types of beer?


# Unsupervised Clustering 

We can approach this question from a clustering standpoint by asking, to what extent do natural clusters in beers align with brewer-assigned style boundaries?

First off, the best visual representation of this is found in the [clustering Shiny app](https://amandadobbyn.shinyapps.io/clusterfun/). There you can run and re-run the algorithm using any number of clusters you choose and see whether beers of a certain style fall neatly or not so neatly into a single cluster.

This section will go through how that clustering is done.

We use the k-means [algorithm](https://en.wikipedia.org/wiki/K-means_clustering) to cluster beers based on certain numeric predictor variables. The data we'll use is includes all beers as well as the total number of hops and malts in each beer. 


**Prep the Data**

We'll prep the data for clustering first by taking out outcome variables and scaling our predictors so that variables of higher scale don't have an outsize effect on the resulting cluster assignments.

Here we define a function that takes a dataframe, a set of predictors, a set of variables to scale, and a response variable.

We select only the response variable(s) and the variables to cluster on. If there are any missing values in any of these columsn, we remove them. (NB: many beers are missing SRM so it's fair to not want to omit based on it. If you're interested in what happens when you remove SRM from the equation, try taking it out of the predictors in the Shiny app. )

Next we remove outliers, only keeping beers that have an ABV between 3 and 20 and an IBU less than 200.

Finally, we cluster on just the predictors and glue everything back together to compare cluster assignment to the response variable.


```r
library(NbClust)

prep_clusters <- function(df, preds, to_scale, resp) {
  df_for_clustering <- df %>%
    select_(.dots = c(response_vars, cluster_on)) %>%
    na.omit() %>%
    filter(
      abv < 20 & abv > 3    # Only keep beers with ABV between 3 and 20 and an IBU less than 200
    ) %>%
    filter(
      ibu < 200    
    )
  
  df_all_preds <- df_for_clustering %>%
    select_(.dots = preds)
  
  df_preds_scale <- df_all_preds %>%
    select_(.dots = to_scale) %>%
    rename(
      abv_scaled = abv,
      ibu_scaled = ibu,
      srm_scaled = srm
    ) %>%
    scale() %>%
    as_tibble()
  
  df_preds <- bind_cols(df_preds_scale, df_all_preds[, (!names(df_all_preds) %in% to_scale)])
  
  df_outcome <- df_for_clustering %>%
    select_(.dots = resp) %>%
    na.omit()
  
  cluster_prep_out <- list(df_for_clustering = df_for_clustering, preds = df_preds, outcome = df_outcome)
  
  return(cluster_prep_out)
}
```


Now we do the prepping. We'll cluster on the predictors ABV, IBU, SRM, total number of hops, and total number of malts.

```r
cluster_on <- c("abv", "ibu", "srm", "total_hops", "total_malt")
to_scale <- c("abv", "ibu", "srm", "total_hops", "total_malt")
response_vars <- c("name", "style", "style_collapsed")

cluster_prep <- prep_clusters(df = beer_dat,
                   preds = cluster_on,
                   to_scale = to_scale,
                   resp = response_vars)
```


After prepping, we're left with  beers to cluster on.



Before clustering, we can determine an optimal number of clusters by setting the minimum to 2 and max to 15 clusters.
From the resulting histogram (not run here for computational reasons), 10 seemed an optimal number of clusters. 


```r
nb <- NbClust(cluster_prep$preds, distance = "euclidean",
              min.nc = 2, max.nc = 15, method = "kmeans")
hist(nb$Best.nc[1,], breaks = max(na.omit(nb$Best.nc[1,])))
```




 
**Do the Clustering**

Now cluster on the prepped predictors using 10 centers.


```r
cluster_it <- function(df_preds, n_centers) {
  set.seed(9)
  clustered_df_out <- kmeans(x = df_preds$preds, centers = n_centers, trace = FALSE)

  clustered_df <- as_tibble(data.frame(
    cluster_assignment = factor(clustered_df_out$cluster),
    df_preds$outcome, df_preds$preds,
    df_preds$df_for_clustering %>% select(abv, ibu, srm)))

  return(clustered_df)
}

clustered_beer <- cluster_it(df_preds = cluster_prep, n_centers = 10)
```


We take a look at the top of the resulting clustered data. The cluster assignment column appears on the far left.

```r
kable(clustered_beer[1:10, ])
```



|cluster_assignment |name                                                         |style                                         |style_collapsed | abv_scaled| ibu_scaled| srm_scaled| total_hops| total_malt| abv|  ibu| srm|
|:------------------|:------------------------------------------------------------|:---------------------------------------------|:---------------|----------:|----------:|----------:|----------:|----------:|---:|----:|---:|
|6                  |"Admiral" Stache                                             |Baltic-Style Porter                           |Porter          |  0.2700989| -0.7075654|  2.1858706|  2.5475341|  4.6826819| 7.0| 23.0|  37|
|10                 |"Ah Me Joy" Porter                                           |Robust Porter                                 |Porter          | -0.6074754|  0.3844558|  2.4677869| -0.2502903| -0.2274607| 5.4| 51.0|  40|
|1                  |"Bison Eye Rye" Pale Ale &#124; 2 of 4 Part Pale Ale Series  |American-Style Pale Ale                       |Pale Ale        | -0.3880818|  0.3844558| -0.5393202| -0.2502903| -0.2274607| 5.8| 51.0|   8|
|1                  |"Dust Up" Cloudy Pale Ale &#124; 1 of 4 Part Pale Ale Series |American-Style Pale Ale                       |Pale Ale        | -0.6074754|  0.5014580| -0.2574039| -0.2502903| -0.2274607| 5.4| 54.0|  11|
|3                  |"God Country" Kolsch                                         |German-Style Kölsch / Köln-Style Kölsch       |Kölsch          | -0.4977786| -0.5047614| -0.8212365| -0.2502903| -0.2274607| 5.6| 28.2|   5|
|3                  |"Jemez Field Notes" Golden Lager                             |Golden or Blonde Ale                          |Blonde          | -0.8817174| -0.8245676| -0.8212365| -0.2502903| -0.2274607| 4.9| 20.0|   5|
|3                  |#10 Hefewiezen                                               |South German-Style Hefeweizen / Hefeweissbier |Wheat           | -0.7720206| -1.1755744| -0.9152086| -0.2502903| -0.2274607| 5.1| 11.0|   4|
|6                  |#9                                                           |American-Style Pale Ale                       |Pale Ale        | -0.7720206| -0.8245676| -0.4453481|  2.5475341|  2.2276106| 5.1| 20.0|   9|
|3                  |#KoLSCH                                                      |German-Style Kölsch / Köln-Style Kölsch       |Kölsch          | -0.9365658| -0.5515624| -1.0091807| -0.2502903| -0.2274607| 4.8| 27.0|   3|
|3                  |'Inappropriate' Cream Ale                                    |American-Style Cream Ale or Lager             |Lager           | -0.6623238| -0.9025691| -0.8212365| -0.2502903| -0.2274607| 5.3| 18.0|   5|


We can get an idea of how cleanly styles were fit into clusters by looking at a table of cluster counts broken down by style.

|                         |   1|   2|   3|   4|  5|  6|   7|  8|  9|  10|
|:------------------------|---:|---:|---:|---:|--:|--:|---:|--:|--:|---:|
|Barley Wine              |   0|  27|   0|   0| 11|  4|   2|  5| 13|   0|
|Barrel-Aged              |   3|   3|   2|   4|  8|  1|   1| 10| 14|   2|
|Bitter                   |  37|   0|  15|  19|  0|  5|   2|  1|  0|   1|
|Black                    |   0|   0|   0|   1| 12|  2|  11|  0|  0|  17|
|Blonde                   |  14|   0| 112|   2|  0|  6|   1| 23|  1|   1|
|Brown                    |   2|   1|   7|  90|  4| 10|   5|  0|  4|  25|
|Double India Pale Ale    |   0| 157|   0|   0|  7| 19|  44|  4|  1|   0|
|Dubbel                   |   0|   0|   0|  16|  1|  1|   1|  7|  5|  10|
|Fruit Beer               |   2|   0|  36|   7|  0|  1|   3|  4|  2|   1|
|Fruit Cider              |   0|   0|   1|   0|  0|  0|   0|  0|  0|   0|
|German-Style Doppelbock  |   0|   0|   0|   5|  0|  1|   0|  5| 13|   5|
|German-Style Märzen      |   2|   0|  11|  13|  0|  3|   0|  0|  0|   1|
|Herb and Spice Beer      |   4|   0|  12|  11|  0|  5|   7|  2|  5|   9|
|India Pale Ale           |  92|  18|   6|   7|  5| 53| 387|  3|  0|   6|
|Kölsch                   |   3|   0|  65|   1|  0|  2|   1|  0|  0|   0|
|Lager                    |  24|   2| 128|  48|  3| 17|  25| 10|  3|   7|
|Other Belgian-Style Ales |   4|   0|   4|   7|  1|  0|   9|  4|  5|   5|
|Pale Ale                 | 231|   2|  53|  25|  2| 25|  46| 11|  2|   1|
|Pilsener                 |  52|   1|  70|   0|  0|  6|   3|  3|  0|   1|
|Porter                   |   1|   0|   0|  34|  8|  8|   0|  1| 12| 120|
|Pumpkin Beer             |   3|   0|   6|  17|  0|  3|   0|  8|  5|   4|
|Red                      |  44|   9|  31| 118|  5| 18|  21|  6|  5|  16|
|Saison                   |  33|   0|  50|   6|  1|  6|   0| 41|  0|   2|
|Scotch Ale               |   1|   0|   0|   9|  1|  2|   0|  4|  7|   9|
|Sour                     |   3|   0|  18|   4|  0|  1|   1|  4|  4|   2|
|Specialty Beer           |   5|   1|  14|  13|  0|  1|   5| 10|  6|  10|
|Stout                    |   2|   0|   2|   5| 51|  5|   1|  3|  9| 125|
|Strong Ale               |   2|   4|   0|   5|  2|  4|   4| 26| 32|   3|
|Tripel                   |   1|   2|   0|   0|  1|  3|   1| 53|  4|   0|
|Wheat                    |  16|   0| 257|  11|  0| 13|   4| 11|  2|   3|


Now we can plot the clusters. There are 3 dimensions, ABV, IBU, and SRM, so we choose two at a time to graph. 
We add in the style centers (means) for each `style_collapsed`.
Anecdotally, style centers match up approximately to where we'd expect them to fall.


```r
clustered_beer_plot_srm_ibu <- ggplot() +
  geom_jitter(data = clustered_beer, 
             aes(x = srm, y = ibu, colour = cluster_assignment), alpha = 0.5) +
  geom_point(data = style_centers,
             aes(mean_srm, mean_ibu), colour = "black") +
  theme_minimal()  +
  geom_text_repel(data = style_centers, aes(mean_srm, mean_ibu, label = style_collapsed), 
                  box.padding = unit(0.45, "lines"),
                  family = "Calibri",
                  label.size = 0.3) +
  ggtitle("k-Means Clustering of Beer: SRM vs. IBU") +
  labs(x = "SRM", y = "IBU") +
  labs(colour = "Cluster Assignment") +
  theme(legend.position="none")
clustered_beer_plot_srm_ibu
```

![](compile_files/figure-html/cluster_srm_ibu-1.png)<!-- -->


```r
clustered_beer_plot_srm_abv <- ggplot() +   
  geom_jitter(data = clustered_beer, 
             aes(x = srm, y = abv, colour = cluster_assignment), alpha = 0.5) +
  geom_point(data = style_centers,
             aes(mean_srm, mean_abv), colour = "black") +
  theme_minimal()  +
  geom_text_repel(data = style_centers, aes(mean_srm, mean_abv, label = style_collapsed), 
                  box.padding = unit(0.45, "lines"),
                  family = "Calibri",
                  label.size = 0.3) +
  ggtitle("k-Means Clustering of Beer: SRM vs. ABV") +
  labs(x = "SRM", y = "ABV") +
  labs(colour = "Cluster Assignment") +
  theme(legend.position="none")
clustered_beer_plot_srm_abv
```

![](compile_files/figure-html/cluster_srm_abv-1.png)<!-- -->



```r
abv_ibu_clusters_vs_style_centers <- ggplot() +   
  geom_point(data = clustered_beer, 
             aes(x = abv, y = ibu, colour = cluster_assignment), alpha = 0.5) +
  geom_point(data = style_centers,
             aes(mean_abv, mean_ibu), colour = "black") +
  geom_text_repel(data = style_centers, aes(mean_abv, mean_ibu, label = style_collapsed), 
                  box.padding = unit(0.45, "lines"),
                  family = "Calibri",
                  label.size = 0.3) +
  ggtitle("Popular Styles vs. k-Means Clustering of Beer: ABV vs. IBU") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Cluster Assignment") +
  theme_minimal() +
  theme(legend.position="none")
abv_ibu_clusters_vs_style_centers
```

![](compile_files/figure-html/cluster_abv_ibu-1.png)<!-- -->


That's one way to get a sense of the data. However, one snag is that the clustering above used a smaller number of clusters (10) than there are `styles_collapsed` (30). That makes it difficult to determine whether a given style fits snugly into a cluster or not.




**Cluster on Selected Styles**

As a workaround to this problem, we'll take five very distinct collapsed styles and re-run the clustering on beers that fall into these categories. 
These styles were intentionally chosen because they are quite distinct: Blonde, IPA, Stout, Tripel, Wheat. 

Arguably, of these five styles Blondes and Wheats are the closest. We can see whether that plays out in the clusters if beers in those styles tend to be assigned to the same cluster.


```r
styles_to_keep <- c("Blonde", "India Pale Ale", "Stout", "Tripel", "Wheat")
bd_certain_styles <- beer_dat %>%
  filter(
    style_collapsed %in% styles_to_keep
  ) %>% 
  droplevels()

cluster_on <- c("abv", "ibu", "srm", "total_hops", "total_malt")
to_scale <- c("abv", "ibu", "srm", "total_hops", "total_malt")
response_vars <- c("name", "style", "style_collapsed")

bd_cluster_prep <- prep_clusters(df = bd_certain_styles,
                   preds = cluster_on,
                   to_scale = to_scale,
                   resp = response_vars)

certain_styles_clustered <- cluster_it(df_preds = bd_cluster_prep, n_centers = 5)

style_centers_certain_styles <- style_centers %>% 
  filter(style_collapsed %in% styles_to_keep)
```





Table of style vs. cluster.

```r
kable(table(style = certain_styles_clustered$style_collapsed, cluster = certain_styles_clustered$cluster_assignment))
```



|               |  1|   2|   3|   4|  5|
|:--------------|--:|---:|---:|---:|--:|
|Blonde         |  1| 136|   1|  15|  7|
|India Pale Ale |  2|  44|  11| 466| 54|
|Stout          | 55|   5| 133|   5|  5|
|Tripel         |  3|   3|   1|  54|  4|
|Wheat          |  3| 284|   5|  13| 12|



Now that we have a manageable number of styles, we can see how well fit each cluster is to each style. If the features we clustered on perfectly predicted style, there would each color (cluster) would be unique to each facet of the plot. (E.g., left the left facet would be entirely blue, second from left entirely green, etc.) Style centers are denoted by the black circle.



```r
by_style_plot <- ggplot() +   
  geom_point(data = certain_styles_clustered, 
             aes(x = abv, y = ibu,
                 colour = cluster_assignment), alpha = 0.5) +
  facet_grid(. ~ style_collapsed) +
  geom_point(data = style_centers_certain_styles,
           aes(mean_abv, mean_ibu), shape = 1, colour = "black", fill="black", size = 4, solid=TRUE) +
  ggtitle("Selected Styles Cluster Assignment") +
  labs(x = "ABV", y = "IBU") +
  labs(colour = "Cluster") +
  theme_bw()
by_style_plot
```

![](compile_files/figure-html/cluster_certain_styles-1.png)<!-- -->



<!-- ggplot() + -->
<!--   geom_point(data = certain_styles_clustered, -->
<!--              aes(x = abv, y = ibu, -->
<!--                  shape = cluster_assignment, -->
<!--                  colour = style_collapsed), alpha = 0.5) + -->
<!--   geom_point(data = style_centers_certain_styles, -->
<!--              aes(mean_abv, mean_ibu), colour = "black") + -->
<!--   geom_text_repel(data = style_centers_certain_styles, -->
<!--                   aes(mean_abv, mean_ibu, label = style_collapsed), -->
<!--                   box.padding = unit(0.45, "lines"), -->
<!--                   family = "Calibri", -->
<!--                   label.size = 0.3) + -->
<!--   ggtitle("Selected Styles (colors) matched with Cluster Assignments (shapes)") + -->
<!--   labs(x = "ABV", y = "IBU") + -->
<!--   labs(colour = "Style", shape = "Cluster Assignment") + -->
<!--   theme_bw() -->

<!-- ``` -->



# Short Foray into Hops

Quick intermission from our main question to do a quick dive into hops.

First question:

**Do more hops always mean more bitterness?**

Let's look at beers that have at least one hop.



Initial answer: it would appear so, from this jittered graph (considering only beer in the most popular styles) and this regression ($\beta$ = 17.678). Assuming a linear relationship between hops and bitterness, we'd expect an increase in around 18 IBU for every 1 extra hop.


```r
ggplot(data = beer_dat_sparse %>% filter(total_hops > 0), aes(total_hops, ibu)) +
  geom_jitter(aes(total_hops, ibu, colour = style_collapsed), width = 0.5, alpha = 0.5) +
  geom_smooth(method = "loess", se = FALSE, colour = "black") + 
  ggtitle("Hops Per Beer vs. Bitterness") +
  labs(x = "Number of Hops", y = "IBU", colour = "Style Collapsed") +
  theme_minimal()
```

![](compile_files/figure-html/hops_ibu-1.png)<!-- -->


Regressing total number of hops on bitterness (IBU):

```r
kable(hops_ibu_lm)
```



|term        |  estimate| std.error| statistic| p.value|
|:-----------|---------:|---------:|---------:|-------:|
|(Intercept) | 23.735809| 1.3683898|  17.34580|       0|
|total_hops  |  8.635235| 0.4884861|  17.67755|       0|


Are there diminishing returns on bitterness as you increase the number of hops?

```r
ggplot(data = beer_dat_sparse[which(beer_dat_sparse$total_hops >= 5), ], aes(total_hops, ibu)) +
  geom_jitter(aes(total_hops, ibu, colour = style_collapsed), width = 0.5, alpha = 0.5) +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  ggtitle("5+ Hops Per Beer vs. Bitterness") +
  labs(x = "Number of Hops", y = "IBU", colour = "Style Collapsed") +
  theme_minimal()
```

![](compile_files/figure-html/five_plus_hops_ibu-1.png)<!-- -->

The trend holds even with 5 or more hops, with a slightly smaller effect size (probably due to smaller sample size).

```r
five_plus_hops_ibu_lm <- lm(ibu ~ total_hops, data = beer_dat_sparse[which(beer_dat_sparse$total_hops > 5), ]) %>% broom::tidy() 

five_plus_hops_ibu_lm %>% kable()
```



|term        |  estimate| std.error| statistic|   p.value|
|:-----------|---------:|---------:|---------:|---------:|
|(Intercept) | 33.963183| 14.807526|  2.293643| 0.0283144|
|total_hops  |  6.818625|  2.085183|  3.270036| 0.0025192|


**Most Popular Hops**

What are the most popular hops used in beers?


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

pop_hops_display <- pop_hops_beer_stats %>% 
    rename(
    `Hop Name` = hop_name,
    `Mean IBU` = mean_ibu,
    `Mean ABV` = mean_abv,
    `Number Beers Containing this Hop` = n
  )

kable(pop_hops_display)
```



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

```r
# Keep just beers that contain these most popular hops
beer_necessities_w_popular_hops <- beer_necessities_w_hops %>% 
  filter(hop_name %in% pop_hops_beer_stats$hop_name) %>% 
  droplevels() 
```


Are there certian hops that are used more often in very high IBU or ABV beers? It's hard to detect a pattern.

```r
ggplot(data = beer_necessities_w_popular_hops) + 
  geom_point(aes(abv, ibu, colour = hop_name)) +
  ggtitle("Beers Containing most Popular Hops") +
  labs(x = "ABV", y = "IBU", colour = "Hop Name") +
  theme_minimal()
```

![](compile_files/figure-html/abv_ibu_hopname-1.png)<!-- -->


```r
ggplot(data = pop_hops_beer_stats) + 
  geom_point(aes(mean_abv, mean_ibu, colour = hop_name, size = n)) +
  ggtitle("Most Popular Hops' Effect on Alcohol and Bitterness") +
  labs(x = "Mean ABV per Hop Type", y = "Mean IBU per Hop Type", colour = "Hop Name", 
       size = "Number of Beers") +
  theme_minimal()
```

![](compile_files/figure-html/abv_ibu_hopsize-1.png)<!-- -->


***



# Prediction


Okay, okay getting back on track. To the original question: do beer styles define meaningful boundaries in the beer landscape? From a more practical point of view we could ask the question from a drinker's point of view: to what extent is style a useful construct for determining what a beer will be like? How useful is it to me to know that a beer is a wheat beer?

In trying to answer this question empirically we can take the oppostie tack. That is, intead of using style to predict what a beer will be like, we can see how accurately we can predict style using the same features we used in clustering.


## Neural Net

We'll use a multinomial neural net to approach the classification task first. We'll train the neural net on a random 80% of the data and use the rest to test its accuracy. 

The variables we'll supply the function below will be a dataframe, a single outcome variable (either `style` or `style_collapsed`; the one not specified as `outcome` will be dropped from the dataframe), and a set of predictors. 

The function returns a list composed of the following objects: the prediction dataframe, the predicted style for each beer generated by the model, the true beer style, the importance of each variable in the model, and accuracy of the model.


```r
library(nnet)
library(caret)

run_neural_net <- function(df, outcome, predictor_vars) {
  out <- list(outcome = outcome)
  
  # Create a new column outcome; it's style_collapsed if you set outcome to style_collapsed, and style otherwise
  if (outcome == "style_collapsed") {
    df[["outcome"]] <- df[["style_collapsed"]]
  } else {
    df[["outcome"]] <- df[["style"]]
  }

  df$outcome <- factor(df$outcome)
  
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
  
  df_train <- df_train %>%
    select(-row)
  
  # Build multinomail neural net
  nn <- multinom(outcome ~ .,
                 data = df_train, maxit=500, trace=FALSE)

  # Which variables are the most important in the neural net?
  most_important_vars <- varImp(nn)

  # How accurate is the model? Compare predictions to outcomes from test data
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


On this first pass we'll use ABV, IBU, SRM, total hops, and total malts as predictors. The outcome variable will be collapsed style.

First we'll take our dataframe and drop any rows that have missing values in any of the columns we're using for prediction or response. 

```r
# Take out NAs
bt_omit <- beer_dat %>% drop_na(total_hops, total_malt, abv, ibu, srm, style_collapsed)
```

Then we run the model and save its output.

```r
p_vars <- c("total_hops", "total_malt", "abv", "ibu", "srm")

nn_collapsed_out <- run_neural_net(df = bt_omit, outcome = "style_collapsed", 
                         predictor_vars = p_vars)
```

How accurate was it?

```r
round((nn_collapsed_out$nn_accuracy[1])*100, digits=2)
```

```
## Accuracy 
##    40.79
```

What were the most important variables?

```r
get_nn_importance <- function(imp_vec) {
  vals <- imp_vec %>% round(digits=2)
  names <- rownames(vals) %>% map(dobtools::cap_it) %>% map(beer_caps) %>% as_vector()
  out <- cbind("Variable" = names, vals) %>% arrange(desc(Overall)) %>% rename(Importance = Overall)
  rownames(out) <- 1:nrow(out)
  return(out)
}

nn_collapsed_out$most_important_vars %>% get_nn_importance() %>% kable()
```



|Variable   | Importance|
|:----------|----------:|
|Total Hops |      63.22|
|ABV        |      30.68|
|Total Malt |      18.15|
|SRM        |       4.02|
|IBU        |       2.91|


**Change up some Parameters**

Now what if we predcit `style` instead of `style_collapsed`?

We'll run the model and again find accuracy and variable importance.

```r
nn_notcollapsed_out <- run_neural_net(df = bt_omit, outcome = "style", 
                         predictor_vars = p_vars)

round(nn_notcollapsed_out$nn_accuracy[1]*100 , digits = 2)
```

```
## Accuracy 
##    35.58
```

```r
nn_notcollapsed_out$most_important_vars %>% get_nn_importance() %>% kable() 
```



|Variable   | Importance|
|:----------|----------:|
|Total Hops |     333.67|
|Total Malt |     211.32|
|ABV        |      96.53|
|SRM        |      26.33|
|IBU        |      15.89|

So style is harder to predict than collapsed style, which makes sense. However, the relative importance of the variables here doesn't change.


Now we can ask the question of what happens to our accuracty measure if we add `glass` as a predictor. The type of glass that a beer is served in is a property of the beer's style rather than of the beer itself. We'd imagine then that glass should be a good predictor of style. It's not a perfect predictor, though, as styles are served in the same glass type.

```r
p_vars_add_glass <- c("total_hops", "total_malt", "abv", "ibu", "srm", "glass")

nn_collapsed_out_add_glass <- run_neural_net(df = beer_dat_sparse, outcome = "style_collapsed", 
                         predictor_vars = p_vars_add_glass)

round(nn_collapsed_out_add_glass$nn_accuracy[1]*100, digits = 2)
```

```
## Accuracy 
##    41.96
```
So indeed, glass does improve the accuracy of the model. 



```r
nn_collapsed_out_add_glass$most_important_vars %>% get_nn_importance() %>% kable() 
```



|Variable                  | Importance|
|:-------------------------|----------:|
|GlassStange               |     657.06|
|GlassThistle              |     551.76|
|GlassGoblet               |     342.63|
|GlassSnifter              |     311.89|
|GlassTulip                |     291.32|
|GlassPint                 |     270.64|
|GlassMug                  |     265.07|
|GlassWeizen               |     239.27|
|GlassWilli                |     234.98|
|GlassOversized Wine Glass |     231.48|
|GlassPilsner              |     224.98|
|Total Hops                |      74.05|
|Total Malt                |      63.62|
|ABV                       |      33.05|
|IBU                       |       4.47|
|SRM                       |       4.23|

And, unsurprisingly, glass is a very good predictor of style. Nevertheless, we're far from perfect accuracy.



## Random Forest

Earlier we prepared a sparse dataframe, `beer_dat`, specifying the presence or abscence of every single hop and malt in each beer. This dataframe contained too many features for the neural net we just ran; however, a random forest model is able to handle this very high density of inputs. 

The relative accuracy of a random forest model that does compared to one that doesn't include ingredients in its set of predictors may or may not be interesting to you depending on where you come down on the discussion raised at the very beginning in the "Predictor Discussion" section. 
What does it mean if including specific ingredients in the model improves its accuracy? Potentially not much if most brewers determine a beer's style before they choose the ingredients that will go into it. If that is the typical direction of causality then it should be less surprising to us that including ingredients in a model improves its predictive power. 

Glass type certainly isn't fair game to include as a predictor, so we omit it here.



**Full Random Forest**

We'll use the `ranger` package to train on 80% of the data an test on the remaining 20%. First we'll train on everything we've got: ABV, IBU, SRM, total hops, total malts, and whether each individual hop and malt was present.


```r
library(ranger)
library(stringr)

# Take out columns we don't need and remove rows with missing values from the ones we do
bi <- beer_dat_sparse %>% 
  select(-c(id, name, style, hops_name, malt_name,
            glass)) %>% 
  mutate(row = 1:nrow(.)) %>% 
  na.omit()

bi$style_collapsed <- factor(bi$style_collapsed)


# ranger complains about special characters and spaces in ingredient column names so we'll take them out.
names(bi) <- tolower(names(bi))
names(bi) <- str_replace_all(names(bi), " ", "")
names(bi) <- str_replace_all(names(bi), "([\\(\\)-\\/')]+)", "")

# Keep 80% for training
bi_train <- sample_n(bi, nrow(bi)*(0.8))

# The rest is for testing
bi_test <- bi %>%
  filter(! (row %in% bi_train$row)) %>%
  dplyr::select(-row)

bi_train <- bi_train %>%
  dplyr::select(-row) %>% 
  select(-`#06300`)

bi_rf <- ranger(style_collapsed ~ ., data = bi_train, importance = "impurity", seed = 11)
```


Now we compare predicted classification on the test set to their actual style classification.

```r
pred_bi_rf <- predict(bi_rf, dat = bi_test)
kable(table(bi_test$style_collapsed, pred_bi_rf$predictions))
```



|                         | Barley Wine| Barrel-Aged| Bitter| Black| Blonde| Brown| Double India Pale Ale| Dubbel| Fruit Beer| Fruit Cider| German-Style Doppelbock| German-Style Märzen| Herb and Spice Beer| India Pale Ale| Kölsch| Lager| Other Belgian-Style Ales| Pale Ale| Pilsener| Porter| Pumpkin Beer| Red| Saison| Scotch Ale| Sour| Specialty Beer| Stout| Strong Ale| Tripel| Wheat|
|:------------------------|-----------:|-----------:|------:|-----:|------:|-----:|---------------------:|------:|----------:|-----------:|-----------------------:|-------------------:|-------------------:|--------------:|------:|-----:|------------------------:|--------:|--------:|------:|------------:|---:|------:|----------:|----:|--------------:|-----:|----------:|------:|-----:|
|Barley Wine              |           0|           0|      0|     0|      0|     0|                     2|      0|          0|           0|                       0|                   0|                   0|              8|      0|     0|                        0|        0|        0|      0|            0|   0|      0|          0|    0|              0|     1|          0|      0|     0|
|Barrel-Aged              |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|              3|      0|     0|                        0|        0|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|     2|
|Bitter                   |           0|           0|      0|     0|      0|     1|                     0|      0|          0|           0|                       0|                   0|                   0|              3|      0|     0|                        0|        8|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|     3|
|Black                    |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              9|      0|     0|                        0|        0|        0|      1|            0|   0|      0|          0|    0|              0|     0|          0|      0|     0|
|Blonde                   |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|              5|      0|     0|                        0|        4|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|    17|
|Brown                    |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              3|      0|     0|                        0|        9|        0|      7|            0|   1|      0|          0|    0|              0|     2|          0|      0|     2|
|Double India Pale Ale    |           0|           0|      0|     0|      0|     0|                    18|      0|          0|           0|                       0|                   0|                   0|             23|      0|     0|                        0|        0|        0|      0|            0|   0|      0|          0|    0|              0|     2|          0|      0|     0|
|Dubbel                   |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              7|      0|     0|                        0|        0|        0|      0|            0|   0|      0|          0|    0|              0|     1|          0|      0|     0|
|Fruit Beer               |           0|           0|      0|     0|      0|     0|                     3|      0|          0|           0|                       0|                   0|                   0|              2|      0|     0|                        0|        0|        0|      2|            0|   0|      0|          0|    0|              0|     0|          0|      0|     5|
|Fruit Cider              |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              0|      0|     0|                        0|        0|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|     0|
|German-Style Doppelbock  |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|              2|      0|     0|                        0|        0|        0|      2|            0|   0|      0|          0|    0|              0|     1|          0|      0|     0|
|German-Style Märzen      |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              1|      0|     1|                        0|        1|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|     3|
|Herb and Spice Beer      |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|              5|      0|     0|                        0|        1|        0|      3|            0|   0|      0|          0|    0|              0|     0|          0|      0|     1|
|India Pale Ale           |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|            125|      0|     0|                        0|        7|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|     2|
|Kölsch                   |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              0|      0|     0|                        0|        0|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|    13|
|Lager                    |           0|           0|      0|     0|      0|     0|                     3|      0|          0|           0|                       0|                   0|                   0|             15|      0|     1|                        0|       12|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|    31|
|Other Belgian-Style Ales |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              3|      0|     0|                        0|        1|        0|      1|            0|   0|      0|          0|    0|              0|     2|          0|      0|     1|
|Pale Ale                 |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|             26|      0|     0|                        0|       42|        0|      1|            0|   0|      0|          0|    0|              0|     0|          0|      0|    10|
|Pilsener                 |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              1|      0|     0|                        0|        6|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|    15|
|Porter                   |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              1|      0|     0|                        0|        3|        0|     24|            0|   0|      0|          0|    0|              0|     5|          0|      0|     0|
|Pumpkin Beer             |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|              1|      0|     0|                        0|        0|        0|      2|            0|   0|      0|          0|    0|              0|     0|          0|      0|     3|
|Red                      |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|             18|      0|     0|                        0|       15|        0|      2|            0|   0|      0|          0|    0|              0|     1|          0|      0|    11|
|Saison                   |           0|           0|      0|     0|      1|     0|                     3|      0|          0|           0|                       0|                   0|                   0|             18|      0|     0|                        0|        6|        0|      1|            0|   0|      0|          0|    0|              0|     0|          0|      0|     6|
|Scotch Ale               |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              1|      0|     0|                        0|        0|        0|      3|            0|   0|      0|          0|    0|              0|     3|          0|      0|     0|
|Sour                     |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              4|      0|     0|                        0|        0|        0|      3|            0|   0|      0|          0|    0|              0|     0|          0|      0|     2|
|Specialty Beer           |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|              3|      0|     0|                        0|        2|        0|      5|            0|   0|      0|          0|    0|              0|     0|          0|      0|     3|
|Stout                    |           0|           0|      0|     0|      0|     0|                     0|      0|          0|           0|                       0|                   0|                   0|              7|      0|     0|                        0|        0|        0|     24|            0|   0|      0|          0|    0|              0|    15|          0|      0|     0|
|Strong Ale               |           0|           0|      0|     0|      0|     0|                    12|      0|          0|           0|                       0|                   0|                   0|              3|      0|     0|                        0|        1|        0|      2|            0|   1|      0|          0|    0|              0|     3|          0|      1|     0|
|Tripel                   |           0|           0|      0|     0|      0|     0|                     8|      0|          0|           0|                       0|                   0|                   0|              4|      0|     0|                        0|        0|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|     2|
|Wheat                    |           0|           0|      0|     0|      0|     0|                     1|      0|          0|           0|                       0|                   0|                   0|              5|      0|     0|                        0|        3|        0|      0|            0|   0|      0|          0|    0|              0|     0|          0|      0|    44|


To quantify accuracy we could compare predicted style to true style in the test set. Another method is to use out of bag (OOB) prediction error, which is calculated from tree samples constructed but not used in training set. In calculating error, these trees become effectively part of test set allowing us to compute classification error. Percent accuracy, then, is $1 - OOB error * 100$.
    

```r
(1 - bi_rf$prediction.error)*100
```

```
## [1] 32.66539
```



*Variable importance*

The model output provides us with a measure of which variables contributed most to each tree's creation. Here we'll look at just the top 20.

```r
get_rf_importance <- function(rf_df) {
  importance_sorted <- importance(rf_df) %>% sort(., decreasing = TRUE)
  importance_names <- names(importance_sorted) %>% map(dobtools::cap_it) %>% map(beer_caps) %>% as_vector()
  importance_vals <- importance(rf_df) %>% as.numeric()
  importance_df <- cbind(`Variable Name` = importance_names, "Importance" = importance_sorted) %>% as_tibble()
  return(importance_df)
}

bi_rf_imp <- bi_rf %>% get_rf_importance() 
kable(bi_rf_imp[1:10, ])
```



|Variable Name |Importance       |
|:-------------|:----------------|
|IBU           |133.23805651003  |
|SRM           |82.1330830847161 |
|ABV           |77.6321388103711 |
|Total Hops    |5.60525274350915 |
|Total Malt    |4.29584001973546 |
|Cascade       |4.09349689613152 |
|Centennial    |2.23054244826829 |
|Chocolatemalt |2.19405452077647 |
|Columbus      |2.10053776164705 |
|Pilsnermalt   |1.76825888896042 |

Interestingly, in this random forest, `total_hops` and `total_malt` are relatively less important here than they were in the neural net that used the same predictor variables and target. 


**Pared down Random Forest**

And what if we exclude the individual ingredient columns? Again we'll try to predict collapsed style.


```r
# Take out columns we don't need and remove rows with missing values from the ones we do
bi_pared <- beer_dat_sparse %>% 
  select(total_hops, total_malt, abv, ibu, srm, style_collapsed) %>% 
  mutate(row = 1:nrow(.)) %>% 
  na.omit()

bi_pared$style_collapsed <- factor(bi_pared$style_collapsed)

names(bi_pared) <- tolower(names(bi_pared))
names(bi_pared) <- str_replace_all(names(bi_pared), " ", "")
names(bi_pared) <- str_replace_all(names(bi_pared), "([\\(\\)-\\/')]+)", "")

bi_pared_train <- sample_n(bi_pared, nrow(bi_pared)*(0.8))

bi_pared_test <- bi_pared %>%
  filter(! (row %in% bi_pared_train$row)) %>%
  dplyr::select(-row)

bi_pared_train <- bi_pared_train %>%
  dplyr::select(-row)

bi_pared_rf <- ranger(style_collapsed ~ ., data = bi_pared_train, importance = "impurity", seed = 11)
```


Accuracy compared to that of the full random forest model, 32.67%:

```
## [1] 44.6883
```

Why is the pared-down random forest more accurate than the model including sparse, granular ingredient data? It's possible the latter encouraged overfitting, negatively impacting the model's ability to predict accurately.

And we find variable importance. 

```r
bi_pared_rf %>% get_rf_importance() %>% kable()
```



|Variable Name |Importance       |
|:-------------|:----------------|
|IBU           |795.416009395711 |
|ABV           |691.426330812771 |
|SRM           |621.517396319976 |
|Total Hops    |47.009127934829  |
|Total Malt    |41.9568154760899 |

Once again, in the random forest model IBU, ABV, and SRM are more important than total hops and total malts. In fact, variable importance in the random forest is almost the inverse of variable importance in the neural net. Perhaps this is a reflection of intrinsic differences in the models; it's possible they leaned on different features to come to similar conclusions. The random forest performed overall somewhat better than the neural net, though neither was able to conclusively predict style with accuracy above 50%. 

A potentially future direction to take the sparse dataframe in would be to only incorporate either a) certain very popular hops or malts or b) ingredients that are present exclusively in one style into the models to see if they produce a measurable increase in accuracy.

***


# Final Thoughts

*Style first, forgiveness later?*

This analysis is of course preliminary and exploratory. I didn't arrive at it with a certain hypothesis in mind, though I did arrive at it with a question: are style boundaries indicative of true, natural boundaries in the beer landscape?

For now, my tentative answer is that style certainly has a relationship to objective beer qualities but, as is clear from the clustering graphs, distinct pockets (delinated by style or otherwise) just don't seem to exist. What's more, predicting style from features was at least using the measures available to us was not an easy task.

One reason that style is not a cut and dry divider between different beers might be that beers tend to be brewed with style in mind first ("let's make a pale ale") rather than deciding the beer's style after determining its characteristics and idiosyncrasies. It follows that even if the beer turns out more like a sour, and in a blind taste test might be classified as a sour more often than a pale ale, the label on the bottle still says pale ale. This makes the style definitions fuzzier and harder to predict.



*Future Directions*

Suffice it to say, the question is far from settled. But there are many other places to take this dataset. Ideas include but are not limited to:

* Incorporating flavor profiles for beers sourced/scraped from somewhere
* Implementing hierarchical clustering; what style is the mother of all styles?
* Implementing a GAN ([generative adversarial network](https://en.wikipedia.org/wiki/Generative_adversarial_networks)) to come up with beer names
* Going deeper on the hops deep dive: which hops are used most often in which styles?

Please don't hesitate to reach out with other ideas. Cheers!


![](../img/pour.jpg)

***



```r
sessionInfo()
```

```
## R version 3.3.3 (2017-03-06)
## Platform: x86_64-apple-darwin13.4.0 (64-bit)
## Running under: macOS Sierra 10.12.6
## 
## locale:
## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
##  [1] stringr_1.2.0   ranger_0.8.0    caret_6.0-76    lattice_0.20-35
##  [5] nnet_7.3-12     NbClust_3.0     forcats_0.2.0   bindrcpp_0.2   
##  [9] RMySQL_0.10.12  DBI_0.7         dplyr_0.7.2     purrr_0.2.3    
## [13] readr_1.1.1     tidyr_0.6.3     tibble_1.3.3    tidyverse_1.1.1
## [17] dobtools_0.1.0  ggrepel_0.6.5   ggplot2_2.2.1   jsonlite_1.5   
## [21] broom_0.4.2     knitr_1.16     
## 
## loaded via a namespace (and not attached):
##  [1] httr_1.2.1          splines_3.3.3       foreach_1.4.3      
##  [4] modelr_0.1.1        Formula_1.2-2       assertthat_0.2.0   
##  [7] highr_0.6           stats4_3.3.3        latticeExtra_0.6-28
## [10] cellranger_1.1.0    yaml_2.1.14         backports_1.1.0    
## [13] quantreg_5.29       glue_1.1.1          digest_0.6.12      
## [16] RColorBrewer_1.1-2  checkmate_1.8.3     minqa_1.2.4        
## [19] rvest_0.3.2         colorspace_1.3-2    htmltools_0.3.6    
## [22] Matrix_1.2-8        plyr_1.8.4          psych_1.7.5        
## [25] pkgconfig_2.0.1     SparseM_1.74        haven_1.1.0        
## [28] scales_0.4.1        MatrixModels_0.4-1  lme4_1.1-13        
## [31] htmlTable_1.9       mgcv_1.8-17         car_2.1-5          
## [34] lazyeval_0.2.0      pbkrtest_0.4-7      mnormt_1.5-5       
## [37] survival_2.41-3     magrittr_1.5        readxl_1.0.0       
## [40] evaluate_0.10.1     MASS_7.3-47         nlme_3.1-131       
## [43] class_7.3-14        xml2_1.1.1          foreign_0.8-69     
## [46] tools_3.3.3         data.table_1.10.4   hms_0.3            
## [49] munsell_0.4.3       cluster_2.0.5       e1071_1.6-8        
## [52] rlang_0.1.2.9000    nloptr_1.0.4        grid_3.3.3         
## [55] iterators_1.0.8     htmlwidgets_0.9     base64enc_0.1-3    
## [58] rmarkdown_1.6       gtable_0.2.0        ModelMetrics_1.1.0 
## [61] codetools_0.2-15    reshape2_1.4.2      R6_2.2.2           
## [64] gridExtra_2.2.1     lubridate_1.6.0     bindr_0.1          
## [67] Hmisc_4.0-3         rprojroot_1.2       stringi_1.1.5      
## [70] parallel_3.3.3      Rcpp_0.12.12        rpart_4.1-11       
## [73] acepack_1.4.1
```



