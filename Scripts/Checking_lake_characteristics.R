# Checking the LakeCharacteristics_orig.xlsx file and the Lake Characteristics folder
# Corrects the characteristics file and writes it. Also renames Gosia's
# folders to the names used in ISIMIP

library(data.table)

the_wd = dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(the_wd)

lst_to_report = list()

folder_lake_char = "../Lake characteristics"
orig_characteristics_file = file.path(folder_lake_char, "LakeCharacteristics_orig.csv")

# This is a vector of the files downloaded from the ISIMIP server, to know for sure what
# lake names are used in isimip3. 
downloaded_files = c("gswp3-w5e5_obsclim_allequash-lake.zip", "gswp3-w5e5_obsclim_alqueva.zip",
                     "gswp3-w5e5_obsclim_annecy.zip", "gswp3-w5e5_obsclim_annie.zip",
                     "gswp3-w5e5_obsclim_argyle.zip", "gswp3-w5e5_obsclim_biel.zip",
                     "gswp3-w5e5_obsclim_big-muskellunge-lake.zip", "gswp3-w5e5_obsclim_black-oak-lake.zip",
                     "gswp3-w5e5_obsclim_bourget.zip", "gswp3-w5e5_obsclim_burley-griffin.zip",
                     "gswp3-w5e5_obsclim_crystal-bog.zip", "gswp3-w5e5_obsclim_crystal-lake.zip",
                     "gswp3-w5e5_obsclim_delavan.zip", "gswp3-w5e5_obsclim_dickie-lake.zip",
                     "gswp3-w5e5_obsclim_eagle-lake.zip", "gswp3-w5e5_obsclim_ekoln-basin-of-malaren.zip",
                     "gswp3-w5e5_obsclim_erken.zip", "gswp3-w5e5_obsclim_esthwaite-water.zip",
                     "gswp3-w5e5_obsclim_falling-creek-reservoir.zip", "gswp3-w5e5_obsclim_feeagh.zip",
                     "gswp3-w5e5_obsclim_fish-lake.zip", "gswp3-w5e5_obsclim_geneva.zip",
                     "gswp3-w5e5_obsclim_great-pond.zip", "gswp3-w5e5_obsclim_green-lake.zip",
                     "gswp3-w5e5_obsclim_harp-lake.zip", "gswp3-w5e5_obsclim_kilpisjarvi.zip",
                     "gswp3-w5e5_obsclim_kinneret.zip", "gswp3-w5e5_obsclim_kivu.zip",
                     "gswp3-w5e5_obsclim_klicava.zip", "gswp3-w5e5_obsclim_kuivajarvi.zip",
                     "gswp3-w5e5_obsclim_langtjern.zip", "gswp3-w5e5_obsclim_laramie-lake.zip",
                     "gswp3-w5e5_obsclim_lower-zurich.zip", "gswp3-w5e5_obsclim_mendota.zip",
                     "gswp3-w5e5_obsclim_monona.zip", "gswp3-w5e5_obsclim_mozaisk.zip",
                     "gswp3-w5e5_obsclim_mt-bold.zip", "gswp3-w5e5_obsclim_mueggelsee.zip",
                     "gswp3-w5e5_obsclim_neuchatel.zip", "gswp3-w5e5_obsclim_ngoring.zip",
                     "gswp3-w5e5_obsclim_nohipalo-mustjarv.zip", "gswp3-w5e5_obsclim_nohipalo-valgejarv.zip",
                     "gswp3-w5e5_obsclim_okauchee-lake.zip", "gswp3-w5e5_obsclim_paajarvi.zip",
                     "gswp3-w5e5_obsclim_rappbode-reservoir.zip", "gswp3-w5e5_obsclim_rimov.zip",
                     "gswp3-w5e5_obsclim_rotorua.zip", "gswp3-w5e5_obsclim_sammamish.zip",
                     "gswp3-w5e5_obsclim_sau-reservoir.zip", "gswp3-w5e5_obsclim_sparkling-lake.zip",
                     "gswp3-w5e5_obsclim_stechlin.zip", "gswp3-w5e5_obsclim_sunapee.zip",
                     "gswp3-w5e5_obsclim_tahoe.zip", "gswp3-w5e5_obsclim_tarawera.zip",
                     "gswp3-w5e5_obsclim_toolik-lake.zip", "gswp3-w5e5_obsclim_trout-bog.zip",
                     "gswp3-w5e5_obsclim_trout-lake.zip", "gswp3-w5e5_obsclim_two-sisters-lake.zip",
                     "gswp3-w5e5_obsclim_vendyurskoe.zip", "gswp3-w5e5_obsclim_victoria.zip",
                     "gswp3-w5e5_obsclim_vortsjarv.zip", "gswp3-w5e5_obsclim_washington.zip",
                     "gswp3-w5e5_obsclim_windermere.zip", "gswp3-w5e5_obsclim_wingra.zip",
                     "gswp3-w5e5_obsclim_zlutice.zip")
isimip_lakes = gsub("gswp3-w5e5_obsclim_|.zip", "", downloaded_files)

df_char = fread(orig_characteristics_file)

# Underscores became hyphens
df_char[, `Lake Name Folder` := gsub("_", "-", `Lake Name Folder`)]

##### Check the names, and check if ISIMIP names are missing in the LakeCharacteristics file and vice versa -----
names_in_df_char = tolower(df_char$`Lake Name Folder`)

lst_to_report[["Lakes in LakeChar but not in ISIMIP"]] = names_in_df_char[!(names_in_df_char %in% isimip_lakes)]
lst_to_report[["Lakes in ISIMIP but not in LakeChar"]] = isimip_lakes[!(isimip_lakes %in% names_in_df_char)]

df_char = df_char[tolower(`Lake Name Folder`) %in% isimip_lakes]

##### Check the names and formats of the folders in the lake characteristics folder -----
# These folders were downloaded from Gosia's project on the server and
# they contain the temperature observations and hypsographs
lakes_with_hyps_and_obs = list.files(folder_lake_char)
lakes_with_hyps_and_obs = lakes_with_hyps_and_obs[file.info(file.path(folder_lake_char, lakes_with_hyps_and_obs))$isdir]

# Incredible...
tmp_names1 = gsub(" ", "", df_char$`Lake Short Name`)
tmp_names2 = gsub("-", "", df_char$`Lake Name Folder`)

for(i in lakes_with_hyps_and_obs){
  if(i %in% df_char$`Lake Short Name`){
    real_name = df_char[i == `Lake Short Name`, `Lake Name Folder`]
  }else if(i %in% tmp_names1){
    ind = which(tmp_names1 == i)
    real_name = df_char[ind, `Lake Name Folder`]
  }else if(i %in% df_char$`Lake Name Folder`){
    # No action is required, folder name is already correct
    real_name = i
  }else if(i %in% tmp_names2){
    ind = which(tmp_names2 == i)
    real_name = df_char[ind, `Lake Name Folder`]
  }else if(i == "Muggelsee"){
    real_name = "Mueggelsee"
  }else{
    message("Lake ", i, " unaccounted for!")
  }
  
  hyps_file = list.files(file.path(folder_lake_char, i),
                         pattern = "hypsometry.csv")
  if(length(hyps_file) != 1L){
    lst_to_report[["No hypsometry file"]] = c(lst_to_report[["No hypsometry file"]],
                                              real_name)
  }
  
  temp_files = list.files(file.path(folder_lake_char, i),
                          pattern = "_temp_")
  if(length(temp_files) == 0L){
    lst_to_report[["No temp obs"]] = c(lst_to_report[["No temp obs"]],
                                              real_name)
  }
  
  the_folder = file.path(folder_lake_char, real_name)
  file.rename(file.path(folder_lake_char, i),
              the_folder)
}

##### Last corrections  -----
# Annie, based on Gaiser et al. (2009). Fundamental and Applied Limnology, 175(3), 217.
df_char[`Lake Name Folder` == "Annie", `:=`(`mean depth (m)` = 10.0,
                                            `max depth (m)` = 20.7)]

file.rename(file.path(folder_lake_char, "Monona", "Monona_hypsograph.csv"),
            file.path(folder_lake_char, "Monona", "Monona_hypsometry.csv"))

fwrite(df_char, file.path(folder_lake_char, "LakeCharacteristics.csv"))
