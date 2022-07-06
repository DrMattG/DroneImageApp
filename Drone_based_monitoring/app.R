options(shiny.maxRequestSize=50*1024^2) 


library(shiny)
library(exifr)
library(tidyverse)
library(leaflet)




# Define UI 
ui<-fluidPage(
  
  # Application title
  titlePanel("Method for drone-based monitoring of wildlife populations in Murchison Falls National Park"),
  
  # Show a plot of the generated distribution
  tabsetPanel(
    tabPanel(title="Introduction",
             sidebarPanel(
               fileInput("folder", label="Upload image files here",
                         accept = ".jpg",
                         multiple = TRUE)),
             mainPanel(textOutput(outputId = "directorypath"))),
    tabPanel(tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),
             title = "map", 
             leafletOutput("map")),
    tabPanel("image",  shiny::imageOutput("img"),
             actionButton("next", "Next image"))
  )
)


server<-function(input, output) {
  
  imagedata<-reactive({
    files <- input$folder$datapath
    exifr::read_exif(files)
    
  })
  
  output$directorypath <- renderPrint({
          paste0(imagedata()$SourceFile[1])
  })
  
  
 
  
  
  output$map<-renderLeaflet({
    leaflet(imagedata()) %>%
      addProviderTiles("Esri.WorldImagery") %>%
      addCircleMarkers(~ GPSLongitude, ~ GPSLatitude,  layerId = ~FileName, popup =  ~FileName,
                       fillColor = "red", 
                       color = NA,
                       radius = 10,
                       fillOpacity = .75
      ) %>% 
      setView(lng=31.6, lat=1.93, zoom=8)
  })
  
  # click on a marker
  observe({ 
    event <- input$map_marker_click
    output$img<-renderImage({
      print(event)
      
      path_to_image<-imagedata()$SourceFile[grep(event$id,imagedata()$SourceFile)]
      print(path_to_image)
  
      list(
        src =path_to_image,
        contentType = "image/jpeg",
        width = 1500,
        height = 1000
      )
    }, deleteFile = FALSE)
    
  }
  
  )
  
  
}


shinyApp(ui, server)