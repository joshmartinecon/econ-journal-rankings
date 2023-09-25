library(shiny)
library(dplyr)
library(stringr)
library(rsconnect)

##### Load your data #####
df <- readRDS("Journal Rankings.RDS")

##### Define server logic #####
function(input, output) {
  # Reactive expression to filter and sort data based on inputs
  filtered_data <- reactive({
    data_filtered <- df
    if (input$keyword != "") {
      keywords <- trimws(unlist(strsplit(input$keyword, ",")))
      data_filtered <- data_filtered %>%
        dplyr::filter(Reduce(`|`, lapply(keywords, function(k) str_detect(Journal, k))))
    }
    if (input$ex_keyword != "") {
      ex_keywords <- trimws(unlist(strsplit(input$ex_keyword, ",")))
      data_filtered <- data_filtered %>%
        dplyr::filter(!Reduce(`|`, lapply(ex_keywords, function(k) str_detect(Journal, k))))
    }
    # convert text inputs to numbers
    min_score <- as.numeric(input$min_score)
    max_score <- as.numeric(input$max_score)
    data_filtered <- data_filtered %>%
      dplyr::filter(Overall >= min_score & Overall <= max_score)
    
    # sort data
    if (input$sort_descending) {
      data_filtered <- data_filtered %>%
        arrange(desc(!!sym(input$sort_column)))
    } else {
      data_filtered <- data_filtered %>%
        arrange(!!sym(input$sort_column))
    }
    data_filtered
  })
  
  # Render the table output for filtered data
  output$filtered_data <- renderTable({
    filtered_data()
  })
}
