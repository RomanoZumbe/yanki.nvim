  command! -range -nargs=* PutNextLine lua require('yanki.util').dot_repeat(function() require('yanki').PutNext() end)
  command! -range -nargs=* ShowYankHistory lua require("yanki").ShowYankHistory()
  command! -range -nargs=* CleanYankHistory lua require("yanki").ClearYankHistory()
  command! -range -nargs=* ShowTransformers lua require("yanki").ShowTransformers()
  
