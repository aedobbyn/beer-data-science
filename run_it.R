# run it


# ----- get all beer and breweries
# paginated_request() from get_beer.R

all_beer_raw <- paginated_request("beers", "&withIngredients=Y")

all_breweries <- paginated_request("breweries", "")  # if no addition desired, just add empty string



# ------- unnest_ingredients() from munge.R
all_beer <- unnest_ingredients(all_beer_raw)


# ----- unnest_it() from munge.R
unnested_beer <- unnest_it(all_beer)
head(unnested_beer[["data"]])

unnested_breweries <- unnest_it(all_breweries)
head(unnested_breweries[["data"]])

unnested_glassware <- unnest_it(all_glassware)
head(unnested_glassware[["data"]])


# keep only columns we care about
beer_necessities <- all_beer %>%
  rename(
    glass = glass.name,
    srm = srm.name,
    style = style.name
  ) %>% select(
    id, name, description, style,
    abv, ibu, srm, glass,
    hops_name, hops_id, malt_name, malt_id,
    glasswareId, styleId, style.categoryId
  )


# set types
beer_necessities$style <- factor(beer_necessities$style)
beer_necessities$styleId <- factor(beer_necessities$styleId)
beer_necessities$style_collapsed <- factor(beer_necessities$style_collapsed)
beer_necessities$glass <- factor(beer_necessities$glass)

beer_necessities$ibu <- as.numeric(beer_necessities$ibu)
beer_necessities$srm <- as.numeric(beer_necessities$srm)
beer_necessities$abv <- as.numeric(beer_necessities$abv)




