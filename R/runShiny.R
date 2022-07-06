#' A wrapper function to run Shiny Apps from \code{DroneImageApp}.
#' 
#' Running this function will launch the DroneImgApp Shiny
#' @return eviatlas shiny app
#' @param app DroneImgApp 

#' @export

runShiny <- function(app="DroneApp"){
  
  # find and launch the app
  appDir <- system.file("shiny-examples",app,package = "DroneImageApp")
  
  shiny::runApp(appDir, display.mode = "normal")
}
