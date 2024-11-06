
" Settings / Definitions {

    " Settings
    set nocompatible
    set encoding=utf-8
    set belloff=all
    set showcmd
    set number
    set relativenumber
    set clipboard=
    set shiftwidth=4
    set tabstop=4
    set softtabstop=4
    set autoindent
    set smartindent
    set expandtab
    set scrolloff=10
    set nowrap
    set incsearch
    set ignorecase
    set smartcase
    set showmode
    set showmatch
    set hlsearch
    set history=10000
    set cursorline
    set colorcolumn=120
    set shortmess-=S
    set autoread
    set hidden
    set termguicolors
    set wildmenu
    set wildmode=list:longest
    set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
    set gp=git\ grep\ -n\ --column

    " Definitions & Misc.
    let mapleader = " "
    let &t_SI = "\e[5 q"
    let &t_EI = "\e[1 q"
    let g:netrw_banner = 0
    let g:netrw_dirhistmax=0
    let g:netrw_localcopydircmd = 'cp -r'
    filetype on
    filetype indent on
    filetype plugin on
    set omnifunc=syntaxcomplete#Complete
    syntax on
    colorscheme habamax
    highlight ColorColumn ctermbg=gray
    highlight CursorLine cterm=none

"}

" Keymappings {

    " Leader Mappings
    nnoremap <Leader>p :pwd<CR>
    nnoremap <Leader>b :ls<CR>
    nnoremap <Leader>v :DiffOrig<CR>
    nnoremap <Leader>V :windo diffthis<CR>
    nnoremap <Leader>r viw"hy:%s/<C-r>h\C//g<left><left>
    nnoremap <Leader>R viW"hy:%s/<C-r>h\C//g<left><left>
    vnoremap <Leader>r "hy:%s/<C-r>h\C//g<left><left>
    vnoremap <Leader>y "*y
    nnoremap <silent> <Leader>n :call ToggleNumberLines("all")<CR>
    nnoremap <silent> <Leader>N :call ToggleNumberLines("friendly")<CR>
    nnoremap <silent> <Leader>e :Explore %:p:h<CR>
    nnoremap <silent> <Leader>d :bdelete<CR>
    nnoremap <silent> <Leader>D :bdelete!<CR>
    nnoremap <silent> <Leader>B :bufdo bdelete<CR>
    nnoremap <silent> <Leader>y "*y
    nnoremap <silent> <Leader>Y ^"*yg_
    nnoremap <silent> <Leader>w :w<CR>
    nnoremap <silent> <Leader>q :q<CR>
    nnoremap <silent> <Leader>Q :qall!<CR>
    nnoremap <silent> <Leader>c :call ToggleQuickFix()<CR>
    nnoremap <silent> <Leader>C :cclose<CR>:silent cfdo bdelete<CR>:silent cfirst<CR>:silent bdelete<CR>

    " Keyboard Mappings
    nnoremap <silent> <esc> :noh<cr><esc>
    nnoremap <silent> <PageDown> :bnext<CR>
    nnoremap <silent> <PageUp> :bprevious<CR>
    nnoremap <silent> <C-PageDown> :cfirst<CR>zvzz
    nnoremap <silent> <C-PageUp> :clast<CR>zvzz
    nnoremap <silent> <S-l> :bnext<CR>
    nnoremap <silent> <S-h> :bprevious<CR>
    nnoremap <silent> <C-right> :bnext<CR>
    nnoremap <silent> <C-left> :bprevious<CR>
    nnoremap <silent> <C-N> :cnext<CR>zvzz
    nnoremap <silent> <C-P> :cprevious<CR>zvzz
    nnoremap <C-d> <C-d>zz
    nnoremap <C-u> <C-u>zz
    noremap <C-h> <C-w>h
    noremap <C-j> <C-w>j
    noremap <C-k> <C-w>k
    noremap <C-l> <C-w>l
    nnoremap <C-down> :m .+1<CR>==
    nnoremap <C-up> :m .-2<CR>==
    vnoremap <C-down> :m '>+1<CR>gv=gv
    vnoremap <C-up> :m '<-2<CR>gv=gv
    nnoremap Y ^yg_

"}

" Autocmds {

    " Netrw automatic buffer deletion
    augroup netrw
        autocmd!
        autocmd FileType netrw setlocal bufhidden=wipe
    augroup end

"}

" Functions {

    " Quickfix list toggle with preferred settings
    function! ToggleQuickFix()
        if empty(filter(getwininfo(), 'v:val.quickfix'))
            copen
        else
            cclose
        endif
    endfunction

    " Line number toggle with different modes for friendly line view or hiding all
    function! ToggleNumberLines(mode)
        if a:mode == "friendly"
            if &number == "nonumber" && &relativenumber == "relativenumber"
                set number
                set norelativenumber
            else
                set number
                set relativenumber!
            endif
        elseif a:mode == "all"
            if &number == "nonumber" || &relativenumber == "norelativenumber"
                set number
                set relativenumber
            else
                set nonumber
                set norelativenumber
            endif
        endif
    endfunction

"}
