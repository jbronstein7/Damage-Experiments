######################################################
# Purpose: Weighted emissions changes based on higher initial concentrations
# Needs: COBRA Output Files
# Assumes: COBRA was run successfully for all years
# Last Updated: 6/3/2025
# Author: Joe Bronstein
#####################################################
# Set working directory 
# Get the machine name
machine_name <- Sys.info()["nodename"]

if (machine_name == "LZ26JBRONSTE") {
  setwd("C:/Users/jbronste/Documents/local_folder/CMAS-2024/COBRA output files")
} else if (machine_name == "D26265VWJBRONST") { # replace info below with your machine name and path to cobra output 
  setwd("C:/Users/jbronste/Documents/local_folder/CMAS-2024/COBRA output files")
} else {
  stop("Unknown machine name")
}

library(dplyr)  

# Set years 
  years <- seq(2030, 2050, by = 5)
# Identifying pollutants
  pollutants <- c("PM", "SO2", "NOx")
# Identifying source types 
  types <- c("Area", "Other EGU", "Other", "Coal EGU")
# Identifying regions 
  regions <- c("South", "Midwest", "Northeast", "West")
# Identifying states
  states <- c("Alabama", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia")


# Initialize an empty dataframe to store results
  results <- data.frame()

# Loop through each combination of year, state, and pollutant
  for (year in years) {
    for (state in states) {
      for (pollutant in pollutants) {
        for (type in types){
          # Dynamically generate the dataset name
            dataset_name <- paste0("ref_", pollutant, "_", year, "_", type, "_", state, ".csv")
        
          if (file.exists(dataset_name)){
            # Load the dataset; if it does not exist in the directory, it will skip it
              dataset <- read.csv(dataset_name)
          
            dataset <- dataset %>%
              filter(State != "") # Drop observations where state is blank ("total:" rows)
          
            # Add variable for intervention state (indicator)
              dataset$int_state <- paste0(state)
          
          
            # Multiply deltas by population
              dataset$Delta.O3 <- as.numeric(dataset$Delta.O3) # NAs are ok, refer to the "Total:" columns
              dataset$Delta.PM.2.5 <- as.numeric(dataset$Delta.PM.2.5) # NAs are ok, refer to the "Total:" columns
              dataset$Base.O3 <- as.numeric(dataset$Delta.O3) # NAs are ok, refer to the "Total:" columns
              dataset$Base.PM.2.5 <- as.numeric(dataset$Delta.PM.2.5) # NAs are ok, refer to the "Total:" columns
          
              dataset$O3_delta_base <- (dataset$Delta.O3 * dataset$Base.O3) # multiplying O3 delta by the base concentration for each county
              dataset$PM_delta_base <- (dataset$Delta.PM.2.5 * dataset$Base.PM.2.5) # multiplying PM delta by the base concentration for each county
          
          # Summarize the data
            summarized <- dataset %>%
              group_by(int_state, State) %>%  # Separate intervention state and sub state
              summarise(
                O3_delta_base_sum = sum(O3_delta_base, na.rm = TRUE),  # Sum O3 interaction
                PM_delta_base_sum = sum(PM_delta_base, na.rm = TRUE),  # Sum PM interaction
                TOTAL_base_PM_sum = sum(Base.PM.2.5, na.rm = TRUE),    # Sum Base PM
                TOTAL_base_O3_sum = sum(Base.O3, na.rm = TRUE),        # Sum Base O3
                .groups = "drop"
              ) %>%
              mutate(
                year = year,
                source_type = type,
                pollutant = pollutant,
                base_wt_O3_delta = O3_delta_base_sum / TOTAL_base_O3_sum,  # Calculate sum(Base_O3 * delta_O3) / sum(Base_O3)
                base_wt_PM_delta = PM_delta_base_sum / TOTAL_base_PM_sum,  # Calculate sum(Base_PM * delta_PM) / sum(Base_PM)
              )
          
            # Add the summarized data to results
              results <- bind_rows(results, summarized)
          }
        }
      }
    }
  }

# Add in emissions changes file 
  if (machine_name == "LZ26JBRONSTE") {
    setwd("C:/Users/jbronste/Documents/local_folder/CMAS-2024/COBRA inputs for batch")
  } else if (machine_name == "D26265VWJBRONST") { # replace info below with your machine name and path to cobra output 
    setwd("C:/Users/jbronste/Documents/local_folder/CMAS-2024/COBRA inputs for batch")
  } else {
    stop("Unknown machine name")
  }

# Load in Emissions Changes 
  emissions_changes <- read.csv("emissions_changes.csv")
  
  # Add matching variables 
    emissions_changes$int_state <- emissions_changes$State
    emissions_changes$pollutant <- emissions_changes$Pollutant
    emissions_changes$source_type <- emissions_changes$Type
    emissions_changes$year <- emissions_changes$Year

    dataset <- merge(
      results, 
      emissions_changes[, c("year", "pollutant", "source_type", "Delta", "int_state")],
      by = c("year", "pollutant", "source_type", "int_state"),
      all.x = TRUE
    )

# Divide weighted averages by emissions changes 
  dataset$base_wt_PM_ratio <- dataset$base_wt_PM_delta / dataset$Delta
  dataset$base_wt_O3_ratio <- dataset$base_wt_O3_delta / dataset$Delta
  
  write.csv(dataset, paste0("base_weighted_pm_o3.csv"))
