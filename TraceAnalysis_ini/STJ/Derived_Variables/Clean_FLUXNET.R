# Clean FLUXNET data - St Jones Reserve
# Written by Sarah Russell
# April 19th, 2023

# For github, will have to change:
#     - path to read file
#     - setwd()/getwd()

# --------------------------------------------- 
# Need directory: Database_FLUXNET > Calculation_Procedures > TraceAnalysis_ini > STJ > StJ_FULL_DATABASE_2015_2021.csv
# setwd() to folder with Database_FLUXNET
yrs <- 2015:2021
country <- "US"
site <- "STJ"
filename <- "StJ_FULL_DATABASE_2015_2021.csv"
vars_orig <- c("co2_flux","LE","H_scf","CH4_orig","SWin_B2","Tair_MET","RH_MET","VPD","Ustar", "Tsoil", "BP_MET") 
vars <- c("FC","LE","H","FCH4","SW_IN_1_1_1","TA_1_1_1","RH_1_1_1","VPD_1_1_1","USTAR", "TS_1", "PA_1_1_1") 
# ---------------------------------------------
require("lubridate")
library(dplyr)

# Read Ameriflux csv file
data <- read.csv(paste0(base_path,"/Calculation_Procedures/TraceAnalysis_ini_FLUXNET/",site, "/Derived_Variables/",filename))
# Fix TIMESTAMP_START 
data <- data %>%
  mutate(datetime = as.POSIXct(DATE_TIME, format = "%m/%d/%Y %H:%M", tz = "EST"))

datetime <- as.data.frame(seq.POSIXt(from =as.POSIXct("2015-01-01 00:00:00", tz = "EST"), 
                                     to = as.POSIXct("2021-12-31 23:30:00", tz = "EST"), 
                                     by="30 min"))
names(datetime) <- "datetime"
data <- left_join(datetime, data, by="datetime")

data <- data %>%
  mutate(Year = year(datetime),
         Month = substr(as.character(datetime),6,7),
         Day = substr(as.character(datetime),9,10),
         Hour = substr(as.character(datetime),12,13),
         Minute = substr(as.character(datetime),15,16),
         TIMESTAMP_START = paste0(Year, Month, Day, Hour, Minute)) %>%
  select(TIMESTAMP_START, all_of(vars_orig)) %>%
  #Rename vars to standard Ameriflux names
  rename_at(vars(vars_orig), ~ vars)

# Save files by year in Database_FLUXNET
for (i in 1:length(yrs)) {
  # Create folder for csv file if it doesn't exist
  out_path <- paste0(base_path, "/", yrs[i], "/", site, "/Clean/SecondStage")
  if (!file.exists(out_path)){
    dir.create(out_path, recursive = TRUE)
  }
  write.csv(data[grep(yrs[i], substr(data$TIMESTAMP_START,1,4)),],
            paste0(out_path, "/", country, "-", site, "_HH_",
                   first(data[grep(yrs[i], substr(data$TIMESTAMP_START,1,4)),]$TIMESTAMP_START), "_",
                   last(data[grep(yrs[i], substr(data$TIMESTAMP_START,1,4)),]$TIMESTAMP_START), ".csv"), 
            row.names=FALSE
            )
}
