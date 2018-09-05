package = "pk-test-lite"
version = "scm-1"
source = {
   url = "" -- Can be built with luarocks make only
}
description = {
   summary = "pk-test tools and libs, lite version (no pk-engine, testbrowser wouldn't work)",
   homepage = "http://logiceditor.com",
   license = "MIT/X11",
   maintainer = "LogicEditor Team <team@logiceditor.com>"
}
supported_platforms = {
   "unix"
}
dependencies = {
   "lua == 5.1",
   "wsapi-xavante",
   "pk-core >= 0.0.1",
   "lua-nucleo",
   "lua-aplicado",
   "le-tools.le-call-lua-module",
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
