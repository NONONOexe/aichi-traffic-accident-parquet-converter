# Aichi Prefecture Traffic Accident Data to Parquet Converter

## Overview

This project contains a script to convert the Aichi Prefecture traffic accident data into Parquet format. The Parquet format offers significant performance advantages for analytical queries compared to other formats like CSV.

## Data Source

The source data used is non-public and provided by the Aichi Prefectural Police. To use this script, set the environment variables `DATA_DIR` for the directory containing the source data and `OUTPUT_DIR` for the directory where the output data will be stored. If these environment variables are not set, the script will use `internal` and `data` directories by default, respectively.

## How to Read the Data

After converting the source data to Parquet format, you can read the data using various tools and programming languages that support Parquet. Below are examples in R and Python:

### R Example

``` r
library(arrow)
library(sf)

file_name <- "traffic-accidents-2021.parquet"
data_frame <- read_parquet(file_name)
traffic_accidents <- st_as_sf(
  data_frame,
  coords = c("longitude", "latitude"),
  crs    = 4326
)
```

### Python Example

``` python
import pandas as pd
import geopandas as gpd

file_name = "traffic-accidents-2021.parquet"
data_frame = pd.read_parquet(file_name)
traffic_accidents = gpd.GeoDataFrame(
  data_frame,
  geometry=gpd.points_from_xy(data_frame.longitude, data_frame.latitude),
  crs="EPSG:4326"
)
```

## Performance Comparison of CSV and Parquet Files

The benchmark compares read speed of CSV and Parquet files using dataset of traffic accidents recorded in 2021. The dataset, originally an Excel file (26,314 KB), was converted to CSV and Parquet formats for analysis.

| Format  | Size on Disk (KB) | Average Read Time (ms) | Standard Deviation (ms) |
|---------|------------------:|-----------------------:|------------------------:|
| CSV     |            93,736 |                 725.68 |                   73.30 |
| Parquet |             1,767 |                  74.77 |                   24.64 |

The benchmarks were conducted in R using the `microbenchmark` package, with results averaged over 100 runs. Tests were performed on a machine with the following specifications:

-   **Processor**: 11th Gen Intel Core i7-11370H \@ 3.30GHz\
-   **Memory**: 32.0 GB RAM\
-   **Storage**: SSD\
-   **Operating System**: Windows

## Licence

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.
