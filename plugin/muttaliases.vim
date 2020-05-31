if !exists('g:muttaliases_filetypes')
  let g:muttaliases_filetypes = [ 'mail' ]
endif

let s:fts = ''
for ft in g:muttaliases_filetypes
  let s:fts .= ft . ','
endfor
let s:fts = s:fts[:-1]

command! MuttAliasesCompletion call s:muttaliases()

function! s:muttaliases() abort
  call muttaliases#SetMuttAliasesFile()
  setlocal completefunc=muttaliases#CompleteMuttAliases
  command! -buffer EditAliases call muttaliases#EditMuttAliasesFile()
endfunction

augroup muttaliases
  autocmd!
  exe 'autocmd FileType' s:fts 'MuttAliasesCompletion'
augroup end

