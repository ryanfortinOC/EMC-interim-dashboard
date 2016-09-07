library(shiny)
library(readxl)
library(dplyr)
library(stringr)
library(magrittr)
library(tidyr)
library(RCurl)
library(jsonlite)
library(scales)
#library(DT)
library(ggplot2)
library(lubridate)
source('global.R')

shinyServer(function(input, output, session) {

  appIDs = c('80716', '81361', '80701', '80681')
  questions = NULL
  for(i in 1:length(appIDs)) {
    temp = getURL(paste0("https://preview.oncorps.io/export/list?type=question&fmt=102",
                  "&parentId=", appIDs[i], "&parentType=app&showOptions=1",
                  "&token=C3VPi2wE7bZPByjovftQ",
                  "&requestTime=", URLencode(as.character(Sys.time())))) %>%
      fromJSON()
    questions %<>% bind_rows(temp)
  }
  
  scores = read_excel("winability_score_mapping_without_conditional_questions.xlsx") %>%
    select(question_key, question_text, option_title, option_key, category, 
           points, possible, notInPrequal)# %>%
    #mutate_each(funs(as.numeric), points, possible)
  possibleScores = read_excel("winability_score_mapping_without_conditional_questions.xlsx",
                              "total_possible")
  scoreTemplate = scores %>%
    group_by(question_key) %>%
    summarize(possible = max(possible))
    
  
  pursuits = reactive({
    getURL(paste0("https://", server, "/export/list?type=speed-diagnostic&parentId=48443&extendedInfo=1&fmt=102&token=C3VPi2wE7bZPByjovftQ",
           "&requestTime=", URLencode(as.character(Sys.time())))) %>%
      fromJSON() %>%
      mutate(pursuitOrStitch = ifelse(parentLabel == "Pursuits", "Pursuits",
                               ifelse(grepl("stitchIt", label, ignore.case=TRUE), 
                                      "stitchIt", ""))) %>%
      filter(pursuitOrStitch == input$pursuitsGroup) %>%
      mutate(id = as.character(id)) %>%
      mutate(`Pursuit details link` = createAppLink("80716", etid, inviteToken, cfgToken, label = "Pursuit details", state = input$appStage),
             `Stage activities link` = createAppLink("81361", etid, inviteToken, cfgToken, label = "Stage activities", state = input$appStage),
             `Betting link` = createAppLink("80701", etid, inviteToken, cfgToken, label = "Betting", state = input$appStage),
             `Win factors link` = createAppLink("80681", etid, inviteToken, cfgToken, label = "Win factors", state = input$appStage))
    
  })
  
  responses = reactive({
    gsub("span.*script","", getURL(paste0("https://", server, "/export?type=usecase&id=77466&f[0][type]=group&f[0][value]=",
                                          paste(pursuits()$id, collapse = ","), "&f[1][type]=classic-list&f[1][value]=1&f[2][type]=select-data-context&f[2][value]=1&f[3][type]=add-date&f[3][value]=1&fmt=102&token=C3VPi2wE7bZPByjovftQ",
                                          "&requestTime=", URLencode(as.character(Sys.time()))))) %>%
      fromJSON() %>% 
      full_join(pursuits(), by = c("groupID" = "id")) %>%
      mutate(appStage = ifelse(grepl("design", qdef_key), "Design", 
                               ifelse(grepl("test", qdef_key), "Test", "Released"))) %>%
      filter(appStage == input$appStage) %>%
      mutate(qdef_key = sub("-test", "", qdef_key),
             qdef_key = sub("-design", "", qdef_key))
  })  
  
  data = reactive({
    responses() %>%
      arrange(desc(datetime)) %>%
      distinct(qdef_key, label, participant, title, .keep_all = TRUE) %>%
      left_join(qdefMapToNames) %>%
      left_join(questions, by = c("qdef_key" = "question_key", "option_key" = "option_key")) %>%
      left_join(scores, by = c("qdef_key" = "question_key", "option_key" = "option_key")) %>%
      rename(option_title = option_title.x) %>%
      mutate(option_value = ifelse(option_key != "value", option_title, option_value)) %>%
      mutate(points = ifelse(points == "value", option_value,
                             ifelse(points == "inverse", 5 - as.numeric(option_value),
                                    points)),
             points = as.numeric(points))
  })
  
  pursuitDetails = reactive({
    data() %>% 
      filter(chartName == "Account" | chartName == "Value ($ mil)" |
             chartName == "Stage" | chartName == "Potential value ($ mil)") %>% 
      select(chartName, option_value, label) %>%
      distinct(chartName, label, .keep_all = TRUE) %>%
      spread(chartName, option_value) %>%
      select(Pursuit = label, Account, `Value ($ mil)`, `Potential value ($ mil)`, Stage) %>%
      mutate(`Value ($ mil)` = round(as.numeric(`Value ($ mil)`), digits = 20),
             `Potential value ($ mil)` = round(as.numeric(`Potential value ($ mil)`), digits = 20),
             Stage = gsub("amp;", "", Stage))
  })
  
  betSummary = reactive({
    data() %>%
      filter(chartName == "Probability of win" |
             chartName == "Probability of advance by end of next month") %>%
      group_by(label, chartName) %>%
      summarize(bet = percent(mean(as.numeric(option_value))/100)) %>%
      spread(chartName, bet)
  })
  
  winabilityScores = reactive({
    calculateWinability(data(), pursuitDetails())
  })
  
  ##### Engagement #####
  
  userTotals = reactive({
    temp = responses() %>%
      mutate(datetime = as_date(datetime)) %>%
      arrange(datetime) %>%
      distinct(participant, .keep_all = TRUE) %>%
      group_by(datetime) %>%
      summarize(total = n())
    data.frame(datetime = seq(min(temp$datetime), max(temp$datetime), by='day')) %>%
      left_join(temp) %>%
      mutate(total = ifelse(is.na(total), 0, total))
  })
  
  output$cumulativeUsers = renderPlot({
    ggplot(mutate(userTotals(), total = cumsum(total)), aes(x = datetime, y = total)) +
      geom_line() +
      theme_bw()
  })
  
  output$newUsers = renderPlot({
    ggplot(userTotals(), aes(x = datetime, y = total)) +
      geom_bar(stat = "identity") +
      theme_bw()
  })
  
  output$pursuitsByStage = renderPlot({
    x = left_join(pursuitDetails(), stages, by = c("Stage" = "stage"))
    x$Stage = factor(x$Stage, levels = x$Stage[order(x$order)])
    ggplot(x, aes(x = Stage)) +
      geom_bar(stat = "count") +
      theme_bw() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$pursuits = renderDataTable({
    pursuitDetails() %>%
      left_join(betSummary(), by = c("Pursuit" = "label")) %>%
      left_join(winabilityScores(), by = c("Pursuit" = "label")) %>%
      right_join(select(pursuits(), contains("link"), label, parentLabel), by = c("Pursuit" = "label")) %>%
      arrange(Pursuit)
  }, escape = FALSE, options = list(pageLength = 100) #, 
  # rownames = FALSE,
  # options = list(
  #   rowCallback = JS(
  #     "function(row, data) {",
  #     "var num = '$' + data[2].toString().replace(/\\B(?=(\\d{3})+(?!\\d))/g, ',');",
  #     "$('td:eq(2)', row).html(num);",
  #     "}")
  #   )
  )
  
  observe({
    updateSelectInput(session, "pursuits", choices = pursuits() %>% 
                        select(label) %>% 
                        distinct() %>%
                        arrange(label))
  })
  
  output$responses = renderDataTable({
    data() %>%
      select(label, participant, title, datetime, option_value, category, points, possible) %>%
      filter(label %in% input$pursuits)
  }, options = list(pageLength = 50))
  
  # imageSelected <- reactive({
  #   if(input$whichTree == "1 to 2"){
  #     imageSelected <- '1to2.png'
  #   } else if (input$whichTree == "2 to 3"){
  #     imageSelected <- '2to3.png'
  #   } else if (input$whichTree == "3 to 4"){
  #     imageSelected <- '3to4.png'
  #   } else if (input$whichTree == "4 to 5"){
  #     imageSelected <- '4to5.png'
  #   } else{
  #     imageSelected <- '5to6.png'
  #   }
  # })
  # 
  # output$treeImage <- renderUI({
  #   tags$head(tags$link(rel = "stylesheet", type = "text/css",
  #                       href = "style.css")),
  #   # create a div to which the visualization will be anchored
  #   tags$div(id="div_tree"),
  #   # load d3
  #   tags$script(src="https://d3js.org/d3.v3.min.js"),
  #   # load our tree visualization
  #   tags$script(src="tree.js")
  # })

})
