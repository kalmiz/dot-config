" Base settings {{{ vim: set et
runtime defaults.vim
set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set hidden
set foldmethod=marker
set shell=bash
set formatoptions+=r
set title titlestring="%F %a%r%m"
set iskeyword+=-
set ignorecase
set smartcase
if has("persistent_undo")
    set noswapfile undofile undodir=~/.vim/undodir/ 
endif
" }}}

" Bare bone navigation {{{
set path=**
set suffixesadd=.conf,.java,.scala,.php,.js,.yaml
set wildmode=list:longest,full
set wildignore+=*.class,*.jar,*.jpg,*.png,*.gif,**/tiny_mce_dev/**,**/target/**,**/node_modules/**,node_modules/**,cscope.*,.git/**,.idea/**
set wildignorecase
set wildcharm=<C-z>

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

let g:PLUGINS = ['tpope/vim-commentary', 'tpope/vim-surround', 'tpope/vim-repeat', 'tpope/vim-fugitive', 'tpope/vim-rhubarb', 'tpope/vim-rsi', 'hauleth/asyncdo.vim', 'RRethy/vim-quickscope']
let g:THEMES = ['lifepillar/vim-solarized8']
set bg=light
if has('gui')
    color solarized8
endif
let g:sql_type_default = 'mysql'
let g:ftplugin_sql_omni_key = '<C-z>'
if !has('nvim') | packadd! matchit | endif
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

function! Xcopy(cmd) range
    if a:cmd != ''
        let command = a:cmd
    else
        let command = 'wxcopy --clear-selection'
    endif
    return system('echo -n '.shellescape(s:get_visual_selection()).'|' . command)
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

function! ScalacSettings() abort
    func! CloseHandler(channel)
        let line = ''
        while ch_status(a:channel, {'part': 'out'}) == 'buffered'
            let line .= ch_read(a:channel)
        endwhile
        call writefile(['-Ystop-before:jvm', '-cp ' . line], '.scalac')
    endfunc
    let job = job_start('sbt --error "export fullClasspath"', {'close_cb': 'CloseHandler', 'in_mode': 'nl'})
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
command! -range=% TB <line1>,<line2>w !nc termbin.com 9999 | tee /tmp/termbin.com
if has('macunix')
    command! -range=% Xcopy <line1>,<line2>call Xcopy('pbcopy')
else
    command! -range=% Xcopy <line1>,<line2>call Xcopy('')
endif
command! -nargs=1 InstallPlugin call s:InstallPluginCmd(<f-args>)
command! -nargs=0 InitPlugins call s:InitPlugins()
command! -nargs=0 UpdatePlugins call s:UpdatePlugins()
command! -nargs=+ Find edit __find__ | setl bt=nofile bh=hide nobl | %!rg --files | rg <args>
command! -nargs=0 Ctags !ctags .
command! -nargs=0 -bar JavaDoc silent execute('!ivy-doc-viewer.sh') | redraw!
command! -nargs=0 -bar JavaClass silent execute('!ivy-class-search.sh ' . shellescape(expand('<cword>'))) | redraw!
command! -bang -nargs=* -complete=file Make call asyncdo#run(<bang>0, &makeprg, <f-args>)
" }}}

" Mappings {{{
let mapleader = ' '
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
nnoremap <Leader>c :call Replace()<CR>
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
" Change a word under cursor and prepare for repeats via .
nnoremap <Leader>; *``cgn
nnoremap <Leader>, #``cgN
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
    au FileType sh setlocal makeprg=bash\ -n efm=%f:\ line\ %l:\ %m
    au FileType scala setlocal path=.,src/**,app/**,application/**,public/**,conf/**,subprojects/*/src/**,subprojects/*/app/**,*/src/**,*/app/**,test/**,*/test/**,*/model/src/**,*/logic/src/**,modules/**,subprojects/*/conf/**,*/*/src/** commentstring=//%s efm=%E%f:%l:\ %trror:\ %m,%W%f:%l:\ %tarning:%m,%Z%p^,%-G%.%# define=\(def\\s\|class\\s\|trait\\s\|object\\s\|val\\s\\|:\\s) includeexpr=substitute(substitute(v:fname,'\\.','/','g'),'_','\.','g') include=^import
        \| if expand("%:p:h") =~ 'Projects/fmg' | setlocal noet ts=4 sw=4 | endif
        \| call ScalaSnippets()
        \| if filereadable(".scalac") | setlocal makeprg=scalac\ @.scalac | else
        \| setlocal makeprg=scalac\ -Ystop-after:parser | endif
    au BufNewFile,BufRead *.sbt setlocal path=./*,project/* ft=sbt syntax=scala
        \| if expand("%:p:h") =~ 'Projects/fmg' | setlocal noet ts=4 sw=4 | endif
    au FileType javascript setlocal ts=2 sw=2 sts=2 et makeprg=./node_modules/.bin/eslint\ -f\ compact efm=%E%f:\ line\ %l\\,\ col\ %c\\,\ Error\ -\ %m,%-G%.%#,%W%f:\ line\ %l\\,\ col\ %c\\,\ Warning\ -\ %m,%-G%.%#

    au FileType javascript if expand("%:p:h") =~ 'Projects/fmg' | setlocal noet ts=4 sw=4 | endif
    au BufNewFile,BufRead *.md setlocal ft=markdown
    au BufNewFile,BufRead *.es6 setlocal ft=javascript
    au BufNewFile,BufRead *.sql runtime! ftplugin/sql.vim

    " Linting
    autocmd BufWritePost *.scala silent Make! <afile>
    autocmd BufWritePost *.js silent Make! <afile>
    autocmd BufWritePost *.sh silent Make! <afile>
    autocmd QuickFixCmdPost [^l]* cwindow
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
