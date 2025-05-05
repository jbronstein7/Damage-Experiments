######################################################
# Purpose: To generate csv's for COBRA input from base csv's
# Needs: base-year csv's, states.xlsx, type.xslx (included in folder)
# Assumes: GLIMPSE ref scenario has been run, and COBRA base csv's were generated for 2030-2050
# Last Updated: 4/21/2024
# Author: Joe Bronstein
#####################################################

#Installing relevant packages 
  install.packages("readr")
  install.packages("dplyr")
  install.packages("readxl")

# Get the machine name
  machine_name <- Sys.info()["nodename"]

# Set working directory to where the input files are (listed in Needs above)
  if (machine_name == "YOUR MACHINE NAME") {
    setwd("C:/PATH/TO/INPUT_FILES")
  } else if (machine_name == "OTHER MACHINE NAME") {     #replace this info with your machine name(s) and path to inputs
    setwd("C:/PATH/TO/INPUT_FILES")
  } else {
    stop("Unknown machine name")
  }

  
################################################################################
## Generate csv's for 10% reductions in PM, NOx, and SO2
  # Load in the base csv's using a loop
    # Identifying years
      years <- seq(2030, 2050, by = 5)
    
    # Load in state and type labels
      library(readxl)
      states <- read_excel("states.xlsx") # Copied states labels from GLIMPSE to COBRA crosswalk 
      types <- read_excel("type.xlsx") # Copied type labels from GLIMPSE to COBRA crosswalk
  
    # Load in the csv for each year
      for (year in years){
        # read in the data
          data <- read.csv(paste0("base-", year, ".csv")) 
        # Add states 
          data$state <- states$STATE
        # Add pollutant type
          data$type <- types$TYPE
          data$TIER1NAME <- types$TIER1NAME
          data$TIER2NAME <- types$TIER2NAME
          # Change type to Area, Coal EGU, Other EGU, and Other
            data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Electric Utility", "EGU Other", data$type)
            data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Electric Utility" & data$TIER2NAME == "Coal", "EGU Coal", data$type)
            data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Industrial", "Industry", data$type)
            data$type <- ifelse(data$TIER1NAME == "Petroleum & Related Industries", "Fuels", data$type)
            data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Other", "Building", data$type)
            data$type <- ifelse(data$TIER1NAME == "Highway Vehicles", "Highway", data$type)
            data$type <- ifelse(data$TIER1NAME == "Off-Highway", "Off-Highway", data$type)
            data$type <- ifelse(data$TIER1NAME != "Miscellaneous" & data$type == "AREA", "Other Area", data$type)
            data$type <- ifelse(!data$type %in% c("EGU Other", "EGU Coal", "Industry", "Fuels", "Building", "Highway", "Off-Highway",  "Other Area") & data$type != "AREA" & data$TIER1NAME != "Miscellaneous", "Other Point", data$type)
          
        # Add census regions 
          # Create a lookup table for states and their respective census regions
          library(dplyr)
          region_lookup <- data.frame(
            state = c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia"),
            region = c("South", "West", "West", "South", "West", "West", "Northeast", "South", "South", "South", "West", "West", "Midwest", "Midwest", "Midwest", "Midwest", "South", "South", "Northeast", "South", "Northeast", "Midwest", "Midwest", "South", "Midwest", "West", "Midwest", "West", "Northeast", "Northeast", "West", "Northeast", "South", "Midwest", "Midwest", "South", "West", "Northeast", "Northeast", "South", "Midwest", "South", "South", "West", "Northeast", "South", "West", "South", "Midwest", "West", "Northeast")
          )
          
          # Join the data with the lookup table to add the region variable
          data <- data %>%
            left_join(region_lookup, by = "state")
        
          # Ensure 'type' and 'region' are characters
          data$type <- as.character(data$type)
          data$state <- as.character(data$state)
          data$region <- as.character(data$region)
          
          # State and Type vector
          state_list <- c("Alabama", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia")
          type_list <- c("EGU Other", "EGU Coal", "Industry", "Fuels", "Building", "Highway", "Off-Highway",  "Other Area", "Other Point")  
          
          # Complete the pollutant reductions
          # Loop over state/type combos for PM
          for (state in state_list) {
            for (type in type_list) {
              
              # Filter to see if any rows match this combination
              matching_rows <- data %>% filter(state == !!state, type == !!type)
              
              # Skip this loop iteration if there are no matches
              if (nrow(matching_rows) == 0) {
                next
              }
            # If there is a match, do a 10% reduction
              temp_data <- data
              
              temp_data$PM25 <- ifelse(
                temp_data$state == state & temp_data$type == type,
                temp_data$PM25 * 0.9, # 10 % reduction by state and type 
                temp_data$PM25
              )
              # Drop added variables
              temp_data <- temp_data %>% select(-state, -type, -region, -TIER1NAME, -TIER2NAME)
              
              # Save
              file_name <- paste0("cntl_PM_", year, "_", type, "_", state, ".csv")
              write.csv(temp_data, file_name, row.names = FALSE)
            }
          }
          
          # For NOx
          for (state in state_list) {
            for (type in type_list) {
              
              # Filter to see if any rows match this combination
              matching_rows <- data %>% filter(state == !!state, type == !!type)
              
              # Skip this loop iteration if there are no matches
              if (nrow(matching_rows) == 0) {
                next
              }
              # If there is a match, do a 10% reduction
              temp_data <- data
              
              temp_data$NOx <- ifelse(
                temp_data$state == state & temp_data$type == type,
                temp_data$NOx * 0.9, # 10 % reduction by state and type 
                temp_data$NOx
              )
              # Drop added variables
              temp_data <- temp_data %>% select(-state, -type, -region, -TIER1NAME, -TIER2NAME)
              
              # Save
              file_name <- paste0("cntl_NOx_", year, "_", type, "_", state, ".csv")
              write.csv(temp_data, file_name, row.names = FALSE)
            }
          }
          
          # For SO2
          for (state in state_list) {
            for (type in type_list) {
              
              # Filter to see if any rows match this combination
              matching_rows <- data %>% filter(state == !!state, type == !!type)
              
              # Skip this loop iteration if there are no matches
              if (nrow(matching_rows) == 0) {
                next
              }
              # If there is a match, do a 10% reduction
              temp_data <- data
              
              temp_data$SO2 <- ifelse(
                temp_data$state == state & temp_data$type == type,
                temp_data$SO2 * 0.9, # 10 % reduction by state and type 
                temp_data$SO2
              )
              # Drop added variables
              temp_data <- temp_data %>% select(-state, -type, -region, -TIER1NAME, -TIER2NAME)
              
              # Save
              file_name <- paste0("cntl_SO2_", year, "_", type, "_", state, ".csv")
              write.csv(temp_data, file_name, row.names = FALSE)
            }
          }
      }
      
       
  ### Check to make sure ^^^ these 3 loops ^^^  did what they were supposed to (should have 6,435 new files) takes approx 9 hours to run everything
