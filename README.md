#### Overview

This is a preliminary, strictly for-fun foray into beer data. Pairs well with most session IPAs.

All beer data was grabbed from the [BreweryDB API](http://www.brewerydb.com/developers) and dumped into a MySQL database. You can find the **main report in [`compile.md`](https://github.com/aedobbyn/beer-data-science/blob/master/compile.md)**. 

The main question I went into the analysis with was: how well do beer styles actually describe the characteristics of beers within each style? In other words, do natural clusters in beer align well with style boundaries?

I set about answering this with a mix of clustering (k-means) and classification (multinomial neural net and random forest) methods.

![](./brews.jpg)


#### Reproduce it

To grab the data yourself, you can create an API key on BreweryDB run the `run_it.R` script inside the `run_it` folder. For a quicker but less up-to-date solution (the BreweryDB database is updated pretty frequently), feel free to download `beer_necessities.csv`.

This analysis deals mainly with beer and its consituent components like ingredients (hops, malts) and other characteristics like bitterness and alcohol content. However, you can easily construct your own function for grabbing other things like breweries, glassware, locations, etc. by running the function generator in `construct_funcs.R`.


Any and all feedback is more than welcome. Cheers!
 