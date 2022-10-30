library(shiny)
library(MASS)
options(rgl.useNULL = TRUE)
library(rgl)

ui <- fluidPage(
  titlePanel("Correlated variables"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("n", "Sample size",
        min = 2, max = 10^3, value = 200
      ),
      sliderInput("r", "Correlation",
        min = -1, max = 1, value = 0, step = 0.05
      )
    ),
    mainPanel(
      rglwidgetOutput("plot",
        width = "500px", height = "500px")
    )
  )
)

server <- function(input, output) {
  Sigma <- reactive({
    matrix(c(1, input$r, input$r, 1), 2, 2)
  })
  m <- reactive({
    mvrnorm(input$n, c(0, 0), Sigma())
  })
  output$plot <- renderRglwidget({
    d <- m()
    k <- kde2d(d[,1], d[,2])
    try(close3d())
    persp3d(k$x, k$y, k$z,
      ann = FALSE, axes = FALSE,
      xlab = "", ylab = "", zlab = "",
      aspect = c(1, 1, 0.5), col = "lightblue")
    rglwidget()
  })
}

shinyApp(ui, server)
