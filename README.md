Complete `mutt` aliases (listed in `~/.mutt/aliases`) inside Vim;
useful

- when using `Vim` as editor for `mutt` (especially with `$edit_headers` set), and
- even more so with the shell script [mutt-alias.sh](https://github.com/Konfekt/mutt-alias.sh) to populate the aliases file with recent e-mail addresses in your Inbox (or Sent folder).

# Usage

When you're editing a mail file in Vim that reads
```
    From: Lu Guanqun <guanqun.lu@gmail.com>
    To:   foo
```
and in your mutt aliases file there is an entry
```
    alias foo foo@bar.com
```
and your cursor is right after `foo`, then hit `Ctrl+X Ctrl+U` to obtain:
```
    From: Lu Guanqun <guanqun.lu@gmail.com>
    To:   foo@bar.com
```
# Commands

The command `:EditAliases` opens the mutt aliases file in `Vim`.
(For less typing, you can (command-line) alias it to `ea` by [vim-alias](https://github.com/Konfekt/vim-alias))

To complete e-mail addresses inside Vim press `CTRL-X CTRL-U` in insert
mode. See `:help i_CTRL-X_CTRL-U` and `:help compl-function`.

# Setup

The mutt aliases file is automatically set to the value of the variable `$alias_file` used by `mutt`.
To explicitly set the path to a mutt aliases file `$file`, add to your `.vimrc` the line

```vim
  let g:muttaliases_file = '$file'
```

For example, `$file` could be

```
  ~/.mutt/aliases
```

As a suggestion, if you use different mail accounts with different aliases, add in `.muttrc` a folder hook, say for the account `mailo`,

```
folder-hook '~/.local/share/mbsync/mailo/' 'source "$XDG_CONFIG_HOME/mutt/accounts/mailo"'
```

and in `"$XDG_CONFIG_HOME/mutt/accounts/mailo"` tell Vim about the alias file by

```
set editor = 'vim +"let g:muttaliases_file=\"$XDG_CONFIG_HOME/mutt/accounts/mailo.aliases\"" %s'
```

# Related:

- To add aliases

    - for all e-mail addresses found in a mail dir, such as the `INBOX`, there is the [mutt-alias.sh](https://github.com/Konfekt/mutt-alias.sh) shell script;
        best run by a, say weekly, [(ana)cronjob](https://konfekt.github.io/blog/2016/12/11/sane-cron-setup).
    -  for every opened e-mail, there is a [shell script](http://wcaleb.org/blog/mutt-tips) that uses `$display_fiter` (and which is extended in [mutt-alias-auto-add](https://github.com/teddywing/mutt-alias-auto-add)).
- The plugin [vim-notmuch-addrlookup](https://github.com/Konfekt/vim-notmuch-addrlookup) lets you complete e-mail addresses in Vim by those indexed by [notmuch](https://notmuchmail.org).
- The plugin [vim-mailquery](https://github.com/Konfekt/vim-mailquery) lets you complete e-mail addresses in Vim by those in your Inbox (or any other mail folder).

# Credits

Forked from [Lu Guanqun](mailto:guanqun.lu@gmail.com)'s [vim-mutt-aliases-plugin](https://github.com/guanqun/vim-mutt-aliases-plugin/tree/063a7bdd0d852a118253278721f74a053776135d).

# License

Distributable under the same terms as Vim itself.  See `:help license`.

