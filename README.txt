Project Authors: Joe Bronstein (ORISE), Dan Loughlin (EPA), Chris Nolte (EPA)

Code Author: Joe Bronstein

Description of folders:

Necessary input files: This folder contains all of the necessary input files that the provided code references.
Generating the Input Files: This folder has the code files that will generate the necessary input files for the COBRA runs and the code to create and run the COBRA batch file. 
Generating BPT Values Post Cobra: This folder contains the code to complete the BPT calculations after the COBRA runs have been completed. 


Steps: 

FOLDER: Generating the Input Files

1. Run CSV generation file
All you will need are the "base-year.csv" files and the state and type excel sheets provided. This R script will load in those files, create new files with 10% pollutant reductions for each scenario, and save them as separate control files. This entire process is automated, you only need to point to the directory where the files are located.  

2. Run Batch Creation file
Once you have those control files, you can run COBRA. You will need COBRA installed on your machine for this step. This R script will write a batch file which will automate the 6,435 necessary COBRA runs. I have provided all necessary input files except for the control files, these should have been generated in the previous step. For this step, all you need to do is fill in the necessary file paths for your machine, everything else is automated. Assuming you have pointed to the proper file directories, this script will write and run the batch file. 

NOTE: This takes approximately 3 minutes per run, roughly 13.5 days total. If you will need to use R in the meantime, it is recommended that you DO NOT run the batch file through R (comment out the final line) and double-click the batch file in your file explorer instead to run through a command window. If the run is interrupted, simply re-run the batch creation code, it should pick up where you left off without needing to repeat runs.

FOLDER: Generating BPT Values Post Cobra

3. Run calculations file
This file will calculate the benefit per ton values. The first half of the code will calculate the change in emissions from the base files for each scenario. For this step you only need the "base-year" files provided in the Necessary Input Files folder. The second half of this code will identify the total benefits from each scenario, merge the benefits and emissions changes into one data frame, calculate the benefits per ton of each scenario, and convert those values to GLIMPSE units (1990$/short ton). For the second portion of the code, you will need to point to the path where your COBRA output is stored. This should be the same path identified as the output file path in your batch creation file. 