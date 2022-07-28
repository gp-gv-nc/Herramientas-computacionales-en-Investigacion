# Source: https://github.com/Robinlovelace/Creating-maps-in-R

x <- c("ggmap", "rgdal", "rgeos", "maptools", "dplyr", "tidyr", "tmap")

# warning: uncommenting this may take a number of minutes
install.packages(x) 
lapply(x, library, character.only = TRUE) # load the required packages

setwd("~/Google Drive/videos 2 y 3/")

library(rgdal)
lnd <- readOGR(dsn = "data/london_sport.shp")
# lnd <- readOGR(dsn = "data", layer = "london_sport")

#lnd is now an object representing the population of London Boroughs in 2001 and the percentage of the population participating in sporting activities according to the Active People Survey. The boundary data is from the Ordnance Survey (http://www.ordnancesurvey.co.uk/oswebsite/opendata/)

## 
head(lnd@data, n = 10)
mean(lnd$Partic_Per) # short for mean(lnd@data$Partic_Per) 

## check the classes of all the variables in a spatial dataset
sapply(lnd@data, class)

## coerce the variable into the correct, numeric, format
lnd$Pop_2001 <- as.numeric(as.character(lnd$Pop_2001))
sapply(lnd@data, class)

## coordinate reference system (CRS) 
lnd@proj4string

# plots use the geometry data, contained primarily in the @polygons slot.
plot(lnd) 
plot(lnd@data)
plot(lnd$Partic_Per, lnd$Pop_2001)

## select rows of lnd@data where sports participation is less than 13
lnd@data[lnd$Partic_Per < 13, 1:3]

# Select zones where sports participation is between 20 and 25%
sel <- lnd$Partic_Per > 20 & lnd$Partic_Per < 25
plot(lnd[sel, ]) 

## Simple plot of London with areas of high sports participation highlighted in blue"
plot(lnd, col = "lightgrey") # plot the london_sport object
sel <- lnd$Partic_Per > 25
plot(lnd[ sel, ], col = "turquoise", add = TRUE) # add selected zones to map

## Zones in London whose centroid lie within 10 km of the geographic centroid of the City of London. Note the distinction between zones which only touch or 'intersect' with the buffer (light blue) and zones whose centroid is within the buffer (darker blue)."

library(rgeos)
plot(lnd, col = "grey")
# find London's geographic centroid (add ", byid = T" for all)
cent_lnd <- gCentroid(lnd[lnd$name == "City of London",]) 
points(cent_lnd, cex = 3)
# set 10 km buffer
lnd_buffer <- gBuffer(spgeom = cent_lnd, width = 10000) 

# method 1 of subsetting selects any intersecting zones
lnd_central <- lnd[lnd_buffer,] # the selection is too big!
# test the selection for the previous method - uncomment below
plot(lnd_central, col = "lightblue", add = T)
plot(lnd_buffer, add = T) # some areas just touch the buffer

# method2 of subsetting selects only points within the buffer
lnd_cents <- SpatialPoints(coordinates(lnd),
                           proj4string = CRS(proj4string(lnd))) # create spatialpoints
sel <- lnd_cents[lnd_buffer,] # select points inside buffer
points(sel) # show where the points are located
lnd_central <- lnd[sel,] # select zones intersecting w. sel
plot(lnd_central, add = T, col = "lightslateblue", 
     border = "grey")
plot(lnd_buffer, add = T, border = "red", lwd = 2)

# Add text to the plot!
text(coordinates(cent_lnd), "Central\nLondon")

## Attribute joins
# Attribute joins are used to link additional pieces of information to our polygons. In the lnd object, for example, we have 4 attribute variables --- that can be found by typing names(lnd). But what happens when we want to add more variables from an external source? We will use the example of recorded crimes by London boroughs to demonstrate this.
# To reaffirm our starting point, let's re-load the "london_sport" shapefile as a new object and plot it:

library(rgdal) # ensure rgdal is loaded
# Create new object called "lnd" from "london_sport" shapefile
lnd <- readOGR("data/london_sport.shp")
plot(lnd) # plot the lnd object
nrow(lnd) # return the number of rows

## Downloading additional data
# Because we are using borough-level data, and boroughs are official administrative zones, there is much data available at this level. We will use the example of crime data to illustrate this data availability, and join this with the current spatial dataset. As before, we can download and import the data from within R:

#download.file("http://data.london.gov.uk/datafiles/crime-community-safety/mps-recordedcrime-borough.csv", destfile = "mps-recordedcrime-borough.csv")
# UPDATE (but not the same...) https://data.london.gov.uk/dataset/recorded_crime_summary

crime_data <- read.csv("data/mps-recordedcrime-borough.csv",
                       stringsAsFactors = FALSE)

head(crime_data$CrimeType) # information about crime type

# Extract "Theft & Handling" crimes and save
crime_theft <- crime_data[crime_data$CrimeType == "Theft & Handling", ]

# Calculate the sum of the crime count for each district, save result
crime_ag <- aggregate(CrimeCount ~ Borough, FUN = sum, data = crime_theft)

# Compare the name column in lnd to Borough column in crime_ag to see which rows match.
lnd$name %in% crime_ag$Borough
# Return rows which do not match
lnd$name[!lnd$name %in% crime_ag$Borough]

# Load dplyr package
library(dplyr)

# We use left_join because we want the length of the data frame to remain unchanged, with variables from new data appended in new columns (see ?left_join). The *join commands (including inner_join and anti_join) assume, by default, that matching variables have the same name. Here we will specify the association between variables in the two data sets:

head(lnd$name,100) # dataset to add to 
head(crime_ag$Borough,100) # the variables to join

head(left_join(lnd@data, crime_ag)) # you will need "by"
lnd@data <- left_join(lnd@data, crime_ag, by = c('name' = 'Borough'))

# tmap was created to overcome some of the limitations of base graphics and ggmap.
library(tmap) # load tmap package 
qtm(lnd, "CrimeCount") # plot the basic map
qtm(shp = lnd, fill = "Partic_Per", fill.palette = "-Blues", fill.title = "Participation") 

## ggmap is based on the ggplot2 package, an implementation of the Grammar of Graphics (Wilkinson 2005). ggplot2 can replace the base graphics in R (the functions you have been plotting with so far). It contains default options that match good visualisation practice and is well-documented: http://docs.ggplot2.org/current/ .

#As a first attempt with ggplot2 we can create a scatter plot with the attribute data in the lnd object created previously:

library(ggplot2)
p <- ggplot(lnd@data, aes(Partic_Per, Pop_2001))

p + geom_point(aes(colour = Partic_Per, size = Pop_2001)) +
  geom_text(size = 2, aes(label = name))

install.packages("broom")
## ggmap requires spatial data to be supplied as data.frame, using tidy(). The generic plot() function can use Spatial objects directly; ggplot2 cannot. Therefore we need to extract them as a data frame. The tidy function was written specifically for this purpose. For this to work, broom package must be installed.
lnd_f <- broom::tidy(lnd)

# This step has lost the attribute information associated with the lnd object. We can add it back using the left_join function from the dplyr package (see ?left_join).
lnd$id <- row.names(lnd) # allocate an id variable to the sp data
head(lnd@data, n = 2) # final check before join (requires shared variable name)
lnd_f <- left_join(lnd_f, lnd@data) # join the data

# The new lnd_f object contains coordinates alongside the attribute information associated with each London Borough. It is now straightforward to produce a map with ggplot2. coord_equal() is the equivalent of asp = T in regular plots with R:

## ----"Map of Lond Sports Participation"-------------------------------
map <- ggplot(lnd_f, aes(long, lat, group = group, fill = Partic_Per)) +
  geom_polygon() + coord_equal() +
  labs(x = "Easting (m)", y = "Northing (m)",
       fill = "% Sports\nParticipation") +
  ggtitle("London Sports Participation")
map + scale_fill_gradient(low = "white", high = "black")
map

## Advanced Task: Faceting for Maps
## The below code demonstrates how to read in the necessary data for this task and 'tidy' it up. The data file contains historic population values between 1801 and 2001 for London, again from the London data store.

# We tidy the data so that the columns become rows. In other words, we convert the data from 'flat' to 'long' format, which is the form required by ggplot2 for faceting graphics: the date of the population survey becomes a variable in its own right, rather than being strung-out over many columns.

london_data <- read.csv("data/census-historic-population-borough.csv")
# install.packages("tidyr")
library(tidyr) # if not install it
ltidy <- gather(london_data, date, pop, -Area.Code, -Area.Name)
head(ltidy, 2) # check the output

#In the above code we take the london_data object and create the column names 'date' (the date of the record, previously spread over many columns) and 'pop' (the population which varies). The minus (-) symbol in this context tells gather not to include the Area.Name and Area.Code as columns to be removed. In other words, "leave these columns be". Data tidying is an important subject.

#Merge the population data with the London borough geometry contained within our lnd_f object, using the left_join function from the dplyr package:

head(lnd_f, 2) # identify shared variables with ltidy 
ltidy <- rename(ltidy, ons_label = Area.Code) # rename Area.code variable
lnd_f <- left_join(lnd_f, ltidy)
# old way of doing it
# lnd_f <- merge(lnd_f, ltidy, by.x = "id", by.y = "Area.Code")

# Rename the date variable
lnd_f$date <- gsub(pattern = "Pop_", replacement = "", lnd_f$date)

## ----"Faceted plot of the distribution of London's population over time", fig.height=6, fig.width=5----
p <- ggplot(data = lnd_f, # the input data
       aes(x = long, y = lat, fill = pop/1000, group = group)) + # define variables
  geom_polygon() + # plot the boroughs
  geom_path(colour="black", lwd=0.05) + # borough borders
  coord_equal() + # fixed x and y scales
  facet_wrap(~ date) + # one plot per time slice
  scale_fill_gradient2(low = "blue", mid = "grey", high = "red", # colors
                       midpoint = 150, name = "Population\n(thousands)") + # legend options
  theme(axis.text = element_blank(), # change the theme options
        axis.title = element_blank(), # remove axis titles
        axis.ticks = element_blank()) # remove axis ticks
p
# ggsave("figure/facet_london.png", width = 9, height = 9) # save figure

# **Creating an animation of population change over time**
# library(animation)

# Aim: create animated map
pkgs = c("ggmap", "sp", "tmap", "rgeos", "maptools", "dplyr")
lapply(pkgs, library, character.only = TRUE)

## check the classes of all the variables in a spatial dataset
sapply(lnd_f, class)

## coerce the variable into the correct, numeric, format
#lnd_f$date <- as.integer(lnd_f$date)

# needs gganimate package

#install.packages("devtools")
#devtools::install_github("thomasp85/transformr")
#devtools::install_github("thomasp85/gganimate",force=TRUE)

install.packages("gifski")
install.packages('transformr')
install.packages('gganimate')
install.packages("ndtv")

library(gifski)
library(gganimate)
library(transformr)
#library(ggplot2)

p <- ggplot(data = lnd_f, # the input data
            aes(x = long, y = lat, fill = pop/1000, group = group)) + # define variables
  geom_polygon() + # plot the boroughs
  geom_path(colour="black", lwd=0.05) + # borough borders
  coord_equal() + # fixed x and y scales
  scale_fill_gradient2(low = "blue", mid = "grey", high = "red", # colors
                       midpoint = 150, name = "Population\n(thousands)") + # legend options
  theme(axis.text = element_blank(), # change the theme options
        axis.title = element_blank(), # remove axis titles
        axis.ticks = element_blank()) + # remove axis ticks 
  labs(title = 'Year: {as.integer(frame_time)}') +
  transition_time(date)
  animate(p, duration = 5, fps = 20, width = 500, height = 500, renderer = gifski_renderer())
  #animate(p, renderer = ffmpeg_renderer())
  anim_save("output2.gif")