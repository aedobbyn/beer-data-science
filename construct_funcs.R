# construct funcs

source("./get_beer.R")

# ---- build functions for requesting just a single beer, brewery, menu, etc. 
# (from single_param_endpoints)
# using purrr::partial and purr::walk
# https://stackoverflow.com/questions/44223711/use-assign-to-create-multiple-functions-inside-of-a-function-in-r/44223805?noredirect=1#comment75477312_44223805


# set up the base function
get_ <- function(id, ep) {
  fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
}

# for each of the endoints, pipe each single_param_endpoint through
# as .x, so both as the second half of the get_<ep> function name
# and the second argument of the get_ function defined above (so the ep in the fromJSON() call) 

single_param_endpoints %>% walk(~ assign(x = paste0("get_", .x),
                                         value = partial(get_, ep = .x),
                                         envir = .GlobalEnv))
get_beer("HZ9xM2")
get_brewery("pnLmiu")



# ------ original thoughts on how to do this ------
# build_single_arg_requests <- function() {
#   all_funcs <- list()
# 
#   for (ep in single_param_endpoints) {
#     get_ <- function(id, ep) {
#       fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
#     }
# 
#     this_func <- partial(get_, ep = ep, envir = .GlobalEnv)
# 
#     all_funcs <- c(all_funcs, this_func)
# 
#   }
#   all_funcs
# }
# build_single_arg_requests()

