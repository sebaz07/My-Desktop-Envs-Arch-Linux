-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "catppuccin",

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

local theme_file = io.open(os.getenv("HOME") .. "/.config/hypr/current-theme", "r")
local active_theme = theme_file and theme_file:read("*l") or ""
if theme_file then theme_file:close() end

if active_theme == "Johan Neon" or active_theme == "johan-neon" then
	M.base46.hl_override = {
		Normal = { fg = "#d9eaff", bg = "none" },
		NormalNC = { fg = "#c5d5ec", bg = "none" },
		NormalFloat = { fg = "#d9eaff", bg = "#0b1020" },
		FloatBorder = { fg = "#f02bd4", bg = "#0b1020" },
		WinSeparator = { fg = "#00d9ff" },
		CursorLine = { bg = "#15182a" },
		CursorLineNr = { fg = "#00d9ff", bold = true },
		LineNr = { fg = "#586982" },
		Comment = { fg = "#7688a6", italic = true },
		String = { fg = "#55e4d0" },
		Function = { fg = "#00d9ff" },
		Keyword = { fg = "#f02bd4" },
		Type = { fg = "#58bfff" },
		Visual = { bg = "#382044" },
		['@function'] = { fg = "#00d9ff" },
		['@keyword'] = { fg = "#f02bd4" },
		['@type'] = { fg = "#58bfff" },
	}
elseif active_theme == "Liberty" or active_theme == "liberty" then
	M.base46.hl_override = {
		Normal = { fg = "#eeeeee", bg = "none" },
		NormalNC = { fg = "#d0d0d0", bg = "none" },
		NormalFloat = { fg = "#f0f0f0", bg = "#141414" },
		FloatBorder = { fg = "#c8c8c8", bg = "#141414" },
		WinSeparator = { fg = "#777777" },
		CursorLine = { bg = "#202020" },
		CursorLineNr = { fg = "#ffffff", bold = true },
		LineNr = { fg = "#777777" },
		Comment = { fg = "#999999", italic = true },
		String = { fg = "#cfcfcf" },
		Function = { fg = "#ffffff" },
		Keyword = { fg = "#bdbdbd" },
		Type = { fg = "#e6e6e6" },
		Visual = { bg = "#414141" },
		['@function'] = { fg = "#ffffff" },
		['@keyword'] = { fg = "#bdbdbd" },
		['@type'] = { fg = "#e6e6e6" },
	}
end

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
