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
library(geojsonio)


# Define map
map <- leaflet(max) %>%
  addTiles(
    "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png"
  )

# Get Worldpop data
#worldpop_africa <- velox("/Users/hughsturrock/Dropbox/Random/AFR_PPP_2015_adj_v2.tif")


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
                   #browser()
                   # Check overall area of polygon
                   overall_area <- sum(st_area(input_poly)) / 1e+06
                   
                   
                   if(as.vector(overall_area)>20000){
                     showNotification(paste("File too large. Max 20,000 km2 allowed"))
                   }
                   
                   # Make call to algorithm
                   
                   request_json <- geojson_list(input_poly)
                   input_data_list <- list(polys = request_json,
                                      stats = input$stat,
                                      geojson_out = "true")
                   response <-  httr::POST(#url = "http://srv.locational.io:8080/function/fn-worldpop-polygon-extractor",
                                           url = "http://10.0.0.110:8080",
                                          body = toJSON(input_data_list), 
                                           content_type_json())
                      browser()
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
  

