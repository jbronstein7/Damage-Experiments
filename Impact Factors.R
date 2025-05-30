######################################################
# Purpose: Normalize emissions with population
# Needs: COBRA Output Files, Population_all csv
# Assumes: COBRA was run successfully for all years
# Last Updated: 12/12/2024
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
    type_list <- c("EGU Other", "EGU Coal", "Industry", "Fuels", "Building", "Highway", "Off-Highway",  "Other Area", "Other Point")
  # Identifying states
    states <- c("Alabama", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia")
  # Load in population file
    population_all <- read.csv("population_all.csv")

# Initialize an empty dataframe to store results
results <- data.frame()

# Loop through each combination of year, state, and pollutant
for (year in years) {
  for (state in states) {
    for (pollutant in pollutants) {
      for (type in type_list){
      # Dynamically generate the dataset name
      dataset_name <- paste0("ref_", pollutant, "_", year, "_", type, "_", state, ".csv")
      
      if (file.exists(dataset_name)){
      # Load the dataset; if it does not exist in the directory, it will skip it
        dataset <- read.csv(dataset_name)
        
        dataset <- dataset %>%
          filter(State != "") # Drop observations where state is blank ("total:" rows)
        
      # Add variable for intervention state (indicator)
        dataset$int_state <- paste0(state)
        
      # Load in population file 
        population_year <- population_all %>% filter(Year == year)
        dataset <- merge(
          dataset, 
          population_year[, c("State", "County", "TOTAL")],
          by = c("State", "County"),
          all.x = TRUE
        )
        
      # Multiply deltas by population
        dataset$Delta.O3 <- as.numeric(dataset$Delta.O3) # NAs are ok, refer to the "Total:" columns
        dataset$Delta.PM.2.5 <- as.numeric(dataset$Delta.PM.2.5) # NAs are ok, refer to the "Total:" columns
        
        dataset$O3_Pop <- (dataset$Delta.O3 * dataset$TOTAL) # multiplying O3 delta by total population for each county
        dataset$PM_Pop <- (dataset$Delta.PM.2.5 * dataset$TOTAL) # multiplying PM delta by total population for each county
        
        # Summarize the data
        summarized <- dataset %>%
          group_by(int_state, State) %>%  # Separate intervention state and sub state
          summarise(
            O3_Pop_int_sum = sum(O3_Pop, na.rm = TRUE),  # Sum O3_Pop
            PM_Pop_int_sum = sum(PM_Pop, na.rm = TRUE),  # Sum PM_Pop
            TOTAL_pop_sum = sum(TOTAL, na.rm = TRUE),    # Sum TOTAL
            .groups = "drop"
          ) %>%
          mutate(
            year = year,
            source_type = type,
            pollutant = pollutant,
            O3_del_wt_avg = O3_Pop_int_sum / TOTAL_pop_sum,  # Calculate O3_Pop / TOTAL
            PM_del_wt_avg = PM_Pop_int_sum / TOTAL_pop_sum,  # Calculate PM_Pop / TOTAL
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
  dataset$PM_IF <- dataset$PM_del_wt_avg / dataset$Delta
  dataset$O3_IF <- dataset$O3_del_wt_avg / dataset$Delta

  write.csv(dataset, paste0("pm_o3_population_IF.csv"))
