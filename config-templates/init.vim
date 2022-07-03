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

" Show trailing whitepace and spaces before a tab:
:highlight ExtraWhitespace ctermbg=red guibg=red
:autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/

" Plugin definitions
call plug#begin()

Plug 'tpope/vim-sensible'

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

" Wildcard options
set wildmode=longest,list,full
set wildmenu

" Esc to go back to normal mode from terminal
tnoremap <Esc> <C-\><C-n>

" Faster window navigation
nnoremap <C-h> <C-w><C-h>
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>
nnoremap <C-l> <C-w><C-l>
nnoremap <C-Left> <C-w><C-h>
nnoremap <C-Down> <C-w><C-j>
nnoremap <C-Up> <C-w><C-k>
nnoremap <C-Right> <C-w><C-l>

" Faster buffer switch
nnoremap <C-b> <cmd>bp<CR>
nnoremap <C-n> <cmd>bn<CR>
nnoremap <C-X> <cmd>bd<CR>

" Switch to visual mode when shift-arrow-keys
inoremap <S-Down> <Esc>v<Down>
nnoremap <S-Down> <Esc>v<Down>
inoremap <S-Up> <Esc>v<Up>
nnoremap <S-Up> <Esc>v<Up>
inoremap <S-Left> <Esc>v<Left>
nnoremap <S-Left> <Esc>v<Left>
inoremap <S-Right> <Esc>v<Right>
nnoremap <S-Right> <Esc>v<Right>
vnoremap <S-Down> <Down>
vnoremap <S-Up> <Up>

" Save habit
inoremap <C-s> <cmd>:w<CR>
nnoremap <C-s> <cmd>:w<CR>

