""""" created by zzy """"""""""""""""""""""""
"set rtp=~/.vim
let mapleader = ";"
set t_Co=256
set t_AB=[48;5;%dm
set t_AF=[38;5;%dm
colorscheme desert
set number
"make gf can work normally: If you wish to delete other characters from isfname, 
"be sure to delete them one character at a time. That is, execute :set isfname-=- and :set isfname-=:,
"not :set isfname-=-:. The last command will work only if -: are present in isfname together and in that order
set isfname-={
set isfname-=}
set isfname-=,
set isfname+=@-@
let leader=';'


let myos = substitute(system('uname'), "\n", "", "")
"if myos == "SunOS"
" Do Sun-specific stuff.
"elseif myos == "Linux"
" Do Linux-specific stuff.
"endif

set wildmode=list:full
set wildmenu
set showmatch
set ignorecase
syntax enable
syntax on
filetype on
filetype plugin indent on
set nobackup
set noswapfile 
set history=50
if myos == "Linux"
	set mousefocus=on
endif
set mousemodel=extend
"set selection=exclusive
"set selectmode=mouse,key
set noet
set sw=4
set hlsearch incsearch
set nocompatible
set backspace=indent,eol,start
set updatetime=100
set mouse=a
set showcmd
"set iskeyword+=_,@,%,#,-
set iskeyword+=_,-
set completeopt=longest,menu
set cscopequickfix=s-,c-,d-,i-,t-,e-
if has("cscope")
    "set csprg=/usr/bin/cscope
    set csto=1
    set cst
    set csverb
    set cspc=3
    "add any database in current dir
    if filereadable("cscope.out")
        silent! cs add cscope.out
    "else search cscope.out elsewhere
    else
        let cscope_file=findfile("cscope.out", ".;")
        "echo cscope_file
        if !empty(cscope_file) && filereadable(cscope_file)
            exe "silent! cs add" cscope_file
        endif      
     endif
	 "add key mapping for cs find
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>:botright copen<CR><CR>
    nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>:botright copen<CR><CR>
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>:botright copen<CR><CR>
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>:botright copen<CR><CR>
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>:botright copen<CR><CR>
    nmap <C-\>i :cs find i <C-R>=expand("<cfile>")<CR><CR>:botright copen<CR><CR>
    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>:botright copen<CR><CR>
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>:botright copen<CR><CR>
endif

"let Tlist_Ctags_Cmd='/usr/bin/ctags'
let Tlist_Ctags_Cmd='ctags'
let Tlist_Show_One_File=1
let Tlist_OnlyWindow=1
let Tlist_Use_Right_Window=1
let Tlist_Sort_Type='name'
let Tlist_Exit_OnlyWindow=1
let Tlist_Show_Menu=0
let Tlist_Max_Submenu_Items=10
let Tlist_Max_Tag_length=20
let Tlist_Use_SingleClick=0
let Tlist_Auto_Open=0
let Tlist_Close_On_Select=0
let Tlist_File_Fold_Auto_Close=0
let Tlist_GainFocus_On_ToggleOpen=0
let Tlist_Process_File_Always=0
let Tlist_WinHeight=10
let Tlist_WinWidth=22
let Tlist_Use_Horiz_Window=0
let Tlist_Auto_Highlight_Tag=1
let Tlist_Highlight_Tag_On_Bufenter = 1
let Tlist_Inc_Winwidth = 1
let Tlist_Compact_Format = 1

if myos == "Linux"
let Tlist_Auto_Open=0
let Tlist_Process_File_Always=1
endif
map <F4> :TlistToggle<CR>

"for minibuffer
let g:miniBufExplCycleArround=1
"let g:miniBufExplAutoStart = 1
let g:miniBufExplUseSingleClick = 1
let g:miniBufExplMapWindowNavVim=1  
let g:miniBufExplMapCTabSwitchBufs=1  
let g:miniBufExplMapWindowNavArrows=1  
let g:miniBufExplModSelTarget=1 
"new
"let g:miniBufExplStatusLineText="%<%f%=\ [%1*%M%*%n%R%H]\ %-19(%3l,%02c%03V%)%O'%02b'"
let g:miniBufExplStatusLineText=' '
let g:miniBufExplorerAutoStart = 1
noremap <silent><leader>;   :MBEbn<CR>:<BS>
noremap <silent><leader>j   :MBEbp<CR>:<BS>
"noremap <silent><leader>k   :call <SID>CycleBuffer(0)<CR>:<BS>
noremap <silent><leader>l   :b#<CR>:<BS>
noremap <silent><leader>'   :b#<cr>:<BS>

let NERDTreeShowBookmarks = 1
let NERDChristmasTree = 1
let NERDTreeWinPos = "left"
let NERDTreeDirArrows = 0
let NERDTreeWinPos='left'
let NERDTreeWinSize=30
let NERDTreeChDirMode=1 
"let g:SuperTabRetainCompletionType="context"

"ctrlp
let g:ctrlp_working_path_mode = ''


set <S-F6>=[29~
set <S-F7>=[31~
set <S-F8>=[32~
set <F7>=[18~

nmap <F9> :cn<cr>
nmap <F10> :cp<cr>
nmap <F11> :QFix<cr>

"Toggle quickfix window
command! -bang -nargs=? QFix call QFixToggle(<bang>0)
function! QFixToggle(forced)
  if exists("g:qfix_win") && a:forced == 0
    cclose
    unlet g:qfix_win
  else
    botright copen 10
    let g:qfix_win = bufnr("$")
  endif
endfunction

"nnoremap <S-F6> :echo "shift-F6"<CR>
"nnoremap <S-F8> :echo "shift-F8"<CR>
"nnoremap <S-F7> :echo "shift-F7"<CR>

" map Alt-J to Ctrl-Y
map k 
" map Alt-K to Ctrl-E
map j 

map <A-M> :echo "Meta z"<CR>
map <M-K> <C-Y>
"noremap <F8> <C-x><C-o>
map <F2> <C-R>=strftime("%c")<CR><Esc> 
map <silent> <F3> :nohlsearch<CR>
map <F5> :NERDTreeMirror<CR>
map <F5> :NERDTreeToggle<CR>

noremap ;vv <Esc>bi{<Esc>ea}<Esc>
"following line lead to ;j can't back to previous buffer immediatelly
"noremap ;jj <Esc>ea_<Esc>

" Commenting blocks of code.
autocmd FileType c                let b:comment_leader = 'aa'
autocmd FileType cpp,java,scala   let b:comment_leader = '// '
autocmd FileType c                let b:comment_begin  = '/*'
autocmd FileType c                let b:comment_end    = '*/'
autocmd FileType h                let b:comment_begin  = '/*'
autocmd FileType h                let b:comment_end    = '*/'
autocmd FileType rexx             let b:comment_begin  = '/*'
autocmd FileType rexx             let b:comment_end    = '*/'
autocmd FileType sh,ruby,python   let b:comment_leader = '# '
autocmd FileType conf,fstab       let b:comment_leader = '# '
autocmd FileType tex              let b:comment_leader = '% '
autocmd FileType mail             let b:comment_leader = '> '
autocmd FileType vim              let b:comment_leader = '" '
noremap <silent> ,cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> ,cu :<C-B>silent <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>
noremap <silent> ,zc :<C-B>silent <C-E>s/^\(.*\)$/<C-R>=escape(b:comment_begin,'\/*')<CR> \1 <C-R>=escape(b:comment_end,'\/*')<CR>/g<CR>:nohlsearch<CR> 
noremap <silent> ,zu :<C-B>silent <C-E>s/^\(\s*\)<C-R>=escape(b:comment_begin,'\/*')<CR>\(.*\)<C-R>=escape(b:comment_end,'\/*')<CR>/\1\2/e<CR>:nohlsearch<CR>

function! ToggleComment()
" help with :h \v or pattern-atoms
  if exists('b:comment_leader')
    if getline('.') =~ '\v^\s*' .b:comment_leader
      " uncomment the line
      execute 'silent s/\v^\s*\zs' .b:comment_leader.'[ ]?//g'
    else
      " comment the line
      execute 's/\v^\s*\zs\ze(\S|\n)/' .b:comment_leader.' /g'
    endif
  else
    echo 'no comment leader found for filetype'
  end
endfunction

" update tag 
function! UpdateCtags()
	"echo "aa"
    let curdir=getcwd()
    while !filereadable("./tags")
        cd ..
        if getcwd() == "/"
            break
        endif
    endwhile
    if filewritable("./tags")
        "silent execute "!{ ctags -R --file-scope=yes --langmap=c:+.h --languages=c,c++ --links=yes --c-kinds=+p --c++-kinds=+p --fields=+iaS --extra=+q } &"
        "silent execute "!{ cscope -Rqb } &"
		"silent execute ':redraw!'
        TlistUpdate
	endif
	silent! execute ":cd " . curdir
    silent! execute ":cs reset"
	if has("cscope")
		"set csto=1
		"set cst
		"set nocsverb
		" add any database in current directory
		if filereadable("cscope.out")
			"cs show
			silent! cs kill 0
			silent! cs add cscope.out
		endif
		"set csverb
		"execute ":cs reset"
	endif
endfunction

autocmd BufWritePost *.c,*.h,*.cpp,*.sh call UpdateCtags() 
"nnoremap <leader>mc :call ToggleComment()<cr>
"showmarks style
"highlight hlShowMarks ctermbg=white ctermfg=blue guibg=grey guifg=RoyalBlue3
"highlight hlShowMarks ctermfg=white ctermbg=blue guifg=white guibg=RoyalBlue3
"let g:showmarks_marks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

""""""""""""""""""""""""""""""
" showmarks setting
""""""""""""""""""""""""""""""
" Enable ShowMarks
let g:showmarks_enable = 1
" Show which marks
let g:showmarks_include = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
" Ignore help, quickfix, non-modifiable buffers
let g:showmarks_ignore_type = "hqm"
" Hilight lower & upper marks

let g:showmarks_hlline_lower = 1
let g:showmarks_hlline_upper = 1 
" For showmarks plugin, high light one whole line
hi ShowMarksHLl ctermbg=Yellow   ctermfg=Black  guibg=#FFDB72    guifg=Black
hi ShowMarksHLu ctermbg=Magenta  ctermfg=Black  guibg=#FFB3FF    guifg=Black 

" OmniCppcomplete {{{
"let OmniCpp_NamespaceSearch = 1
"let OmniCpp_GlobalScopeSearch = 1
"let OmniCpp_ShowAccess = 1
"let OmniCpp_ShowPrototypeInAbbr = 1 
"let OmniCpp_MayCompleteDot = 1   
"let OmniCpp_MayCompleteArrow = 1 
"let OmniCpp_MayCompleteScope = 1 
"let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]
"au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
"set completeopt=menuone,menu,longest
" }}}

"let g:SuperTabMappingForward="[24~"			
" for Bundle
set nocompatible              " be iMproved, required
filetype off                  " required

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" for YouCompleteMe
let g:ycm_global_ycm_extra_conf='~/.ycm_extra_conf.py' "设置全局配置文件的路径
let g:ycm_seed_identifiers_with_syntax=1 " 语法关键字补全
let g:ycm_confirm_extra_conf=0 " 打开vim时不再询问是否加载ycm_extra_conf.py配置
let g:ycm_key_invoke_completion = '<C-a>' " ctrl + a 触发补全
set completeopt=longest,menu "让Vim的补全菜单行为与一般IDE一致(参考VimTip1228)
let g:ycm_error_symbol = '>>'
let g:ycm_warning_symbol = '>*'
nnoremap <leader>gl :YcmCompleter GoToDeclaration<CR>
nnoremap <leader>gf :YcmCompleter GoToDefinition<CR>
nnoremap <leader>gg :YcmCompleter GoToDefinitionElseDeclaration<CR>
nmap <F6> :YcmDiags<CR>

" set the runtime path to include Vundle and initialize
set rtp+=$MYHOME/.vim/bundle/Vundle.vim
" set rtp+=~/nfs/users/zhaozhan/tmp/.vim/bundle/vundle
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'zefei/vim-wintabs'
"Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
Plugin 'L9'
Plugin 'scrooloose/nerdtree'
Plugin 'Shougo/unite.vim'
Plugin 'tacroe/unite-mark'
Plugin 'scrooloose/nerdcommenter'
"Plugin 'vim-scripts/OmniCppComplete'
"Plugin 'OmniCppComplete'
Plugin 'vim-scripts/AutoComplPop'
Plugin 'vim-scripts/ShowMarks'
Plugin 'ervandew/supertab'
Plugin 'majutsushi/tagbar'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'fatih/vim-go'
Plugin 'taglist.vim'
Plugin 'jlanzarotta/bufexplorer'
Plugin 'weynhamz/vim-plugin-minibufexpl'
"Plugin 'jacquesbh/vim-showmarks'
Plugin 'elzr/vim-json'
Plugin 'yegappan/grep'
Plugin 'Valloric/YouCompleteMe'
"Plugin 'minibufexpl.vim'
"Plugin 'fholgado/minibufexpl.vim'

"map f7 :tabnew<CR>
"map f5 :tabp<CR>
"map f6 :tabn<CR>
"nnoremap <S-F7> :tabnew<CR>
"nnoremap <S-F8> :tabp<CR>
"nnoremap <S-F9> :tabn<CR>
"Plugin 'bling/vim-airline'
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
"Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line


" for airline
" enable/disable enhanced tabline. >
  let g:airline#extensions#tabline#enabled = 1
" enable/disable displaying buffers with a single tab. >
  let g:airline#extensions#tabline#show_buffers = 1
" enable/disable displaying tabs, regardless of number. >
  let g:airline#extensions#tabline#show_tabs = 1
" configure filename match rules to exclude from the tabline. >
  let g:airline#extensions#tabline#excludes = []
" configure how numbers are calculated in tab mode. >
  "let g:airline#extensions#tabline#tab_nr_type = 0 " # of splits (default)
  let g:airline#extensions#tabline#tab_nr_type = 1 " tab number
" enable/disable displaying tab number in tabs mode. >
  let g:airline#extensions#tabline#show_tab_nr = 1
" enable/disable displaying tab type (far right)
  let g:airline#extensions#tabline#show_tab_type = 1
  let g:airline#extensions#tabline#buffer_nr_show = 1

"let g:SuperTabRetainCompletionType = 1
"let g:SuperTabDefaultCompletionType = "<C-X><C-O>" 

	"let g:showmarks_marks_notime = 1

	" {{{
"let g:unite_source_mark_marks = '01abcABCDEFGHIJKLNMOPQRSTUVWXYZ' 
let g:unite_source_mark_marks =  
\   "abcdefghijklmnopqrstuvwxyz" 
"\ . "ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
"\ . "0123456789.'`^<>[]{}()\""   

	if !exists('g:markrement_char')
		let g:markrement_char = [
		\     'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
		\     'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
		\     'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
		\     'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
		\ ]
	en

	fu! s:AutoMarkrement()
		if !exists('b:markrement_pos')
			let b:markrement_pos = 0
		else
			let b:markrement_pos = (b:markrement_pos + 1) % len(g:markrement_char)
		en
		exe 'mark' g:markrement_char[b:markrement_pos]
		echo 'marked' g:markrement_char[b:markrement_pos]
	endf

    "delete mark in current line
    function! Delmarks()
        let l:m = join(filter(
           \ map(range(char2nr('a'), char2nr('z')), 'nr2char(v:val)'),
           \ 'line("''".v:val) == line(".")'))
        if !empty(l:m)
            exe 'delmarks' l:m
        endif
    endfunction 
    function! DoShowMarksIfHave()
        let l:m = join(filter(
           \ map(range(char2nr('a'), char2nr('z')), 'nr2char(v:val)'),
           \ 'line("''".v:val) != 0'))
        " echo "l:m" l:m
        if !empty(l:m)
            " let g:showmarks_enable = 1
            " exe 'ShowMarksToggle'
            exe 'ShowMarksOn'
        endif
    endfunction 

	aug show-marks-sync
			au!
			"au BufReadPost * sil! ShowMarksOnce
			au BufReadPost * sil! call DoShowMarksIfHave()
	aug END

    "define key for UniteMark
	nn [Mark] <Nop>
	nm <leader>m [Mark]
	nn <silent> [Mark]s :Unite mark<CR>
	nn <silent> [Mark]b :Unite buffer<CR>
	"nn <silent> [Mark]b :Unite buffer file_mru<CR>
	nn <silent> [Mark]c :UniteClose<CR>
	nn <silent> [Mark]f :UniteWithBufferDir -buffer-name=files file<CR>
	nn <silent> [Mark]r :Unite -buffer-name=register register<CR>
	nn <silent> [Mark]l :Unite file_mru<CR>
	"nn <silent> [Mark]m :unite<CR>
	nn [Mark]j :<C-u>call <SID>AutoMarkrement()<CR><CR>:ShowMarksOnce<CR>
	com! -bar MarksDelete sil :delm! | :delm 0-9A-Z | :wv! | :ShowMarksOnce
	nn <silent> [Mark]D :MarksDelete<CR>
    "add by zzy
    nnoremap    [Mark]d :<c-u>call Delmarks()<cr>
    nnoremap    [Mark]n ]'
    nnoremap    [Mark]p ['
	" }}}

"define 3 custom highlight groups                                            
hi User1 ctermbg=darkred ctermfg=white  guibg=green guifg=red                   
hi User2 ctermbg=red   ctermfg=blue  guibg=red   guifg=blue                  
hi User3 ctermbg=blue  ctermfg=green guibg=blue  guifg=green                 
set statusline=%1*%F%m%r,\ %Y,\ %{&fileformat}\ \ \ ASCII=\%b(\0x\%B)buf=%n\ \ \ %l,%c%V\ \ %p%%(%L\L)\ %M 
set laststatus=2

"autocmd BufNewFile,BufRead * if match(getline(1),"node") >= 0 | set filetype=sh | endif
"for BatchRT only, it's a history issue
"autocmd BufRead,BufNewFile m* set filetype=sh
"setfiletype sh
hi Directory guifg=#FF0000 ctermfg=red
nnoremap ` :ShowMarksOnce<cr>`
"silent execute ':redraw!'
" autocmd FileType c              call DoShowMarksIfHave()
" autocmd FileType sh             call DoShowMarksIfHave()
autocmd FileType *             call DoShowMarksIfHave()

"设置tagbar使用的ctags的插件,必须要设置对  
"let g:tagbar_ctags_bin='/usr/bin/ctags'  
"设置tagbar的窗口宽度  
let g:tagbar_width=25
"设置tagbar的窗口显示的位置,为左边  
let g:tagbar_left=0
"打开文件自动 打开tagbar  
autocmd BufReadPost *.cpp,*.c,*.h,*.hpp,*.cc,*.cxx,*.go,* call tagbar#autoopen()
"autocmd BufReadPost *.cxx,*.go,*.sh call tagbar#autoopen()  
"disable auto format for go source code
let g:go_fmt_autosave = 0
"映射tagbar的快捷键  
map <F8> :TagbarToggle<CR>  

"don't auto format go source code
let g:go_fmt_autosave = 0
let g:go_version_warning = 0

"==============================================================
" run set at tail part to provent other plugin changing them
"==============================================================
set expandtab 
"set cindent
"set cindent shiftwidth=4  
"set smartindent
set cinoptions={0,1s,t0,n-2,p2s,(03s,=.5s,>1s,=1s,:1s
"set cindent cinoptions=:0,g0,t0
"set autochdir 
set cinoptions={0,1s,t0,n-2,p2s,(03s,=.5s,>1s,=1s,:1s 
set enc=utf8
set fileencodings=ucs-bom,utf8,GB18030,Big5,latin1 
set fileformat=unix 
"set cursorline 
"set smartindent 
set shiftwidth=4 
set softtabstop=4 
set smartcase 
set hidden
set tabstop=4
set paste
set autoindent shiftwidth=4  
