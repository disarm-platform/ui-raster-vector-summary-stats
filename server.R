library(raster)
library(sp)
library(leaflet)
library(RANN)
library(rgeos)
library(rjson)
library(httr)
library(wesanderson)
library(readr)
library(stringi)
library(DT)
library(ggplot2)
library(geoR)
library(velox)
library(sf)
library(RColorBrewer)


# Define map
map <- leaflet(max) %>%
  addTiles(
    "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png"
  )

# Get Worldpop data
worldpop_africa <- velox("/Users/hughsturrock/Dropbox/Random/AFR_PPP_2015_adj_v2.tif")


shinyServer(function(input, output) {
  
  map_data <- reactive({
    inFile <- input$File

    if (is.null(inFile))
      return(NULL)
    
    
    # Give loading bar
    withProgress(message = 'Hold on',
                 detail = 'Crunching data..',
                 value = 5,
                 {
                   input_poly <- st_read(inFile$datapath)
                   
                   # Check if points and if so, create buffer
                   # and extract using that polygon
                   if(unique(st_geometry_type(input_poly))=="POINT"){
                     centroids <- st_centroid(input_poly)
                     input_poly <- st_buffer(centroids, input$Buffer/112)
                   }
                   
                   # if(length(dups)>0){
                   #   
                   #   drop <- unlist(sapply(dups, function(x){as.numeric(x[-1])}))
                   #   pred_points <- pred_points[-drop,]
                   #   
                   #   showNotification(paste("Removed", length(drop), "prediction points with duplicate coordinates"))
                   #   
                   # }
                   
                   # Make call to algorithm
                   sum_with_na <- function(x){sum(x, na.rm=T)}
                   worldpop_africa$crop(as.vector(extent(input_poly)))
                   input_poly$extracted_pop <- round(worldpop_africa$extract(sp=input_poly, fun=sum_with_na), 0)
                   print("Extraction complete")
                   return(input_poly)

                 })
  })
  
  output$pop_table <- DT::renderDT({
 
    if (is.null(map_data())) {
      return(NULL)
    }
    map_data_no_geom <- map_data()
    st_geometry(map_data_no_geom) <- NULL
    output_table <- as.data.frame(map_data_no_geom)
    DT::datatable(output_table,
                  options = list(pageLength = 15),
                  rownames = F)
  })

  
  output$pop_map <- renderLeaflet({
    if (is.null(map_data())) {
      return(map %>% setView(0, 0, zoom = 2))
    }

    # Define color palette
    pal <-
      colorNumeric(brewer.pal(9, "Greens")[5:9],
                   map_data()$extracted_pop)
    
    labels <- sprintf(
      paste("<strong>Population: </strong>",
      map_data()$extracted_pop)
    ) %>% lapply(htmltools::HTML)
    
    # Map
    input_poly_sp <- as(map_data(), "Spatial")
    map %>% addPolygons(
      data = input_poly_sp,
      color = "#696969",
      fillColor = pal(map_data()$extracted_pop),
      fillOpacity = 0.6,
      weight = 4,
      highlightOptions = highlightOptions(
        weight = 5,
        color = "#FF0080",
        bringToFront = TRUE,
        fillOpacity = 0.7
      ),
      label = labels) %>%
        leaflet::addLegend(pal = pal, 
                           values = map_data()$extracted_pop,
                           title = "Population")

      
      # addLayersControl(overlayGroups = c("Survey points"),
      #                  options = layersControlOptions(collapsed = F))
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("extracted_population.csv")
    },
    content = function(file) {
      map_data_no_geom <- map_data()
      st_geometry(map_data_no_geom) <- NULL
      output_table <- as.data.frame(map_data_no_geom)
      write.csv(output_table, file, row.names = FALSE)
    }
  )
  
  output$downloadGeoData <- downloadHandler(
    filename = function() {
      paste("extracted_population.geojson")
    },
    content = function(file) {
      st_write(map_data(), file)
    }
  )

}) 
  

