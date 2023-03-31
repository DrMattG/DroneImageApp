# DroneImageApp

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7788318.svg)](https://doi.org/10.5281/zenodo.7788318)

*WARNING - The App is in development and will change considerably*

Please clone the repository (see detailed instructions [here](https://happygitwithr.com/rstudio-git-github.html)). 

In RStudio go to:

 File > New Project > Version Control > Git.
 
In "Repository URL", paste this URL:  https://github.com/DrMattG/DroneImageApp.git

To launch the App locally please use:


```
library(DroneImageApp)

runShiny()
```

You can also run the Shiny App directly from GitHub using 


```
shiny::runGitHub("DrMattG", "DroneImageApp")

```