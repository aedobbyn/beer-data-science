# construct funcs

# ---- build functions for requesting just a single beer, brewery, menu, etc. (from single_param_endpoints)
# uses purrr::partial 

build_single_arg_requests <- function() {
  all_funcs <- list()
  
  for (ep in single_param_endpoints) {
    get_ <- function(id, ep) {
      fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
    }
    
    this_func <- partial(get_, ep = ep, envir = .GlobalEnv)
    
    all_funcs <- c(all_funcs, this_func)
    
  }
  all_funcs
}


single_param_endpoints %>% walk(~ assign(x = paste0("func_", .x),
                                         value = partial(func_, key_name = .x),
                                         envir = .GlobalEnv))

build_single_arg_requests()
get_beer("HZ9xM2")
this_func


get_ <- function(id, ep) {
  fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
}

single_param_endpoints %>% walk(~ assign(x = paste0("get_", .x),
                                         value = partial(func_, ep = .x),
                                         envir = .GlobalEnv))

get_beer("HZ9xM2")


# actually make the functions
get_beer <- partial(get_, ep = "beer")
get_brewery <- partial(get_, ep = "brewery")

# example use case
get_beer("HZ9xM2")

get_event("1")






# ------ SO answer 

func_ <- function(x, key_name) {
  paste0("key_name:  ", key_name, " -----  value_x: ", x)
}



letters %>% walk(~ assign(x = paste0("func_", .x),
                          value = partial(func_, key_name = .x),
                          envir = .GlobalEnv))

func_b("foo") # "key_name:  b -----  value_x: foo"
func_a("foo")






get_bar_ <- function(id, ep) {
  fromJSON(paste0(base_url, "/", ep, "/", id, "/", key_preface, key))
}

single_param_endpoints %>% walk(~ assign(x = paste0("get_bar_", .x),
                                         value = partial(get_bar_, ep = .x),
                                         envir = .GlobalEnv))
get_bar_beer("HZ9xM2")

