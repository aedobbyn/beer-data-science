#### Overview

This is a preliminary, strictly for-fun foray into beer data science. Pairs well with most session IPAs.

All beer data was grabbed from the [BreweryDB API](http://www.brewerydb.com/developers) and dumped into a MySQL database. You can find the **main report in `compile.md`**. 

The main question I went into the analysis with was: how well do beer styles actually describe the characteristics of beers within each style?

![](./brews.jpg)


#### Reproduce it

To grab the data yourself, you can create an API key on BreweryDB run the `run_it.R` script inside the `run_it` folder. For a quicker but less up-to-date solution (the BreweryDB database is updated pretty frequently), feel free to download `beer_necessities.csv`.

This analysis deals mainly with beer and its consituent components like ingredients (hops, malts) and other characteristics like bitterness and alcohol content. However, you can easily construct your own function for grabbing other things like breweries, glassware, locations, etc. by running the function generator in `construct_funcs.R`.


Any and all feedback is more than welcome. Cheers!
 