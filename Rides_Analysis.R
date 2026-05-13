# Cycling Capstone Project
# Ana Sierra
# 2023-04-16

# Analyzing the difference in bike usage patterns between casual riders and 
# annual members to identify behavioral trends that the marketing team can use 
# to design strategies that convert casual riders into members.

# Load Packages ----

if (!require(pacman)) install.packages("pacman")
pacman::p_load (
  tidyverse, # Meta-package
  janitor, # Cleaning 
  plotly, # Interactive Plots
  leaflet, # Mapping
  lubridate # Time Analysis
)

# Load  and Join Datasets ----
divvy_2019 <- read_csv("Divvy_Trips_2019_Q1 - Divvy_Trips_2019_Q1F.csv")
divvy_2020 <- read_csv("Divvy_Trips_2020_Q1 - Divvy_Trips_2020_Q1F.csv")

divvy_2019$ride_id <- as.character(divvy_2019$ride_id)
divvy_2019$start_lat <- NA
divvy_2019$start_lng <- NA
divvy_2019$end_lat <- NA
divvy_2019$end_lng <- NA

divvy_2019$start_time <- mdy_hms(divvy_2019$start_time)
divvy_2019$end_time   <- mdy_hms(divvy_2019$end_time)
divvy_2020$start_time <- mdy_hms(divvy_2020$start_time)
divvy_2020$end_time   <- mdy_hms(divvy_2020$end_time)

divvy_2019$ride_length <- as.numeric(difftime(divvy_2019$end_time, divvy_2019$start_time, units = "mins"))
divvy_2020$ride_length <- as.numeric(difftime(divvy_2020$end_time, divvy_2020$start_time, units = "mins"))

divvy_data <- bind_rows(divvy_2019, divvy_2020)
divvy_data <- divvy_data %>%
  mutate(ride_length = round(ride_length, 2))

# Explore Data ----

#glimpse(divvy_data)
#head(divvy_2019)
View(divvy_data)
library (tidyverse)
summary(divvy_data)

#Ride Length Analysis ----
summary_data <- divvy_data %>%
  group_by(usertype) %>%
  summarise(
    avg_ride = mean(ride_length),
    median_ride = median(ride_length),
    count = n()
  )
print (summary_data)

options(scipen = 999)

summary(divvy_data$ride_length)

quantile(divvy_data$ride_length, probs = c(.90,.95,.99,.999))

Q1 <- quantile(divvy_data$ride_length, 0.25)
Q3 <- quantile(divvy_data$ride_length, 0.75)
IQR_value <- IQR(divvy_data$ride_length)

lower_bound <- Q1 - 1.5 * IQR_value
upper_bound <- Q3 + 1.5 * IQR_value

lower_bound
upper_bound

divvy_data %>%
  group_by(usertype) %>%
  summarise(
    p95 = quantile(ride_length, .95),
    p99 = quantile(ride_length, .99),
    max = max(ride_length)
  )

divvy_clean <- divvy_data %>%
  filter(
    ride_length >= 1,
    ride_length <= 1440
  )
print (divvy_clean)

divvy_clean %>%
  group_by(usertype) %>%
  summarise(
    avg_ride = mean(ride_length),
    median_ride = median(ride_length),
    count = n()
  )
library(ggplot2)
library(plotly)
library(scales)
ride_length_summary_plot <- ggplot(divvy_clean,
       aes(x = usertype,
           y = ride_length,
           fill = usertype)) +
  geom_violin(alpha = .35, trim = TRUE) +
  geom_boxplot(
    width = .18,
    outlier.alpha = .08,
    alpha = .7
  ) +
  scale_y_log10(
    labels = label_number()
  ) +
  labs(
    title = "Casual Riders Take Significantly Longer Trips",
    subtitle = "Ride duration distribution is substantially longer and more variable among casual riders",
    x = NULL,
    y = "Ride Length (minutes, log scale)",
    fill = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(size = 12, color = "gray35")
  )

ride_length_summary_plot

# Day of the Week Analysis ----
divvy_clean <- divvy_clean %>%
  mutate(
    day_of_week = factor(
      day_of_week,
      levels = c(1,2,3,4,5,6,7),
      labels = c(
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
      )
    )
  )

rides_by_day <- divvy_clean %>%
  group_by(usertype, day_of_week) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  )

rides_by_day

rides_pct_day <- divvy_clean %>%
  group_by(usertype, day_of_week) %>%
  summarise(rides = n(), .groups = "drop") %>%
  group_by(usertype) %>%
  mutate(
    pct = rides / sum(rides) * 100
  )

rides_pct_day

ggplot(rides_pct_day,
       aes(day_of_week, pct, fill = usertype)) +
  geom_col(
    position = position_dodge(.8),
    width = .72
  ) +
  geom_text(
    aes(label = paste0(round(pct,1), "%")),
    position = position_dodge(.8),
    vjust = -.35,
    size = 3.5,
    fontface = "bold"
  ) +
  labs(
    title = "Weekend vs Weekday Usage Shows Clear Behavioral Segmentation",
    subtitle = "Casual riders cluster on weekends, while members ride primarily during the workweek",
    x = NULL,
    y = "% of rides",
    fill = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "gray35")
  )

# Hour of the Day Analysis ----

divvy_clean <- divvy_clean %>%
  mutate(hour = lubridate::hour(start_time))

rides_pct_hour <- divvy_clean %>%
  group_by(usertype, hour) %>%
  summarise(rides = n(), .groups = "drop") %>%
  group_by(usertype) %>%
  mutate(pct = rides / sum(rides) * 100)
print(rides_pct_hour)

ggplot(rides_pct_hour,
       aes(hour, pct, color = usertype)) +
  geom_line(linewidth = 1.6) +
  geom_point(size = 2.3) +
  annotate(
    "rect",
    xmin = 7, xmax = 9,
    ymin = -Inf, ymax = Inf,
    alpha = .06
  ) +
  annotate(
    "rect",
    xmin = 16, xmax = 18,
    ymin = -Inf, ymax = Inf,
    alpha = .06
  ) +
  scale_x_continuous(
    breaks = c(0,4,8,12,16,20,23),
    labels = c("12 AM","4 AM","8 AM","12 PM","4 PM","8 PM","11 PM")
  ) +
  labs(
    title = "Members Follow a Commuting Rhythm; Casual Riders Follow a Leisure Rhythm",
    subtitle = "Commute peaks appear in morning and evening for members, while casual ridership peaks mid-afternoon",
    x = NULL,
    y = "% of rides",
    color = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 18)
  )

# Station Analysis ----
top_start <- divvy_clean %>%
  group_by(usertype, start_station_name) %>%
  summarise(rides = n(), .groups = "drop") %>%
  group_by(usertype) %>%
  slice_max(rides, n = 10) %>%
  arrange(usertype, desc(rides))

print(top_start, n = 20)

top_end <- divvy_clean %>%
  group_by(usertype, end_station_name) %>%
  summarise(rides = n(), .groups = "drop") %>%
  group_by(usertype) %>%
  slice_max(rides, n = 10) %>%
  arrange(usertype, desc(rides))

print(top_end, n = 20)

divvy_clean %>%
  mutate(same_station = start_station_name == end_station_name) %>%
  group_by(usertype) %>%
  summarise(
    pct_same = mean(same_station) * 100
  )

weekend_casual_station <- divvy_clean %>%
  filter(
    usertype == "casual",
    day_of_week %in% c("Friday", "Saturday", "Sunday")
  ) %>%
  count(start_station_name, sort = TRUE) %>%
  mutate(
    pct = n / sum(n) * 100
  )

head(weekend_casual_station, 15)

top_station_by_user <- divvy_clean %>%
  count(usertype, start_station_name, sort = TRUE) %>%
  group_by(usertype) %>%
  slice_head(n = 15) %>%
  ungroup()

top_station_by_user

# Map Visualization
library(leaflet)
library(dplyr)

map_data <- divvy_clean %>%
  filter(
    !is.na(start_lat),
    !is.na(start_lng)
  ) %>%
  select(
    usertype,
    start_station_name,
    start_lat,
    start_lng,
    ride_length
  )


station_mix <- map_data %>%
  group_by(start_station_name, start_lat, start_lng, usertype) %>%
  summarise(rides = n(), .groups = "drop") %>%
  tidyr::pivot_wider(
    names_from = usertype,
    values_from = rides,
    values_fill = 0
  ) %>%
  mutate(
    total = casual + member,
    casual_share = casual / total
  )

glimpse(station_mix)
summary(station_mix$casual_share)

station_mix2 <- station_mix %>%
  mutate(
    segment = case_when(
      casual_share < .30 ~ "Mostly Member",
      casual_share <= .70 ~ "Mixed Use",
      TRUE ~ "Mostly Casual"
    )
  )

pal <- colorFactor(
  palette = c(
    "Mostly Member" = "#264653",
    "Mixed Use" = "#9E9E9E",
    "Mostly Casual" = "#E76F51"
  ),
  domain = station_mix2$segment
)

leaflet(station_mix2) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  
  # Mostly Member
  addCircleMarkers(
    data = filter(station_mix2, segment == "Mostly Member"),
    lng = ~start_lng,
    lat = ~start_lat,
    radius = ~pmax(5, sqrt(total) / 2),
    fillColor = "#264653",
    fillOpacity = 0.95,
    stroke = FALSE,
    group = "Mostly Member",
    popup = ~paste0(
      "<b>", start_station_name, "</b><br>",
      "Type: Mostly Member<br>",
      "Casual share: ", round(casual_share*100,1), "%<br>",
      "Total rides: ", total
    )
  ) %>%
  
  # Mixed
  addCircleMarkers(
    data = filter(station_mix2, segment == "Mixed Use"),
    lng = ~start_lng,
    lat = ~start_lat,
    radius = ~pmax(5, sqrt(total) / 2),
    fillColor = "#9E9E9E",
    fillOpacity = 0.95,
    stroke = FALSE,
    group = "Mixed Use",
    popup = ~paste0(
      "<b>", start_station_name, "</b><br>",
      "Type: Mixed Use<br>",
      "Casual share: ", round(casual_share*100,1), "%<br>",
      "Total rides: ", total
    )
  ) %>%
  
  # Mostly Casual
  addCircleMarkers(
    data = filter(station_mix2, segment == "Mostly Casual"),
    lng = ~start_lng,
    lat = ~start_lat,
    radius = ~pmax(5, sqrt(total) / 2),
    fillColor = "#E76F51",
    fillOpacity = 0.95,
    stroke = FALSE,
    group = "Mostly Casual",
    popup = ~paste0(
      "<b>", start_station_name, "</b><br>",
      "Type: Mostly Casual<br>",
      "Casual share: ", round(casual_share*100,1), "%<br>",
      "Total rides: ", total
    )
  ) %>%
  
  addLayersControl(
    overlayGroups = c(
      "Mostly Member",
      "Mixed Use",
      "Mostly Casual"
    ),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  
  addLegend(
    position = "bottomright",
    colors = c(
      "#264653",
      "#9E9E9E",
      "#E76F51"
    ),
    labels = c(
      "Mostly Member",
      "Mixed Use",
      "Mostly Casual"
    ),
    title = "Station Type",
    opacity = 1
  )

# KPI Card

round_trip_kpi <- tibble(
  usertype = c("Casual Riders", "Annual Members"),
  pct = c(14.1, 1.43)
)

ggplot(round_trip_kpi,
       aes(x = usertype,
           y = pct,
           fill = usertype)) +
  
  geom_col(width = .55, show.legend = FALSE) +
  
  geom_text(
    aes(label = paste0(round(pct, 2), "%")),
    vjust = -0.6,
    size = 8,
    fontface = "bold"
  ) +
  
  annotate(
    "text",
    x = 1.5,
    y = 17.5,
    label = "Casual riders are nearly 10× more likely\nto make round trips",
    size = 5.2,
    fontface = "bold",
    color = "#1f1f1f"
  ) +
  
  scale_fill_manual(
    values = c(
      "Casual Riders" = "#E76F51",
      "Annual Members" = "#264653"
    )
  ) +
  
  coord_cartesian(ylim = c(0, 19)) +
  
  labs(
    title = "Round-Trip Behavior Strongly Differentiates Rider Segments",
    subtitle = "Round trip defined as rides beginning and ending at the same station",
    x = NULL,
    y = "Percent of Rides"
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "gray35"),
    axis.title.x = element_blank()
  )


