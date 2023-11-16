library(shiny)
library(dplyr)
library(stringr)
library(rsconnect)

##### Load your data #####
df <- readRDS("Journal Rankings.RDS")

##### Define UI for application #####
fluidPage(
  # Application title
  titlePanel("Economics Journal Rankings"),
  
  # Author information
  tags$div("Created by ", 
           tags$a("Joshua C. Martin", href = "https://joshmartinecon.github.io/")),
  
  # Updated
  tags$div(paste("Updated: 2023-06-13")),
  
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
