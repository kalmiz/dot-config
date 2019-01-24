" Base settings {{{ vim: set foldmethod=marker :
runtime defaults.vim
set secure
set shiftwidth=2
set softtabstop=2
set tabstop=2
set hidden
set formatoptions+=r
set title titlestring="%f %a%r%m"
set iskeyword+=-
set ignorecase
set smartcase
if has("persistent_undo")
	set noswapfile undofile undodir=~/.vim/undodir/ 
endif
set wildmode=list:longest,full
set wildignore+=*.class,*.jar,*.jpg,*.png,*.gif,**/target/**,**/node_modules/**,node_modules/**,cscope.*,.git/**,.idea/**
set wildignorecase
set wildcharm=<C-z>
" }}}

" Plugins and settings {{{ 
if has('nvim') | set packpath^=~/.vim | else | packadd! matchit | endif

let g:has_fzf = 1
if filereadable("/usr/local/opt/fzf/install")
	set rtp+=/usr/local/opt/fzf
elseif filereadable($HOME . "/.fzf/install")
	set rtp+=$HOME/.fzf
else
	let g:has_fzf = 0
endif

if executable('rg')
	set grepprg=rg\ --vimgrep\ --no-heading
	set grepformat=%f:%l:%c:%m
elseif executable('ack')
	set grepprg=ack\ --nogroup\ --nocolor\ --ignore-case\ --column
	set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

let g:netrw_list_hide='\(^\|\s\s\)\zs\.\S\+'
let g:sql_type_default = 'mysql'
let g:ftplugin_sql_omni_key = '<C-z>'
" }}}

" Functions {{{
function! PackInit() abort
	packadd minpac 

	if exists('*minpac#init')
		call minpac#init()
		call minpac#add('k-takata/minpac', {'type': 'opt'})
		call minpac#add('tpope/vim-rsi')
		call minpac#add('tpope/vim-repeat')
		call minpac#add('tpope/vim-commentary')
		call minpac#add('tpope/vim-surround')
		call minpac#add('tpope/vim-fugitive')
		call minpac#add('tpope/vim-rhubarb')
		call minpac#add('hauleth/asyncdo.vim')
		call minpac#add('RRethy/vim-quickscope')
		call minpac#add('kalmiz/vim-play')
		call minpac#add('maralla/completor.vim')
	else
		call system('git clone https://github.com/k-takata/minpac.git ~/.vim/pack/minpac/opt/minpac')
		throw 'minpac has been installed, please restart Vim'
	endif
endfunction

function! Pack(cmd) abort
	try
		if !exists('g:loaded_minpac')
			call PackInit()
		endif
		if a:cmd == 'clean'
			call minpac#clean()
		elseif a:cmd == 'update'
			call minpac#update('', {'do': 'call minpac#status()'})
		else
			call minpac#status()
		endif
	catch /^minpac
		echomsg v:exception
	endtry
endfunction

function! s:get_visual_selection() abort
	" Why is this not a built-in Vim script function?!
	let [lnum1, col1] = getpos("'<")[1:2]
	let [lnum2, col2] = getpos("'>")[1:2]
	let lines = getline(lnum1, lnum2)
	let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][col1 - 1:]
	return join(lines, "\n")
endfunction

function! Xcopy(cmd) range
	if a:cmd != ''
		let command = a:cmd
	else
		let command = 'wxcopy --clear-selection'
	endif
	return system('echo -n '.shellescape(s:get_visual_selection()).'|' . command)
endfunction

" Highlight all instances of word under cursor, when idle.
function! AutoHighlightToggle() abort
	let @/ = ''
	if exists('#auto_highlight')
		au! auto_highlight
		augroup! auto_highlight
		setl updatetime=4000
		echo 'Highlight current word: off'
		return 0
	else
		augroup auto_highlight
			au!
			au CursorHold * let @/ = '\V\<'.escape(expand('<cword>'), '\').'\>'
		augroup end
		setl updatetime=500
		echo 'Highlight current word: ON'
		return 1
	endif
endfunction
" }}}

" Commands {{{
command! PackUpdate call Pack('update')
command! PackClean  call Pack('clean')
command! PackStatus call Pack('status')
command! -range=% TB <line1>,<line2>w !nc termbin.com 9999 | tee /tmp/termbin.com
if has('macunix')
	command! -range=% Xcopy <line1>,<line2>call Xcopy('pbcopy')
else
	command! -range=% Xcopy <line1>,<line2>call Xcopy('')
endif
command! -nargs=+ Find edit __find__ | setl bt=nofile bh=hide nobl | %!rg --files | rg <args>
command! -nargs=0 Ctags !ctags .
command! -nargs=0 -bar JavaDoc silent execute('!ivy-doc-viewer.sh') | redraw!
command! -nargs=0 -bar JavaClass silent execute('!ivy-class-search.sh ' . shellescape(expand('<cword>'))) | redraw!
command! -bang -nargs=* -complete=file Make call asyncdo#run(<bang>0, &makeprg, <f-args>)
" }}}

" Mappings {{{
let mapleader = ' '
nnoremap <Up> :
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
nnoremap <Leader>1 :!
nnoremap <Leader>. :Ex<CR>
cnoremap %% <C-R>=fnameescape(expand('%:h')).'/'<cr>
map <leader>ew :e %%
map <leader>es :sp %%
map <leader>ev :vsp %%
map <leader>et :tabe %%
nnoremap <Leader>a :silent grep  \| copen<Left><Left><Left><Left><Left><Left><Left><Left>
if executable('rg')
	nnoremap <Leader>A :silent grep <cword> -t<C-r>=&filetype<CR> \| copen<CR>
else
	nnoremap <Leader>A :silent grep <cword> --type=<C-r>=&filetype<CR> \| copen<CR>
endif
nnoremap <Leader>f :find 
nnoremap <Leader>l :Lines<CR> 
if has('nvim')
	nnoremap <Leader>s :below 15sp term://bash<CR>i
else
	nnoremap <Leader>s :below term ++rows=15 ++close bash --login<CR>
	nnoremap <Leader>S :vertical rightbelow term ++cols=80 ++close bash --login<CR>
endif
nnoremap <Leader>k :tj 
nnoremap <Leader>m :make<CR>
nnoremap <Leader>t :FZF<CR>
nnoremap <C-C> :update<CR>
inoremap <C-c> <C-o>:update<CR>
nnoremap z/ :if AutoHighlightToggle()<Bar>set hls<Bar>endif<CR>
nnoremap Q @q
xnoremap <Leader>y :Xcopy<CR>
if has('nvim')
	tnoremap <C-w> <C-\><C-n><C-w>
	augroup nterm
		au!
		au TermOpen * setlocal nonumber norelativenumber | if expand("%:p") =~ '^term://.//\d\+:git' | nnoremap <buffer> q :bd!<CR> | endif
	augroup END
endif
nnoremap <Leader>b :buffers<CR>:buffer<Space>
nnoremap <Leader>gs :Gstatus<CR>
nnoremap <Leader>gp :Git push<CR>
nnoremap <Leader>gP :exe 'Git push --set-upstream origin ' . system('git symbolic-ref --short HEAD')<CR>
nnoremap <Leader>gl :Git pl<CR>
nnoremap [q :cprev<CR>
nnoremap ]q :cnext<CR>
nnoremap [l :lprev<CR>
nnoremap ]l :lnext<CR>
nnoremap [b :bprev<CR>
nnoremap ]b :bnext<CR>
nnoremap ]u :later<CR>
nnoremap [u :earlier<CR>
" Show whitespace
nnoremap <C-x>w :set list!<CR>
" Toggle paste
nnoremap <C-x>p :set paste!<CR>
" Redraw screen and de-highlighting the matches,
" fixing syntax highlighting,
" updating the syntax highlighting in diff mode
nnoremap <Leader>l :nohlsearch<CR>:diffupdate<CR>:syntax sync fromstart<CR><C-l>
" }}}

" Autocommands {{{
if &diff
	set cursorline
endif
augroup CustomColors
	au!
	" better matching parens
	hi MatchParen cterm=bold ctermbg=none ctermfg=magenta
augroup END
augroup filesettings
	au!
	" Keep window position when switching buffers
	" https://stackoverflow.com/questions/4251533/vim-keep-window-position-when-switching-buffers
	au BufLeave * let b:winview = winsaveview()
	au BufEnter * if(exists('b:winview')) | call winrestview(b:winview) | endif

	au FileType vim setlocal path=.,$VIMRUNTIME
	au FileType sh setlocal makeprg=bash\ -n efm=%f:\ line\ %l:\ %m keywordprg=:Man | runtime ftplugin/man.vim
	au FileType conf setlocal suffixesadd=.conf

	au FileType javascript setlocal makeprg=./node_modules/.bin/eslint\ -f\ compact efm=%E%f:\ line\ %l\\,\ col\ %c\\,\ Error\ -\ %m,%-G%.%#,%W%f:\ line\ %l\\,\ col\ %c\\,\ Warning\ -\ %m,%-G%.%#
	"au FileType javascript if expand("%:p:h") =~ 'Projects/fmg' | setlocal et | endif

	au VimEnter * if expand('%') == '' && filereadable('build.sbt') | setlocal ft=scala | endif

	au BufNewFile,BufRead *.md setlocal ft=markdown
	au BufNewFile,BufRead *.es6 setlocal ft=javascript

	" Show mixed whitespaces
	au BufWritePre * if search('^' . (&expandtab ? '	' : ' '), 'wn') > 0 | setlocal list | endif

	" Linting
	au BufWritePost *.scala,*.js,*.sh silent Make! <afile>
	au QuickFixCmdPost [^l]* cwindow
augroup END

augroup templates
	au!
	" read in template files
	au BufNewFile *_deployment.yaml silent! execute '0r $HOME/.config/nvim/templates/skeleton-k8s-deployment.yaml'
	au BufNewFile *_service.yaml silent! execute '0r $HOME/.config/nvim/templates/skeleton-k8s-service.yaml'
	au BufNewFile *.* silent! execute '0r $HOME/.config/nvim/templates/skeleton.'.expand("<afile>:e") | retab

	" parse special text in the templates after the read
	au BufNewFile * %substitute#\[:VIM_EVAL:\]\(.\{-\}\)\[:END_EVAL:\]#\=eval(submatch(1))#ge
augroup END
" }}}
