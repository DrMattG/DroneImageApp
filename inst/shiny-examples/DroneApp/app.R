options(shiny.maxRequestSize=50*1024^2) 


library(shiny)
library(exifr)
library(tidyverse)
library(leaflet)


speciesList=c("buffalo (Syncerus caffer)", 
              "elephant (Loxodonta africana)", 
              "giraffe (Giraffa camelopardalis ssp. rothschildi)", 
              "hartebeest (Alcelaphus buselaphus ssp. lelwel)", 
              "oribi (Ourebia ourebi ssp. cottoni)",
              "Uganda kob (Kobus kob ssp. thomasi)", 
              "warthog (Phacochoerus africanus ssp. massaicus)", 
              "waterbuck (Kobus ellipsiprymnus ssp. defassa)",
              "none")

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
    tabPanel(title="image",  
             #sidebarPanel(
               #selectInput("species", "Species Obs", choices = speciesList, multiple = TRUE)
             #),
             mainPanel(shiny::imageOutput("img")
                       #,
             #actionButton("next", "Next image")
             )
             ),
    tabPanel(title="data",
             mainPanel(DT::DTOutput("tab"))
             )
  )
)


server<-function(input, output) {
  
  imagedata<-reactive({
    req(input$folder)
    files <- input$folder$datapath
    exifr::read_exif(files)
    
  })
  
  output$directorypath <- renderText({
              paste0("You have uploaded ", dim(imagedata())[1], " images")
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
      path_to_image<-imagedata()$SourceFile[grep(paste0("\\/",event$id),imagedata()$SourceFile)]
     list(
        src =path_to_image,
        contentType = "image/jpeg",
        width = 1500,
        height = 1000
      )
    }, deleteFile = FALSE)
    
  })
  
  output$tab<-DT::renderDataTable({
   tab=imagedata() %>% 
      select(GPSLongitude,GPSLatitude,FileName) %>% 
     mutate("Species"=NA)
   
   DT::datatable(tab, editable = TRUE)
  })
  
  
}


shinyApp(ui, server)