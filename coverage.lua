--[[ 
each mod that requires `coverage.lua` will have a remote "__coverage_modname"
with start(testname), stop(), and dump()
and will check coverage.isrunning on startup for an ongoing test

data is saved in a table by testname, short_src and line number:
coveragedata = {
  levelpath = { modname = "", basepath = "" }
  tests = {
    [testname] = {
      [short_src] = {
        lines = {
          [linenumber] = count
        },
      }
    }
  }
}
--]]

local levelpath

local _Coverage = {
  Start = function(testname)
    remote.call("coverage","start",testname)
  end,
  Stop = function()
    remote.call("coverage","stop")
  end,
  Report = function()
    remote.call("coverage","report")
  end,
  LevelPath = function(modname,basepath)
    levelpath = {
      modname = modname,
      basepath = basepath,
    }
  end,
}

local tests = {}

local function start(testname)
  if not testname then testname = "" end
  local test = tests[testname]
  if not test then 
    test = {} 
    tests[testname] = test 
  end
  local getinfo = debug.getinfo
  local sub = string.sub
  debug.sethook(function(event,line)
    local s = getinfo(2,"S").short_src
    -- startup logging gets all the serpent loads of `global`
    -- serpent itself will also always show up as one of these
    if sub(s,1,7) == "[string" then return end 
    local fileinfo = test[s]
    if not fileinfo then
      fileinfo = {}
      test[s] = fileinfo
    end
    fileinfo[line] = (fileinfo[line] or 0) + 1
  end,"l")
end

log("coverage registered for " .. script.mod_name)
remote.add_interface("__coverage_" .. script.mod_name ,{
  start = start,
  stop = function()
    debug.sethook()
  end,
  dump = function()
    local dump = {tests = tests}
      if script.mod_name == "level" then
        dump.levelpath = levelpath 
      end
    tests = {}
    return dump
  end
})

if settings.global["coverage-startup"].value then
  log("startup coverage for " .. script.mod_name)
  start("startup")
end

return _Coverage