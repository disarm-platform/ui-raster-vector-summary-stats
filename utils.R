define_color_palettes <- function(stat_df){
  browser()
  pal_list <- list()
  
  for(i in 1:ncol(stat_df)){ # no column s for single stat
    pal_list[[names(stat_df)[i]]] <- colorNumeric(brewer.pal(9, "Greens")[5:9],
                                stat_df[,i], na.color = NA)
  }
  return(pal_list)
}

add_all_map_layers = function(map, map_data, palette_list, available_layers) {
  # browser()
  for (layer in available_layers) {
    # map = addPolygons(map, data = result_data, pal = palette_list[[layer]], group = layer)
    map = addPolygons(map, data = map_data, group = layer)
  }
  return(map)
}