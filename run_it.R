# run it

source("./get_beer.R")
source("./munge.R")
source("./collapse_styles.R")


# --------------- get all raw beer and breweries --------------
# paginated_request() from get_beer.R
all_beer_raw <- paginated_request("beers", "&withIngredients=Y")

all_breweries <- paginated_request("breweries", "")  # if no addition desired, just add empty string

all_glassware <- paginated_request("glassware", "")


# --------------- get the columns we care about ---------------
# unnest_ingredients() from munge.R
all_beer <- unnest_ingredients(all_beer_raw) %>% as_tibble()

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
beer_necessities$glass <- factor(beer_necessities$glass)

beer_necessities$ibu <- as.numeric(beer_necessities$ibu)
beer_necessities$srm <- as.numeric(beer_necessities$srm)
beer_necessities$abv <- as.numeric(beer_necessities$abv)


# ------------------- collapse styles ------------------- 
# collapse_styles() and collapse_further() from collapse_styles.R
beer_necessities$style_collapsed <- NA
beer_necessities <- collapse_styles(beer_necessities)

beer_necessities$style_collapsed <- factor(beer_necessities$style_collapsed)
beer_necessities <- collapse_further(beer_necessities)

droplevels(beer_necessities)$style_collapsed %>% as_tibble() 




# ------------------ pare to most popular styles ---------------
beer_dat_pared <- beer_necessities[complete.cases(beer_necessities$style), ]

# arrange beer dat by style popularity
style_popularity <- beer_dat_pared %>% 
  group_by(style) %>% 
  count() %>% 
  arrange(desc(n))
style_popularity

# and add a column that scales popularity so we can filter by z-score
style_popularity <- bind_cols(style_popularity, 
                              n_scaled = as.vector(scale(style_popularity$n)))

# find styles that are above a z-score of 0
popular_styles <- style_popularity %>% 
  filter(n_scaled > 0)

# pare dat down to only beers that fall into those styles
popular_beer_dat <- beer_dat_pared %>% 
  filter(
    style %in% popular_styles$style
  ) %>% 
  droplevels()
nrow(popular_beer_dat)

# find the centers (mean abv, ibu, srm) of the most popular styles
style_centers <- popular_beer_dat %>% 
  group_by(style_collapsed) %>% 
  summarise(
    mean_abv = mean(abv, na.rm = TRUE),
    mean_ibu = mean(ibu, na.rm = TRUE), 
    mean_srm = mean(srm, na.rm = TRUE)
  ) %>% 
  drop_na() %>% 
  droplevels()




