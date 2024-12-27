
" Settings / Definitions {

    " Settings
    set nocompatible
    set encoding=utf-8
    set belloff=all
    set laststatus=2
    set showcmd
    set ruler
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
    set ssl
    set nowrap
    set incsearch
    set ignorecase
    set smartcase
    set showmode
    set showmatch
    set hlsearch
    set fileformats=unix,dos
    set history=10000
    set updatetime=300
    set cursorline
    set colorcolumn=120
    set shortmess-=S
    set autoread
    set hidden
    set termguicolors
    set wildmenu
    set wildmode=list:longest
    set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
    set runtimepath=~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after
    set packpath=~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after
    set omnifunc=syntaxcomplete#Complete
    set grepprg=git\ grep\ -n\ --column
    set grepformat=%f:%l:%c:%m,%f:%l%c%m,%f\ \ %l%c%m
    if executable("rg")
        set grepprg=rg\ --vimgrep
    endif
    if &shell ==# "sh"
        set shell=bash
    endif

    " Definitions & Misc.
    let mapleader = " "
    let &t_SI = "\e[5 q"
    let &t_EI = "\e[1 q"
    let g:netrw_banner = 0
    let g:netrw_dirhistmax = 0
    let g:netrw_localcopydircmd = 'cp -r'
    filetype on
    filetype indent on
    filetype plugin on
    syntax on
    colorscheme habamax
    highlight ColorColumn ctermbg=gray
    highlight CursorLine cterm=none

"}

" Keymappings {

    " Leader Mappings
    nnoremap <Leader>l :pwd<CR>
    nnoremap <Leader>b :ClearBufs<CR>:ls<CR>:b<Space>
    nnoremap <Leader>v :DiffOrig<CR>
    nnoremap <Leader>V :windo diffthis<CR>
    nnoremap <Leader>r viw"hy:%s/<C-r>h\C//g<left><left>
    nnoremap <Leader>R viW"hy:%s/<C-r>h\C//g<left><left>
    vnoremap <Leader>r "hy:%s/<C-r>h\C//g<left><left>
    vnoremap <Leader>* y/\V<C-R>=escape(@",'/\')<CR>\C<CR>
    vnoremap <Leader>y "*y
    vnoremap <Leader>Y "*Y
    nnoremap <silent> <Leader>m :set cursorline!<CR>
    nnoremap <silent> <Leader>n :call ToggleNumberLines("all")<CR>
    nnoremap <silent> <Leader>N :call ToggleNumberLines("friendly")<CR>
    nnoremap <silent> <Leader>e :Explore<CR>
    nnoremap <silent> <Leader>EE :set fileformat?<CR>
    nnoremap <silent> <Leader>Ee :set fileformat?<CR>
    nnoremap <silent> <Leader>Eu :edit ++ff=unix<CR>
    nnoremap <silent> <Leader>Ed :edit ++ff=dos<CR>
    nnoremap <silent> <Leader>Em :edit ++ff=mac<CR>
    nnoremap <silent> <Leader>t :below terminal ++rows=10 ++close bash<CR>
    nnoremap <silent> <Leader>T :silent tabedit %<CR>
    nnoremap <silent> <Leader>o :silent edit ~/.vimrc<CR>
    nnoremap <silent> <Leader>O :source ~/.vimrc<CR>:noh<CR>
    nnoremap <silent> <Leader>i :silent enew<CR>
    nnoremap <silent> <Leader>I :silent tabnew<CR>
    nnoremap <silent> <Leader>d :silent bdelete<CR>:ClearBufs<CR>
    nnoremap <silent> <Leader>D :silent bdelete!<CR>:ClearBufs<CR>
    nnoremap <silent> <Leader>B :bufdo bdelete<CR>
    nnoremap <silent> <Leader>y "*y
    nnoremap <silent> <Leader>Y ^"*yg_
    nnoremap <silent> <Leader>p "*p
    nnoremap <silent> <Leader>P "*P
    nnoremap <silent> <Leader>k K
    vnoremap <silent> <Leader>k K
    nnoremap <silent> <Leader>L :silent %s/\r//g<CR>:noh<CR><C-o>
    nnoremap <silent> <Leader>w :w<CR>
    nnoremap <silent> <Leader>W :w<CR>:!dos2unix "%"<CR><CR>
    nnoremap <silent> <Leader>q :q<CR>
    nnoremap <silent> <Leader>Q :qall!<CR>
    nnoremap <silent> <Leader>c :call ToggleQuickFix()<CR>
    nnoremap <silent> <Leader>C :cclose<CR>:silent cfdo bdelete<CR>:silent cfirst<CR>:silent bdelete<CR>

    " Keyboard Mappings
    nnoremap <silent> <esc> :noh<CR>:echo<CR><esc>
    nnoremap <silent> <PageDown> :ClearBufs<CR>:silent bnext<CR>
    nnoremap <silent> <PageUp> :ClearBufs<CR>:silent bprevious<CR>
    nnoremap <silent> <End> :ClearBufs<CR>:silent bprevious<CR>
    nnoremap <silent> <C-PageUp> :cfirst<CR>zv
    nnoremap <silent> <C-PageDown> :clast<CR>zv
    nnoremap <silent> <S-l> :ClearBufs<CR>:silent bnext<CR>
    nnoremap <silent> <S-h> :ClearBufs<CR>:silent bprevious<CR>
    nnoremap <silent> <S-right> :ClearBufs<CR>:silent bnext<CR>
    nnoremap <silent> <S-left> :ClearBufs<CR>:silent bprevious<CR>
    nnoremap <silent> <C-right> :silent tabnext<CR>
    nnoremap <silent> <C-left> :silent tabprevious<CR>
    nnoremap <silent> <C-N> :cnext<CR>zv
    nnoremap <silent> <C-P> :cprevious<CR>zv
    nnoremap <C-d> <C-d>zz
    nnoremap <C-u> <C-u>zz
    noremap <C-h> <C-w>h
    noremap <C-j> <C-w>j
    noremap <C-k> <C-w>k
    noremap <C-l> <C-w>l
    tnoremap <C-h> <C-w>h
    tnoremap <C-j> <C-w>j
    tnoremap <C-k> <C-w>k
    tnoremap <C-l> <C-w>l
    tnoremap <C-n> <C-w>N
    tnoremap <esc> <C-w>N
    nnoremap <C-down> :m .+1<CR>==
    nnoremap <C-up> :m .-2<CR>==
    vnoremap <C-down> :m '>+1<CR>gv=gv
    vnoremap <C-up> :m '<-2<CR>gv=gv
    vnoremap <silent> <C-s> :sort<CR>
    nnoremap U <C-r>
    nnoremap Y ^yg_
    nnoremap J 5j
    nnoremap K 5k
    vnoremap J 5j
    vnoremap K 5k

"}

" Autocmds {

    " Netrw automatic buffer deletion
    augroup netrw
        autocmd!
        autocmd FileType netrw setlocal bufhidden=wipe
    augroup end

    " Set syntax for custom file formats
    au BufReadPost .bash_* set syntax=bash

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

    " Bash terminal Shortcut aliases
    function! BashTerminal(...)
        let args = a:000
        if args[0] ==# ""
            below terminal ++rows=10 ++close bash
        elseif match(args[0], "^/") == 0
            execute 'below terminal ++rows=10 ++close bash --rcfile ~/.bashrc -ci "cd ' .. args[0] .. '; exec bash"'
        elseif match(args[0], "^\\.") == 0
            let path = expand("%:p:h") .. "/" .. args[0]
            execute 'below terminal ++rows=10 ++close bash --rcfile ~/.bashrc -ci "cd ' .. path .. '; exec bash"'
        else
            execute 'below terminal ++rows=10 bash --rcfile ~/.bashrc -ci "' .. args[0] .. '"'
        endif
        echo
    endfunction
    command! -nargs=? Terminal call BashTerminal(<q-args>)
    command! -nargs=? Term call BashTerminal(<q-args>)
    cabbrev terminal Terminal
    cabbrev term Term

    " Close empty no name file buffers with no content upon switching buffer
    function! ClearEmptyBufs()
        silent! execute 'bd' g:next_empty_buf
    endfunction
    augroup CloseEmptyBuffers
        autocmd!
        autocmd Bufleave * if expand('%') == "" | let g:next_empty_buf = bufnr('%') | endif
    augroup end
    command! ClearBufs call ClearEmptyBufs()

    " Adding DiffOrig command back if missing
    command! DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis | wincmd p | diffthis

"}

" GVim settings {
    if has("gui_running")
        set gcr=n-v-c:block-Cursor
            \/lCursor-blinkwait500-blinkon500-blinkoff500,ve:ver35-Cursor,o:hor50-Cursor,i-ci:ver25-Cursor
            \/lCursor-blinkwait500-blinkon500-blinkoff500,r-cr:hor20-Cursor
            \/lCursor-blinkwait500-blinkon500-blinkoff500,sm:block-Cursor-blinkwait100-blinkoff500-blinkon500
        highlight Cursor guifg=#222222 guibg=#ffffff
        set guifont=JetBrains\ Mono\ NL:h13:cANSI:qDRAFT
        set guitablabel=%t
        set guioptions-=t
        set laststatus=1
        set backspace=2
        set scrolloff=0
        set guioptions+=!
        set guioptions-=T
        set mouse=a
    endif
"}

" Misc. {

    " Custom plugin settings sourced if it exists
    if filereadable(expand("~/.vimrc_plugins"))
        source ~/.vimrc_plugins
    endif

"}
