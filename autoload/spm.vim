" This designed to work with iCompleteMe signs
function! s:SetUpSigns()
  " We try to ensure backwards compatibility with Syntastic if the user has
  " already defined styling for Syntastic highlight groups.

  if !hlexists( 'IcmErrorSign' )
    if hlexists( 'SyntasticErrorSign')
      highlight link IcmErrorSign SyntasticErrorSign
    else
      highlight link IcmErrorSign error
    endif
  endif

  if !hlexists( 'IcmWarningSign' )
    if hlexists( 'SyntasticWarningSign')
      highlight link IcmWarningSign SyntasticWarningSign
    else
      highlight link IcmWarningSign todo
    endif
  endif

  if !hlexists( 'IcmErrorLine' )
    highlight link IcmErrorLine SyntasticErrorLine
  endif

  if !hlexists( 'IcmWarningLine' )
    highlight link IcmWarningLine SyntasticWarningLine
  endif

  exe 'sign define IcmError text=' . g:icm_error_symbol .
        \ ' texthl=IcmErrorSign linehl=IcmErrorLine'
  exe 'sign define IcmWarning text=' . g:icm_warning_symbol .
        \ ' texthl=IcmWarningSign linehl=IcmWarningLine'
endfunction


function! s:SetUpSyntaxHighlighting()
  " We try to ensure backwards compatibility with Syntastic if the user has
  " already defined styling for Syntastic highlight groups.

  if !hlexists( 'IcmErrorSection' )
    if hlexists( 'SyntasticError' )
      highlight link IcmErrorSection SyntasticError
    else
      highlight link IcmErrorSection SpellBad
    endif
  endif

  if !hlexists( 'IcmWarningSection' )
    if hlexists( 'SyntasticWarning' )
      highlight link IcmWarningSection SyntasticWarning
    else
      highlight link IcmWarningSection SpellCap
    endif
  endif
endfunction


function! s:SetUpBackwardsCompatibility()
  let complete_in_comments_and_strings =
        \ get( g:, 'icm_complete_in_comments_and_strings', 0 )

  if complete_in_comments_and_strings
    let g:icm_complete_in_strings = 1
    let g:icm_complete_in_comments = 1
  endif

  " icm_filetypes_to_completely_ignore is the old name for fileype_blacklist
  if has_key( g:, 'icm_filetypes_to_completely_ignore' )
    let g:filetype_blacklist =  g:icm_filetypes_to_completely_ignore
  endif
endfunction
