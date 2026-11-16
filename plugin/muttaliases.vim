if exists('g:loaded_muttaliases') || &compatible
  finish
endif
let g:loaded_muttaliases = 1

let s:keepcpo = &cpoptions
set cpoptions&vim
" ------------------------------------------------------------------------------

if !exists('g:muttaliases_filetypes')
  let g:muttaliases_filetypes = [ 'mail' ]
endif

command! MuttAliasesCompletion call s:muttaliases()

function! s:muttaliases() abort
  call muttaliases#SetMuttAliasesFile()
  setlocal completefunc=muttaliases#CompleteMuttAliases
  command! -buffer EditAliases call muttaliases#EditMuttAliasesFile()
endfunction

augroup muttaliases
  autocmd!
  if !empty(g:muttaliases_filetypes)
    exe 'autocmd FileType' join(g:muttaliases_filetypes, ',') 'MuttAliasesCompletion'
  endif
augroup end

" ------------------------------------------------------------------------------
let &cpoptions = s:keepcpo
unlet s:keepcpo
