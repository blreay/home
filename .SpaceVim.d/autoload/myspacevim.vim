function! myspacevim#before() abort
  let g:neomake_enabled_c_makers = ['clang']
  let leader=';'
  let g:mapleader = ";"
  "nnoremap jk <esc>
  " noremap <silent><leader>;   :bn<CR>:<BS>
  noremap <silent><leader>j   :bp<CR>:<BS>
  "noremap <silent><leader>k   :call <SID>CycleBuffer(0)<CR>:<BS>
  noremap <silent><leader>l   :bn<CR>:<BS>
  " noremap <silent><leader>'   :b#<cr>:<BS>
  noremap <silent><leader>'   :b#<cr>:<BS>
  nmap s <Plug>(easymotion-s2)
  nmap t <Plug>(easymotion-t2)
  " 可视模式下：<leader>y 把选中内容送给 myyank.sh, 但是不起作用
  "xnoremap <silent> <leader>Y :<C-u>w !myyank.sh<CR>


  let g:bookmark_sign = '>>'
  let g:bookmark_highlight_lines = 1

  "tagbar
  let g:tagbar_autopreview = 1
  let g:tagbar_autoshowtag = 1
  let g:tagbar_autofocus   = 1
  let g:tagbar_silent      = 0
  let g:tagbar_iconchars = ['+', '-']

  "############# YCM #######################
  let g:spacevim_enable_ycm = 1
  " let g:ycm_auto_hover = 'CursorHold'  " default is CursorHold, but very slow when moving cursor, must disable it
  let g:ycm_auto_hover = ''  " default is CursorHold, but very slow when moving cursor, must disable it
  " let g:ycm_collect_identifiers_from_tags_files = 1           " 开启 YCM 基于标签引擎
  " let g:ycm_collect_identifiers_from_comments_and_strings = 1 " 注释与字符串中的内容也用于补全
  " let g:syntastic_ignore_files=[".*\.py$"]
  let g:ycm_seed_identifiers_with_syntax = 1                  " 语法关键字补全
  " let g:ycm_complete_in_comments = 1
  let g:ycm_confirm_extra_conf = 0
  " let g:ycm_key_list_select_completion = ['<c-n>', '<Down>']  " 映射按键, 没有这个会拦截掉tab, 导致其他插件的tab不能用.
  " let g:ycm_key_list_previous_completion = ['<c-p>', '<Up>']
  " let g:ycm_complete_in_comments = 1                          " 在注释输入中也能补全
  " let g:ycm_complete_in_strings = 1                           " 在字符串输入中也能补全
  " let g:ycm_collect_identifiers_from_comments_and_strings = 1 " 注释和字符串中的文字也会被收入补全
  " let g:ycm_global_ycm_extra_conf='~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py'
  " let g:ycm_show_diagnostics_ui = 0                           " 禁用语法检查
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>" |            " 回车即选中当前项
  nnoremap <c-m> :YcmCompleter GoToDefinitionElseDeclaration<CR>|     " 跳转到定义处
  nnoremap <c-h> <plug>(YCMHover)
  nmap <leader>n <plug>(YCMHover)
  " nnoremap <silent> <c-h> :call <SID>Hover()<CR>
  "" let g:ycm_min_num_of_chars_for_completion=2                 " 从第2个键入字符就开始罗列匹配项
  "############# YCM #######################
  set t_Co=256

endf

function! myspacevim#after() abort
  let leader=';'
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
  hi! ShowMarksHLl ctermbg=Yellow   ctermfg=Black  guibg=#FFDB72    guifg=Black
  " hi ShowMarksHLu ctermbg=Magenta  ctermfg=Black  guibg=#FFB3FF    guifg=Black
  hi! ShowMarksHLu ctermbg=green  ctermfg=Black  guibg=#FFB3FF    guifg=Black
  highlight BookmarkLine ctermbg=Yellow ctermfg=Black
  set autochdir
  "to avoid warn msg when starting vim: "Found a swap file by the name"
  set noswapfile

  " set timeout after presss space key
  set timeoutlen=300
  set noautoread

  set t_Co=256
  set t_AB=[48;5;%dm
  set t_AF=[38;5;%dm
  " colorscheme desert
  " set number
  "make gf can work normally: If you wish to delete other characters from isfname, 
  "be sure to delete them one character at a time. That is, execute :set isfname-=- and :set isfname-=:,
  "not :set isfname-=-:. The last command will work only if -: are present in isfname together and in that order
  set isfname-={
  set isfname-=}
  set isfname-=,
  set isfname-==
  set isfname+=@-@

  set sessionoptions=buffers

  set wildmode=list:full
  set wildmenu
  set showmatch
  set ignorecase
  "following setting conflict with spacevim
  " syntax enable
  " syntax on
  " filetype on
  " filetype plugin indent on
  set nobackup
  set history=50
  " if myos == "Linux"
  "   set mousefocus=on
  " endif
  set mousemodel=extend
  "set selection=exclusive
  "set selectmode=mouse,key
  set noet
  " set sw=4
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
  set expandtab
  set wrap

  let mapleader = ";"
  let leader=';'
  let myos = substitute(system('uname'), "\n", "", "")

  noremap ;vv <Esc>bi{<Esc>ea}<Esc>
  "let g:tagbar_iconchars = ['▸', '▾']
  let g:tagbar_iconchars = ['+', '-']

  set showcmd
  " ############# cscope and ctags BEGIN ###############################################################
  " #分号是必不可少的。这个命令让vim首先在当前目录里寻找tags文件，如果没有找到tags文件，
  " #或者没有找到对应的目标，就到父目录中查找，一直向上递归。因为tags文件中记录的路径总
  " #是相对于tags文件所在的路径，所以要使用第二个设置项来改变vim的当前目录。
  set tags=tags; 
  set tagcase=match  "Don't ignore case
  "set iskeyword+=_,@,%,#,-
  set iskeyword+=_,-
  set completeopt=longest,menu
  "set cscopequickfix=s-,c-,d-,i-,t-,e-,a-,g-
  set cscopequickfix=s-,c-,d-,i-,t-,e-
  if has("cscope")
    "echo "has cscope"
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
    nmap <C-\>a :cs find a <C-R>=expand("<cword>")<CR><CR>:botright copen<CR><CR>
  endif
  set t_Co=256
  "############# cscope and ctags END ###############################################################
   "call clipboard#set('/home/zhaoyong.zzy/common/sh/myyank.sh -', 'tmux save-buffer -')
   "xnoremap <silent> <Leader>y :<C-u>call CopyToWindowsClipboard()<cr>
endf
