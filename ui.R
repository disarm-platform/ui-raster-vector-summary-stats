library(leaflet)
library(lubridate)
library(shinyBS)
library(shinydashboard)
# library(dashboardthemes)
library(shinyjs)

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(disable = T),
  dashboardBody(
    
    useShinyjs(),
    
    # shinyDashboardThemes(
    #   theme = "grey_dark"
    # ),
    
    fluidRow(
      
      includeCSS("styles.css"),

             box(width = 3, height = 800,
                 
                 # Conditional inputs for local file v GeoJSON/base64 string/URL
                 radioButtons("raster_type","Raster input type",
                              choices = c("Local .tif file", "Base 64 string or URL"),
                              selected = "Local .tif file"),
                 conditionalPanel(
                   condition = "input.raster_type == 'Local .tif file'",
                   fileInput("file_input", "")
                 ),
                 conditionalPanel(
                   condition = "input.raster_type == 'Base 64 string or URL'",
                   textInput("text_input", "", placeholder = "Base 64 string or URL")
                 ),
                 
                 #fileInput("File", "Query polygons", width = "100%"),
                 #shinyjs::disabled(textInput("textInput", "Query raster", 
                #                             value = "WorldPop2015.tif", width = "100%")),
                 selectInput("stat", "Statistic", 
                             c("Sum" = "sum",
                              "Mean" = "mean",
                              "Max" = "max",
                              "Min" = "min")),
                 # selectInput("geojson", "Return GeoJSON", 
                 #             c("True" = "TRUE",
                 #               "False" = "FALSE")),
                  downloadButton("downloadData", "Download table"),
                  downloadButton("downloadGeoData", "Download geojson")),
            
                             box(leafletOutput("pop_map", height = 800, width = "100%"), width = 9),
                             box(DT::DTOutput('pop_table'), width = 12))
             )
)


      

