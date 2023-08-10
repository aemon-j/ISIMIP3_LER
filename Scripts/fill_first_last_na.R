# Function to assess the LER output files and fill a first or last NA value
# with the following or preceding non-NA value. FLake gave an NA at the first
# or last time
# mtr = matrix resulting from ncvar_get on the LER output netcdf
# The first of the dimensions is assumed to be the models

fill_first_last_na = function(mtr){
  if(length(dim(mtr)) == 2L){
    # 1D variable
    
    for(i in seq_len(dim(mtr)[1])){
      # Fill first
      if(is.na(mtr[i, 1L]) & !is.na(mtr[i, 2L])){
        mtr[i, 1L] = mtr[i, 2L]
      }
      
      # Fill last
      len_mtr = length(mtr[i,])
      if(is.na(mtr[i, len_mtr]) & !is.na(mtr[i, len_mtr - 1L])){
        mtr[i, len_mtr] = mtr[i, len_mtr - 1L]
      }
    }
    
  }else if(length(dim(mtr)) == 3L){
    # 2D variable
    
    for(i in seq_len(dim(mtr)[1])){
      # Fill first
      if(all(is.na(mtr[i, 1L,])) & !all(is.na(mtr[i, 2L,]))){
        mtr[i, 1L,] = mtr[i, 2L,]
      }
      
      # Fill last
      len_mtr = length(mtr[i, ,1])
      if(all(is.na(mtr[i, len_mtr,])) & !all(is.na(mtr[i, len_mtr - 1L,]))){
        mtr[i, len_mtr,] = mtr[i, len_mtr - 1L,]
      }
    }
    
  }else{
    stop("Dimensions are wrong!")
  }
  
  return(mtr)
}
