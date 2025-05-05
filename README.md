# Damage-Experiments
Project Authors: Joe Bronstein, Dan Loughlin (EPA), Chris Nolte (EPA)

Code Author: Joe Bronstein

Needs:

COBRA software installed

GLIMPSE reference case, COBRA formatted CSV's (the ones I used are provided)

Formatted incidence, population, and valuation csv's for 2030-2050 in 5 year increments (the ones I used are provided)

Steps:

FOLDER: Generating the Input Files
1. CSV Generation.R

  This file will create the necessary CSV's to run the COBRA model. All necessary input files are included in that folder. 

2. Batch Creation

  This file will write and run the batch file for the COBRA runs. You will need COBRA installed on your machine for this step. This code will run COBRA through R and will take approximately 2 weeks to finish. If you will need to use R in the meantime, it is recommended that you do not run the final system("cobra_commands.bat") line and instead double click the batch file in your file explorer. 

FOLDER: Generating the BPT Values Post Cobra
1. Calculations

  This file will take the COBRA output and generate $ benefit-per-ton values for each experiment scenario. 
