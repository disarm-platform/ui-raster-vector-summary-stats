library(leaflet)
library(lubridate)
library(shinyBS)
library(shinydashboard)
# library(dashboardthemes)
library(shinyjs)

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(disable = T),
  dashboardBody(useShinyjs(),
                
                fluidRow(
                  includeCSS("styles.css"),
                  
                  box(p("This app allows you to extract raster values at/over points/polygons
                  using", a("this", href = "https://github.com/disarm-platform/fn-raster-vector-summary-stats/blob/master/SPECS.md"),
                      " algorithm. 
                      You can run with your own data using the input boxes below, 
                        or using the demo inputs:"),
                      
                      br(#tags$ol(
                         tags$li(strong("raster"), "- Worldpop 2020 population (Africa)"),
                         tags$li(strong("subject"), "- Admin 2 boundaries (Swaziland)")
                          ),
                      
                      actionButton("useDemo", "USE DEMO DATA"),
                    
                    width = 3,
                    height = 800,
                    
                    br(""),
                    # Conditional inputs for local file v GeoJSON/base64 string/URL
                    radioButtons(
                      "raster_type",
                      "Raster input type",
                      choices = c("Local .tif file", "Base 64 string or URL"),
                      selected = "Base 64 string or URL"
                    ),
                    conditionalPanel(condition = "input.raster_type == 'Local .tif file'",
                                     fileInput("raster_file_input", "")),
                    conditionalPanel(
                      condition = "input.raster_type == 'Base 64 string or URL' &
                      input.useDemo == 0",
                      textInput(
                        "raster_text_input",
                        label = NULL,
                        placeholder = "Base 64 string or URL"
                      )
                    ),
                    
                    conditionalPanel(
                      condition = "input.useDemo > 0",
                      textInput(
                        "raster_demo_input",
                        label = NULL,
                        value = "https://ds-faas.storage.googleapis.com/algo_test_data/general/worldpop/AFR_PPP_2020_adj_v2.tif"
                      )
                    ),
                    
                    #h4("Subject input type"),
                    radioButtons(
                      "GeoJSON_type",
                      "Subject input type",
                      choices = c("Local file", "GeoJSON string or URL"),
                      selected = "GeoJSON string or URL"
                    ),
                    conditionalPanel(condition = "input.GeoJSON_type == 'Local file'",
                                     fileInput("geo_file_input", "")),
                    
                    conditionalPanel(
                      condition = "input.GeoJSON_type == 'GeoJSON string or URL' &
                      input.useDemo == 0",
                      textInput("geo_text_input", label = NULL, 
                                placeholder = "GeoJSON string or URL"
                    )),
                    
                    conditionalPanel(
                      condition = "input.useDemo > 0",
                      textInput("geo_demo_input", label = NULL, 
                                value = "https://ds-faas.storage.googleapis.com/algo_test_data/general/adm2_swz.geojson")
                    ),
                    
                    selectInput(
                      "stat",
                      "Statistic",
                      c(
                        "Sum" = "sum",
                        "Mean" = "mean",
                        "Max" = "max",
                        "Min" = "min"
                      ),
                      multiple = TRUE,
                      selected = "mean"
                    ),
                    # selectInput("geojson", "Return GeoJSON",
                    #             c("True" = "TRUE",
                    #               "False" = "FALSE")),
                    
                    br(actionButton("goExtract", "RUN QUERY")),
                    #br(actionButton("goExtract", "", icon = icon("play-circle", "fa-3x"))),

                    conditionalPanel(condition = "input.goExtract > 0",
                                     br(h4("Download results")),  
                                     downloadButton("downloadData", "Download table"),
                                     downloadButton("downloadGeoData", "Download geojson"))

                  ),
                  
                  box(leafletOutput(
                    "output_map", height = 750, width = "100%"
                  ), height = 800, width = 9),
                  box(DT::DTOutput('output_table'), width = 12)
                ))
)
