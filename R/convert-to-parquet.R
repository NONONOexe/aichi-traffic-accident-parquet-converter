library(readxl)
library(tidyverse)
library(scales)
library(celestial)
library(arrow)

# Define column names -----------------------------------------------------

key_items <- c(
  accident_id        = "■本票番号（共通）_本票番号"
)

accident_items <- c(
  occurrence_date    = "■発生_発生年月日",
  day_of_week        = "■曜日_曜日名称",
  day_night_type     = "□昼夜_昼夜名称",
  occurrence_hour    = "□発生時間_発生時",
  police_office      = "■発生警察署（共通）_発生警察署名称",
  occurrence_place   = "□発生場所_市区町村名称（大字出力）",
  latitude           = "□地図情報_Ｘ座標",
  longitude          = "□地図情報_Ｙ座標",
  weather            = "■天候_天候名称",
  road_surface       = "□路面状態_路面状態名称",
  road_type          = "■路線_路線中種別名称",
  road_shape         = "□道路形状_道路形状名",
  road_alignment     = "□道路線形_道路線形中種別名称",
  carriageway_width  = "■車道幅員_車道幅員名称",
  traffic_signal     = "■信号機_信号機名称",
  injury_pattern     = "■事故内容_事故内容名称",
  fatality           = "□全被害_死者数",
  severe_injury      = "□全被害_重傷者数",
  slight_injury      = "□全被害_軽傷者数",
  impact_type        = "■事故類型_事故類型名称",
  collision_position = "□衝突地点_衝突地点名称",
  special_category_1 = "■特殊事故（共通）_特殊事故１名称",
  special_category_2 = "■特殊事故（共通）_特殊事故２名称",
  special_category_3 = "■特殊事故（共通）_特殊事故３名称"
)

party_items <- c(
  car_id             = "■当事車番号_当事車番号",
  passenger_id       = "□同乗者番号_同乗者番号",
  party_rank         = "■乗車別_乗車別名称",
  violation_type     = "■法令違反_法令違反中種別名称",
  violation_detail   = "■法令違反_法令違反名称",
  cause_road         = "□事故原因_道路環境的原因名称",
  cause_car          = "□事故原因_車両的原因名称",
  cause_human        = "□事故原因_人的原因名称",
  action_type        = "■行動類型_行動類型名称",
  move_direction     = "□本票（当事者）_進行方向",
  car_light_state    = "□本票（当事者）_ライト点灯状況",
  party_type         = "■当事者種別_当事者大種別名称",
  party_subtype      = "■当事者種別_当事者中種別名称",
  party_subsubtype   = "■当事者種別_当事者種別名称",
  car_tire           = "□本票（当事者）_タイヤ等の状況名称",
  use_type           = "■用途_用途別中種別名称",
  use_detail         = "■用途_用途別名称",
  injured_part       = "■人身損傷主部位_負傷主部位名称",
  injury_level       = "□負傷程度_負傷程度名称",
  seat_belt          = "□本票（当事者）_シートベルト名称",
  helmet             = "□本票（当事者）_ヘルメット名称",
  air_bag            = "□本票（当事者）_エアバック名称",
  side_air_bag       = "□本票（当事者）_サイドエアバック名称",
  alcohol_intake     = "□飲酒運転_飲酒運転名称",
  cell_phone         = "□本票（当事者）_携帯電話名称",
  car_nav_system     = "□本票（当事者）_カーナビ名称",
  critical_speed     = "□本票（当事者）_危険認知速度名称",
  party_gender       = "■当事者_性別名称",
  party_age          = "■当事者_年齢",
  home_prefecture    = "□居住_居住県名称",
  home_address       = "□居住_居住市区町村名称",
  home_distance      = "□本票（当事者）_自宅距離名称",
  party_job          = "□職業_職業名称",
  purpose            = "■通行目的_通行目的名称"
)


# Read accident data ------------------------------------------------------

convert_deg <- function(dms) {
  dms_num <- dms |>
    str_replace("^([0-9]{3})([0-9]{8})$", "\\1.\\2") |>
    as.numeric()
  dms_str <- number(dms_num, accuracy = .00000001, digits = 8)

  d <- dms_str |>
    str_replace("^(.+)\\..{8}$", "\\1") |>
    str_replace_na("0")
  m <- dms_str |>
    str_replace("^.+\\.(.{2}).{6}$", "\\1") |>
    str_replace_na("0")
  s <- dms_str |>
    str_replace("^.+\\..{2}(.{2})(.{4})$", "\\1.\\2") |>
    str_replace_na("0")

  deg <- if_else(is.na(dms), dms_num, dms2deg(d, m, s))

  return(deg)
}

convert_to_parquet <- function(file_name) {
  # Load accident data
  input_dir <- Sys.getenv("DATA_DIR", unset = "internal")
  accident_file_path <- file.path(input_dir, paste0(file_name, ".xlsx"))
  accident_data <- read_excel(accident_file_path, .name_repair = make.unique)

  # Process traffic accidents
  traffic_accidents <- accident_data |>
    select(any_of(c(key_items, accident_items))) |>
    distinct(accident_id, .keep_all = TRUE) |>
    mutate(
      occurrence_date = as_date(occurrence_date),
      occurrence_hour = as.integer(occurrence_hour),
      latitude        = convert_deg(latitude),
      longitude       = convert_deg(longitude),
      fatality        = as.integer(fatality),
      severe_injury   = as.integer(severe_injury),
      slight_injury   = as.integer(slight_injury)
    ) |>
    drop_na(latitude, longitude)

  # Process injured parties
  injured_parties <- accident_data |>
    select(any_of(c(key_items, party_items))) |>
    mutate(party_age = as.integer(party_age))

  # Write to output directory
  output_dir <- Sys.getenv("OUTPUT_DIR", unset = "data")
  write_parquet(
    traffic_accidents,
    file.path(output_dir, str_c("traffic-accidents-", file_name, ".parquet"))
  )
  write_parquet(
    injured_parties,
    file.path(output_dir, str_c("injured-parties-", file_name, ".parquet"))
  )
}


# Convert accident data into parquet file ---------------------------------

years <- 2009:2021
walk(as.character(years), convert_to_parquet)
