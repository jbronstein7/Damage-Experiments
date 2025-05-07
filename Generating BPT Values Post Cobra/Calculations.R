######################################################
# Purpose: Do relevant calculations 
# Needs: Initial cobra output 
# Assumes: CSV generation file run, initial COBRA run completed 
# Last Updated: 4/23/2024
# Author: Joe Bronstein
#####################################################

# Install packages 
  install.packages("ggplot2") # for graphing 
  install.packages("pracma") # for area under curve 
  install.packages("dplyr") 
  install.packages("tidyr")
# Get the machine name
  machine_name <- Sys.info()["nodename"]
  
################################################################################
# Calculate benefits per ton of each pollutant to get tax values (from first cobra run)
  # Calculate the total change in emissions between base and control by year (denominator)
    # 1. Load in data
    # Set working directory 
      if (machine_name == "YOUR MACHINE NAME") {
        setwd("PATH/TO/COBRA/INPUT/FILES") # (need base-year files)
      } else if (machine_name == "ALTERNATE MACHINE NAME") { 
        setwd("PATH/TO/COBRA/INPUT/FILES")
      } else {
        stop("Unknown machine name")
      }
    # Set years 
      years <- seq(2030, 2050, by = 5)
    # Identifying pollutants
      pollutants <- c("PM", "SO2", "NOx")
    # Identifying source types 
      type_list <- c("EGU Other", "EGU Coal", "Industry", "Fuels", "Building", "Highway", "Off-Highway",  "Other Area", "Other Point")
    # Identifying states
      state_list <- c("Alabama", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia")
    # Identifying years
      years <- seq(2030, 2050, by = 5)
    
     # creating a place to store sums 
      results <- data.frame(Year = integer(), State = character(), Type = character(), base_PM = numeric(), base_NOx = numeric(), base_SO2 = numeric(), 
                                cntl_PM = numeric(), cntl_NOx = numeric(), cntl_SO2 = numeric())
  
      
    # Load in state and type labels
      library(readxl)
      states <- read_excel("states.xlsx") # Copied states labels from GLIMPSE to COBRA crosswalk 
      types <- read_excel("type.xlsx") # Copied type labels from GLIMPSE to COBRA crosswalk

      library(dplyr)  
      
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
          # Identify necessary types
          data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Electric Utility", "EGU Other", data$type)
          data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Electric Utility" & data$TIER2NAME == "Coal", "EGU Coal", data$type)
          data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Industrial", "Industry", data$type)
          data$type <- ifelse(data$TIER1NAME == "Petroleum & Related Industries", "Fuels", data$type)
          data$type <- ifelse(data$TIER1NAME == "Fuel Combustion: Other", "Building", data$type)
          data$type <- ifelse(data$TIER1NAME == "Highway Vehicles", "Highway", data$type)
          data$type <- ifelse(data$TIER1NAME == "Off-Highway", "Off-Highway", data$type)
          data$type <- ifelse(data$TIER1NAME != "Miscellaneous" & data$type == "AREA", "Other Area", data$type)
          data$type <- ifelse(!data$type %in% c("EGU Other", "EGU Coal", "Industry", "Fuels", "Building", "Highway", "Off-Highway",  "Other Area") & data$type != "AREA" & data$TIER1NAME != "Miscellaneous", "Other Point", data$type)
        
          # Ensure 'type' and 'region' are characters
          data$type <- as.character(data$type)
          data$state <- as.character(data$state)
          
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
        # If there are matches, filter the data 
          dataset <- data %>% filter(state == !!state, type == !!type)
  
        # Sum the columns
          base_PM <- sum(dataset$PM25, na.rm = TRUE)
          base_NOx <- sum(dataset$NOx, na.rm = TRUE)
          base_SO2 <- sum(dataset$SO2, na.rm = TRUE)
          type_b <- paste0(type)
        # Store the results
          results <- rbind(results, data.frame(Year = year, State = state, Type = type_b, base_PM = base_PM, base_NOx = base_NOx, base_SO2 = base_SO2))
            }
          }
        }
        
    ## Now have sums of base pollutants for each year stored in results table ##        
    
    # To get total changes, can just multiply each base total by 0.1, because we did a 10% reduction
      
    # Calculate emissions changes for each pollutant 
        results$delta_PM <- results$base_PM * 0.1
        results$delta_NOx <- results$base_NOx * 0.1
        results$delta_SO2 <- results$base_SO2 * 0.1
        
    # re shape that table to get a panel
        # Load necessary library
        library(tidyr)
        
        # Reshape the data frame
        results <- results %>%
          pivot_longer(cols = starts_with("base_"), names_to = "Pollutant", values_to = "Base") %>%
          pivot_longer(cols = starts_with("delta_"), names_to = "Pollutant_delta", values_to = "Delta") %>%
          mutate(Pollutant = gsub("base_", "", Pollutant),
                 Pollutant_delta = gsub("delta_", "", Pollutant_delta)) %>%
          filter(Pollutant == Pollutant_delta) %>%
          select(Year, State, Pollutant, Type, Base, Delta)
        
        write.csv(results, "emissions_changes.csv") # file contains raw emissions changes for each scenario
        
  ## Now have pollutant differences  calculated as delta variables   

################################################################################
# Calculate total $ benefits of each pollutant in each year 
      library(dplyr)
      # Set working directory 
        if (machine_name == "YOUR MACHINE NAME") {
          setwd("PATH/TO/COBRA output files") # Whichever path you used in the batch file step to store results 
        } else if (machine_name == "ALTERNATE MACHINE NAME") { 
          setwd("PATH/TO/COBRA output files")
        } else {
          stop("Unknown machine name")
        }
      # Initialize an empty data frame to store the results
        results_health_benefits <- data.frame(
          Year = integer(),
          Pollutant = character(),
          Type = character(), 
          State = character(), 
          Total_Health_Benefits_low_estimate = numeric(),
          Total_Health_Benefits_high_estimate = numeric(),
          PM_Mortality_Low = numeric(), 
          PM_Mortality_High = numeric(), 
          O3_Mortality = numeric(),
          stringsAsFactors = FALSE
        )
        
        # Loop through the years and pollutants to extract the first observation
          for (year in years) {
            for (pollutant in pollutants) {
              for (type in type_list) {
                for (state in state_list) {
              # Construct the dataset name
                dataset_name <- paste0("ref_", pollutant, "_", year, "_", type, "_", state, ".csv")
                if (file.exists(dataset_name)){
              
              # Get the dataset from the environment
                dataset <- read.csv(dataset_name)
            
              # Extract the first observation of the required variables (total values)
                low_estimate <- dataset$X..Total.Health.Benefits.low.estimate.[1]
                high_estimate <- dataset$X..Total.Health.Benefits.high.estimate.[1]
                pm_high <- dataset$X..PM.Mortality..All.Cause..low.[1] # Low estimate and high estimate are labeled incorrectly in COBRA output
                pm_low <- dataset$X..PM.Mortality..All.Cause..high.[1] # Check prior to running to ensure this still holds
                O3_estimate <- dataset$X..Total.O3.Mortality[1]
                type_b <- paste0(type)
              # Store the results
                results_health_benefits <- rbind(results_health_benefits, data.frame(
                  Year = year,
                  Pollutant = pollutant,
                  Type = type_b, 
                  State = state,
                  Total_Health_Benefits_low_estimate = low_estimate,
                  Total_Health_Benefits_high_estimate = high_estimate,
                  PM_Mortality_Low = pm_low, 
                  PM_Mortality_High = pm_high, 
                  O3_Mortality = O3_estimate
                ))
            }
          }
        }
      }
    }
          
      # Remove the "Total:" prefix from the cells and convert to numeric values 
        results_health_benefits$Total_Health_Benefits_low_estimate <- as.numeric(gsub("Total: ", "", results_health_benefits$Total_Health_Benefits_low_estimate))
        results_health_benefits$Total_Health_Benefits_high_estimate <- as.numeric(gsub("Total: ", "", results_health_benefits$Total_Health_Benefits_high_estimate))
        results_health_benefits$PM_Mortality_Low <- as.numeric(gsub("Total: ", "", results_health_benefits$PM_Mortality_Low))
        results_health_benefits$PM_Mortality_High <- as.numeric(gsub("Total: ", "", results_health_benefits$PM_Mortality_High))
        results_health_benefits$O3_Mortality <- as.numeric(gsub("Total: ", "", results_health_benefits$O3_Mortality))
      # merge emissions changes and health cost datasets 
        merged_results <- merge(results, results_health_benefits, by = c("Year", "Pollutant", "Type", "State"))

                
################################################################################        
#### Calculate emissions per ton and convert to glimpse values to get taxes       
  # Calculate emissions per ton 
    # Emissions per ton = benefits estimate / change in emissions (delta)

  # Convert to GLIMPSE units (1990$ / metric ton)
    # Converting money to 1990$ - COBRA output is in 2023$
      dollars_2023_tot_low <- merged_results$Total_Health_Benefits_low_estimate
      dollars_2023_tot_high <- merged_results$Total_Health_Benefits_high_estimate 
      dollars_2023_pm_low <- merged_results$PM_Mortality_Low
      dollars_2023_pm_high <- merged_results$PM_Mortality_High
      dollars_2023_o3 <- merged_results$O3_Mortality
      cpi_1990 <- 130.7
      cpi_2023 <- 304.702
    
      merged_results$dollars_1990_low <- dollars_2023_tot_low * (cpi_1990 / cpi_2023)
      merged_results$dollars_1990_high <- dollars_2023_tot_high * (cpi_1990 / cpi_2023)
      merged_results$dollars_1990_pm_low <- dollars_2023_pm_low * (cpi_1990 / cpi_2023)
      merged_results$dollars_1990_pm_high <- dollars_2023_pm_high * (cpi_1990 / cpi_2023)
      merged_results$dollars_1990_o3 <- dollars_2023_o3 * (cpi_1990 / cpi_2023)

    # Converting emissions short tons to tons 
      delta_tons <- merged_results$Delta / 1.10231
      
    # Now getting 1990$ / ton values 
      merged_results$dpt_low_tot <- merged_results$dollars_1990_low / delta_tons
      merged_results$dpt_high_tot <- merged_results$dollars_1990_high / delta_tons
      merged_results$dpt_low_pm <- merged_results$dollars_1990_pm_low / delta_tons
      merged_results$dpt_high_pm <- merged_results$dollars_1990_pm_high / delta_tons
      merged_results$dpt_o3 <- merged_results$dollars_1990_o3 / delta_tons
    # filtering for variables of interest
      merged_results <- merged_results %>%
        select(Year, Pollutant, State, Type, dpt_low_tot, dpt_high_tot, dpt_low_pm, dpt_high_pm, dpt_o3)
    
    # Drop duplicates if there are any
      library(dplyr)
      merged_results <- merged_results %>% distinct()
      
    # Write csv
      write.csv(merged_results, paste0("BPT_Values.csv"))

### Now can use these new values as taxes for the health tax GLIMPSE scenario
      
      

        
