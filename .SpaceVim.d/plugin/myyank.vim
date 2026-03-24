" 可视模式：<Leader>y 把选区内容通过 myyank.sh 复制到剪贴板
function! CopyToWindowsClipboard() range
    " 获取选中的文本
    let saved_reg = @"
    silent normal! gvy
    let selected_text = @"
    let @" = saved_reg
    
    " 创建临时文件
    let tempfile = tempname()
    echo tempfile
    call writefile(split(selected_text, "\n", 1), tempfile)
    
    " 使用 silent ! 直接输出到终端
    execute 'silent !myyank.sh < ' . shellescape(tempfile)
    
    " 清理临时文件
    call delete(tempfile)
    
    " 返回正常模式并显示消息
    redraw!
    echo "Text copied to Windows clipboard via OSC52"
endfunction

"ynoremap <leader>Y :call CopyToWindowsClipboard()<CR>
"xnoremap <leader>Y :call CopyToWindowsClipboard()<CR>
"vnoremap <leader>Y :'<,'>call CopyToWindowsClipboard()<CR>
xnoremap <silent> <Leader>M :<C-u>call CopyToWindowsClipboard()<cr>
" all make no sense
"xnoremap <silent> <Leader><cr> :<C-u>call CopyToWindowsClipboard()<cr>
"xnoremap <silent> <Leader>y :<C-u>call CopyToWindowsClipboard()<cr>
"xnoremap <silent> <Leader>Y :<C-u>call CopyToWindowsClipboard()<cr>

"## seems cannot work
function! MyYankVisual() range abort
  " 保存无名寄存器
  let l:save_reg = @"

  " 把可视选区复制到无名寄存器 "
  normal! ""gvy
  let l:text = @"

  " 恢复无名寄存器
  let @" = l:save_reg

  " 把选区内容作为 stdin 传给 myyank.sh
  " 如果 myyank.sh 不在 PATH，用绝对路径替换 'myyank.sh'
  call system('myyank.sh', l:text)
endfunction

"## seems cannot work
function! CopyToWindowsClipboard2() range
    let saved_reg = @"
    silent normal! gvy
    let selected_text = @"
    let @" = saved_reg
    
    echo "Selected text length: " . len(selected_text)
    
    " 测试系统调用
    let test_result = system('echo "test"')
    echo "System call test: " . test_result
    
    let result = system('myyank.sh', selected_text)
    echo "Script result: " . result
    echo "Exit code: " . v:shell_error
  endfunction

" 在 SpaceVim 中添加自定义映射
" call SpaceVim#custom#SPC('vnoremap', ['y', 'y'], 'call CopyToWindowsClipboard()', 'Yank to Windows clipboard', 1)

" 或者使用 leader 映射（如果你想要 leader+y）
"let g:mapleader = '\'  " SpaceVim 默认 leader 是空格，但这里用反斜杠示例
"vnoremap <leader>y :call CopyToWindowsClipboard()<CR>

" 可视模式映射：<Leader>y 调用上面的函数, 不起作用
" xnoremap <silent> <Leader>y :<C-u>call MyYankVisual()<CR>

