" Candidate mutt configuration files, searched in order when no mutt
" executable can be queried for $alias_file.
let s:muttrcs = [
      \ '~/.config/neomutt/neomuttrc', '~/.config/neomutt/muttrc',
      \ '~/.config/mutt/neomuttrc', '~/.config/mutt/muttrc',
      \ '~/.neomutt/neomuttrc', '~/.neomutt/muttrc',
      \ '~/.mutt/neomuttrc', '~/.mutt/muttrc',
      \ '~/.neomuttrc', '~/.muttrc']

" The aliases file in use, with ~ and environment variables expanded.
function! s:file() abort
  let file = get(g:, 'muttaliases_file', '')
  return empty(file) ? '' : resolve(expand(file))
endfunction

function! s:error(file) abort
  echoerr (empty(a:file) ? 'No mutt aliases file found.' : 'The file ' . a:file . ' is no valid mutt aliases file.')
        \ 'Please set $alias_file in ~/.muttrc or g:muttaliases_file in ~/.vimrc to a mutt aliases file!'
endfunction

" Ask (neo)mutt for $alias_file; mutt prints alias_file="...", neomutt
" set alias_file = "...".
function! s:query_mutt(mutt) abort
  silent let output = systemlist(a:mutt . ' -Q alias_file')
  for line in output
    let file = matchstr(line, '\v^\s*%(set\s+)?alias_file\s*\=\s*"\zs[^"]+\ze"\s*$')
    if !empty(file)
      return file
    endif
  endfor
  return ''
endfunction

" Read $alias_file from the first readable muttrc; the value may be quoted
" and followed by a comment.
function! s:parse_muttrc() abort
  for muttrc in s:muttrcs
    if filereadable(expand(muttrc))
      for line in readfile(expand(muttrc))
        let file = matchstr(line, '\v^\s*set\s+alias_file\s*\=\s*'
              \ . '%("\zs[^"]+\ze"|''\zs[^'']+\ze''|\zs[^"''[:space:]#]+\ze)'
              \ . '\s*%(#.*)?$')
        if !empty(file)
          return file
        endif
      endfor
      return ''
    endif
  endfor
  return ''
endfunction

function! muttaliases#SetMuttAliasesFile() abort
  if !exists('g:muttaliases_file')
    let mutt = get(filter(['neomutt', 'mutt'], 'executable(v:val)'), 0, '')
    let file = empty(mutt) ? '' : s:query_mutt(mutt)
    if empty(file)
      " No mutt, or it failed, for example on an error in the muttrc.
      let file = s:parse_muttrc()
    endif
    let g:muttaliases_file = empty(file) ? '' : resolve(expand(file))
  endif
  if !filereadable(s:file())
    let file = g:muttaliases_file
    let g:muttaliases_file = ''
    call s:error(file)
  endif
endfunction

function! muttaliases#EditMuttAliasesFile() abort
  let file = s:file()
  if empty(file)
    call s:error(file)
    return
  endif
  execute 'edit' fnameescape(file)
endfunction

" Return the number of ways {str} matches: anywhere (1), additionally after
" a delimiter (2), additionally at the beginning (3), or not at all (0).
function! s:score(str, patterns) abort
  let score = 0
  for pattern in a:patterns
    if a:str !~? pattern
      break
    endif
    let score += 1
  endfor
  return score
endfunction

" Turn the address part of an alias line into a completion word.
function! s:address(words) abort
  let address = join(a:words, ' ')
  " remove comments
  let address = substitute(address, '\v([^\\])#.*$', '\1', '')
  " remove \ (used for escaping ")...
  let address = substitute(address, '\\', '', 'g')
  let address = substitute(address, '\s\+$', '', '')
  " Add double quotes in case of special characters such as , or ;
  let address = substitute(address, '\v(^.*)\s+(\<[^>]+\>)', '"\1" \2', '')
  " ... but avoid doubling double quotes
  return substitute(address, '"\+', '"', 'g')
endfunction

function! muttaliases#CompleteMuttAliases(findstart, base) abort
  if a:findstart
    " locate the start of the word before the cursor
    let text_before_cursor = strpart(getline('.'), 0, col('.') - 1)
    return match(text_before_cursor, '\v<\S+$')
  endif

  let file = s:file()
  if empty(file) || !filereadable(file)
    return []
  endif

  " vim regexes to sort according to whether the base matches anywhere,
  " after a delimiter, or at the beginning (of the part before any @)
  let before = '\v^[^@]*'
  let base   = '\V' . escape(a:base, '\')
  let after  = '\v[^@]*($|[@])'
  let patterns = [
        \ before . base . after,
        \ before . '\v(^|\A)' . base . after,
        \ '\v^' . base . after]

  let results = [[], [], [], [], [], [], []]
  for line in readfile(file)
    " remove optional group parameters
    let words = split(substitute(line, '\v(\s+-group\s+\S+)+', '', ''))
    if len(words) < 3 || words[0] isnot# 'alias'
      continue
    endif
    let name = words[1]
    let name_score = s:score(name, patterns)
    if name_score == 0
      continue
    endif
    let address = s:address(words[2:])
    call add(results[name_score + s:score(address, patterns)], {
          \ 'word': address,
          \ 'abbr': strchars(name) < 35 ? name : strcharpart(name, 0, 31) . '...',
          \ 'menu': address,
          \ })
  endfor

  let sorted = []
  for group in reverse(results)
    call extend(sorted, sort(group, 1))
  endfor
  return uniq(sorted, 1)
endfunction
