syntax on
set number
set mouse=a
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent
set ignorecase
set hlsearch

" Use system clipboard
set clipboard+=unnamedplus

" Vertical ruler
:set colorcolumn=80
:highlight ColorColumn ctermbg=DarkGray guibg=DarkGray

" Plugin definitions
call plug#begin()

Plug 'ibhagwan/fzf-lua', {'branch': 'main'}
Plug 'kyazdani42/nvim-web-devicons'

Plug 'sakhnik/nvim-gdb', { 'do': ':!./install.sh' }

" Need to install 'sudo apt install --yes -- python3-venv' for this to work
Plug 'ms-jpq/chadtree', {'branch': 'chad', 'do': 'python3 -m chadtree deps'}

" Initialize plugin system
call plug#end()

" Ctrl+P fzf mapping
nnoremap <c-P> <cmd>lua require('fzf-lua').files({ fzf_opts = { ['--border'] = false }})<CR>

" Ctrl+E CHADopen
nnoremap <c-E> <cmd>CHADopen<CR>

