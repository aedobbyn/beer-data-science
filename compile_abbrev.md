# Data Science Musings on Beer -- Abbreviated
`r format(Sys.time(), "%B %d, %Y")`  





This is a first pass exploration of different aspects of beer.

* Data courtesy of [BreweryDB](http://www.brewerydb.com/developers)
    * Special thanks to [Kris Kroski](https://kro.ski/) for data ideation and beer

* The main question on the table is this:
    * Are beer styles actually indicative of shared attributes of the beers within that style? Or are style boundaries more or less arbitrary?
      * Two approaches: clustering and prediction 
      * Clustering: are there natural clusters across the spectum of beers that align well with the styles they're grouped into? 
          * Unsupervised (k-means) clustering based on 
              * ABV (alcohol by volume), IBU (international bitterness units), SRM (measure of color)
              * How well do these match up with various "style centers," defined by mean of ABV, IBU, and SRM per beer style
      * Prediction: can we predict a beer's style based on certain characteristics of the beer?
          * Neural net 
          * Random forest
      
* Answer thus far
    * Beer-intrinsic attributes aren't great predictors of style
    * Style-defined attributes are the best predictors
        * For instance, the glass a beer is served in (which is defined by its style) is a much better predictor of its style than actual characteristics of the beer like ABV and even the number of different types of hops it contains

![](./taps.jpg)

### Workflow Overview

* Hit the BreweryDB API to iteratively pull in all beers and their ingredients along with other things we might want like breweries and glassware
* Unnest the JSON responses, including all the ingredients columns, and 
* Dump this all into a MySQL database 

* Create a `style_collapsed` column to reduce the number of levels of our outcome variable
    * `grep` through each beer's style to determine if that style contains a keyword that qualifies it to be rolled into a collapsed style
    * If it does, it gets that keyword in a `style_collapsed` column 
    * Further collpase styles that are similar like Hefeweizen and Wit into Wheat
    
* Unnest the ingredients `hops` and `malts` into a sparse matrix
    * Individual ingredients as columns, beers as rows; cell gets a 1 if ingredient is present and 0 otherwise 
    
* Cluster: unsupervised k-means clsutering based on ABV, IBU, and SRM

* Run a neural net
    * Predict either `style` or `style_collapsed` from all the predictors including the total number of hops and malts per beer



**Short Aside**

The question of what should be a predictor variable for style is a bit murky here. What should be fair game for predicting style and what shouldn't? Characteristics of a beer that are defined *by* its style would seem to be "cheating" in a way. 

* Main candidates are:
    * ABV (alcohol by volume), IBU (international bitterness units), SRM (standard reference measure, a scale of beer color from light to dark)
        * These are outputs of a beer that meaningfully define the beer and are theoretically orthogonal to each other
    * Ingredients in a beer such as hops and malts
        * Inputs to a beer that have some effect on its flavor profile
        * Semi-cheating because if style is determined beforehand it likely determines at least in part which ingredients are added 
    * Glass type
        * This is defined entirely by style and is very predictive of it





















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
clustered_beer <- cluster_it(df = popular_beer_dat,
                             preds = cluster_on,
                             to_scale = to_scale,
                             resp = response_vars,
                             n_centers = 10)
```

```
## KMNS(*, k=10): iter=  1, indx=14
##  QTRAN(): istep=3399, icoun=5
##  QTRAN(): istep=6798, icoun=24
##  QTRAN(): istep=10197, icoun=41
##  QTRAN(): istep=13596, icoun=25
##  QTRAN(): istep=16995, icoun=115
##  QTRAN(): istep=20394, icoun=13
##  QTRAN(): istep=23793, icoun=115
##  QTRAN(): istep=27192, icoun=557
##  QTRAN(): istep=30591, icoun=372
##  QTRAN(): istep=33990, icoun=1417
##  QTRAN(): istep=37389, icoun=2075
##  QTRAN(): istep=40788, icoun=1810
##  QTRAN(): istep=44187, icoun=300
## KMNS(*, k=10): iter=  2, indx=0
##  QTRAN(): istep=3399, icoun=14
##  QTRAN(): istep=6798, icoun=18
##  QTRAN(): istep=10197, icoun=297
##  QTRAN(): istep=13596, icoun=307
##  QTRAN(): istep=16995, icoun=647
##  QTRAN(): istep=20394, icoun=195
##  QTRAN(): istep=23793, icoun=634
##  QTRAN(): istep=27192, icoun=520
##  QTRAN(): istep=30591, icoun=2482
## KMNS(*, k=10): iter=  3, indx=118
##  QTRAN(): istep=3399, icoun=1
##  QTRAN(): istep=6798, icoun=1
##  QTRAN(): istep=10197, icoun=18
##  QTRAN(): istep=13596, icoun=252
##  QTRAN(): istep=16995, icoun=270
##  QTRAN(): istep=20394, icoun=161
##  QTRAN(): istep=23793, icoun=232
##  QTRAN(): istep=27192, icoun=39
##  QTRAN(): istep=30591, icoun=489
##  QTRAN(): istep=33990, icoun=217
##  QTRAN(): istep=37389, icoun=52
##  QTRAN(): istep=40788, icoun=596
##  QTRAN(): istep=44187, icoun=597
##  QTRAN(): istep=47586, icoun=1130
##  QTRAN(): istep=50985, icoun=1832
## KMNS(*, k=10): iter=  4, indx=17
##  QTRAN(): istep=3399, icoun=9
##  QTRAN(): istep=6798, icoun=388
##  QTRAN(): istep=10197, icoun=2244
## KMNS(*, k=10): iter=  5, indx=374
##  QTRAN(): istep=3399, icoun=2244
##  QTRAN(): istep=6798, icoun=583
##  QTRAN(): istep=10197, icoun=1833
## KMNS(*, k=10): iter=  6, indx=3399
```

Head of the clustering data

|cluster_assignment |name                                                         |style                                              |styleId |style_collapsed       | abv_scaled| ibu_scaled| srm_scaled| abv|  ibu| srm|
|:------------------|:------------------------------------------------------------|:--------------------------------------------------|:-------|:---------------------|----------:|----------:|----------:|---:|----:|---:|
|3                  |"Ah Me Joy" Porter                                           |Robust Porter                                      |19      |Porter                | -0.6113116|  0.3483405|  2.5598503| 5.4| 51.0|  40|
|2                  |"Bison Eye Rye" Pale Ale &#124; 2 of 4 Part Pale Ale Series  |American-Style Pale Ale                            |25      |Pale Ale              | -0.3851131|  0.3483405| -0.5138012| 5.8| 51.0|   8|
|2                  |"Dust Up" Cloudy Pale Ale &#124; 1 of 4 Part Pale Ale Series |American-Style Pale Ale                            |25      |Pale Ale              | -0.6113116|  0.4631499| -0.2256464| 5.4| 54.0|  11|
|6                  |"God Country" Kolsch                                         |German-Style Kölsch / Köln-Style Kölsch            |45      |Kölsch                | -0.4982124| -0.5242109| -0.8019561| 5.6| 28.2|   5|
|6                  |"Jemez Field Notes" Golden Lager                             |Golden or Blonde Ale                               |36      |Blonde                | -0.8940598| -0.8380232| -0.8019561| 4.9| 20.0|   5|
|6                  |#10 Hefewiezen                                               |South German-Style Hefeweizen / Hefeweissbier      |48      |Wheat                 | -0.7809605| -1.1824514| -0.8980077| 5.1| 11.0|   4|
|6                  |#9                                                           |American-Style Pale Ale                            |25      |Pale Ale              | -0.7809605| -0.8380232| -0.4177496| 5.1| 20.0|   9|
|6                  |#KoLSCH                                                      |German-Style Kölsch / Köln-Style Kölsch            |45      |Kölsch                | -0.9506094| -0.5701346| -0.9940593| 4.8| 27.0|   3|
|6                  |'Inappropriate' Cream Ale                                    |American-Style Cream Ale or Lager                  |109     |Lager                 | -0.6678613| -0.9145628| -0.8019561| 5.3| 18.0|   5|
|2                  |'tis the Saison                                              |French & Belgian-Style Saison                      |72      |Saison                |  0.2934824| -0.4553252| -0.6098528| 7.0| 30.0|   7|
|6                  |(306) URBAN WHEAT BEER                                       |Belgian-Style White (or Wit) / Belgian-Style Wheat |65      |Wheat                 | -0.8375102| -0.8380232| -0.4177496| 5.0| 20.0|   9|
|4                  |(512) Bruin (A.K.A. Brown Bear)                              |American-Style Brown Ale                           |37      |Brown                 |  0.6327802| -0.4553252|  0.7348697| 7.6| 30.0|  21|
|1                  |(512) FOUR                                                   |Strong Ale                                         |14      |Strong Ale            |  0.5762306| -0.2639763| -0.5138012| 7.5| 35.0|   8|
|5                  |(512) IPA                                                    |American-Style India Pale Ale                      |30      |India Pale Ale        |  0.2934824|  0.8841177| -0.5138012| 7.0| 65.0|   8|
|2                  |(512) Pale                                                   |American-Style Pale Ale                            |25      |Pale Ale              | -0.2720139| -0.4553252| -0.6098528| 6.0| 30.0|   7|
|9                  |(512) SIX                                                    |Belgian-Style Dubbel                               |58      |Dubbel                |  0.5762306| -0.6466742|  1.4072310| 7.5| 25.0|  28|
|1                  |(512) THREE                                                  |Belgian-Style Tripel                               |59      |Tripel                |  1.7072231| -0.7614836| -0.3216980| 9.5| 22.0|  10|
|9                  |(512) THREE (Cabernet Barrel Aged)                           |Belgian-Style Tripel                               |59      |Tripel                |  1.7072231| -0.7614836|  2.5598503| 9.5| 22.0|  40|
|7                  |(512) TWO                                                    |Imperial or Double India Pale Ale                  |31      |Double India Pale Ale |  1.4244750|  2.1852908| -0.4177496| 9.0| 99.0|   9|
|2                  |(512) White IPA                                              |American-Style India Pale Ale                      |30      |India Pale Ale        | -0.6678613|  0.5014197| -0.8980077| 5.3| 55.0|   4|



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


Plot the clusters. There are 3 axes: ABV, IBU, and SRM, so we choose two at a time. 

![](compile_abbrev_files/figure-html/unnamed-chunk-11-1.png)<!-- -->![](compile_abbrev_files/figure-html/unnamed-chunk-11-2.png)<!-- -->


### Certain selected styles

![](compile_abbrev_files/figure-html/unnamed-chunk-12-1.png)<!-- -->


### Now add in the style centers (means) for collapsed styles

![](compile_abbrev_files/figure-html/unnamed-chunk-13-1.png)<!-- -->





### Ingredients

To get more granular with ingredients, we can split out each individual ingredient into its own column. If a beer or style contains that ingredient, its row gets a ` in that ingredient column and a 0 otherwise.














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




### Back to clustering: cluster on only 5 styles
* But now add in `total_hops` and `total_malts` as predictors 


```
## KMNS(*, k=5): iter=  1, indx=5
##  QTRAN(): istep=1220, icoun=16
##  QTRAN(): istep=2440, icoun=879
## KMNS(*, k=5): iter=  2, indx=1220
```



|               |   1|  2|   3|   4|  5|
|:--------------|---:|--:|---:|---:|--:|
|Blonde         |   2| 25| 125|   4|  4|
|India Pale Ale |  11|  4|  41| 439| 67|
|Stout          | 160|  3|   3|   1|  3|
|Tripel         |   3| 60|   0|   1|  1|
|Wheat          |   0|  9| 234|   5| 15|

![](compile_abbrev_files/figure-html/unnamed-chunk-19-1.png)<!-- -->



## Random asides into hops

**Do more hops always mean more bitterness?**

* It would appear so, from this graph and this regression (beta = 2.394418)
![](compile_abbrev_files/figure-html/unnamed-chunk-20-1.png)<!-- -->

```
## 
## Call:
## lm(formula = ibu ~ total_hops, data = beer_ingredients_join)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -40.024 -19.235  -7.235  18.765 141.765 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)  41.2352     0.4619   89.28  < 2e-16 ***
## total_hops    2.3944     0.4526    5.29  1.3e-07 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 26 on 3417 degrees of freedom
## Multiple R-squared:  0.008123,	Adjusted R-squared:  0.007833 
## F-statistic: 27.98 on 1 and 3417 DF,  p-value: 1.3e-07
```

* However, past a certain point (3 hops or more), there's no effect of number of hops on IBU

![](compile_abbrev_files/figure-html/unnamed-chunk-21-1.png)<!-- -->


**Most popular hops**


|hop_name                   | mean_ibu| mean_abv|   n|
|:--------------------------|--------:|--------:|---:|
|Amarillo                   | 61.36053| 6.959264| 163|
|Cascade                    | 51.92405| 6.510729| 445|
|Centennial                 | 63.96526| 7.081883| 243|
|Chinook                    | 60.86871| 7.043439| 194|
|Citra                      | 59.60000| 6.733290| 157|
|Columbus                   | 63.74483| 6.953846| 183|
|East Kent Golding          | 38.51875| 6.347386|  89|
|Fuggles                    | 40.75581| 6.772143|  59|
|Hallertauer (American)     | 23.92388| 5.658537|  83|
|Magnum                     | 48.71596| 6.926852| 109|
|Mosaic                     | 56.81818| 6.977465|  71|
|Mount Hood                 | 37.83500| 6.550000|  68|
|Northern Brewer (American) | 39.48475| 6.473944|  71|
|Nugget                     | 52.23810| 6.383119| 114|
|Perle (American)           | 32.03947| 6.251744|  88|
|Saaz (American)            | 30.69778| 6.248333|  60|
|Simcoe                     | 64.07211| 6.877394| 191|
|Sterling                   | 35.41860| 6.024259|  55|
|Tettnanger (American)      | 30.27551| 6.016780|  59|
|Warrior                    | 59.13043| 6.983115|  62|
|Willamette                 | 39.61078| 7.014657| 133|

Are there certian hops that are used more often in very high IBU or ABV beers?
Hard to detect a pattern

![](compile_abbrev_files/figure-html/unnamed-chunk-23-1.png)<!-- -->


# Neural Net

* Can ABV, IBU, and SRM be used in a neural net to predict `style` or `style_collapsed`?
* In the function, specify the dataframe and the outcome, either `style` or `style_collapsed`; the one not specified as `outcome` will be dropped
* The predictor columns will be everything not specified in the vector `predictor_vars`


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
                 data = df_train, maxit=500, trace=T)

  # Which variables are the most important in the neural net?
  most_important_vars <- varImp(nn)

  # How accurate is the model? Compare predictions to outcomes from test data
  nn_preds <- predict(nn, type="class", newdata = df_test)
  nn_accuracy <- postResample(df_test$outcome, nn_preds)

  out <- list(out, nn = nn, most_important_vars = most_important_vars,
              df_test = df_test,
              nn_preds = nn_preds,
           nn_accuracy = nn_accuracy)

  return(out)
}
```

* Set the dataframe to be `beer_ingredients_join`, the predictor variables to be the vector contained in `p_vars`, the outcome to be `style_collapsed`


```r
p_vars <- c("total_hops", "total_malt", "abv", "ibu", "srm", "glass")

nn_collapsed_out <- run_neural_net(df = beer_ingredients_join, outcome = "style_collapsed", 
                         predictor_vars = p_vars)
```

```
## # weights:  522 (476 variable)
## initial  value 5189.002874 
## iter  10 value 4101.664681
## iter  20 value 3818.943295
## iter  30 value 3683.869955
## iter  40 value 3494.261404
## iter  50 value 3242.052315
## iter  60 value 3106.920640
## iter  70 value 2968.841371
## iter  80 value 2769.439750
## iter  90 value 2660.340209
## iter 100 value 2577.879191
## iter 110 value 2515.471734
## iter 120 value 2492.212775
## iter 130 value 2473.771723
## iter 140 value 2463.134319
## iter 150 value 2458.636652
## iter 160 value 2456.476818
## iter 170 value 2456.036254
## iter 180 value 2455.881297
## iter 190 value 2455.773302
## iter 200 value 2455.622832
## iter 210 value 2455.526383
## iter 220 value 2455.480184
## iter 230 value 2455.458931
## iter 240 value 2455.422694
## iter 250 value 2455.410839
## iter 260 value 2455.407746
## iter 270 value 2455.406563
## iter 280 value 2455.401931
## final  value 2455.401259 
## converged
```

```r
# How accurate was it?
nn_collapsed_out$nn_accuracy
```

```
##  Accuracy     Kappa 
## 0.5000000 0.4588764
```

```r
# What were the most important variables?
nn_collapsed_out$most_important_vars
```

```
##                              Overall
## total_hops                 69.654945
## total_malt                 50.311853
## abv                        42.615502
## ibu                         3.918066
## srm                         4.579843
## glassGoblet               397.374182
## glassMug                  331.569097
## glassOversized Wine Glass 191.839994
## glassPilsner              461.028137
## glassPint                 278.156121
## glassSnifter              312.602345
## glassStange               189.351854
## glassThistle              452.468707
## glassTulip                266.547554
## glassWeizen               123.188935
## glassWilli                262.940788
```


* What if we predcit `style` instead of `style_collapsed`?


```
## # weights:  828 (765 variable)
## initial  value 6022.452917 
## iter  10 value 4996.432878
## iter  20 value 4765.792309
## iter  30 value 4510.391741
## iter  40 value 4361.302193
## iter  50 value 4204.858745
## iter  60 value 4027.583899
## iter  70 value 3837.375623
## iter  80 value 3653.275878
## iter  90 value 3462.294270
## iter 100 value 3320.692374
## iter 110 value 3194.622144
## iter 120 value 3069.284975
## iter 130 value 2965.936521
## iter 140 value 2906.978999
## iter 150 value 2883.867936
## iter 160 value 2865.643770
## iter 170 value 2858.183468
## iter 180 value 2851.846211
## iter 190 value 2848.122314
## iter 200 value 2843.968435
## iter 210 value 2840.894240
## iter 220 value 2838.828006
## iter 230 value 2837.463334
## iter 240 value 2836.667079
## iter 250 value 2836.246844
## iter 260 value 2836.096131
## iter 270 value 2836.030396
## iter 280 value 2836.007094
## iter 290 value 2836.000876
## iter 300 value 2835.991817
## iter 310 value 2835.986783
## iter 320 value 2835.984746
## iter 330 value 2835.982948
## iter 340 value 2835.977150
## iter 350 value 2835.973669
## iter 360 value 2835.972699
## final  value 2835.972544 
## converged
```

```
##  Accuracy     Kappa 
## 0.4224599 0.3875314
```

```
##                              Overall
## total_hops                204.453599
## total_malt                120.372485
## abv                        41.370443
## ibu                         4.490022
## srm                         8.542849
## glassGoblet               560.331043
## glassMug                  428.192923
## glassOversized Wine Glass 103.542307
## glassPilsner              480.581556
## glassPint                 279.514041
## glassSnifter              379.692790
## glassStange               161.842943
## glassThistle              199.484794
## glassTulip                319.849211
## glassWeizen               285.273981
## glassWilli                402.236342
```


And now if we drop `glass`?

```
## # weights:  522 (476 variable)
## initial  value 5236.145016 
## iter  10 value 4082.038509
## iter  20 value 3858.491269
## iter  30 value 3720.703952
## iter  40 value 3494.242497
## iter  50 value 3281.935700
## iter  60 value 3149.716012
## iter  70 value 2961.425572
## iter  80 value 2782.820310
## iter  90 value 2684.365914
## iter 100 value 2608.859823
## iter 110 value 2564.879856
## iter 120 value 2544.784423
## iter 130 value 2530.106423
## iter 140 value 2519.650287
## iter 150 value 2514.338195
## iter 160 value 2513.189531
## iter 170 value 2512.956552
## iter 180 value 2512.764390
## iter 190 value 2512.596447
## iter 200 value 2512.402201
## iter 210 value 2512.292879
## iter 220 value 2512.238512
## iter 230 value 2512.226630
## iter 240 value 2512.201402
## iter 250 value 2512.191406
## iter 260 value 2512.188362
## iter 270 value 2512.187644
## iter 280 value 2512.187248
## final  value 2512.187127 
## converged
```

```
##  Accuracy     Kappa 
## 0.4770408 0.4361770
```

```
##                              Overall
## total_hops                 70.750103
## total_malt                 68.640660
## abv                        37.797184
## ibu                         3.902783
## srm                         4.554177
## glassGoblet               383.850580
## glassMug                  336.192229
## glassOversized Wine Glass 119.553928
## glassPilsner              585.312255
## glassPint                 298.943364
## glassSnifter              344.712146
## glassStange               189.979984
## glassThistle              832.762378
## glassTulip                271.027999
## glassWeizen               126.127095
## glassWilli                260.200505
```




### Random forest with all ingredients

* We can use a random forest to get even more granular with ingredients
    * The sparse ingredient dataframe was too complex for the multinomial neural net; however, we can 

* Here we don't include `glass` as a predictor


```
## Ranger result
## 
## Call:
##  ranger(style_collapsed ~ ., data = bi_train, importance = "impurity") 
## 
## Type:                             Classification 
## Number of trees:                  500 
## Sample size:                      2735 
## Number of independent variables:  201 
## Mtry:                             14 
## Target node size:                 1 
## Variable importance mode:         impurity 
## OOB prediction error:             56.78 %
```


* Interestingly, ABV, IBU, and SRM are all much more important in the random forest than `total_hops` and `total_malt`

```
##               total_hops               total_malt                      abv 
##               10.3590387                8.4187124              108.2855551 
##                      ibu                      srm ageddebitteredhopslambic 
##              174.3470872               97.9125272                0.2416759 
##                  ahtanum                  alchemy                 amarillo 
##                0.5750893                1.7049982                2.9860434 
##                   apollo 
##                0.7517504
```


How does a CSRF (case-specific random forest) fare?


```
##  Accuracy     Kappa 
## 0.3040936 0.2243069
```


![](./pour.jpg)



### Final Thoughts


*Style first, forgiveness later?*

* One reason  seems that beers are generally brewed with style in mind first ("let's make a pale ale") rather than deciding the beer's style after determining its characteristics and idiosyncrasies 
    * Even if the beer turns out more like a sour, and in a blind taste test might be classified as a sour more often than a pale ale, it still gets the label pale ale
    * This makes the style definitions broader and harder to predict



*Future Directions*

* Incorporate flavor profiles for beers sourced/scraped from somewhere
* Implement a GAN to come up with beer names
* More on the hops deep dive: which hops are used most often in which styles?

