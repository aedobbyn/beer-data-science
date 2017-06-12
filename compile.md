# Data Science Musings on Beer
`r format(Sys.time(), '%B %d, %Y')`  

![](./taps.jpg)




* Main question
    * Are there natural clusters in beer that are defined by styles? Or are style boundaries more or less arbitrary?
      * Unsupervised (k-means) clustering based on 
        * ABV (alcohol by volume), IBU (international bitterness units), SRM (measure of color)
      * Style centers defined by mean of ABV, IBU, and SRM
      
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


**Getting Beer**

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



Head of the data

name                                                      style                                                styleId   style_collapsed          abv    ibu   srm
--------------------------------------------------------  ---------------------------------------------------  --------  ----------------------  ----  -----  ----
"Ah Me Joy" Porter                                        Robust Porter                                        19        Porter                   5.4   51.0    40
"Bison Eye Rye" Pale Ale | 2 of 4 Part Pale Ale Series    American-Style Pale Ale                              25        Pale Ale                 5.8   51.0     8
"Dust Up" Cloudy Pale Ale | 1 of 4 Part Pale Ale Series   American-Style Pale Ale                              25        Pale Ale                 5.4   54.0    11
"God Country" Kolsch                                      German-Style Kölsch / Köln-Style Kölsch              45        Kölsch                   5.6   28.2     5
"Jemez Field Notes" Golden Lager                          Golden or Blonde Ale                                 36        Blonde                   4.9   20.0     5
#10 Hefewiezen                                            South German-Style Hefeweizen / Hefeweissbier        48        Wheat                    5.1   11.0     4
#9                                                        American-Style Pale Ale                              25        Pale Ale                 5.1   20.0     9
#KoLSCH                                                   German-Style Kölsch / Köln-Style Kölsch              45        Kölsch                   4.8   27.0     3
'Inappropriate' Cream Ale                                 American-Style Cream Ale or Lager                    109       Lager                    5.3   18.0     5
'tis the Saison                                           French & Belgian-Style Saison                        72        Saison                   7.0   30.0     7
(306) URBAN WHEAT BEER                                    Belgian-Style White (or Wit) / Belgian-Style Wheat   65        Wheat                    5.0   20.0     9
(512) Bruin (A.K.A. Brown Bear)                           American-Style Brown Ale                             37        Brown                    7.6   30.0    21
(512) FOUR                                                Strong Ale                                           14        Strong Ale               7.5   35.0     8
(512) IPA                                                 American-Style India Pale Ale                        30        India Pale Ale           7.0   65.0     8
(512) Pale                                                American-Style Pale Ale                              25        Pale Ale                 6.0   30.0     7
(512) SIX                                                 Belgian-Style Dubbel                                 58        Dubbel                   7.5   25.0    28
(512) THREE                                               Belgian-Style Tripel                                 59        Tripel                   9.5   22.0    10
(512) THREE (Cabernet Barrel Aged)                        Belgian-Style Tripel                                 59        Tripel                   9.5   22.0    40
(512) TWO                                                 Imperial or Double India Pale Ale                    31        Double India Pale Ale    9.0   99.0     9
(512) White IPA                                           American-Style India Pale Ale                        30        India Pale Ale           5.3   55.0     4


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


## Unsupervised Clustering 
* Pare down to beers that have ABV, IBU, and SRM
* K-means cluster beers based on these predictors

Compare popular styles      

style_collapsed              mean_abv   mean_ibu    mean_srm      n
-------------------------  ----------  ---------  ----------  -----
India Pale Ale               6.578468   66.04268    9.989313   6524
Pale Ale                     5.695480   40.86930    8.890306   4280
Stout                        7.991841   43.89729   36.300000   4238
Wheat                        5.158040   17.47168    5.861842   3349
Double India Pale Ale        8.930599   93.48142   11.006873   2525
Red                          5.742565   33.81127   16.178862   2521
Lager                        5.453718   30.64361    8.457447   2230
Saison                       6.400189   27.25114    7.053476   2167
Blonde                       5.595298   22.39432    5.625000   2044
Porter                       6.182049   33.25369   32.197605   1973
Brown                        6.159212   32.21577   23.592000   1462
Pilsener                     5.227593   33.51346    4.413462   1268
Specialty Beer               6.446402   33.77676   15.520548   1044
Bitter                       5.322364   38.28175   12.460526    939
Fruit Beer                   5.195222   19.24049    8.666667    905
Herb and Spice Beer          6.621446   27.77342   18.166667    872
Sour                         6.224316   18.88869   10.040816    797
Strong Ale                   8.826425   36.74233   22.547945    767
Tripel                       9.029775   32.51500    7.680556    734
Black                        6.958714   65.50831   31.080000    622
Barley Wine                 10.781600   74.04843   19.561404    605
Kölsch                       4.982216   23.37183    4.371795    593
Barrel-Aged                  9.002506   39.15789   18.133333    540
Other Belgian-Style Ales     7.516318   37.55812   17.549020    506
Pumpkin Beer                 6.712839   23.48359   17.918033    458
Dubbel                       7.509088   25.05128   22.940000    399
Scotch Ale                   7.620233   26.36909   24.222222    393
German-Style Doppelbock      8.045762   28.88692   25.696970    376
Fruit Cider                  6.205786   25.60000   12.000000    370
German-Style Märzen          5.746102   25.63796   14.322581    370


**Do Clustering**

* Use only the top beer styles
* Split off the predictors, ABV, IBU, and SRM
* Take out NAs, and scale the data
    * NB: There are not not very many beers have SRM so we may not want to omit based on it...
* Take out some outliers
  * Beers have to have an ABV between 3 and 20 and an IBU less than 200
  

```r
beer_for_clustering <- popular_beer_dat %>% 
  select(name, style, styleId, style_collapsed,
         abv, ibu, srm) %>%       # 
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

                                                       1     2    3    4     5    6     7    8    9   10
---------------------------------------------------  ---  ----  ---  ---  ----  ---  ----  ---  ---  ---
American-Style Amber/Red Ale                           2    33    8   87     9   18     2    0    1    4
American-Style Barley Wine Ale                         7     0    0    0     2    0    19   15    2    0
American-Style Black Ale                               0     0    4    1     0    0     0    0    2   36
American-Style Brown Ale                               1     1   20   68     2    7     1    1    6    3
American-Style Cream Ale or Lager                      3     4    0    1     0   43     0    0    0    0
American-Style Imperial Stout                          2     0    3    0     0    0     0   23   10    9
American-Style India Pale Ale                          2    64    1    6   395    1    27    0    0   26
American-Style Lager                                   1     9    1    7     4   29     0    0    0    0
American-Style Pale Ale                                5   211    1   25    29   32     0    0    1    3
American-Style Pilsener                                1    15    0    0     2   28     1    0    0    1
American-Style Premium Lager                           0     0    1    4     0   14     0    0    0    0
American-Style Sour Ale                                1     4    1    2     1   17     0    0    2    0
American-Style Stout                                   0     3   24    1     0    1     0    0    3    9
Belgian-Style Blonde Ale                              16     6    1    0     0   21     0    0    0    0
Belgian-Style Dark Strong Ale                         10     0    1    1     0    0     0    1   21    0
Belgian-Style Dubbel                                   8     0    1   14     1    0     0    0   16    1
Belgian-Style Pale Ale                                 6    10    0    5     3   18     0    0    0    0
Belgian-Style Tripel                                  59     1    0    0     0    0     2    0    2    1
Belgian-Style White (or Wit) / Belgian-Style Wheat     4     1    0    3     0   71     0    0    0    0
Berliner-Style Weisse (Wheat)                          0     0    0    0     0   26     0    0    0    0
Brown Porter                                           0     0   51   24     0    0     0    0    3    0
Extra Special Bitter                                   0    26    0   18     2    5     0    0    0    1
French & Belgian-Style Saison                         35    44    2    6     2   48     0    0    2    0
Fruit Beer                                             5     2    2    6     4   36     0    1    0    0
Fruit Cider                                            0     0    0    0     0    1     0    0    0    0
German-Style Doppelbock                                7     0    1    4     0    0     0    0   16    1
German-Style Kölsch / Köln-Style Kölsch                0     3    0    1     1   67     0    0    0    0
German-Style Märzen                                    0     2    1   15     0   12     0    0    0    0
German-Style Pilsener                                  0    24    0    1     1   18     0    0    0    0
Golden or Blonde Ale                                   5    12    0    3     1   94     0    0    1    0
Herb and Spice Beer                                    5     4    8   11     6   13     0    1    6    1
Imperial or Double India Pale Ale                      5     0    0    0    38    0   174    6    0    9
Irish-Style Red Ale                                    0     3    6   40     1   11     1    0    0    2
Light American Wheat Ale or Lager with Yeast           1    12    0    3     3   47     0    0    0    0
Oatmeal Stout                                          0     0   32    0     0    0     0    0    2    1
Ordinary Bitter                                        1     2    0    7     0    8     0    0    0    0
Other Belgian-Style Ales                               6     5    4    7     8    3     1    0    4    1
Pumpkin Beer                                           9     3    5   18     0    7     0    0    4    0
Robust Porter                                          0     1   51    5     0    0     0    0    8    3
Rye Ale or Lager with or without Yeast                 1     8    1    5    16    4     2    0    0    4
Scotch Ale                                             7     1    4    9     0    0     0    0   12    0
Session India Pale Ale                                 0    29    0    0     2    5     0    0    0    0
South German-Style Hefeweizen / Hefeweissbier          4     1    0    0     1   84     0    0    0    0
Specialty Beer                                        11     5    8   13     5   15     1    0    6    1
Strong Ale                                            11     0    1    1     0    0     4    3    1    2
Sweet or Cream Stout                                   0     0   32    1     0    0     0    1    7    0
Wood- and Barrel-Aged Beer                             5     3    2    4     1    2     1    1    4    0


Just the clusters
![](compile_files/figure-html/unnamed-chunk-11-1.png)<!-- -->


### Plot clusters related to style centers

![](compile_files/figure-html/unnamed-chunk-12-1.png)<!-- -->



### Ingredients

All hops types

-----------------------------------
                                   
#06300                             
Admiral                            
Aged / Debittered Hops (Lambic)    
Ahtanum                            
Alchemy                            
Amarillo                           
Amarillo Gold                      
Apollo                             
Aquila                             
Aramis                             
Argentine Cascade                  
Athanum                            
Aurora                             
Australian Dr. Rudi                
Azacca                             
Belma                              
Bramling Cross                     
Bravo                              
Brewer's Gold                      
Brewer's Gold (American)           
Calypso                            
Cascade                            
Celeia                             
Centennial                         
Challenger                         
Chinook                            
Citra                              
Cluster                            
Columbus                           
Crystal                            
CTZ                                
Delta                              
East Kent Golding                  
El Dorado                          
Ella                               
Enigma                             
Equinox                            
Eureka                             
Falconer's Flight                  
First Gold                         
French Strisserspalt               
Fuggle (American)                  
Fuggle (English)                   
Fuggles                            
Galaxy                             
Galena                             
German Magnum                      
German Mandarina Bavaria           
German Opal                        
German Perle                       
German Polaris                     
German Select                      
German Tradition                   
Glacier                            
Golding (American)                 
Green Bullet                       
Hallertau Hallertauer Mittelfrüher 
Hallertau Hallertauer Tradition    
Hallertau Northern Brewer          
Hallertauer (American)             
Hallertauer Herkules               
Hallertauer Hersbrucker            
Hallertauer Perle                  
Hallertauer Select                 
Hop Extract                        
Hops                               
Horizon                            
Kent Goldings                      
Kohatu                             
Lemon Drop                         
Liberty                            
Magnum                             
Marynka                            
Meridian                           
Millenium                          
Mosaic                             
Motueka                            
Mount Hood                         
Nelson Sauvin                      
New Zealand Hallertauer            
Noble                              
Northdown                          
Northern Brewer (American)         
Nugget                             
Pacific Gem                        
Pacific Jade                       
Pacifica                           
Palisades                          
Perle (American)                   
Phoenix                            
Pilgrim                            
Premiant                           
Rakau                              
Saaz (American)                    
Saaz (Czech)                       
Saphir (German Organic)            
Simcoe                             
Sorachi Ace                        
Southern Cross                     
Spalt                              
Spalt Select                       
Spalt Spalter                      
Sterling                           
Sticklebract                       
Styrian Goldings                   
Summit                             
Target                             
Tettnang Tettnanger                
Tettnanger (American)              
Warrior                            
Willamette                         
Zeus                               
Azzeca                             
Bobek                              
Cobb                               
Comet                              
Huell Melon                        
Mt. Rainier                        
New Zealand Sauvin                 
Pride of Ringwood                  
Revolution                         
Santiam                            
Sladek (Saaz)                      
Sovereign                          
Strisselspalt                      
Styrian Aurora                     
Styrian Bobeks                     
Topaz                              
Tradition                          
Vanguard                           
Waimea                             
Yakima Willamette                  
Zythos                             
Idaho 7                            
Jarrylo                            
Orbit                              
Tomahawk                           
Ultra                              
Vic Secret                         
New Zealand Motueka                
Newport                            
Wakatu                             
Columbus (Tomahawk)                
Experimental 06277                 
French Triskel                     
Experimental 05256                 
Helga                              
Super Galena                       
-----------------------------------

All malt types

-------------------------------------
                                     
Abbey Malt                           
Acidulated Malt                      
Amber Malt                           
Aromatic Malt                        
Barley - Black                       
Barley - Flaked                      
Barley - Lightly Roasted             
Barley - Malted                      
Barley - Raw                         
Barley - Roasted                     
Beechwood Smoked                     
Belgian Pale                         
Belgian Pilsner                      
Biscuit Malt                         
Black Malt                           
Black Malt - Debittered              
Black Patent                         
Black Roast                          
Blackprinz Malt                      
Bonlander                            
British Pale Malt                    
Brown Malt                           
Brown Sugar                          
Buckwheat - Roasted                  
C-15                                 
Canada 2-Row Silo                    
Cara Malt                            
CaraAmber                            
CaraAroma                            
CaraBrown                            
Carafa I                             
Carafa II                            
Carafa III                           
Carafa Special                       
CaraFoam                             
CaraHell                             
Caramel/Crystal Malt                 
Caramel/Crystal Malt - Dark          
Caramel/Crystal Malt - Heritage      
Caramel/Crystal Malt - Light         
Caramel/Crystal Malt - Organic       
Caramel/Crystal Malt 10L             
Caramel/Crystal Malt 120L            
Caramel/Crystal Malt 15L             
Caramel/Crystal Malt 20L             
Caramel/Crystal Malt 300L            
Caramel/Crystal Malt 30L             
Caramel/Crystal Malt 40L             
Caramel/Crystal Malt 45L             
Caramel/Crystal Malt 50L             
Caramel/Crystal Malt 55L             
Caramel/Crystal Malt 60L             
Caramel/Crystal Malt 75L             
Caramel/Crystal Malt 80L             
Caramel/Crystal Malt 8L              
CaraMunich                           
CaraMunich 120L                      
CaraMunich 40L                       
CaraMunich II                        
CaraMunich III                       
CaraPils/Dextrin Malt                
CaraRed                              
CaraRye                              
CaraStan                             
CaraVienne Malt                      
CaraWheat                            
Cherry Smoked                        
Cherrywood Smoke Malt                
Chocolate Malt                       
Coffee Malt                          
Corn - Field                         
Corn - Flaked                        
Crisp 77                             
Crystal 77                           
Dark Chocolate                       
Dememera Sugar                       
Dextrin Malt                         
Extra Special Malt                   
Gladfield Pale                       
Golden Promise                       
Honey                                
Honey Malt                           
Hugh Baird Pale Ale Malt             
Kiln Amber                           
Lactose                              
Lager Malt                           
Malted Rye                           
Maris Otter                          
Melanoidin Malt                      
Midnight Wheat                       
Munich Malt                          
Munich Malt - Dark                   
Munich Malt - Light                  
Munich Malt - Smoked                 
Munich Malt - Type I                 
Munich Malt - Type II                
Munich Malt 10L                      
Munich Wheat                         
Oats - Flaked                        
Oats - Malted                        
Oats - Rolled                        
Oats - Steel Cut (Pinhead Oats)      
Pale Malt                            
Pale Wheat                           
Pilsner Malt                         
Pilsner Malt - Organic               
Rahr Special Pale                    
Rice                                 
Rice - Flaked                        
Rice - Red                           
Rice - White                         
Rye Malt                             
Six-Row Pale Malt                    
Smoked Malt                          
Special B Malt                       
Spelt Malt                           
Two-Row Barley Malt                  
Two-Row Pale Malt                    
Two-Row Pale Malt - Organic          
Two-Row Pilsner Malt                 
Two-Row Pilsner Malt - Germany       
Victory Malt                         
Wheat - Flaked                       
Wheat - Raw                          
Wheat - Red                          
Wheat Malt                           
Wheat Malt - White                   
Barley - Roasted/De-husked           
Black Malt - Organic                 
Briess 2-row Chocolate Malt          
Cane Sugar                           
Caramel/Crystal Malt - Extra Dark    
Caramel/Crystal Malt - Medium        
Caramel/Crystal Malt 85L             
Caramel/Crystal Malt 90L             
CaraMunich 20L                       
CaraMunich 60L                       
CaraMunich I                         
Cereal                               
Chocolate Rye Malt                   
Chocolate Wheat Malt                 
Corn                                 
Corn Grits                           
Dextrose Syrup                       
Fawcett Crystal Rye                  
Harrington 2-Row Base Malt           
Malt Extract                         
Munich Malt - Organic                
Oats - Golden Naked                  
Pale Chocolate Malt                  
Pale Malt - Optic                    
Pale Malt - Organic                  
Rahr 2-Row Malt                      
Rauchmalz                            
Rice - Hulls                         
Roast Malt                           
Rye - Flaked                         
Two-Row Pale Malt - Toasted          
Two-Row Pilsner Malt - Belgian       
Vienna Malt                          
Wheat - Toasted                      
Wheat Malt - German                  
White Wheat                          
Wyermann Vienna                      
Asheburne Mild Malt                  
Briess Blackprinz Malt               
Chit Malt                            
Crisp 120                            
Fawcett Rye                          
Malto Franco-Belge Pils Malt         
Metcalfe                             
Mild Malt                            
Millet                               
Munich Malt 20L                      
Munich Malt 40L                      
Pale Malt - Halcyon                  
Palev                                
Piloncillo                           
Special Roast                        
Toasted Malt                         
Wheat - Torrified                    
Wheat Malt - Dark                    
Wheat Malt - Light                   
Wheat Malt - Red                     
Bamberg Smoked Malt                  
Caramel/Crystal Malt 150L            
Caramel/Crystal Malt 70L             
German Cologne                       
Glen Eagle Maris Otter               
High Fructose Corn Syrup             
Oats - Toasted                       
Pearl Malt                           
Peated Malt - Smoked                 
Samuel Adams two-row pale malt blend 
Special W Malt                       
Wheat Malt - Organic                 
Blue Agave Nectar                    
Torrefied Wheat                      
Weyermann Rye                        
Blue Corn                            
Carolina Rye Malt                    
Maple Syrup                          
Wheat Malt - Smoked                  
Sugar (Albion)                       
-------------------------------------

