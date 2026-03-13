# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "RelWithDebInfo")
  file(REMOVE_RECURSE
  "CMakeFiles/colors_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/colors_autogen.dir/ParseCache.txt"
  "CMakeFiles/colorsplugin_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/colorsplugin_autogen.dir/ParseCache.txt"
  "colors_autogen"
  "colorsplugin_autogen"
  )
endif()
