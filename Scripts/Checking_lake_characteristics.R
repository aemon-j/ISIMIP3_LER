# Checking and correcting the LakeCharacteristics csv file
# Using the ISIMIP3 Lake char file (downloaded 2022-12-15)

library(data.table)

the_wd = dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(the_wd)

lst_to_report = list()

folder_lake_char = "../LakeCharacteristics"
orig_characteristics_file = file.path(folder_lake_char, "ISIMIP3_Lake_Sector_Contributions - MetaData Hydrothermal.csv")

df_char = fread(orig_characteristics_file)

# Ensure that I have all the lake names correct, with at least these headers:
# Lake Long,	Lake Short Name,	Lake Name Folder,	latitude (dec deg),	longitude (dec deg),
#   elevation (m),	mean depth (m),	max depth (m)

##### Remove lakes that are not included, and only keep relevant columns -----
ind_to_remove = which(df_char$`Date of contribution (dd/mm/yyyy)` == "marked for deletion")
df_char = df_char[1L:(ind_to_remove - 1L)]
df_char = df_char[`Lake Name` != "", .(`Lake Name`,
                                       `Lake Short Name`,
                                       `Lake Name in file name (reporting)`,
                                       `Reservoir or lake?`,
                                       Country,
                                       `latitude (dec deg)`,
                                       `longitude (dec deg)`,
                                       `elevation (m)`,
                                       `mean depth (m)`,
                                       `max depth (m)`,
                                       `lake area (km²)`,
                                       `Average Secchi disk depth [m]`,
                                       `Light extinction coefficient [m-1]`)]
setnames(df_char, old = "Lake Name in file name (reporting)", new = "Lake Name Folder")

##### Dots instead of commas -----
col_names = names(df_char)
num_col_names = col_names[!(col_names %in% c("Lake Name", "Lake Short Name",
                                             "Lake Name Folder",
                                             "Reservoir or lake?", "Country"))]

df_char[, (num_col_names) := lapply(.SD, function(x) gsub(",", ".", x)), .SDcols = num_col_names]
df_char[, (num_col_names) := lapply(.SD, as.numeric), .SDcols = num_col_names]

##### Remove double entries -----
ind_dupl = which(duplicated(df_char$`Lake Name Folder`))
df_char = df_char[-ind_dupl]

##### Special character corrections -----
# In general, use the 26-alfabet sign, based on the reporting name
df_char[`Lake Name Folder` == "crystal-bog", `Lake Short Name` := "CrystalBog"]
df_char[`Lake Name Folder` == "ekoln", `Lake Name` := "Ekoln basin of Malaren"]
df_char[`Lake Name Folder` == "kilpisjarvi", `Lake Name` := "Kilpisjarvi"]
df_char[`Lake Name Folder` == "mueggelsee", `:=`(`Lake Name` = "Lake Muggelsee",
                                                 `Lake Short Name` = "Muggelsee")]
df_char[`Lake Name Folder` == "neuchatel", `:=`(`Lake Name` = "Lake Neuchatel",
                                                `Lake Short Name` = "Neuchatel")]
df_char[`Lake Name Folder` == "nohipalo-mustjaerv", `:=`(`Lake Name` = "Lake Nohipalo Mustjaerv",
                                                         `Lake Short Name` = "NohipaloMustjarv")]
df_char[`Lake Name Folder` == "nohipalo-valgejaerv", `:=`(`Lake Name` = "Lake Nohipalo Valgejaerv",
                                                          `Lake Short Name` = "NohipaloValgejarv")]
df_char[`Lake Name Folder` == "paaijarvi", `:=`(`Lake Name` = "Lake Paaijarvi",
                                                `Lake Short Name` = "Paajarvi")]
df_char[`Lake Name Folder` == "trout-bog", `Lake Short Name` := "TroutBog"]
df_char[`Lake Name Folder` == "vortsjaerv", `Lake Name` := "Lake Vortsjarv"]
df_char[`Lake Name Folder` == "scharmutzelsee", `:=`(`Lake Name` = "Lake Scharmutzelsee",
                                                     `Lake Short Name` = "Scharmutzel")]

##### Filling in or correcting values -----
# I need values for lat, lon, and elevation in order to run LER. Max depth could be used as well
df_char[`Lake Name Folder` == "allequash", `elevation (m)` := 494] # Hanson et al. (2018). JAWRA, 54(6), 1302-1324
df_char[`Lake Name Folder` == "annie", `max depth (m)` := 20.7] # Gaiser et al. (2009). Fundamental and Applied Limnology, 175(3), 217
df_char[`Lake Name Folder` == "big-muskellunge", `elevation (m)` := 500] # Hanson et al. (2018). JAWRA, 54(6), 1302-1324
df_char[`Lake Name Folder` == "black-oak", `Average Secchi disk depth [m]` := 3.2] # Original value 32.06, but notes say "min Secchi =3, max Secchi = 12"
df_char[`Lake Name Folder` == "bryrup", `elevation (m)` := 66] # mapcarta.com
df_char[`Lake Name Folder` == "crystal-lake", `elevation (m)` := 501] # Hanson et al. (2018). JAWRA, 54(6), 1302-1324
df_char[`Lake Name Folder` == "crystal-bog", `elevation (m)` := 501.5] # Hanson et al. (2018). JAWRA, 54(6), 1302-1324
df_char[`Lake Name Folder` == "eagle", `elevation (m)` := 190] # Oveisy and Boegman (2014). J. Limnol., 73(3) 441-453
df_char[`Lake Name Folder` == "fish", `elevation (m)` := 265] # Rough estimate using Google Maps
df_char[`Lake Name Folder` == "mendota", `elevation (m)` := 258.5] # Chen et al. (2019). Journal of Hydrology, 577, 123920
df_char[`Lake Name Folder` == "monona", `elevation (m)` := 257] # Chen et al. (2019). Journal of Hydrology, 577, 123920
df_char[`Lake Name Folder` == "sparkling", `elevation (m)` := 495] # Hanson et al. (2018). JAWRA, 54(6), 1302-1324
df_char[`Lake Name Folder` == "toolik", `:=`(`elevation (m)` = 720,
                                             `mean depth (m)` = 7,
                                             `max depth (m)` = 25)] # O'Brien et al. (1997). The limnology of Toolik lake. In Freshwaters of Alaska (pp. 61-106). Springer, New York, NY.
df_char[`Lake Name Folder` == "trout-lake", `elevation (m)` := 491.8] # Hanson et al. (2018). JAWRA, 54(6), 1302-1324
df_char[`Lake Name Folder` == "trout-bog", `elevation (m)` := 495] # Hanson et al. (2018). JAWRA, 54(6), 1302-1324
df_char[`Lake Name Folder` == "wingra", `elevation (m)` := 254] # Boylen et al. (1973). L&O, 18(4), 628-634

##### Correcting file naming and other mistakes -----
if(file.exists(file.path(folder_lake_char, "Monona", "Monona_hypsograph.csv"))){
  file.rename(file.path(folder_lake_char, "Monona", "Monona_hypsograph.csv"),
              file.path(folder_lake_char, "Monona", "Monona_hypsometry.csv"))
}
if(file.exists(file.path(folder_lake_char, "Bryrup", "Bryrup_wtemp_daily.csv"))){
  file.rename(file.path(folder_lake_char, "Bryrup", "Bryrup_wtemp_daily.csv"),
              file.path(folder_lake_char, "Bryrup", "Bryrup_temp_daily.csv"))
}
if(file.exists(file.path(folder_lake_char, "Murten", "Murten_Temp.csv"))){
  file.rename(file.path(folder_lake_char, "Murten", "Murten_Temp.csv"),
              file.path(folder_lake_char, "Murten", "Murten_temp_daily.csv"))
}
if(file.exists(file.path(folder_lake_char, "Wingra", "Wingra_hypsography.csv"))){
  file.rename(file.path(folder_lake_char, "Wingra", "Wingra_hypsography.csv"),
              file.path(folder_lake_char, "Wingra", "Wingra_hypsometry.csv"))
}
if(file.exists(file.path(folder_lake_char, "Zurich", "Zurich_Temp.csv"))){
  file.rename(file.path(folder_lake_char, "Zurich", "Zurich_Temp.csv"),
              file.path(folder_lake_char, "Zurich", "Zurich_temp_daily.csv"))
}

# Mistakes in Zurich's headers
df_temp_zurich = fread(file.path(folder_lake_char, "Zurich", "Zurich_temp_daily.csv"))
setnames(df_temp_zurich, c("SITE_ID", "SITE_NAME", "TIMESTAMP", "DEPTH", "WTEMP"))
fwrite(df_temp_zurich, file.path(folder_lake_char, "Zurich", "Zurich_temp_daily.csv"))

if(file.exists(file.path(folder_lake_char, "Crystal", "Crystal_hypsography.csv"))){
  file.rename(file.path(folder_lake_char, "Crystal", "Crystal_hypsography.csv"),
              file.path(folder_lake_char, "Crystal", "Crystal_hypsometry.csv"))
}
# Mistake in Crystal's headers
df_hyps_crystal = fread(file.path(folder_lake_char, "Crystal", "Crystal_hypsometry.csv"))
setnames(df_hyps_crystal, gsub("-", "_", names(df_hyps_crystal)))
fwrite(df_hyps_crystal, file.path(folder_lake_char, "Crystal", "Crystal_hypsometry.csv"))

# Zlutice hypsograph has an extra column
df_hyps_zlutice = fread(file.path(folder_lake_char, "Zlutice", "Zlutice_hypsometry.csv"))
if("ELEVATION_M" %in% names(df_hyps_zlutice)){
  df_hyps_zlutice[, ELEVATION_M := NULL]
}
fwrite(df_hyps_zlutice, file.path(folder_lake_char, "Zlutice", "Zlutice_hypsometry.csv"))

# Zlutice temp obs has an extra column
df_temp_zlutice = fread(file.path(folder_lake_char, "Zlutice", "Zlutice_temp_daily.csv"))
if("ELEVATION_M" %in% names(df_temp_zlutice)){
  df_temp_zlutice[, ELEVATION_M := NULL]
}
fwrite(df_temp_zlutice, file.path(folder_lake_char, "Zlutice", "Zlutice_temp_daily.csv"))

# Tarawera has some observations in an odd format - only six digits in TIMESTAMP
df_temp_tarawera = fread(file.path(folder_lake_char, "Tarawera", "Tarawera_temp_daily.csv"))
df_temp_tarawera = df_temp_tarawera[floor(log10(TIMESTAMP)) + 1 > 6L]
fwrite(df_temp_tarawera, file.path(folder_lake_char, "Tarawera", "Tarawera_temp_daily.csv"))

# Hypsograph of Taihu is upside down
df_hyps_taihu = fread(file.path(folder_lake_char, "Taihu", "Taihu_hypsometry.csv"))
if(df_hyps_taihu[1L, DEPTH] == 0.0 & df_hyps_taihu[1L, BATHYMETRY_AREA] == 0.0){
  df_hyps_taihu[, BATHYMETRY_AREA := rev(BATHYMETRY_AREA)]
}
fwrite(df_hyps_taihu, file.path(folder_lake_char, "Taihu", "Taihu_hypsometry.csv"))

# Hypsographs of Hulun and MtBold do not contain a depth 0, causing Simstrat to crash
df_hyps_mtbold = fread(file.path(folder_lake_char, "MtBold", "MtBold_hypsometry.csv"))
if(df_hyps_mtbold[1L, DEPTH] != 0.0 & df_hyps_mtbold[1L, DEPTH] == min(df_hyps_mtbold[, DEPTH])){
  df_hyps_mtbold[1L, DEPTH := 0.0]
}
fwrite(df_hyps_mtbold, file.path(folder_lake_char, "MtBold", "MtBold_hypsometry.csv"))

df_hyps_hulun = fread(file.path(folder_lake_char, "Hulun", "Hulun_hypsometry.csv"))
if(df_hyps_hulun[1L, DEPTH] != 0.0 & df_hyps_hulun[1L, DEPTH] == min(df_hyps_hulun[, DEPTH])){
  df_hyps_hulun[1L, DEPTH := 0.0]
}
fwrite(df_hyps_hulun, file.path(folder_lake_char, "Hulun", "Hulun_hypsometry.csv"))

# Mozhaysk daily obs file has a depth "???" in it
df_temp_mozhaysk = fread(file.path(folder_lake_char, "Mozhaysk", "Mozhaysk_temp_daily.csv"))
df_temp_mozhaysk = df_temp_mozhaysk[DEPTH != "???"]
fwrite(df_temp_mozhaysk, file.path(folder_lake_char, "Mozhaysk", "Mozhaysk_temp_daily.csv"))

# Large number of digits in depth of the Delavan hypsograph causes Simstrat to crash - 4 digits will do
df_hyps_delavan = fread(file.path(folder_lake_char, "Delavan", "Delavan_hypsometry.csv"))
df_hyps_delavan[, DEPTH := round(DEPTH, digits = 4L)]
fwrite(df_hyps_delavan, file.path(folder_lake_char, "Delavan", "Delavan_hypsometry.csv"))

##### Write file -----
fwrite(df_char, file.path(folder_lake_char, "LakeCharacteristics.csv"))
