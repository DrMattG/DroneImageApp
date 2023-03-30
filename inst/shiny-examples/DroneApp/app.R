options(shiny.maxRequestSize=50*1024^2) 


library(shiny)
library(shinyjs)
library(exifr)
library(tidyverse)
library(leaflet)
library(imager)
library(uasimg)
library(magick)
library(DT)


# Define UI 
ui<-fluidPage(
  useShinyjs(),
  # Application title
  titlePanel("Method for drone-based monitoring of wildlife populations in Murchison Falls National Park"),
  
  # Tabset panel
  tabsetPanel(
    # Tab panel to select images and show on a leaflet map
    
      tabPanel(title="Flight Information",
             sidebarPanel(
               fileInput("folder", label="Upload image files here",
                         accept = ".jpg",
                         multiple = TRUE),
               textOutput(outputId = "directorypath")),
             mainPanel(tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),
             leafletOutput("map"))),
   
    tabPanel(title="image",
    # Tab panel to select images - dropdown to select image
           fluidRow(
             uiOutput("image_selector"),
               column(width = 6,
                      # Add an image
                      imageOutput("img", click="plot_click"),
                      ),
               
              )),
    tabPanel(title="Table",
             fluidRow(
               column(width = 6,
                      uiOutput("species_input"),
                      # Add a table
                      DT::dataTableOutput("coord_table"),
                      actionButton("save", "Save Coordinates"),
               )
               
             )))
  )

server<-function(input, output, session) {
  
  imagedata<-reactive({
    req(input$folder)
    files <- input$folder$datapath
    exifr::read_exif(files)
    })
  
 output$image_selector <- renderUI({
    choices <- imagedata()$SourceFile
    selectInput("image", "Select an image", choices = choices)
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
    
  output$species_input <- renderUI({
      selectInput("species", "Species", c("Elephant","White Rhinoceros", "Hippopotamus", "Warthog","Kob", "Waterbuck", "Bohor Reedbuck", 
                                          "Duiker", "Hartebeest", "Oribi", "Buffalo" ,"Giraffe", "Other"), selected = "Hartebeest")
    })
    
    
    output$img<-renderImage({
      image <- image_read(input$image,imagedata()$SourceFile)
      tmp <- image %>%
        image_border("grey", "20x10") %>%
        image_write(tempfile(fileext='jpg'), format = 'jpg')
      list(src = paste(tmp),
           contentType = 'image/jpeg',
           height = 'auto')
    }, deleteFile = F)
    
  
# Record clicked coordinates
    coords <- reactiveValues()
    
    observeEvent(input$plot_click, {
      coords$click <- input$plot_click
      print(coords)
    })
    
    # Save data to table
    data <- reactiveValues(table = data.frame(file = character(),
                                              x = numeric(),
                                              y = numeric()))
    
    observeEvent(input$save, {
      if (!is.null(input$image) & !is.null(coords$click)) {
        data$table <- rbind(data$table, data.frame(file = input$image,
                                                   x = coords$click$x,
                                                   y = coords$click$y,
                                                   species=input$species))
      }
    })
    
    # Show table
    output$coord_table <- renderDataTable(
      datatable(data$table, extensions = 'Buttons',
                options=list(scrollX=TRUE, lengthMenu = c(5,10,15),
                             paging = TRUE, searching = TRUE,
                             fixedColumns = TRUE, autoWidth = TRUE,
                             ordering = TRUE, dom = 'tB',
                             buttons = c('copy', 'csv', 'excel','pdf'))))

  
}


shinyApp(ui, server)