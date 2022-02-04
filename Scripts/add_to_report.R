# Add text to a report, which will allow to track progress

# Arguments:
# folder, report_name

# Test
folder = file.path(folder_root, folder_report)
report_name = paste0(report_name, "_1.0.txt")
text = "This is a test!"

add_to_report = function(folder, report_name, text){
  
  # If there is no directory, make one
  if(!dir.exists(folder)){
    dir.create(folder)
  }
  
  # If there is no report, make one
  if(!file.exists(file.path(folder, report_name))){
    rep_text = ""
  }else{
    rep_text = readLines(file.path(folder, report_name))
  }
  
  writeLines(c(rep_text, "\n*-*-*\n", text), file.path(folder, report_name))
}

### Function works. Now to work on a "compile_reports", using a report_name and a folder
### And to incorporate that into the other scripts. Use version numbers to write a report per core
### And per scripts number
