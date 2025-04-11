library(shiny)
library(dplyr)
library(stringr)
library(rsconnect)

##### Load your data #####
df <- readRDS("Journal Rankings.RDS")

##### Define UI for application #####

ui <- fluidPage(
  titlePanel("Economics Journal Rankings"),
  
  tags$div("Created by ", 
           tags$a("Joshua C. Martin", href = "https://joshmartinecon.github.io/")),
  tags$div(paste("Updated:", Sys.Date())),
  
  # Custom layout with floating sidebar
  fluidRow(
    column(
      width = 3,
      div(
        style = "position: sticky; top: 10px;",
        textInput("keyword", "Include keywords (comma-separated):", value = ""),
        textInput("ex_keyword", "Exclude keywords (comma-separated):", value = ""),
        numericInput("min_score", "Minimum Score:", value = min(df$Rating, na.rm = TRUE), step = 0.01),
        numericInput("max_score", "Maximum Score:", value = max(df$Rating, na.rm = TRUE), step = 0.01),
        checkboxInput("show_na", "Show Non-Matched Journals (missing ABDC)", value = FALSE)
      )
    ),
    
    column(
      width = 9,
      DTOutput("filtered_table")
    )
  )
)