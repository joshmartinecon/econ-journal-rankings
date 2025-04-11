library(shiny)
library(dplyr)
library(stringr)
library(DT)
library(rsconnect)

##### Load data #####

# setwd("C:/Users/jmart/OneDrive/Desktop/GitHub/econ-journal-rankings")
df <- readRDS("Journal Rankings.RDS")

##### Define server logic #####

server <- function(input, output, session) {
  filtered_data <- reactive({
    data_filtered <- df %>%
      select(Journal, Rating, ABDC, Full_Journal_Title)
    
    # Include keywords (OR logic, case-insensitive)
    if (input$keyword != "") {
      keywords <- str_to_lower(trimws(unlist(strsplit(input$keyword, ","))))
      data_filtered <- data_filtered %>%
        filter(Reduce(`|`, lapply(keywords, function(k) str_detect(str_to_lower(Journal), fixed(k)))))
    }
    
    # Exclude keywords (OR logic, case-insensitive)
    if (input$ex_keyword != "") {
      ex_keywords <- str_to_lower(trimws(unlist(strsplit(input$ex_keyword, ","))))
      data_filtered <- data_filtered %>%
        filter(!Reduce(`|`, lapply(ex_keywords, function(k) str_detect(str_to_lower(Journal), fixed(k)))))
    }
    
    # Score filter
    data_filtered <- data_filtered %>%
      filter(Rating >= input$min_score & Rating <= input$max_score)
    
    # Show or hide missing ABDC
    if (!input$show_na) {
      data_filtered <- data_filtered %>%
        filter(!is.na(ABDC))
    }
    
    data_filtered
  })
  
  output$filtered_table <- renderDT({
    df_render <- filtered_data()
    
    # Tooltip on Journal title
    df_render$Journal <- mapply(
      function(j, full) {
        sprintf('<span title="%s">%s</span>', full, j)
      },
      j = df_render$Journal,
      full = df_render$Full_Journal_Title
    )
    
    df_render <- df_render %>% select(Journal, Rating, ABDC)
    
    datatable(df_render, escape = FALSE, rownames = FALSE,
              options = list(
                pageLength = 25,
                autoWidth = TRUE,
                searching = FALSE  # disable default search bar
              ))
  })
}
