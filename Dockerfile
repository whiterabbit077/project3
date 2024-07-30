# Use the official R image as the base image
FROM rocker/r-ver:4.3.3

# Install system dependencies for the R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

# Install the necessary R packages
RUN R -e "install.packages(c('plumber', 'dplyr', 'caret'), repos='http://cran.rstudio.com/')"

# Create a directory for the app
WORKDIR /app

# Copy the dataset and API script into the Docker image
COPY diabetes_binary_health_indicators_BRFSS2015.csv /app/diabetes_binary_health_indicators_BRFSS2015.csv
COPY api.R /app/api.R

# Expose the port the API will run on
EXPOSE 8000

# Set the entry point to run the API
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('/app/api.R'); pr$run(host='0.0.0.0', port=8000)"]
