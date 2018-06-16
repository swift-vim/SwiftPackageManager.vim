" Use Swift with Vim thanks to Swift

" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

" Setup default Symbols
let g:icm_error_symbol =
      \ get( g:, 'icm_error_symbol',
      \ get( g:, 'syntastic_error_symbol', '>>' ) )

let g:icm_warning_symbol =
      \ get( g:, 'icm_warning_symbol',
      \ get( g:, 'syntastic_warning_symbol', '>>' ) )


function! s:UsingPython3()
  if has('python3')
    return 1
  endif
  return 0
endfunction

" Prefer py3
let s:using_python3 = s:UsingPython3()
let s:python_until_eof = s:using_python3 ? "python3 << EOF" : "python << EOF"
let s:python_command = s:using_python3 ? "py3 " : "py "

let s:path = fnamemodify(expand('<sfile>:p:h'), ':h')

" autocmds

" Show a message when the user moves
autocmd CursorMoved * call s:Pyeval("swiftvim.event(1002, '')")

" Run some python
function! s:Pyeval( eval_string )
  if s:using_python3
    return py3eval( a:eval_string )
  endif
  return pyeval( a:eval_string )
endfunction

function! s:SetUpPython() abort
  exec s:python_until_eof
import vim
import os
import sys

# Directory of the plugin
plugin_dir  = vim.eval('s:path')

# Bootstrap Swift Plugin
sys.path.insert(0, os.path.join(plugin_dir, '.build'))
import swiftvim
swiftvim.load()

vim.command('return 1')
EOF
endfunction

" Wake up the runloop 
fun s:runloop_timer(timer)
    call s:Pyeval("swiftvim.event(2, '')")
endf

let timer = timer_start(100, function('s:runloop_timer'), {'repeat':-1})

if s:SetUpPython() != 1
  echom "Setting up python failed..." . s:path
endif

" UI Helpers:
fun spm#showerrfile(file)
    echom 'Build updated. results @ ' . a:file
    set errorformat=
			\%f:%l:%c:{%*[^}]}:\ error:\ %m,
			\%f:%l:%c:{%*[^}]}:\ fatal\ error:\ %m,
			\%f:%l:%c:{%*[^}]}:\ warning:\ %m,
			\%f:%l:%c:\ error:\ %m,
			\%f:%l:%c:\ fatal\ error:\ %m,
			\%f:%l:%c:\ warning:\ %m,
			\%f:%l:\ Error:\ %m,
			\%f:%l:\ error:\ %m,
			\%f:%l:\ fatal\ error:\ %m,
			\%f:%l:\ warning:\ %m
    execute "cgetfile " . a:file
endf

fun spm#showlogs()
    " TODO: Add log showing to SPMVim
    " call s:Pyeval("server.PrintLogs()")
endf

" This is basic vim plugin boilerplate
let &cpo = s:save_cpo
unlet s:save_cpo

