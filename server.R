library(raster)
library(sp)
library(leaflet)
library(rjson)
library(httr)
library(readr)
library(DT)
library(sf)
library(RColorBrewer)
library(geojsonio)
library(base64enc)
library(MapPalettes)

source('utils.R')

# Define map
map <- leaflet() %>%
  addTiles(
    "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png"
  )

shinyServer(function(input, output) {
  
  map_data <- eventReactive(input$goExtract, {

    
  withProgress(message = 'Crunching data..',{
    
    raster_in <- input$raster_file_input
    geo_in <- input$geo_file_input
    
    # Run some checks - to be handled in function
    # if (is.null(c(raster_in, input$raster_text_input)))
    #   return(NULL)
    #
    # if (is.null(c(geo_in, input$geo_text_input)))
    #   return(NULL)
    #
    # if (is.null(input$stat))
    #   return(NULL)
    
    
    # If input is local file, read in
    if (!is.null(raster_in)) {
      input_raster <- base64encode(raster_in$datapath)
    } else{
      if(!(input$raster_text_input == "")){
        input_raster <- input$raster_text_input
      }else{
        input_raster <- input$raster_demo_input  
      }
    }
    
    if (!is.null(geo_in)) {
      input_geo <- geojson_list(st_read(geo_in$datapath))
    } else{
      if(!(input$geo_text_input == "")){
        input_geo <- geojson_list(st_read(input$geo_text_input))
      }else{
        input_geo <- geojson_list(st_read(input$geo_demo_input))
      }
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
      stats = paste(input$stat, collapse = ' ')
    )

    response <-
      httr::POST(
        url = "https://faas.srv.disarm.io/function/fn-raster-vector-summary-stats-enhanced",
        body = as.json(input_data_list),
        content_type_json(),
        timeout(90)
      )
    
    # Check status
    if (response$status_code != 200) {
      stop('Sorry, there was a problem with your request - check your inputs and try again')
    }

    # Return geojson as sf object
    response_content <- content(response)
    geo_result <- st_read(as.json(response_content$result), quiet = TRUE)
    
    # Deal with any missing values
    for(stat in input$stat){
    geo_result[[stat]] <- as.numeric(as.character(geo_result[[stat]]))
    }
    return(geo_result)
  })
})
  
  output$output_table <-
    
    DT::renderDT({
      
      output_table <- eventReactive(input$goExtract, {
        map_data_no_geom <- map_data()
        st_geometry(map_data_no_geom) <- NULL
        output_table <- as.data.frame(map_data_no_geom)
        DT::datatable(output_table,
                      options = list(pageLength = 15),
                      rownames = F)
      })
      
      return(output_table())
    })
  
  
  
  output$output_map <- renderLeaflet({
    
    if(input$goExtract[1]==0){
    return(map %>% setView(0,0,zoom=2))
    }
    
    output_map <- eventReactive(input$goExtract, {
      
      # If points
      if(st_geometry_type(map_data())[1] %in% c("POINT", "MULTIPOINT")){
        
        col_pal <- colorNumeric(map_palette("bruiser", 10),
                                 as.data.frame(as.data.frame(map_data())[, "value"]))

        point_map <- map %>% addCircleMarkers(data = map_data(),
                                 color = col_pal(unlist(as.data.frame(as.data.frame(map_data())[, "value"]))),
                                 fillOpacity = 0.6) %>%
          
          addLegend(pal = col_pal, values = unlist(as.data.frame(as.data.frame(map_data())[, "value"])))
       
         return(point_map)
      }

      extracted_stat = as.data.frame(as.data.frame(map_data())[, input$stat])
      names(extracted_stat) <- input$stat
      
      # Define color palettes
      col_pals_list <-
        define_color_palettes(extracted_stat)
      
      # Define layer to hide
      if (length(input$stat) == 1) {
        to_hide <- NULL
      } else{
        to_hide <- input$stat[-1]
      }
      
      # Map
      map %>%
        add_all_map_layers(map_data(), col_pals_list, input$stat) %>%
        addLayersControl(overlayGroups = input$stat,
                         options = layersControlOptions(collapsed = FALSE)) %>%
        hideGroup(to_hide)
    })
    return(output_map())
    
  })
  
  # Handle downloads
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
