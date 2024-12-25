library(microbenchmark)
library(readr)
library(arrow)

benchmark_time_csv <- microbenchmark(
  suppressMessages({
    traffic_accidents <- read_csv("traffic-accidents-2021.csv")
    injured_parties <- read_csv("injured-parties-2021.csv")
  })
)

benchmark_time_parquet <- microbenchmark(
  suppressMessages({
    traffic_accidents <- read_parquet("traffic-accidents-2021.parquet")
    injured_parties <- read_parquet("injured-parties-2021.parquet")
  })
)
