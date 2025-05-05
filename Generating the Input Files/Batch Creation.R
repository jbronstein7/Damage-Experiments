######################################################
# Purpose: Generate and run the COBRA batch file to automate runs 
# Needs: File paths for batch input csv's
# Assumes: necessary input csv's are in the path's below, named accordingly, and COBRA is installed. csv generation file has been run
# Last Updated: 4/30/2025
# Author: Joe Bronstein
#####################################################

# Get the machine name
  machine_name <- Sys.info()["nodename"]

  # Set working directory to where you want the batch file to be stored (listed in Needs above)
  if (machine_name == "YOUR MACHINE NAME") { # Given by running line 10
    setwd("C:/PATH/TO/INPUT_FILES") # Path to folder with files referenced below 
  } else if (machine_name == "OTHER MACHINE NAME") {     #replace this info with your machine name(s) and path
    setwd("C:/PATH/TO/INPUT_FILES")
  } else {
    stop("Unknown machine name")
  }

###################################  COBRA Run #################################

# Create lists for pollutants and years
  # Identifying years
    years <- seq(2030, 2050, by = 5)
  # Identifying pollutants
    pollutants <- c("PM", "SO2", "NOx")
  # Identifying source types 
    types <- c("EGU Other", "EGU Coal", "Industry", "Fuels", "Building", "Highway", "Off-Highway",  "Other Area", "Other Point")
  # Identifying States 
    states <- c("Alabama", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia")

# Generate paths for base inputs for each year 
    # Open connections to a text file and batch file (the .txt will be editable)
      txt_file_conn <- file("cobra_commands.txt", open = "wt")
      bat_file_conn <- file("cobra_commands.bat", open = "wt")
    
    # Loop through each year and each pollutant
      for (year in years) {
        for (pollutant in pollutants) {
          for (type in types) {
            for (state in states) {
        # Construct the file paths, Fill in with your paths
          base_file <- paste0("C:\\path to base\\base-", year, ".csv")
          control_file <- paste0("C:\\path to control\\cntl_", pollutant, "_", year, "_", type, "_", state, ".csv")
          population_file <- paste0("C:\\path to population\\Population ", year, ".csv")
          incidence_file <- paste0("C:\\Users\\path to incidence\\Incidence ", year, ".csv")
          valuation_file <- paste0("C:\\path to valuation\\Valuation ", year, ".csv")
          output_file <- paste0("C:\\path to store output\\ref_", pollutant, "_", year, "_", type, "_", state, ".csv") # Wherever you'd like to store the output csv's
        
        # If output file already exists, move to the next one 
          if (file.exists(output_file)){ next }  # Comment out if you wish to overwrite existing output files from a previous run
          
        # Construct the COBRA command if control file exists 
          if (file.exists(control_file)){
          cobra_command <- paste(
            "\"C:\\Program Files\\COBRA\\cobra_console.exe\"", # Path to COBRA exe on your machine 
            "-d \"C:\\Program Files\\COBRA\\data\\cobra.db\"", # Path to COBRA db on your machine 
            "-b", shQuote(base_file),
            "-c", shQuote(control_file),
            "-p", shQuote(population_file),
            "-i", shQuote(incidence_file),
            "-v", shQuote(valuation_file),
            "-o", shQuote(output_file),
            "--discountrate 2"
          )
        
        # Write the command to both files
          writeLines(cobra_command, txt_file_conn)
          writeLines(cobra_command, bat_file_conn)
        }
      }
    }
  } 
}
    # Close the connections to the files
      close(txt_file_conn)
      close(bat_file_conn)
    
    # Run the batch file (Comment out to avoid running in R)
      system("cobra_commands.bat")
    
## This created a text and batch file with the commands to run cobra for each combination of pollutant, year, state, and source type (6,435 total runs) ##
## Took approx 322 hours, 13.5 days to run the batch file in COBRA (Roughly 3 minutes per run, 6,435 total runs) ##
    
  ## If the batch run does not work:
  ## compare the created .txt file to the cobra user guide on batch creation to ensure format is correct ##
  ## check file paths and file names to ensure they are referenced properly (i.e do the files you are referencing actually exist where you say?)##
