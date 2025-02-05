# nvim-cartographer

This is a plugin for Neovim which aims to simplify setting and deleting with keybindings / mappings in Lua The target audience is users who are trying to port from an `init.vim` to an `init.lua` following the release of Neovim 0.5.

Here is an example:

```lua
-- This is how you map with the Neovim API
vim.api.nvim_set_keymap('n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', {noremap=true, silent=true})

-- This is how you do that with `nvim-cartographer`
map.n.nore.silent['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

## Installation

This plugin can be installed with any plugin manager. I use [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
local fn = vim.fn

local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'

if not vim.loop.fs_stat(fn.glob(install_path)) then
	os.execute('git clone https://github.com/wbthomason/packer.nvim '..install_path)
end

vim.api.nvim_command 'packadd packer.nvim'

return require('packer').startup {function(use)
	use {'wbthomason/packer.nvim', opt=true}
	use 'Iron-E/nvim-cartographer'
end}
```

## Usage

To import this plugin, add the following line to the top of any file you wish to use this plugin in:

```lua
local map = require 'cartographer'
```

This plugin implements a builder to make toggling options as easy as possible. You may specify zero to one of `nvim_set_keymap`'s `mode` argument (i.e. you can `map.x` or `map`). It also supports all of the `:h :map-arguments`. `nore` is used to perform a non-recursive `:map`. The ordering of arguments is not important:

```lua
assert(vim.deep_equal(map.n.nore.silent.unique, map.silent.n.unique.nore))
```

Here is an example:

```lua
-- `:map` 'gt' in normal mode to searching for symbol references with the LSP
map.n.nore.silent.unique['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

The above is equivalent to the following VimL:

```vim
" This is how you bind `gr` to the builtin LSP symbol-references command
nnoremap <silent><unique> gr <Cmd>lua vim.lsp.buf.references()<CR>
```

### Buffer-Local Mapping

You can create mappings for specific buffers:

```lua
local nnoremap = map.n.nore.silent

-- Only buffer sets map to current buffer
nnoremap.buffer['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'

-- You can specify bufnr like <bufer=n>
-- This keymap will be set for buffer 3
nnoremap.buffer3['gr'] = '<Cmd>lua vim.lsp.buf.references()<CR>'
```

### Lua Functions

You can also register `local` lua `function`s to mappings, rather than attempt to navigate `v:lua`/`luaeval` bindings:

```lua
local api = vim.api
local go = vim.go

local function float_term()
	local buffer = api.nvim_create_buf(false, true)
	local window = api.nvim_open_win(buffer, true,
	{
		relative = 'cursor',
		height = math.floor(go.lines / 2),
		width = math.floor(go.columns / 2),
		col = 0,
		row = 0,
	})
	api.nvim_command 'terminal'
end

map.n.nore.silent['<Tab>'] = float_term
```

### Multiple Modes

You can `:map` to multiple `modes` if necessary.

```lua
-- Map `gr` to LSP symbol references in 'x' and 'n' modes.
map.n.x.nore.expr['<Tab>'] = 'pumvisible() ? "\\<C-n>" : check_backspace() ? "\\<Tab>" : compe#complete()'
```

### Unmapping

You can `:unmap` as well by setting a `<lhs>` to `nil` instead of any `<rhs>`:

```lua
-- `:unmap` 'zfo' in `x` mode
map.x['zfo'] = nil
```

