" only enable auto completion in Mutt mails
" only setup muttrc file after command-line parameters have been processed
autocmd BufRead,BufNewFile,BufFilePost mutt{ng,}-*-\w\+,mutt[[:alnum:]_-]\\\{6\},neomutt-[[:alnum:]_-]\\\{6\}
      \ exe 'setlocal completefunc=muttaliases#CompleteMuttAliases' |
      \ exe 'command! -buffer EditAliases call muttaliases#EditMuttAliasesFile()' |
      \ autocmd BufWinEnter <buffer> call muttaliases#SetMuttAliasesFile()
