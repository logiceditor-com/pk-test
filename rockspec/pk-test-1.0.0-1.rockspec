package = "pk-test"
version = "1.0.0-1"
source = {
   url = "" -- Can be built with luarocks make only
}
description = {
   summary = "pk-test tools and libs",
   homepage = "http://logiceditor.com",
   license = "MIT/X11",
   maintainer = "LogicEditor Team <team@logiceditor.com>"
}
supported_platforms = {
   "unix"
}
dependencies = {
   "lua == 5.1",
   "pk-engine >= 0.0.1",
   "pk-core >= 0.0.1",
   "lua-nucleo",
   "lua-aplicado"
}
build = {
   type = "none",
   copy_directories = {
     "pk-test/"
   };
   install = {
      bin = {
         "bin/pk-test"
      }
   }
}
