library(shiny)
library(shinydashboard)

header = dashboardHeader(title = "EMC Engagement Dashboard")

sidebar = dashboardSidebar(
  sidebarMenu(
    menuItem("Engagement", tabName = "engagement"),
    menuItem("Pursuit list", tabName = "pursuitList"),
    menuItem("Response list", tabName = "responseList"),
    menuItem("Decision Trees", tabName = "trees"),
    menuSubItem("1 to 2", tabName="1to2"),
    menuSubItem("2 to 3", tabName = "2to3"),
    menuSubItem("3 to 4", tabName = "3to4"),
    menuSubItem("4 to 5", tabName = "4to5"),
    menuSubItem("5 to 6", tabName = "5to6"),
    selectInput("pursuitsGroup", "Select pursuits", c("Pursuits", "stitchIt")),
    selectInput("appStage", "Select app stage", c("Released", "Test", "Design"))
  )
)

body = dashboardBody(

  tabItems(
    tabItem(tabName = "engagement",
      fluidPage(
        box(title = "Cumulative users over time",
            plotOutput("cumulativeUsers")
        ),
        box(title = "New users over time",
            plotOutput("newUsers")
        ),
        box(title = "Pursuits by stage",
            plotOutput("pursuitsByStage")
        )
        
      )
    ),
    
    tabItem(tabName = "pursuitList",
      h1("Pursuit list"),
      dataTableOutput("pursuits")
    ),
    
    tabItem(tabName = "responseList",
      h1("Response list"),
      selectInput("pursuits", "Select pursuit", ""),
      # selectInput("participants", "Select participant", "", multiple = TRUE),
      dataTableOutput("responses")
    ),
    # tabItem(tabName = "trees",
    #         h1("Decision Trees"),
    #         selectInput("whichTree", "Select Stage Advancement", c("1 to 2", "2 to 3", "3 to 4", "4 to 5", "5 to 6"), selected = "1 to 2"),
    #         # uiOutput("treeImage"),
    #         
    # ),
    tabItem(tabName = "4to5",
            h1("Stage 4 to Stage 5"),
            fluidRow(
              box(
                # within an R Shiny code block such as mainPanel()
                # reference the style sheet, which can be used to globally modify appearance
                tags$head(tags$link(rel = "stylesheet", type = "text/css",
                                    href = "style.css")),
                # create a div to which the visualization will be anchored
                tags$div(id="div_tree2"),
                # load d3
                tags$script(src="https://d3js.org/d3.v3.min.js"),
                # load our tree visualization
                tags$script(src="CopyOftree.js") ,
                width = 12)
            )
            ),
    tabItem(tabName="2to3",
            h1("Stage 2 to Stage 3"),
            fluidRow(
              box(
                # within an R Shiny code block such as mainPanel()
                # reference the style sheet, which can be used to globally modify appearance
                tags$head(tags$link(rel = "stylesheet", type = "text/css",
                                    href = "style.css")),
                # create a div to which the visualization will be anchored
                tags$div(id="div_tree4"),
                # load d3
                tags$script(src="https://d3js.org/d3.v3.min.js"),
                # load our tree visualization
                tags$script(src="CopyOftree3.js") ,
                width = 12)
            )
            ),
    tabItem(tabName="3to4",
            h1("Stage 3 to Stage 4"),
            fluidRow(
              box(
                # within an R Shiny code block such as mainPanel()
                # reference the style sheet, which can be used to globally modify appearance
                tags$head(tags$link(rel = "stylesheet", type = "text/css",
                                    href = "style.css")),
                # create a div to which the visualization will be anchored
                tags$div(id="div_tree3"),
                # load d3
                tags$script(src="https://d3js.org/d3.v3.min.js"),
                # load our tree visualization
                tags$script(src="CopyOftree2.js") ,
                width = 12)
            )
            ),
    tabItem(tabName="1to2",
            h1("Stage 1 to Stage 2"),
            fluidRow(
              box(
                # within an R Shiny code block such as mainPanel()
                # reference the style sheet, which can be used to globally modify appearance
                tags$head(tags$link(rel = "stylesheet", type = "text/css",
                                    href = "style.css")),
                # create a div to which the visualization will be anchored
                tags$div(id="div_tree5"),
                # load d3
                tags$script(src="https://d3js.org/d3.v3.min.js"),
                # load our tree visualization
                tags$script(src="CopyOftree4.js") ,
                width = 12)
            )
            ),
    tabItem(tabName="5to6",
            h1("Stage 5 to Stage 6"),
            fluidRow(
              box(
                # within an R Shiny code block such as mainPanel()
                # reference the style sheet, which can be used to globally modify appearance
                tags$head(tags$link(rel = "stylesheet", type = "text/css",
                                    href = "style.css")),
                # create a div to which the visualization will be anchored
                tags$div(id="div_tree"),
                # load d3
                tags$script(src="https://d3js.org/d3.v3.min.js"),
                # load our tree visualization
                tags$script(src="tree.js") ,
                width = 12)
            )
            )
  )
  
  
  
)


dashboardPage(header, sidebar, body, skin = "blue")