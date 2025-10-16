# argparse a/attribute= g/gui l/list o/open p/password s/show t/thorough u/username -- $argv


complete --command kpass --exclusive  --long gui        -s g  --description "Open keepassxc GUI APP"
complete --command kpass              --long list       -s l  --description "LIST matches instead of showing a fzf interface"
complete --command kpass --exclusive  --long open       -s o  --description "OPEN keepassxc-cli app in interactive mode (it will always ask for a password)"
complete --command kpass --exclusive  --long password   -s p  --description "Search in PASSWORDS fields specifically"
complete --command kpass              --long show       -s s  --description "SHOW the selected entry's info instead of copying the password"
complete --command kpass --exclusive  --long thorough   -s t  --description "Search THOROUGHLY (in all these fields: title, username, url, notes, attachemnts, group, tags)"
complete --command kpass --exclusive  --long username   -s u  --description "Copy the selected entry's username field instead of the password"
