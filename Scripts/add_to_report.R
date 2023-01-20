# Add text to a report, which will allow to track progress

# Arguments:
# folder, report_name

# # Test
# folder = file.path(folder_root, folder_report)
# report_name = paste0(report_name, "_1.0.txt")
# text = "This is a test!"

add_to_report = function(folder, report_name, step, core, text){
  
  # If there is no directory, make one
  if(!dir.exists(folder)){
    dir.create(folder)
  }
  
  the_report_name = paste0(report_name, "_", step, "-", core, ".txt")
  
  cat(paste0(text),
      file = file.path(folder, the_report_name), sep = "\n", append = T)
}
