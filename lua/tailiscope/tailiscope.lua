-- required imports for the telescope api
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local results = require("tailiscope.docs")

_G.tailiscope_config = tailiscope_config or {}

_G.paste = function(value)
	-- vim.notify("value is " .. value)
end

local history = {}
local table_results = nil

local previewer = previewers.new_buffer_previewer({
	define_preview = function(self, entry, status)
		local bufnr = self.state.bufnr
		if entry.value.base then
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { entry.value[2] })
		else
			table_results = require("lua.tailiscope.docs." .. entry.value[2])
			local temp = {}
			for i, v in ipairs(table_results) do
				table.insert(temp, v[1])
			end
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, temp)
		end
	end,
})

local picker = function(filename, opts)
	-- results = table_results or require("lua.tailiscope.docs." .. filename)
	results = require("lua.tailiscope.docs." .. filename)
	opts = opts or {}
	pickers
		.new(opts, {
			previewer = previewer,
			prompt_title = "Search",
			results_title = filename,
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry[1],
						ordinal = entry[1],
					}
				end,
			}),

			layout_config = {
				width = 0.75,
				height = 0.75,
			},

			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				map("n", "b", function()
					if next(history) ~= nil then
						actions.close(prompt_bufnr)
						vim.notify(vim.inspect(history))
						recursive_picker(table.remove(history))
					end
					return true
				end)

				map("i", "<c-b>", function()
					actions.close(prompt_bufnr)
					if next(history) ~= nil then
						vim.notify(vim.inspect(history))
						recursive_picker(table.remove(history))
					end
					return true
				end)

				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection.value.base then
						paste(selection.value[1])
					else
						table.insert(history, filename)
						recursive_picker(selection.value[2])
					end
				end)
				return true
			end,
		})
		:find()
end

_G.recursive_picker = function(filename)
	picker(filename, {})
end

-- https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script
-- I haven't tested this outside of osx but it should work
local getOperatingSystem = function()
	local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
	if BinaryFormat == "dll" then
		function os.name()
			return "Windows"
		end
	elseif BinaryFormat == "so" then
		function os.name()
			return "Linux"
		end
	elseif BinaryFormat == "dylib" then
		function os.name()
			return "MacOS"
		end
	end
	BinaryFormat = nil
end

local open_doc = function(docfile, path)
	path = path or "https://tailwindcss.com/docs/"
	docfile = docfile or "index"
	local prefix = 'open "'
	local _os = getOperatingSystem()
	if _os == "Windows" then
		prefix = 'start "'
	elseif _os == "Linux" then
		prefix = 'xdg-open "'
	end
	local command = prefix .. path .. docfile .. '"'
	os.execute(command)
end

-- picker

-- local recursive_picker = function(opts)
-- 	opts = opts or {}
-- 	pickers.new(opts, {
-- 		previewer = previewer,
-- 		prompt_title = "Tailiscope",
-- 		finder = finders
-- 			.new_table({
-- 				results = results,
-- 				entry_maker = function(entry)
-- 					return {
-- 						value = entry,
-- 						display = entry[1],
-- 						ordinal = entry[1],
-- 					}
-- 				end,
--
-- 				sorter = conf.generic_sorter(opts),
-- 				attach_mappings = function(prompt_bufnr, map)
-- 					actions.select_default:replace(function()
-- 						actions.close(prompt_bufnr)
-- 						local selection = action_state.get_selected_entry()
-- 						local doc = selection.value[2]
-- 						selection.value[2]()
-- 					end)
-- 					return true
-- 				end,
-- 			})
-- 			:find(),
-- 	})
-- end
--
-- local picker = function(opts)
-- 	opts = opts or {}
-- 	local cheat_opt = _G.tailiscope_config.cheatpath or "https://nerdcave.com/tailwind-cheat-sheet"
-- 	local path = _G.tailiscope_config.path or "https://tailwindcss.com/docs/"
-- 	pickers
-- 		.new(opts, {
-- 			previewer = previewer,
-- 			prompt_title = "Tailiscope",
-- 			finder = finders.new_table({
-- 				results = results,
-- 				entry_maker = function(entry)
-- 					return {
-- 						value = entry,
-- 						display = entry[1],
-- 						ordinal = entry[1],
-- 					}
-- 				end,
-- 			}),
--
-- 			layout_config = {
-- 				width = 0.5,
-- 				height = 0.75,
-- 			},
--
-- 			sorter = conf.generic_sorter(opts),
-- 			attach_mappings = function(prompt_bufnr, map)
-- 				actions.select_default:replace(function()
-- 					actions.close(prompt_bufnr)
-- 					local _path = path
-- 					local selection = action_state.get_selected_entry()
-- 					local doc = selection.value[2]
-- 					if doc == "cheat-sheet" then
-- 						_path = cheat_opt
-- 						doc = ""
-- 					end
-- 					open_doc(doc, _path)
-- 				end)
-- 				return true
-- 			end,
-- 		})
-- 		:find()
-- end
--

recursive_picker("base")
return picker
