data:extend{
    {
      type = "bool-setting",
      name = "coverage-startup",
      setting_type = "runtime-global",
      default_value = false,
      order="coverage-10-startup",
    },
    {
      type = "string-setting",
      name = "coverage-include-modstates",
      setting_type = "runtime-global",
      default_value = "",
      allow_blank = true,
      order="coverage-20-include-modstates",
    },
    {
      type = "string-setting",
      name = "coverage-exclude-modfiles",
      setting_type = "runtime-global",
      default_value = "[\"coverage\"]",
      allow_blank = true,
      order="coverage-30-exclude-modfiles",
    },
    {
      type = "string-setting",
      name = "coverage-nopath-mods",
      setting_type = "runtime-global",
      default_value = "",
      allow_blank = true,
      order="coverage-40-nopath-mods",
    },
  }