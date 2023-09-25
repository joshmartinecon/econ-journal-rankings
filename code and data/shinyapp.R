library(shiny)
library(dplyr)
library(stringr)

setwd("G:/Other computers/My Laptop/Scraping/EconJournalRankings")

##### Load your data #####
df <- readRDS("Journal Rankings.RDS")

##### Define UI for application #####
ui <- fluidPage(
  # Application title
  titlePanel("Economics Journal Rankings"),
  
  # Author information
  tags$div("Created by ", 
           tags$a("Joshua C. Martin", href = "http://www.joshmartinecon.com")),
  
  # Updated
  tags$div(paste("Updated:"), Sys.Date()),
  
  # Sidebar layout with input and output definitions
  sidebarLayout(
    sidebarPanel(
      # Add an input: Text input for keyword in Journal
      textInput("keyword",
                "Include keywords (separate by comma for multiple):",
                value = ""),
      textInput("ex_keyword",
                "Exclude keywords (separate by comma for multiple):",
                value = ""),
      
      # Add an input: Numeric inputs for score range
      textInput("min_score",
                "Minimum score:",
                value = min(df$Overall)),
      textInput("max_score",
                "Maximum score:",
                value = max(df$Overall)),
      
      # Add inputs for sorting
      selectInput("sort_column",
                  "Column to sort by:",
                  choices = names(df),
                  selected = "Overall"), # make "Scores" the default
      checkboxInput("sort_descending",
                    "Sort in descending order",
                    value = TRUE) # make descending the default
    ),
    
    # Show a table of the filtered data
    mainPanel(
      tableOutput("filtered_data")
    )
  )
)

##### Define server logic #####
server <- function(input, output) {
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

##### Run the application #####
shinyApp(ui = ui, server = server)