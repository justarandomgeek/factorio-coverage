--[[ 
each mod that requires `coverage.lua` will have a 
remote "__coverage_modname" defined for it
with start(testname), stop(), and dump()

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

local function callAll(mods,funcname,...)
  local results = {}
  for name,version in pairs(mods) do
    local remotename = "__coverage_" .. name
    if remote.interfaces[remotename] then
      results[name] = remote.call(remotename,funcname,...)
    end
  end
  if remote.interfaces["__coverage_level"] then
    results["level"] = remote.call("__coverage_level",funcname,...)
  end
  return results
end

local active_mods = nil
local function getActiveMods()
  if active_mods then return active_mods end
  local json = game.json_to_table(settings.global["coverage-include-modstates"].value)
  if json then
    active_mods = {}
    for _,modname in pairs(json) do
      active_mods[modname] = game.active_mods[modname]
    end
  else 
    active_mods = game.active_mods
  end
  return active_mods
end


local function getExcludeMods(excludetype)
  local json = game.json_to_table(settings.global[excludetype].value)
  local nopathmods = {}
  if json then
    for _,modname in pairs(json) do
      nopathmods[modname] = true
    end
  else 
    nopathmods = game.active_mods
  end
  return nopathmods
end

local runningtestname = nil
local function start(testname)
  runningtestname = testname
  callAll(getActiveMods(),"start",testname)
end
local function stop()
  runningtestname = nil
  callAll(getActiveMods(),"stop")
end

local function report()
  if runningtestname then stop() end
  -- These mod names will remain in __modname__ format, rather than being translated
  local nopathmods = getExcludeMods("coverage-nopath-mods")
  nopathmods.level = true
  nopathmods.base = true
  nopathmods.core = true
  -- These mods will be omitted from output entirely
  local ignoremods = getExcludeMods("coverage-exclude-modfiles")
  --dump everything anyone collected, will just be empty for disabled mods unless startup collection
  local moddumps = callAll(game.active_mods,"dump")
  local outlines = {}
  for dumpname,dump in pairs(moddumps) do
    for testname,files in pairs(dump.tests) do
      for file,lines in pairs(files) do
        local modname,filename = file:match("__(.+)__/(.+)")
        if not ignoremods[modname] then
          outlines[#outlines+1] = string.format("TN:%s [%s]\n",testname,dumpname)
          if not modname then
            --startup tracing sometimes gives absolute path of the scenario script, turn it back into the usual form...
            filename = file:match("currently%-playing/(.+)")
            if filename then 
              modname = "level"
            end
          end
          -- scenario scripts may provide hints to where they came from...
          if modname == "level" then 
            local level = moddumps.level
            local levelpath = level and level.levelpath
            if levelpath then
              modname = levelpath.modname
              filename = levelpath.basepath .. filename
            end
          end
          if nopathmods[modname] then
            -- we *still* can't identify level properly, so just give up...
            -- also, we can't create proper paths for core/base anyway
            outlines[#outlines+1] = string.format("SF:__%s__/%s\n",modname,filename)
          elseif modname == nil then
            --something totally unrecognized?
            outlines[#outlines+1] = string.format("SF:%s\n",file)
          else
            -- we found it! This will be a path relative to the `mods` directory.
            local modver = game.active_mods[modname]
            outlines[#outlines+1] = string.format("SF:./%s_%s/%s\n",modname,modver,filename)
          end
          for line,count in pairs(lines) do
            outlines[#outlines+1] = string.format("DA:%d,%d\n",line,count)
          end
          outlines[#outlines+1] = "end_of_record\n"
        end
      end
    end
  end
  game.write_file("lcov.info",table.concat(outlines))
end

remote.add_interface("coverage",{
  start = start,
  isrunning = function() return runningtestname end,
  stop = stop,
  report = report,
})

script.on_init(function()
  if runningtestname == "startup" then
    runningtestname = nil
    callAll(game.active_mods,"stop")
  end
end)

script.on_load(function()
  if runningtestname == "startup" then
    runningtestname = nil
    callAll(game.active_mods,"stop")
  end
end)

commands.add_command("startCoverage", "Starts coverage counting",
function(command)
	start(command.parameter)
end)
commands.add_command("stopCoverage", "Stops coverage counting",stop)
commands.add_command("reportCoverage", "Generate coverage report",report)
