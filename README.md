#### Overview

This is a preliminary, strictly for-fun foray into beer data. Pairs well with most session IPAs.

You can find the **main report in [`compile/compile.md`](https://github.com/aedobbyn/beer-data-science/blob/master/compile/compile.md)**, read an [**interview**](https://medium.com/@Earlybird/chatting-with-data-scientist-amanda-dobbyn-about-analyzing-beer-styles-10a7a3278dfd) about the project, or flip through the [**presentation slides**](https://aedobbyn.github.io/beer-data-science/#/) for a talk given at RLadies Chicago. (The code behind those slides is in the [`present`](https://github.com/aedobbyn/beer-data-science/blob/master/present) directory.)

<br>

The *overarching question* I went into the analysis with was: how well do beer styles actually describe the characteristics of beers within each style? In other words, do natural clusters in beer align well with style boundaries?

I set about answering this with a mix of clustering (k-means) and classification (neural net and random forest) methods. If you want to play around with clustering interactively, there's a small [Shiny app](https://amandadobbyn.shinyapps.io/clusterfun/) that'll let you do that.

<br>

#### Structure
- Markdown report in [`/compile`](https://github.com/aedobbyn/beer-data-science/blob/master//compile/compile.md)
- .Rpres code behind RLadies Oktoberfest meetup [presentation](https://aedobbyn.github.io/beer-data-science/#/) in [`/present`](https://github.com/aedobbyn/beer-data-science/blob/master/present) 
- [Shiny app](https://amandadobbyn.shinyapps.io/clusterfun/) code in [`/clusterfun`](https://github.com/aedobbyn/beer-data-science/blob/master/clusterfun)
- Step-by-step scripts for getting and munging data in [`/run_it`](https://github.com/aedobbyn/beer-data-science/blob/master/run_it)

<br>

#### Reproduce it

All beer data was grabbed from the [BreweryDB API](http://www.brewerydb.com/developers), converted from JSON into a dataframe, and dumped into a MySQL database. To grab the data yourself, you can create an API key on BreweryDB run the `run_it.R` script inside the `run_it` directory. For a quicker but less up-to-date solution (the BreweryDB database is updated pretty frequently) you might consider stashing the data in a CSV or .feather file.

This analysis deals mainly with beer and its consituent components like ingredients (hops, malts) and other characteristics like bitterness and alcohol content. However, you can easily construct your own function for grabbing other things like breweries, glassware, locations, etc. by running the function generator in `helpers/construct_funcs.R`.


Any and all feedback is more than welcome. Cheers!

<br>
 
![](./img/cheers.jpg)

