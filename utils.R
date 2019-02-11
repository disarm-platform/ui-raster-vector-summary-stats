define_color_palettes <- function(stat_df){
 
  pal_list <- list()
  
  for(i in 1:ncol(stat_df)){ # no column s for single stat
    pal_list[[names(stat_df)[i]]] <- colorNumeric(map_palette("bruiser", n=10),
                                stat_df[,i], na.color = NA)
  }
  return(pal_list)
}

add_all_map_layers = function(map, map_data, palette_list, available_layers) {

  for (layer in available_layers) {
   
    
    labels <- sprintf(
             paste("<strong>", layer, ": </strong>",
                   as.data.frame(map_data)[,layer])
           ) %>% lapply(htmltools::HTML)
    
    map = addPolygons(map, 
                      data = map_data, 
                      group = layer,
                      color = "#696969",
                      fillOpacity = 0.9,
                      fillColor = palette_list[[layer]](as.data.frame(map_data)[,layer]),
                      highlightOptions = highlightOptions(
                        weight = 3,
                        color = "#FF0080",
                        bringToFront = TRUE,
                        fillOpacity = 0.7
                      ),
                      label = labels) %>%
      leaflet::addLegend("topleft", pal = palette_list[[layer]], 
                values = as.data.frame(map_data)[,layer],
                group = layer,
                title = layer)
  }
  return(map)
}