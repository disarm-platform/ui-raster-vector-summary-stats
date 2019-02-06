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
library(velox)
library(sf)
library(RColorBrewer)
library(geojsonio)
library(base64enc)


# Define map
map <- leaflet(max) %>%
  addTiles(
    "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png"
  )

# Get Worldpop data
#worldpop_africa <- velox("/Users/hughsturrock/Dropbox/Random/AFR_PPP_2015_adj_v2.tif")


shinyServer(function(input, output) {
  
  map_data <- eventReactive(input$goExtract, {

    # If no data yet for raster or subject
    # then return now
    raster_in <- input$raster_file_input
    geo_in <- input$geo_file_input
    
    # if (is.null(c(raster_in, input$raster_text_input)))
    #   return(NULL)
    # 
    # if (is.null(c(geo_in, input$geo_text_input)))
    #   return(NULL)
    # 
    # if (is.null(input$stat))
    #   return(NULL)


    # If input is local file, read in
    if(!is.null(raster_in)){
      input_raster <- base64encode(raster_in$datapath)
    }else{
      input_raster <- input$raster_text_input
    }
    
    if(!is.null(geo_in)){
      input_geo <- geojson_list(st_read(geo_in$datapath))
    }else{
      input_geo <- input$geo_text_input
    }
  

     # Check overall area of polygon
     #overall_area <- sum(st_area(input_poly)) / 1e+06
     
     # 
     # if(as.vector(overall_area)>20000){
     #   showNotification(paste("File too large. Max 20,000 km2 allowed"))
     # }
     
     # Make call to algorithm
    input_data_list <- list(
      raster = input_raster,
      subject = input_geo,
      stats = input$stat,
      geojson_out = "true"
    )


    response <-  httr::POST(url = "https://en44o61b64j8n.x.pipedream.net",
                            body = as.json(input_data_list),
                            content_type_json())
    return(response)
    #st_read(as.json(content(response)))

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
    
    extracted_stat = as.data.frame(map_data())[,input$stat]

    # Define color palette
    pal <-
      colorNumeric(brewer.pal(9, "Greens")[5:9],
                   extracted_stat)
    
    labels <- sprintf(
      paste("<strong>Population: </strong>",
            extracted_stat)
    ) %>% lapply(htmltools::HTML)
    
    # Map
    input_poly_sp <- as(map_data(), "Spatial")
    map %>% addPolygons(
      data = input_poly_sp,
      color = "#696969",
      fillColor = pal(extracted_stat),
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
                           values = extracted_stat,
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
  

