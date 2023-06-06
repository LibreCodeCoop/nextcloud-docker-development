# ~/.bash aliases

With an alias you can simplify the execution of big and complex commands assigning an alias to the big command and using the alias as a new command.

Bash alias is often defined in `~/.bashrc` file. However, it is possible to use `~/.bash_aliases` file too on certain Linux distros.

You may want to put all your additions into a separate file like `~/.bash_aliases`, instead of adding them directly to ~/.bashrc file.

## Calling ~/bash aliases

The ~/.bash_aliases must be called by your $HOME/.bashrc file as follows:

```bash
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```
The `~/.bashrc` file is executed every when you start a new terminal session. If you don't want to start a new terminal, run the follow command to execute your changes:

```bash
source ~/.bashrc
```

## Sample ~/.bash_aliases file

```bash
alias occ='docker compose exec -u www-data nextcloud occ'
alias nextcloud-mysql='docker compose up nextcloud mysql nginx mailhog redis'
alias nextcloud-pgsql='docker compose up nextcloud pgsql nginx mailhog redis'
```

⬅️ [Back to index](../README.md)
