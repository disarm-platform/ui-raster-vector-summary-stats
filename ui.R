library(leaflet)
library(lubridate)
library(shinyBS)
library(shinydashboard)
library(dashboardthemes)

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(disable = T),
  dashboardBody(
    
    shinyDashboardThemes(
      theme = "grey_dark"
    ),
    
    fluidRow(
      
      includeCSS("styles.css"),

             box(width = 12, 
                  fileInput("File", "Query polygons", width = "20%"),
                  sliderInput("Buffer", "Buffer around points (km)", min = 0.001, max = 100, value = 25),
                  downloadButton("downloadData", "Download table"),
                  downloadButton("downloadGeoData", "Download geojson")),
            
                             box(leafletOutput("pop_map", height = 800), width = 12),
                             box(DT::DTOutput('pop_table'), width = 12))
             )
)


      

