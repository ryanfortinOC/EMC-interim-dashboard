##### Globals #####
server = "preview.oncorps.io"

stages = data.frame(stage = c("Pre-Qualification", "Opportunity Review & Qualification",
                              "Pursuit Strategy", "Solution Development",
                              "Client Evaluation", "Contract Negotiations / Incremental Development",
                              "MVP-1"),
                    order = c(1,2,3,4,5,6,7))

qdefMapToNames = data.frame(qdef_key = c("qf9c7e1c5_7244-ae8d-a494-54e93a74a61c",
                                         "q7a0bd429_696a-ca6b-fa25-4fbaf7582505",
                                         "qf75726ce_e4ef-97e4-e56f-905dd94b9b83",
                                         "q77854c0c_1b90-c78b-42da-4a2577d9e03b",
                                         "qcf768faa_3d58-a8f5-84e6-ad91560701c0",
                                         "q4031bbb2_2657-4472-3582-cf58be3249ec",
                                         "qe281f687_ee11-2c64-de3c-5fc222fd7f40"),
                            chartName = c("Stage",
                                     "Value ($ mil)",
                                     "Name",
                                     "Account",
                                     "Probability of win",
                                     "Probability of advance by end of next month",
                                     "Potential value ($ mil)"))


##### Functions #####

createAppLink = function(appID, etid, inviteToken, cfgToken, state = "released", label = "") {
  return(paste0("<a href = \"https://preview.oncorps.io/app/",appID,
                "?destination=invitation/",etid,
                "/accept/",inviteToken,"&cfg=",cfgToken,
                "&state=",tolower(state),
                "\" target=\"_blank\">",label,"</a>"))
}

createImportLink = function(appID, groupID, cfgToken, label, usecaseID = 77466) {
  return(paste0("<a href = https://preview.oncorps.io/import/app/baseline/",appID,
                "/", usecaseID, "/", groupID,
                "/false/false/false/undefined/",cfgToken,
                ">",label,"</a>"))
}

calculateWinability = function(data, pursuits) {
  
  avgResponses = data %>%
    filter(!is.na(points)) %>%
    group_by(qdef_key, title, label) %>%
    summarize(points = mean(points, na.rm = TRUE)) %>%
    ungroup()
  
  template = data %>%
    distinct(qdef_key, title, possible, category, notInPrequal) %>%
    filter(!is.na(possible))
  
  numPursuits = avgResponses %>% distinct(label) %>% nrow()
  numQuestions = template %>% nrow()
  template = template[rep(seq_len(nrow(template)), numPursuits), ]
  template$label = avgResponses$label %>% unique() %>% rep(each = numQuestions)
  
  result = full_join(avgResponses, template) %>%
    filter(!is.na(category)) %>%
    left_join(select(pursuits, Pursuit, Stage), by = c("label" = "Pursuit")) %>%
    filter(!(notInPrequal == 1 & Stage == "Pre-Qualification"))
  
  result %<>%
    group_by(label, category) %>%
    summarize(score = sum(points, na.rm = TRUE) / sum(possible, na.rm = TRUE),
              numAnswered = sum(!is.na(points)), numPossible = sum(!is.na(possible))) %>%
    ungroup() %>%
    group_by(label) %>%
    summarize(`Winability score` = mean(score, na.rm = TRUE),
              pctAnswered = sum(numAnswered) / sum(numPossible)) %>%
    #filter(pctAnswered >= .8) %>%
    arrange(desc(`Winability score`)) %>%
    mutate(`Winability score` = round(`Winability score` * 100)) #%>%
    #select(-pctAnswered)
}
