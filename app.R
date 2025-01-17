# Author : Laura van Aalst

rm(list = ls())
# install.packages("shiny")
# install.packages("shinyjs")
library(shiny)

ui <- fluidPage(
  
  titlePanel("Randomly select students for lectures with limited seats"),
  
  sidebarPanel(
    shinyjs::useShinyjs(),
    textAreaInput(inputId = "student_data", "Paste studentnumbers below each other", height = "100px"),
    numericInput(inputId = 'N_lectures', 'Choose the number of lectures', 1, min = 1),
    numericInput(inputId = 'N_seats', 'Choose the number of available seats per lecture', 1, min = 1),
    actionButton(inputId = 'submit_button', 'GO')
    ),
  
  mainPanel(
    shinyjs::hidden(downloadButton('download_table', 'Download table')),
    tableOutput(outputId = 'result')
    )
  )

server <- function(input, output) {
  
  students <- eventReactive(input$submit_button, {(input$student_data)})
  
  results <- eventReactive(input$submit_button, {
    
    N_spots <- input$N_lectures*input$N_seats
    students_vector <- strsplit(students(), "\n")[[1]]
    N_students <- length(students_vector)
    
    if(N_students > N_spots) {
      
      sampled_students <- sample(students_vector, size = N_spots, replace = F)
      df_results <- as.data.frame(matrix(sampled_students, ncol = input$N_lectures, nrow = input$N_seats))
      
      } else if (N_students < input$N_seats) { 
        
        df_results <- as.data.frame(matrix(students_vector, ncol = input$N_lectures, nrow = N_students))
        
        } else {
          
          N_visits_every_stud <- N_spots %/% N_students # number of times every student may come
          remaining_spots <- N_spots %% N_students # remaining number of spots to sample for
        
          remaining_spots_sample <- sample(students_vector, size = remaining_spots, replace = F)
          sampled_students <- c(rep(students_vector, times= N_visits_every_stud), remaining_spots_sample)
          
          while(anyDuplicated(tail(sampled_students, input$N_seats)) != 0) {
            
            remaining_spots_sample <- sample(students_vector, size = remaining_spots, replace = F)
            sampled_students <- c(rep(students_vector, times= N_visits_every_stud), remaining_spots_sample)
            
          } # if last lecture contains duplicates, take a new sample
          
          df_results <- as.data.frame(matrix(sampled_students, ncol = input$N_lectures, nrow = input$N_seats))
          
          }
    
    colnames(df_results) <- paste0("Lecture ", 1:input$N_lectures)
    df_results

  })
  
  output$result <- renderTable({results()})
  
  output$download_table <- downloadHandler(
    filename = function(){paste("lecture-seats-sampler", Sys.Date(), ".xlsx", sep="")},
    content = function(file){writexl::write_xlsx(results(), file)},
    contentType = "text/csv")
  
  observeEvent(input$submit_button, {
    if (input$submit_button == FALSE)
      shinyjs::hide("download_table")
    else shinyjs::show("download_table")
  })
  
}

shinyApp(ui = ui, server = server)
