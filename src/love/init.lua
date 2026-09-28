local path = (...):gsub('%.', '.'):gsub('.init$', '.')

require(path .. "run")
require(path .. "error")
