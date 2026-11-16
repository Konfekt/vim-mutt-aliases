scriptencoding utf-8
" Headless tests for vim-mutt-aliases.
" Run with test/run.sh, or:
"   vim -N -u NONE -i NONE --not-a-term -S test/test.vim
"   nvim --headless -u NONE -i NONE -S test/test.vim
" Results are written to the file in $MUTTALIASES_TEST_OUT (default:
" test/result.txt); the editor exits with status 1 if any test fails.

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:out = empty($MUTTALIASES_TEST_OUT) ? s:root . '/test/result.txt' : $MUTTALIASES_TEST_OUT

" Sandbox: a fake $HOME and a $PATH without any real mutt.
let s:tmp = tempname()
call mkdir(s:tmp . '/home/.mutt', 'p')
call mkdir(s:tmp . '/bin', 'p')
call mkdir(s:tmp . '/nobin', 'p')
let $HOME = s:tmp . '/home'
let $PATH = s:tmp . '/nobin'

let &runtimepath = s:root . ',' . &runtimepath
execute 'source' fnameescape(s:root . '/plugin/muttaliases.vim')
set noswapfile hidden nomore

let s:log = []
let s:failed = 0

function! s:Check(name, got, want) abort
  if a:got ==# a:want
    call add(s:log, 'ok   ' . a:name)
  else
    let s:failed += 1
    call add(s:log, 'FAIL ' . a:name . ': got ' . string(a:got) . ', want ' . string(a:want))
  endif
endfunction

" Run {cmd}; return the error message or '' when there was none.
function! s:Try(cmd) abort
  try
    execute a:cmd
  catch
    return v:exception
  endtry
  return ''
endfunction

function! s:Detect() abort
  silent! unlet g:muttaliases_file
  return s:Try('call muttaliases#SetMuttAliasesFile()')
endfunction

function! s:Words(base) abort
  return map(muttaliases#CompleteMuttAliases(0, a:base), 'v:val.word')
endfunction

let s:aliases = s:tmp . '/home/.mutt/aliases'
call writefile([
      \ '# a comment line',
      \ 'alias foo foo@bar.com',
      \ 'alias -group work -group team bob Bob Builder <bob@build.er>',
      \ 'alias xfoo x@foo.org',
      \ 'alias quoted "Doe, Jane" <jane@doe.org>',
      \ 'alias escaped \"Roe, Rick\" <rick@roe.org>',
      \ 'alias carl carl@c.org # Carl',
      \ 'alias carlton Carl Ton <ct@c.org>   # friend',
      \ 'alias ' . repeat('ü', 20) . ' u@u.de',
      \ ], s:aliases)

" --- detection ---------------------------------------------------------------

function! s:TestMuttrcFallback() abort
  call writefile(['set alias_file = "~/.mutt/aliases"'], $HOME . '/.muttrc')
  call s:Check('muttrc: no error', s:Detect(), '')
  call s:Check('muttrc: alias_file found', get(g:, 'muttaliases_file', ''), resolve(s:aliases))
endfunction

function! s:TestMuttrcTrailingComment() abort
  call writefile(["set alias_file='~/.mutt/aliases'   # my aliases"], $HOME . '/.muttrc')
  call s:Check('muttrc comment: no error', s:Detect(), '')
  call s:Check('muttrc comment: alias_file found', get(g:, 'muttaliases_file', ''), resolve(s:aliases))
  call delete($HOME . '/.muttrc')
endfunction

function! s:TestMuttrcXdg() abort
  call mkdir($HOME . '/.config/neomutt', 'p')
  call writefile(['set alias_file = ~/.mutt/aliases'], $HOME . '/.config/neomutt/neomuttrc')
  call s:Check('neomuttrc: no error', s:Detect(), '')
  call s:Check('neomuttrc: alias_file found', get(g:, 'muttaliases_file', ''), resolve(s:aliases))
  call delete($HOME . '/.config', 'rf')
endfunction

function! s:TestNeomuttQuery() abort
  let exe = s:tmp . '/bin/neomutt'
  call writefile(['#!/bin/sh', 'echo ''set alias_file = "~/.mutt/aliases"'''], exe)
  call setfperm(exe, 'rwx------')
  let $PATH = s:tmp . '/bin:/usr/bin:/bin'
  call s:Check('neomutt -Q: no error', s:Detect(), '')
  call s:Check('neomutt -Q: alias_file found', get(g:, 'muttaliases_file', ''), resolve(s:aliases))
  let $PATH = s:tmp . '/nobin'
endfunction

function! s:TestUserTilde() abort
  let g:muttaliases_file = '~/.mutt/aliases'
  call s:Check('user ~ path: no error', s:Try('call muttaliases#SetMuttAliasesFile()'), '')
  call s:Check('user ~ path: completes', s:Words('foo'), ['foo@bar.com', 'x@foo.org'])
endfunction

function! s:TestInvalidFile() abort
  let g:muttaliases_file = s:tmp . '/missing'
  let err = s:Try('call muttaliases#SetMuttAliasesFile()')
  call s:Check('invalid file: error raised', err =~# 'no valid mutt aliases file', 1)
  call s:Check('invalid file: variable cleared', g:muttaliases_file, '')
  call s:Check('invalid file: completion empty', muttaliases#CompleteMuttAliases(0, 'foo'), [])
endfunction

" --- completion --------------------------------------------------------------

function! s:TestFindstart() abort
  enew!
  call setline(1, 'To:   foo')
  call cursor(1, 10)
  call s:Check('findstart: after word', muttaliases#CompleteMuttAliases(1, ''), 6)
  call setline(1, 'To: a@b.c, bo')
  call cursor(1, 14)
  call s:Check('findstart: after comma', muttaliases#CompleteMuttAliases(1, ''), 11)
endfunction

function! s:TestBlankLines() abort
  let file = s:tmp . '/blank'
  call writefile(['', '   ', "\t", 'alias foo foo@bar.com'], file)
  let g:muttaliases_file = file
  call s:Check('blank lines: no error', s:Try('let g:words = s:Words("foo")'), '')
  call s:Check('blank lines: completes', get(g:, 'words', []), ['foo@bar.com'])
  let g:muttaliases_file = s:aliases
endfunction

function! s:TestCompletion() abort
  let g:muttaliases_file = s:aliases
  call s:Check('begin match ranks first', s:Words('foo'), ['foo@bar.com', 'x@foo.org'])
  call s:Check('group options dropped, name quoted', s:Words('bob'), ['"Bob Builder" <bob@build.er>'])
  call s:Check('no doubled quotes', s:Words('quoted'), ['"Doe, Jane" <jane@doe.org>'])
  call s:Check('backslashes dropped', s:Words('escaped'), ['"Roe, Rick" <rick@roe.org>'])
  call s:Check('comments dropped without trailing blanks', s:Words('carl'),
        \ ['carl@c.org', '"Carl Ton" <ct@c.org>'])
  call s:Check('case-insensitive', s:Words('FOO'), ['foo@bar.com', 'x@foo.org'])
  call s:Check('no match', s:Words('zzz'), [])
  let item = muttaliases#CompleteMuttAliases(0, 'foo')[0]
  call s:Check('item menu', item.menu, 'foo@bar.com')
  call s:Check('item abbr', item.abbr, 'foo')
  let abbr = muttaliases#CompleteMuttAliases(0, 'üü')[0].abbr
  call s:Check('multibyte abbr kept intact', abbr, repeat('ü', 20))
  let long = repeat('a', 40)
  call writefile(['alias ' . long . ' l@l.de'], s:tmp . '/long')
  let g:muttaliases_file = s:tmp . '/long'
  call s:Check('long abbr truncated', muttaliases#CompleteMuttAliases(0, 'aa')[0].abbr, repeat('a', 31) . '...')
  let g:muttaliases_file = s:aliases
endfunction

" --- commands ----------------------------------------------------------------

function! s:TestFileTypeSetup() abort
  let g:muttaliases_file = s:aliases
  enew!
  setfiletype mail
  call s:Check('filetype: completefunc', &l:completefunc, 'muttaliases#CompleteMuttAliases')
  call s:Check('filetype: EditAliases defined', exists(':EditAliases'), 2)
  EditAliases
  call s:Check('EditAliases opens file', resolve(expand('%:p')), resolve(s:aliases))
endfunction

function! s:TestEditAliasesSpecialName() abort
  let file = s:tmp . '/my #aliases %x'
  call writefile(['alias a a@a.de'], file)
  let g:muttaliases_file = file
  enew!
  MuttAliasesCompletion
  call s:Check('EditAliases special name: no error', s:Try('EditAliases'), '')
  call s:Check('EditAliases special name: opened', expand('%:p'), file)
  let g:muttaliases_file = s:aliases
endfunction

function! s:TestInsertModeCompletion() abort
  let g:muttaliases_file = s:aliases
  enew!
  MuttAliasesCompletion
  call setline(1, 'To: bob')
  call feedkeys("A\<C-x>\<C-u>\<C-y>\<Esc>", 'xt')
  call s:Check('insert-mode completion', getline(1), 'To: "Bob Builder" <bob@build.er>')
endfunction

for s:test in [
      \ 'MuttrcFallback', 'MuttrcTrailingComment', 'MuttrcXdg', 'NeomuttQuery',
      \ 'UserTilde', 'InvalidFile', 'Findstart', 'BlankLines', 'Completion',
      \ 'FileTypeSetup', 'EditAliasesSpecialName', 'InsertModeCompletion']
  let s:err = s:Try('call s:Test' . s:test . '()')
  if !empty(s:err)
    let s:failed += 1
    call add(s:log, 'FAIL ' . s:test . ': ' . s:err)
  endif
endfor

call add(s:log, s:failed ? s:failed . ' failed' : 'all passed')
call writefile(s:log, s:out)
call delete(s:tmp, 'rf')
execute s:failed ? 'cquit' : 'qall!'
