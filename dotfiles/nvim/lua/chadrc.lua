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

local palettes = {
	liberty = { bg = "#141414", fg = "#eeeeee", muted = "#999999", surface = "#202020", primary = "#ffffff", secondary = "#bdbdbd", string = "#cfcfcf", type = "#e6e6e6", visual = "#414141" },
	["johan-neon"] = { bg = "#0b1020", fg = "#d9eaff", muted = "#7688a6", surface = "#15182a", primary = "#00d9ff", secondary = "#f02bd4", string = "#55e4d0", type = "#58bfff", visual = "#382044" },
	["arch-blue"] = { bg = "#080e1b", fg = "#d8eaff", muted = "#7188a8", surface = "#14233a", primary = "#31b7ff", secondary = "#9f9ce8", string = "#7de0cb", type = "#54d8ff", visual = "#183654" },
	["skull-teal"] = { bg = "#0a1517", fg = "#e2efeb", muted = "#809b92", surface = "#17312e", primary = "#70d3b5", secondary = "#e8b870", string = "#a9d79c", type = "#70d3b5", visual = "#27473d" },
	["dusk-city"] = { bg = "#10121c", fg = "#e8efff", muted = "#818ba9", surface = "#252b40", primary = "#89dceb", secondary = "#f38ba8", string = "#a6e3a1", type = "#89b4fa", visual = "#3b3458" },
}

local active_key = active_theme:lower():gsub("%s*%b()", ""):gsub("%s+", "-")
if active_key == "skull" then active_key = "skull-teal" end
if active_key == "liberty-monochrome" then active_key = "liberty" end
local palette = palettes[active_key]
if palette then
	M.base46.hl_override = {
		Normal = { fg = palette.fg, bg = "none" },
		NormalNC = { fg = palette.fg, bg = "none" },
		NormalFloat = { fg = palette.fg, bg = palette.bg },
		FloatBorder = { fg = palette.secondary, bg = palette.bg },
		WinSeparator = { fg = palette.primary },
		CursorLine = { bg = palette.surface },
		CursorLineNr = { fg = palette.primary, bold = true },
		LineNr = { fg = palette.muted },
		Comment = { fg = palette.muted, italic = true },
		String = { fg = palette.string },
		Function = { fg = palette.primary },
		Keyword = { fg = palette.secondary },
		Type = { fg = palette.type },
		Visual = { bg = palette.visual },
		["@function"] = { fg = palette.primary },
		["@keyword"] = { fg = palette.secondary },
		["@type"] = { fg = palette.type },
	}
else
	local custom_palette_path = os.getenv("HOME") .. "/.config/hypr/nvim-theme.lua"
	local ok, custom_palette = pcall(dofile, custom_palette_path)
	if ok and type(custom_palette) == "table" then
		M.base46.hl_override = custom_palette
	end
end

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
