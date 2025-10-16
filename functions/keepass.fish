function kpass --description "Mimics the functionality of pass using fzf (so it's arguably now better than pass when selecting an item to clip)"
    set kpcmd "keepassxc-cli"
    set kpclip_timeout 8
    # set fzfcmd "fzf --scheme=history --exit-0 -1"


    argparse a/attribute= g/gui l/list o/open p/password s/show t/thorough u/username -- $argv
    or return

    set kpass (GPG_AGENT_INFO="" gpg -r "$KPASS_GPG_RECIPIENT" -q -d "$KPASS_GPG_FILE")

    set search $argv[1]


    if set -q _flag_username
        set attribute username
    else
        set attribute password
    end

    if test -n "$_flag_attribute"
        set attribute $_flag_attribute
    end

    function get_flat_list_formatted --no-scope-shadowing

        set flat_list_formatted (echo $kpass | $kpcmd ls -q -R -f $KEYPASS_FILE | sed -e 's/^/\//')

        begin
          # Handle entries without a title (these will be duplicated) by only showing the dupes, the deduping those
          # Need to sort before running uniq
          for i in $flat_list_formatted; echo $i; end | sort | uniq -D | uniq;
          # remove all directories
          for i in $flat_list_formatted; echo $i; end | grep -v '/$'
        # calling sort here sorts the output from both of the above commands
        end | sort
    end


    if set -q _flag_thorough

        # Note:
        # An empty string and a "*" seem to have the same affect for the $search parameter.
        # So in this case, running all the commands below instead of a single search command is redundant and slower.

        # Note:
        # If there are no matches, the fzf command here will be given a single empty line (instead of 0 lines).
        # This was fixed in the last else block below by appending a ' || return' to the command substitution.
        # That worked there because the 'grep "$search"' command will exit with exit code 1 if there are no matches.
        # And that short circuits the `set items (...)` command which is the cause of the single empty line.
        # But here, we'll need another way to check if the input to fzf is a single empty line.

        # The situation was ultimately fixed for both scenarios in the same way.
        # Instead of using a new-line separated list of items inside a single string (via the use of the "$(...)" syntax), we're using arrays.
        # Then we're echoing each array element (for i in $items; echo $i; end).


        # This would be great is the above command could be on multiple lines like this
        set items (begin
            echo $kpass | $kpcmd search $KEYPASS_FILE "t:$search" 2>/dev/null
            echo $kpass | $kpcmd search $KEYPASS_FILE "u:$search" 2>/dev/null
            echo $kpass | $kpcmd search $KEYPASS_FILE "url:$search" 2>/dev/null
            echo $kpass | $kpcmd search $KEYPASS_FILE "n:$search" 2>/dev/null
            echo $kpass | $kpcmd search $KEYPASS_FILE "attach:$search" 2>/dev/null
            echo $kpass | $kpcmd search $KEYPASS_FILE "g:$search" 2>/dev/null
            echo $kpass | $kpcmd search $KEYPASS_FILE "tag:$search" 2>/dev/null
            for i in (get_flat_list_formatted); echo $i; end | grep "$search"
            end | sort | uniq)

        # TODO: Search attributes
        # echo $kpass | $kpcmd search $KEYPASS_FILE "attr:$search" 2>/dev/null

        if set -q _flag_list
          for i in $items; echo $i; end | grep (echo $search || '')
        else

          set item (for i in $items; echo $i; end | fzf --exit-0 -1 --scheme=history)
          or return

          echo Picked: (echo $item | string escape) of (for i in $items; echo $i; end | wc -l | tr -d ' ') 'item(s)' 1>&2
          echo 1>&2

          if set -q _flag_show
            echo $kpass | $kpcmd show $KEYPASS_FILE $item 2>/dev/null
          else

            # the 2>/dev/null allows the info about the timeout for when the clipboard will be restored,
            # but prevents the prompt for the password which is already given by the 'echo $kpass' part
            echo $kpass | $kpcmd clip -a $attribute $KEYPASS_FILE $item $kpclip_timeout 2>/dev/null

          end
        end

    else if set -q _flag_password

        set items (echo $kpass | $kpcmd search -q $KEYPASS_FILE "p:$search" 2>/dev/null)

        set history_line_num (grep '^- cmd: kc -p' -n ~/.local/share/fish/fish_history | tail -n 1 | cut -d : -f 1)
        awk -i inplace "NR==$history_line_num { gsub(/\y$search\y/, \"*****\") } 1" ~/.local/share/fish/fish_history
        echo 'INFO: search string redacted from shell history' 1>&2
        echo 1>&2

        if set -q _flag_list
            for i in $items; echo $i; end | grep (echo $search || '')
        else

          set item (for i in $items; echo $i; end | fzf --exit-0 -1 --scheme=history)
          or return

          echo Picked: (echo $item | string escape) of (for i in $items; echo $i; end | wc -l | tr -d ' ') 'item(s)' 1>&2
          echo 1>&2

          if set -q _flag_show
            echo $kpass | $kpcmd show $KEYPASS_FILE $item 2>/dev/null
          else

            # the 2>/dev/null allows the info about the timeout for when the clipboard will be restored,
            # but prevents the prompt for the password which is already given by the 'echo $kpass' part
            echo $kpass | $kpcmd clip -a $attribute $KEYPASS_FILE $item $kpclip_timeout 2>/dev/null

          end
        end

    else if set -q _flag_gui
        open -a KeePassXC $KEYPASS_FILE

    else if set -q _flag_open
        # This just quits keepassxc-cli immediately. It doesn't work as expected
        $kpcmd open $KEYPASS_FILE

        # echo $kpass | kpcli --kdb=$KEYPASS_FILE  < /dev/tty
        # echo $kpass | kpcli --kdb=$KEYPASS_FILE
        # echo "Starting an interactive command..."
        # read -P "Enter your name: " name
        # echo "Hello, $name!"
        # echo "Exiting interactive command."
        # fish -i --command "echo $kpass | exec $kpcmd open $KEYPASS_FILE 2>/dev/null"
        # commandline "echo '$kpass' | $kpcmd open $KEYPASS_FILE 2>/dev/null";
        # commandline "$kpcmd open $KEYPASS_FILE"
        # set piped_data (cat) # Read all piped input into a variable
        # echo $kpass | $kpcmd open $KEYPASS_FILE < /dev/tty
        # bash -i -c 'PASS=$(GPG_AGENT_INFO="" gpg -r "$KPASS_GPG_RECIPIENT" -q -d "$KPASS_GPG_FILE") keepassxc-cli open $KEYPASS_FILE <<< ${PASS}'

        # echo '$kpass' | $kpcmd open $KEYPASS_FILE 2>/dev/null < /dev/tty
    else

        # This assumes that all items that end in a forward slash are directories/groups and aren't actually password entries.
        # But when you run this function without an argument, there is a different amount of lines between this `set item` command and the previous `set item` command
        set items (for i in (get_flat_list_formatted); echo $i; end | grep "$search")

        if set -q _flag_list
            for i in $items; echo $i; end | grep (echo $search || '')
        else

          set item (for i in $items; echo $i; end | fzf --exit-0 -1 --scheme=history)
          or return

          echo Picked: (echo $item | string escape) of (for i in $items; echo $i; end | wc -l | tr -d ' ') 'item(s)' 1>&2
          echo 1>&2

          if set -q _flag_show
              echo $kpass | $kpcmd show $KEYPASS_FILE $item 2>/dev/null
          else

              # the 2>/dev/null allows the info about the timeout for when the clipboard will be restored,
              # but prevents the prompt for the password which is already given by the 'echo $kpass' part
              echo $kpass | $kpcmd clip -a $attribute $KEYPASS_FILE $item $kpclip_timeout 2>/dev/null

          end

        end

    end



# set err `echo $status`
# if [ $err -gt 0 ]
#     echo $pass
# end
end
