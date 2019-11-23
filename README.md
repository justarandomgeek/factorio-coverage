# Factorio Coverage Tester

A coverage tool for Factorio Mods, by justarandomgeek.

Usage:

`/startCoverage testname` (Command)

`Coverage.Start("testname")` or `remote.call("coverage","start","testname")` (Script)

Start line counting for all participating mods. Each mod will collect data independently, to be gathered after tests complete.


`/stopCoverage` (Command)

`Coverage.Stop()` or `remote.call("coverage","stop")` (Script)

Stop line counting for all participating mods.


`/reportCoverage` (Command)

`Coverage.Report()` or `remote.call("coverage","report")` (Script)

Collect test data from all participating mods and write it out to `script-outputs\lcov.info`. Automatically stops counting if a test was still running.


Most scripts simply need to `pcall(require,'__coverage__/coverage.lua')` to be included in line counts. Scenarios/campaign scripts must also provide a path hint to translate "level" to a correct path:
```lua
CoverageLoaded,Coverage = pcall(require,'__coverage__/coverage.lua')
if CoverageLoaded then
    Coverage.LevelPath("modname","scenarios/scenarioname/")
end
```
This form is also useful to provide the `Coverage` object for `Start()`/`Stop()` API calls.


There is a mod setting to enable line counting immediately on control.lua initialization, but this is disabled by default because it makes starting a game very slow.
