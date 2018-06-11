" Use Swift with Vim thanks to Swift

" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

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

" Setup some autocmds
autocmd BufWritePost * call s:OnBufWritePost()

" FIXME: add this to swift
" autocmd QuitPre      * call s:Pyeval("server.Stop()")
"
" TODO:
" autocmd CursorMoved      * call s:Pyeval("swiftvim.event()")
autocmd CursorMoved      * call s:Pyeval("diag_ui.OnCursorMoved()")

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

# Setup Legacy diag ui
sys.path.insert(0, os.path.join(plugin_dir, 'plugin_python'))
from diagnostic_interface import DiagnosticInterface
diag_ui = DiagnosticInterface()
vim.command('return 1')
EOF
endfunction

function! s:OnCursorMoved()
endfunction

function! s:OnBufWritePost()
endfunction

if s:SetUpPython() != 1
  echom "Setting up python failed..." . s:path
endif

" EditorService Helpers

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
    call s:Pyeval("diag_ui.UpdateBuildState('" . a:file ."')")
endf

fun spm#showlogs()
    call s:Pyeval("server.PrintLogs()")
endf

" This is basic vim plugin boilerplate
let &cpo = s:save_cpo
unlet s:save_cpo

