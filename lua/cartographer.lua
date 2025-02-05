--- The current
local version = vim.version()

--- The Cargorapher Lua-callbacks registrant
--- TODO: delete this module when `0.7` is stabilized
--- @type Cartographer.Callbacks|nil
local Callbacks = (version.major == 0 and version.minor < 7) and require 'cartographer.callbacks'

--- Return an empty table with all necessary fields initialized.
--- @return table
local function new() return {_modes = {}} end

--- Make a deep copy of opts table
--- @param tbl table the table to copy
--- @return table copy
local function copy(tbl)
	local new_tbl = new()

	for key, val in pairs(tbl) do
		if key ~= '_modes' then new_tbl[key] = val
		else for i, mode in ipairs(tbl._modes) do new_tbl._modes[i] = mode end
		end
	end

	return new_tbl
end

--- A fluent interface to create more straightforward syntax for Lua |:map|ping and |:unmap|ping.
--- @class Cartographer
--- @field buffer number the buffer to apply the keymap to.
--- @field _modes table the modes to apply a keymap to.
local Cartographer = {}

function Cartographer:Delegate(fn)
  self.delegate = fn; return self
end
--- Set `key` to `true` if it was not already present
--- @param key string the setting to set to `true`
--- @returns table self so that this function can be called again
function Cartographer:__index(key)
	self = copy(self)

	if #key < 2 then -- set the mode
		self._modes[#self._modes+1] = key
	elseif #key > 5 and key:sub(1, 1) == 'b' then -- PERF: 'buffer' is the only 6-letter option starting with 'b'
		self.buffer = #key > 6 and tonumber(key:sub(7)) or 0 -- NOTE: 0 is the current buffer
	else -- the fluent interface
		self[key] = true
	end

	return setmetatable(self, Cartographer)
end

--- Set a `lhs` combination of keys to some `rhs`
--- @param lhs string the left-hand side |key-notation| which will execute `rhs` after running this function
--- @param rhs string|nil if `nil`, |:unmap| lhs. Otherwise, see |:map|.
function Cartographer:__newindex(lhs, rhs)
	local buffer = rawget(self, 'buffer')
	local modes = rawget(self, '_modes')
	modes = #modes > 0 and modes or {''}

	if rhs then
		local opts =
		{
			expr = rawget(self, 'expr'),
			noremap = rawget(self, 'nore'),
			nowait = rawget(self, 'nowait'),
			script = rawget(self, 'script'),
			silent = rawget(self, 'silent'),
			unique = rawget(self, 'unique'),
		}

    local  delegate = self.delegate() or vim.api.nvim_set_keymap()

		if type(rhs) == 'function' then
			if Callbacks then -- TODO: remove when `0.7` is stabilized
				local id = Callbacks.new(rhs)
				rhs = opts.expr and
					'luaeval("require(\'cartographer.callbacks\')['..id..']")()' or
					'<Cmd>lua require("cartographer.callbacks")['..id..']()<CR>'
			else
				opts.callback = rhs
				rhs = ''
			end
			opts.noremap = true
		end

		if buffer then
			for _, mode in ipairs(modes) do
				vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
			end
		else
			for _, mode in ipairs(modes) do
        delegate(buffer, mode, lhs, rhs, opts)
      end
		end
	else
		if buffer then
			for _, mode in ipairs(modes) do
				vim.api.nvim_buf_del_keymap(buffer, mode, lhs)
			end
		else
			for _, mode in ipairs(modes) do
				vim.api.nvim_del_keymap(mode, lhs)
			end
		end
	end
end

return setmetatable(new(), Cartographer)
