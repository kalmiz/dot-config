
let g:plugin_dir = expand('~/.config/nvim/bundle', ':p')
let g:plugin_hash = {}
let g:pathogen_blacklist = []

let g:sql_type_default = 'mysql'

let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_completion_start_length = 3

" Poor man's plugin downloader {{{
if !isdirectory(g:plugin_dir) | call mkdir(g:plugin_dir, "p") | endif

function! DownloadPluginIfMissing(plugin) abort
	let output_dir = g:plugin_dir . '/' . fnamemodify(a:plugin, ":t")
	if isdirectory(output_dir) || !executable('git')
		return
	endif
	let command = printf("git clone -q %s %s", "https://github.com/" . a:plugin . '.git', output_dir)
	echo "DownloadPluginIfMissing: " . command | echo system(command)
	silent! execute 'helptags ' . output_dir . '/doc'
endfunction

function! UpdatePlugin(plugin) abort
	let output_dir = g:plugin_dir . '/' . fnamemodify(a:plugin, ":t")
	if !isdirectory(output_dir) || !executable('git')
		return
	endif
	let command = printf("cd %s && git pull -q", output_dir)
	echo "UpdatePlugin: " . command | echo system(command)
endfunction

function! Pl(...) abort
	for plugin in map(copy(a:000), 'substitute(v:val, ''''''\|"'', "", "g")')
		let g:plugin_hash[ fnamemodify(plugin, ':t') ] = 1
		call DownloadPluginIfMissing(plugin)
	endfor
endfunction

command! -nargs=+ Pl call Pl(<f-args>)
command! -nargs=0 UpdatePlugins call map( keys(g:plugin_hash), 'UpdatePlugin( v:val )' ) | Helptags
" }}}

" Plugins {{{
" SCMs
Pl 'tpope/vim-fugitive'
" Languages
Pl 'fatih/vim-go' 'derekwyatt/vim-scala'
" Linters
Pl 'benekastah/neomake'
" Text objects
Pl 'wellle/targets.vim'
" Tools
Pl 'vim-scripts/dbext.vim' 'mileszs/ack.vim'
Pl 'Shougo/deoplete.nvim'
Pl 'rizzatti/dash.vim'
Pl 'markcornick/vim-terraform'
" }}}

" run pathogen
Pl 'tpope/vim-pathogen'
execute "source " . g:plugin_dir . '/vim-pathogen/autoload/pathogen.vim'
let g:pathogen_blacklist = filter(map(split(glob(g:plugin_dir . '/*', 1), "\n"),'fnamemodify(v:val,":t")'), '!has_key(g:plugin_hash, v:val)')
execute pathogen#infect(g:plugin_dir . '/{}')

if filereadable("/usr/local/opt/fzf/install")
	set rtp+=/usr/local/opt/fzf
endif

" Functions {{{
fun! SbtQuickfix()
	setlocal errorformat=%E\ %#[error]\ %#%f:%l:\ %m,%-Z\ %#[error]\ %p^,%-G\ %#[error]\ %m
	setlocal errorformat+=%W\ %#[warn]\ %#%f:%l:\ %m,%-Z\ %#[warn]\ %p^,%-G\ %#[warn]\ %m
	setlocal errorformat+=%C\ %#%m
	let file = "~/tmp/sbt.quickfix"
	call system("echo -n > " . file . "; for i in `find . | grep sbt.quickfix`; do grep -v '\\[warn\\]' $i >> " . file . "; rm $i; done;")
	exe "cf " . file
endfun
" }}}

" Settings {{{
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~
set hidden
set noswapfile
set visualbell
syn on
set foldmethod=marker
set ai
set noexpandtab sw=4 ts=4 softtabstop=4
set fo+=c
set fo+=r
if exists('+relativenumber')
	set relativenumber
endif
set shell=bash
" }}}

" Mappings {{{
let mapleader = ' '

" Movement
inoremap <C-a> <ESC>I
inoremap <C-e> <ESC>A
nnoremap <Up> -
nnoremap <Down> +
cnoremap <C-a> <Home>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Delete>
cnoremap <M-b> <S-Left>
cnoremap <M-f> <S-Right>
cnoremap <M-d> <S-right><Delete>
cnoremap <Esc>b <S-Left>
cnoremap <Esc>f <S-Right>
cnoremap <Esc>d <S-right><Delete>
cnoremap <C-g> <C-c><Paste>

" Navigation
nnoremap <Leader>. :Ex<CR>
nnoremap <Leader>k :tj 
nnoremap <Leader>b :buffers<CR>:buffer<Space>
nnoremap gb :buffers<CR>:buffer<Space>
nnoremap <Leader>a :Ack 
noremap <Leader>A :Ack <cword><CR>
nnoremap <leader>f :find 
nnoremap <leader>t :FZF<CR> 
nnoremap <Leader>e :e 
nnoremap <Leader>/ :e ../
nnoremap <Leader>m :Neomake<CR>

" Save
nnoremap <Leader>w :update<CR>
nnoremap s :update<CR>
nnoremap S :update<CR>:Neomake<CR>

" Quit
nnoremap <Leader>q :qall<CR>

" Use <C-l> to clear the highlighting of :set hlsearch.
if maparg('<C-L>', 'n') ==# ''
	nnoremap <silent> <C-L> :nohlsearch<CR><C-L>
endif

" Tab
imap <silent><expr> <TAB>
	\ pumvisible() ? "\<C-n>" :
	\ <SID>check_back_space() ? "\<TAB>" :
	\ deoplete#mappings#manual_complete()

function! s:check_back_space()
	let col = col('.') - 1
	return !col || getline('.')[col - 1] =~ '\s'
endfunction

" Git
nnoremap <Leader>gs :Gstatus<CR>
nnoremap <Leader>gp :Git push<CR>
nnoremap <Leader>gl :Git pl<CR>
nnoremap <Leader>gm :Git cm<CR>
nnoremap <Leader>gg :Git 

" Focus window
nnoremap <C-w>z :tab sp<CR>
" Show whitespace
noremap <C-x>w :set list!<CR>
nnoremap <a-j> <c-w>j
nnoremap <a-k> <c-w>k
nnoremap <a-h> <c-w>h
nnoremap <a-l> <c-w>l
nnoremap <a--> <c-w>s
nnoremap <a-\> <c-w>v
nnoremap <a-r> <c-w>r
nnoremap <a-c> <c-w>c
nnoremap <a-;> :
nnoremap <a-q> :bd!<CR>
vnoremap <a-j> <c-\><c-n><c-w>j
vnoremap <a-k> <c-\><c-n><c-w>k
vnoremap <a-h> <c-\><c-n><c-w>h
vnoremap <a-l> <c-\><c-n><c-w>l
vnoremap <a--> <c-\><c-n><c-w>s
vnoremap <a-\> <c-\><c-n><c-w>v
vnoremap <a-r> <c-\><c-n><c-w>r
vnoremap <a-c> <c-\><c-n><c-w>c
vnoremap <a-;> <c-\><c-n>:
vnoremap <a-q> <c-\><c-n>:bd!<CR>
inoremap <a-j> <c-\><c-n><c-w>j
inoremap <a-k> <c-\><c-n><c-w>k
inoremap <a-h> <c-\><c-n><c-w>h
inoremap <a-l> <c-\><c-n><c-w>l
inoremap <a--> <c-\><c-n><c-w>s
inoremap <a-\> <c-\><c-n><c-w>v
inoremap <a-r> <c-\><c-n><c-w>r
inoremap <a-c> <c-\><c-n><c-w>c
inoremap <a-;> <c-\><c-n>:
inoremap <a-q> <c-\><c-n>:bd!<CR>
cnoremap <a-j> <c-\><c-n><c-w>j
cnoremap <a-k> <c-\><c-n><c-w>k
cnoremap <a-h> <c-\><c-n><c-w>h
cnoremap <a-l> <c-\><c-n><c-w>l
cnoremap <a--> <c-\><c-n><c-w>s
cnoremap <a-\> <c-\><c-n><c-w>v
cnoremap <a-r> <c-\><c-n><c-w>r
cnoremap <a-c> <c-\><c-n><c-w>c
cnoremap <a-q> <c-\><c-n>:bd!<CR>
if has('nvim')
	tnoremap <Esc> <c-\><c-n>
	tnoremap <a-j> <c-\><c-n><c-w>j
	tnoremap <a-k> <c-\><c-n><c-w>k
	tnoremap <a-h> <c-\><c-n><c-w>h
	tnoremap <a-l> <c-\><c-n><c-w>l
	tnoremap <a--> <c-\><c-n><c-w>s
	tnoremap <a-\> <c-\><c-n><c-w>v
	tnoremap <a-r> <c-\><c-n><c-w>r
	tnoremap <a-c> <c-\><c-n><c-w>c
	tnoremap <a-;> <c-\><c-n>:
	tnoremap <a-q> <c-\><c-n>:bd!<CR>
	augroup terminal
		au!
		au WinEnter term://* call feedkeys('i') |
	augroup END
endif
" }}}

" Bare bone navigation {{{
set path=src/**,app/**,application/**,public/**,conf/**,subprojects/*/src/**,subprojects/*/app/**,*/src/**,*/app/**,test/**,*/test/**,*/model/src/**,*/logic/src/**,modules/**,subprojects/*/conf/**
set suffixesadd=.java,.scala,.php,.js
set wildmode=longest,full
set wildmenu
set wildignore+=*.class
set wildignore+=*.jar
set wildignore+=*.jpg
set wildignore+=*.png 
set wildignore+=*.gif
set wildignore+=**/tiny_mce_dev/**
set wildignore+=**/target/**
set wildignore+=**/node_modules/**
set wildignore+=node_modules/**
set wildignore+=cscope.*
set wildignore+=.git/**

let g:netrw_list_hide= '\(^\|\s\s\)\zs\.\S\+'
" }}}

" Autocommands {{{
augroup filesettings
	au!
	" When editing a file, always jump to the last known cursor position.
	" Don't do it when the position is invalid or when inside an event
	" handler (happens when dropping a file on gvim).
	au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
		\|	exe "normal g`\""
		\|endif

	au FileType * if &filetype == 'sql'
		\|	exe('setl dict+='.$VIMRUNTIME.'/syntax/'.g:sql_type_default.'.vim')
		\|	setl complete-=t
		\|else
		\|	exe('setl dict+='.$VIMRUNTIME.'/syntax/'.&filetype.'.vim')
		\|endif

	au FileType css setlocal omnifunc=csscomplete#CompleteCSS
	au FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
	au FileType go setlocal omnifunc=go#complete#Complete
	au FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
	au FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
	au FileType yaml setlocal expandtab sw=2 softtabstop=2 ts=2 path=**
	au FileType terraform setlocal expandtab sw=2 softtabstop=2 ts=2
	au FileType dockerfile setlocal path=**

	au BufNewFile,BufRead *.md setlocal ft=markdown

	" Poor man vim-rooter, git only, using fugitive
	au BufLeave * let b:last_cwd = getcwd()
	au BufEnter * if exists('b:last_cwd')
		\|	execute 'lcd ' . b:last_cwd
		\|else
		\|	if exists('b:netrw_curdir')
		\|		execute 'lcd ' . b:netrw_curdir
		\|	else "if getcwd() != $GOPATH
		\|		silent! Glcd
		\|	endif
		\|endif
augroup END
" }}}

" Terminal {{{
function! OpenTerminal(cmd, dir)
    if a:dir == 'r'
        vsplit
        wincmd l
    elseif a:dir == 't'
        split
    elseif a:dir == 'b'
        split
        wincmd j
    elseif a:dir == 'l'
        vsplit
    endif
    execute 'term ' . a:cmd
endfunction

command! -nargs=* Term call OpenTerminal(<f-args>, 'f')
command! -nargs=1 Lterm call OpenTerminal(<f-args>, 'l')
command! -nargs=1 Rterm call OpenTerminal(<f-args>, 'r') 
command! -nargs=1 Tterm call OpenTerminal(<f-args>, 't') 
command! -nargs=1 Bterm call OpenTerminal(<f-args>, 'b')
" }}}

set exrc
set secure
