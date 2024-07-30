# Load necessary libraries
library(plumber)
library(dplyr)
library(caret)

# Read in your data and fit your ‘best’ model (Logistic Regression)
data <- read.csv("diabetes_binary_health_indicators_BRFSS2015.csv")

# Data preparation
data <- data %>%
  mutate(
    Diabetes_binary = factor(Diabetes_binary, levels = c(0, 1), labels = c("No", "Yes")),
    HighBP = factor(HighBP, levels = c(0, 1), labels = c("No", "Yes")),
    PhysActivity = factor(PhysActivity, levels = c(0, 1), labels = c("No", "Yes")),
    GenHlth = factor(GenHlth, levels = 1:5, labels = c("Excellent", "Very Good", "Good", "Fair", "Poor"))
  )

# Select relevant columns
data <- data %>%
  select(Diabetes_binary, BMI, HighBP, PhysActivity, GenHlth)

# Fit the logistic regression model
set.seed(123)
trainIndex <- createDataPartition(data$Diabetes_binary, p = 0.7, list = FALSE, times = 1)
trainData <- data[trainIndex, ]
testData <- data[-trainIndex, ]

logit_model <- train(Diabetes_binary ~ BMI + HighBP + PhysActivity + GenHlth, 
                     data = trainData, 
                     method = "glm", 
                     family = "binomial", 
                     trControl = trainControl(method = "cv", number = 5, classProbs = TRUE, summaryFunction = mnLogLoss),
                     metric = "logLoss")

#* @apiTitle Diabetes Prediction API

#* @param BMI Numeric value for BMI (default: mean BMI)
#* @param HighBP Binary value for High Blood Pressure (default: most prevalent class)
#* @param PhysActivity Binary value for Physical Activity (default: most prevalent class)
#* @param GenHlth Categorical value for General Health (default: most prevalent class)
#* @post /pred
function(BMI = mean(trainData$BMI, na.rm = TRUE), 
         HighBP = levels(trainData$HighBP)[which.max(table(trainData$HighBP))],
         PhysActivity = levels(trainData$PhysActivity)[which.max(table(trainData$PhysActivity))],
         GenHlth = levels(trainData$GenHlth)[which.max(table(trainData$GenHlth))]) {
  new_data <- data.frame(BMI = as.numeric(BMI),
                         HighBP = factor(HighBP, levels = levels(trainData$HighBP)),
                         PhysActivity = factor(PhysActivity, levels = levels(trainData$PhysActivity)),
                         GenHlth = factor(GenHlth, levels = levels(trainData$GenHlth)))
  prediction <- predict(logit_model, new_data, type = "prob")[,2]
  list(prediction = prediction)
}

#* @get /info
function() {
  list(
    name = "Anna Giczewska",
    github_page = "https://github.com/whiterabbit077/project3"
  )
}

# Example function calls to check that it works:
# POST /pred with default values:
# curl -X POST "http://localhost:8000/pred"

# POST /pred with specified values:
# curl -X POST "http://localhost:8000/pred" -d "BMI=25&HighBP=Yes&PhysActivity=Yes&GenHlth=Good"
# curl -X POST "http://localhost:8000/pred" -d "BMI=30&HighBP=No&PhysActivity=No&GenHlth=Poor"
# curl -X POST "http://localhost:8000/pred" -d "BMI=22&HighBP=Yes&PhysActivity=No&GenHlth=Excellent"
