" Base settings {{{
set et sw=4 sts=4 ts=4 hidden ruler showcmd fdm=marker shell=bash bs=2 fo+=r
set title titlestring="%F %a%r%m"
if exists('+relativenumber')
    set relativenumber
endif
set number
if has("persistent_undo")
    set noswapfile undofile undodir=~/.vim/undodir/ 
endif
filetype plugin indent on
syntax on
if has('nvim')
    let $VISUAL = 'nvr -cc split --remote-wait'
endif
" }}}

" Bare bone navigation {{{
set path=**
set suffixesadd=.conf,.java,.scala,.php,.js,.yaml
set wildmode=list:longest,full
set wildmenu
set wildignore+=*.class,*.jar,*.jpg,*.png,*.gif,**/tiny_mce_dev/**,**/target/**,**/node_modules/**,node_modules/**,cscope.*,.git/**,.idea/**
set wildignorecase

let g:netrw_list_hide='\(^\|\s\s\)\zs\.\S\+'
" }}}

" {{{ Plugins
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

let g:PLUGINS = ['tpope/vim-commentary', 'tpope/vim-surround', 'tpope/vim-fugitive', 'tpope/vim-rhubarb', 'tpope/vim-rsi', '907th/vim-auto-save', 'w0rp/ale', 'junegunn/fzf.vim']
let g:THEMES = ['lifepillar/vim-solarized8']
if has('gui_vimr')
    color solarized8_light
endif

let g:auto_save = 1  " enable AutoSave on Vim startup
let g:racer_cmd = "~/.cargo/bin/racer"
let $RUST_SRC_PATH = "~/.multirust/toolchains/stable-x86_64-apple-darwin/lib/rustlib/src/rust/src/"
let g:racer_experimental_completer = 1
let g:sql_type_default = 'mysql'
let g:ftplugin_sql_omni_key = '<C-z>'
let g:ale_python_pylint_options = "--disable=deprecated-module,C0103 --const-rgx='[a-z_][a-z0-9_]{2,30}$'"
" }}}

" Functions {{{
function! s:get_visual_selection() abort
    " Why is this not a built-in Vim script function?!
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endfunction

function! PbCopy() range
    echo system('echo '.shellescape(s:get_visual_selection()).'| pbcopy')
endfunction

function! PhpSnippets() abort
    iabbrev <buffer> ife <?php if (): ?><CR><?php else: ?><CR><?php endif; ?><ESC>02kf)i
    iabbrev <buffer> fun function() {<CR>}<ESC>kf(i
endfunction

function! ScalaSnippets() abort
    iabbrev <buffer> iff if () {<CR>}<ESC>kf(a
    iabbrev <buffer> ife if () {<CR>} else {<CR>}<ESC>2kf(a
    iabbrev <buffer> flatm flatMap { => <LEFT><LEFT><LEFT><LEFT>
    iabbrev <buffer> match match {<CR>case => <CR>case _ => <CR>}<ESC>2kfea
    iabbrev <buffer> def def():  = {<CR>}<ESC>kffa
    inoremap <buffer> <C-l> <ESC>f:<RIGHT>a
endfunction

function! CssSnippets() abort
    " Use ; as trigger key
    iabbrev <buffer> dbl display: block
    iabbrev <buffer> din display: inline-block
    iabbrev <buffer> dno display: none
    iabbrev <buffer> ff font-family: '', serif
    iabbrev <buffer> fs font-size: 
    iabbrev <buffer> p0 padding: 0px
    iabbrev <buffer> m0 margin: 0px
    iabbrev <buffer> fwb font-weight: bold
    iabbrev <buffer> cb color: #000
    iabbrev <buffer> cw color: #fff
    iabbrev <buffer> tac text-align: center
    iabbrev <buffer> bgno background-repeat: no-repeat
endfunction

function! Replace() abort
    let pattern = substitute(escape(@", '\?'), '\n', '\\n', 'g')
    let replacement = substitute(escape(@., '\?'), '\n', '\\r', 'g')
    execute "%s/\\V" . pattern . "/" . replacement . "/gc"
endfunction

function! LocalCd(dir, tab) abort
    let cmd = "e "
    if a:tab != ""
        let cmd = "tabnew "
    endif
    exe cmd . a:dir
    exe "lcd " . a:dir
endfunction

function! s:InstallPlugin(name, prefix) abort
    echomsg a:name
    let dir = split(a:name, '/')
    if len(dir) == 2
        let target = $HOME . "/" . a:prefix . dir[1]
        if !isdirectory(target)
            call mkdir(target, "p")
            let s = system("git clone https://github.com/" . a:name . " " . target)
        endif
    endif
endfunction

function! s:InstallPlugins(list, prefix) abort
    for p in a:list
        call s:InstallPlugin(p, a:prefix)
    endfor
endfunction

function! s:InstallPluginCmd(name) abort
    call s:InstallPlugin(a:name, ".vim/pack/bundle/start/")
endfunction

function! s:UpdatePlugins() abort
    for p in g:PLUGINS
        let dir = split(p, '/')
        let target = $HOME . "/.vim/pack/bundle/start/" . dir[1]
        if isdirectory(target)
            echomsg p
            let s = system("cd " . target . " && git pull")
        endif
    endfor
endfunction

function! s:InitPlugins() abort
    call s:InstallPlugins(g:PLUGINS, ".vim/pack/bundle/start/")
    call s:InstallPlugins(g:THEMES, ".vim/pack/themes/opt/")
endfunction

" Highlight all instances of word under cursor, when idle.
" Useful when studying strange source code.
" Type z/ to toggle highlighting on/off.
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

function! Align() abort
    '<,'>!column -t|sed 's/  \(\S\)/ \1/g'
    normal gv=
endfunction

" }}}

" Commands {{{
command! -range=% TB <line1>,<line2>w !nc termbin.com 9999 | tee /tmp/termbin.com
command! -nargs=1 -complete=file Lcd call LocalCd(<f-args>)
command! -nargs=1 -complete=file Lcdt call LocalCd(<f-args>, "t")
command! -nargs=1 InstallPlugin call s:InstallPluginCmd(<f-args>)
command! -nargs=0 InitPlugins call s:InitPlugins()
command! -nargs=0 UpdatePlugins call s:UpdatePlugins()
command! -range=% -nargs=0 PbCopy :<line1>,<line2>call PbCopy()
command! -nargs=+ Find edit __find__ | setl bt=nofile bh=hide nobl | %!rg --files | rg <args>
command! -nargs=0 Ctags :!/usr/local/bin/ctags .
" }}}

" Mappings {{{
let mapleader = ' '
xnoremap <silent> <leader>= :<C-u>silent call Align()<CR>
nnoremap <Leader>1 :!
nnoremap <Leader>. :Ex<CR>
nnoremap <Leader>a :silent grep 
if executable('rg')
    nnoremap <Leader>A :silent grep <cword> -t<C-r>=&filetype<CR> \| copen<CR>
else
    nnoremap <Leader>A :silent grep <cword> --type=<C-r>=&filetype<CR> \| copen<CR>
endif
nnoremap <leader>c :call Replace()<cr>
nnoremap <Leader>f :find 
nnoremap <Leader>l :Lines<CR> 
if has('nvim')
    nnoremap <Leader>s :below 15sp term://bash<CR>i
else
    nnoremap <Leader>s :below term ++rows=15<CR>
endif
if (g:has_fzf == 1)
    nnoremap <Leader>k :Tags<CR>
else
    nnoremap <Leader>k :tj 
endif
nnoremap <Leader>m :make<CR>
nnoremap <leader>t :FZF<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>z :qall<CR>
nnoremap z/ :if AutoHighlightToggle()<Bar>set hls<Bar>endif<CR>
nnoremap Q @q
if exepath('nvr') != ''
    nnoremap <leader>r :!nvr --remote %<CR>
endif
if has('nvim')
    tnoremap <A-x> <C-\><C-n>
    tnoremap <C-w> <C-\><C-n><C-w>
    tnoremap <A-h> <C-\><C-n><C-w>h
    tnoremap <A-j> <C-\><C-n><C-w>j
    tnoremap <A-k> <C-\><C-n><C-w>k
    tnoremap <A-l> <C-\><C-n><C-w>l
    nnoremap <A-h> <C-w>h
    nnoremap <A-j> <C-w>j
    nnoremap <A-k> <C-w>k
    nnoremap <A-l> <C-w>l
    inoremap <A-h> <Esc><C-w>h
    inoremap <A-j> <Esc><C-w>j
    inoremap <A-k> <Esc><C-w>k
    inoremap <A-l> <Esc><C-w>l
    au TermOpen * setlocal nonumber
endif
if (g:has_fzf == 1)
    nnoremap <silent> <Leader>b :Buffers<CR>
else
    nnoremap <Leader>b :buffers<CR>:buffer<Space>
endif
" Git
nnoremap <Leader>gs :Gstatus<CR>
nnoremap <Leader>gp :Git push<CR>
nnoremap <Leader>gP :exe 'Git push --set-upstream origin ' . system('git symbolic-ref --short HEAD')<CR>
nnoremap <Leader>gl :Git pl<CR>
" Copy
vnoremap <Leader>y :PbCopy<CR>
" Focus window
nnoremap <C-w>z :tab sp<CR>

nnoremap <BS> <C-^>

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
" Disable search highlight
nnoremap <esc> :noh<cr>
" Change a word under cursor and prepare for repeats via .
nnoremap <Leader>; *``cgn
nnoremap <Leader>, #``cgN
" }}}

" Autocommands {{{
if &diff
    set cursorline
    map <buffer> ] ]c
    map <buffer> [ [c
endif
augroup CustomColors
    au!
    " better matching parens
    hi MatchParen cterm=bold ctermbg=none ctermfg=magenta
augroup END
augroup filesettings
    au!
    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event
    " handler (happens when dropping a file on gvim).
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \|  exe "normal g`\""
        \|endif

    " Keep window position when switching buffers
    " https://stackoverflow.com/questions/4251533/vim-keep-window-position-when-switching-buffers
    au BufLeave * let b:winview = winsaveview()
    au BufEnter * if(exists('b:winview')) | call winrestview(b:winview) | endif

    au FileType * if &filetype == 'sql'
        \|  exe('setl dict+='.$VIMRUNTIME.'/syntax/'.g:sql_type_default.'.vim')
        \|  setl complete-=t
        \|else
        \|  exe('setl dict+='.$VIMRUNTIME.'/syntax/'.&filetype.'.vim')
        \|endif

    au FileType xml setlocal omnifunc=xmlcomplete#CompleteTags sw=2 ts=2 sts=2
    au FileType html setlocal omnifunc=htmlcomplete#CompleteTags sw=2 ts=2 sts=2
    au FileType css setlocal omnifunc=csscomplete#CompleteCSS sw=2 ts=2 sts=2
        \| call CssSnippets()
    au FileType php setlocal omnifunc=phpcomplete#CompletePHP
        \| call PhpSnippets()
    au FileType go setlocal makeprg=gometalinter
    au FileType yaml,tf setlocal sw=2 ts=2 sts=2
    au FileType scala setlocal path=.,src/**,app/**,application/**,public/**,conf/**,subprojects/*/src/**,subprojects/*/app/**,*/src/**,*/app/**,test/**,*/test/**,*/model/src/**,*/logic/src/**,modules/**,subprojects/*/conf/** commentstring=//%s
        \| if expand("%:p:h") =~ 'Projects/fmg' | setlocal noet ts=4 sw=4 | endif
        \| call ScalaSnippets()
    au BufNewFile,BufRead *.sbt setlocal path=./*,project/* ft=sbt syntax=scala
        \| if expand("%:p:h") =~ 'Projects/fmg' | setlocal noet ts=4 sw=4 | endif
    au BufNewFile,BufRead *.md setlocal ft=markdown
    au BufNewFile,BufRead *.es6 setlocal ft=javascript
    au BufNewFile,BufRead *.sql runtime! ftplugin/sql.vim
augroup END

augroup templates
    au!
    " read in template files
    autocmd BufNewFile *_deployment.yaml execute '0r $HOME/.config/nvim/templates/skeleton-k8s-deployment.yaml'
    autocmd BufNewFile *_service.yaml execute '0r $HOME/.config/nvim/templates/skeleton-k8s-service.yaml'
    autocmd BufNewFile *.* silent! execute '0r $HOME/.config/nvim/templates/skeleton.'.expand("<afile>:e")

    " parse special text in the templates after the read
    autocmd BufNewFile * %substitute#\[:VIM_EVAL:\]\(.\{-\}\)\[:END_EVAL:\]#\=eval(submatch(1))#ge
augroup END
" }}}
