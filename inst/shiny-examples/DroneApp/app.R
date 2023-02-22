options(shiny.maxRequestSize=50*1024^2) 


library(shiny)
library(exifr)
library(tidyverse)
library(leaflet)
library(imager)
library(uasimg)
library(magick)


# Define UI 
ui<-fluidPage(
  
  # Application title
  titlePanel("Method for drone-based monitoring of wildlife populations in Murchison Falls National Park"),
  
  # Show a plot of the generated distribution
  
  tabsetPanel(
    tabPanel(title="Flight Information",
             sidebarPanel(
               fileInput("folder", label="Upload image files here",
                         accept = ".jpg",
                         multiple = TRUE),
               textOutput(outputId = "directorypath")),
             mainPanel(tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),
             leafletOutput("map"))),
   
    tabPanel(title="image",
             fluidRow(
               actionButton("nyttBilde", "Next picture"),
               actionButton("lastBilde", "Previous picture"),
               sliderInput('width2', label = "Zoom", min=200, max=4000, step=100,
                           value = 600, width = "100%"),
               column(width = 6,
                      # Add an image
                      imageOutput("img", height="600px", click="plotclick"),
                      textOutput("imgName")),
               column(width = 6,
                      # Add a table
                      DT::DTOutput("tab"),
                      textOutput("clickcoord")
               )
              )))
  )

server<-function(input, output, session) {
  
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
                       radius = 5,
                       fillOpacity = .75
      ) %>% 
      setView(lng=31.4, lat=2.27, zoom=12)
  })
    
    
    v <- reactiveValues(data = NULL, index=0)
    
    observeEvent(input$nyttBilde, {
      v$index=v$index+1
      
      print(v$index)
      })
    observeEvent(input$lastBilde, {
      v$index=v$index-1
      
      print(v$index)
    })
    
    
    output$img<-renderImage({
      image <- image_read(imagedata()$SourceFile[grep(paste0("\\/",v$index),imagedata()$SourceFile)])
      tmp <- image %>%
        image_border("grey", "20x10") %>%
        image_write(tempfile(fileext='jpg'), format = 'jpg')
      list(src = paste(tmp),
           contentType = 'image/jpeg',
           width = input$width2,
           height = 'auto')
    }, deleteFile = F)
    
  output$imgName<-renderPrint({
    imagedata()$SourceFile[grep(paste0("\\/",v$index),imagedata()$SourceFile)]
  })
  
  # click on a marker
  # observe({ 
  #   event <- input$map_marker_click
  #   output$img<-renderPlot({
  #     path_to_image<-imagedata()$SourceFile[grep(paste0("\\/",event$id),imagedata()$SourceFile)]
  #     bb<-raster::stack(path_to_image)
  #     plotit=  raster::plotRGB(bb)
  #     plotit
  #     })
  #   output$imgName<-renderPrint(event$id)
    output$clickcoord <- renderPrint({
      print(paste0(input$plotclick$x, " , ", input$plotclick$y))
    })
  #     })
  
  
  
  
  output$tab<-DT::renderDataTable({
    
   tab=imagedata() %>% 
      select(GPSLongitude,GPSLatitude,FileName) %>% 
     mutate("Species"=NA) %>% 
     mutate("Number"=as.numeric(NA)) |> 
     mutate("Location in image"= NA)
   
   DT::datatable(tab, editable = TRUE,
                 extensions='Buttons',
                 options=list(
                   paging = TRUE,
                   searching = TRUE,
                   fixedColumns = TRUE,
                   autoWidth = TRUE,
                   ordering = TRUE,
                   dom = 'tB',
                   buttons = c('copy', 'csv', 'excel')
                 ))
  })
  
  
}


shinyApp(ui, server)