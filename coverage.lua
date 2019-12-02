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
        funcs = {
          [linedefined] = {
            names = {name=true,...},
            linedefined = linedefined,
            count = count,
          },
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
    assert(script.mod_name == "level")
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
    if event == "line" then
      local s = getinfo(2,"S").source
      -- startup logging gets all the serpent loads of `global`
      -- serpent itself will also always show up as one of these
      if sub(s,1,1) ~= "@" then
        return 
      else
        s = sub(s,2)
      end 
      local fileinfo = test[s]
      if not fileinfo then
        fileinfo = {}
        test[s] = fileinfo
      end
      local lines = fileinfo.lines
      if not lines then
        lines = {}
        fileinfo.lines = lines
      end
      lines[line] = (lines[line] or 0) + 1
    elseif event == "call" or event == "tail call" then
      local info = getinfo(2,"nS")
      local s = info.source
      -- startup logging gets all the serpent loads of `global`
      -- serpent itself will also always show up as one of these
      if sub(s,1,1) ~= "@" then
        return 
      else
        s = sub(s,2)
      end 
      local fileinfo = test[s]
      if not fileinfo then
        fileinfo = {}
        test[s] = fileinfo
      end
      local funcs = fileinfo.funcs
      if not funcs then
        funcs = {}
        fileinfo.funcs = funcs
      end
      
      local func = funcs[info.linedefined]
      if not func then
        func = {
          linedefined = info.linedefined,
          names = {},
          count = 1, -- we got here by calling it, so start at one hit...
        }
        funcs[info.linedefined] = func

        -- it's a new function, so add all the lines with zero hitcount
        for line,_ in pairs(getinfo(2,"L").activelines) do
          local lines = fileinfo.lines
          if not lines then
            lines = {}
            fileinfo.lines = lines
          end
          lines[line] = (lines[line] or 0)
        end
      else
        func.count = func.count + 1
      end
      local name = info.name
      if name and name ~= "?" then 
        func.names[name] = (func.names[name] or 0) + 1
      end
    end
  end,"cl")
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