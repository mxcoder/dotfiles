# bash completion for kaf                                  -*- shell-script -*-

__kaf_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__kaf_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__kaf_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__kaf_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__kaf_handle_reply()
{
    __kaf_debug "${FUNCNAME[0]}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __kaf_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __kaf_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions=("${must_have_one_noun[@]}")
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
		if declare -F __kaf_custom_func >/dev/null; then
			# try command name qualified custom func
			__kaf_custom_func
		else
			# otherwise fall back to unqualified for compatibility
			declare -F __custom_func >/dev/null && __custom_func
		fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
        compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__kaf_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__kaf_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__kaf_handle_flag()
{
    __kaf_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __kaf_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __kaf_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __kaf_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __kaf_contains_word "${words[c]}" "${two_word_flags[@]}"; then
			  __kaf_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__kaf_handle_noun()
{
    __kaf_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __kaf_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __kaf_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__kaf_handle_command()
{
    __kaf_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_kaf_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __kaf_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__kaf_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __kaf_handle_reply
        return
    fi
    __kaf_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __kaf_handle_flag
    elif __kaf_contains_word "${words[c]}" "${commands[@]}"; then
        __kaf_handle_command
    elif [[ $c -eq 0 ]]; then
        __kaf_handle_command
    elif __kaf_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __kaf_handle_command
        else
            __kaf_handle_noun
        fi
    else
        __kaf_handle_noun
    fi
    __kaf_handle_word
}


__kaf_config_use_cluster() {
    if out=$( ./kaf config get-clusters --no-headers ); then
        COMPREPLY=( $( compgen -W "${out[*]}" -- "$cur" ) )
    fi
}

__kaf_topics() {
    if out=$( ./kaf topics --no-headers 2>/dev/null | awk '{print $1}' ); then
        COMPREPLY=( $( compgen -W "${out[*]}" -- "$cur" ) )
    fi
}

__kaf_groups() {
    if out=$( ./kaf groups --no-headers 2>/dev/null | awk '{print $1}' ); then
        COMPREPLY=( $( compgen -W "${out[*]}" -- "$cur" ) )
    fi
}

__kaf_custom_func() {
    case ${last_command} in
        kaf_config_use-cluster)
            __kaf_config_use_cluster
        ;;
        kaf_consume | kaf_produce | kaf_topic_add-config | kaf_topic_delete | kaf_topic_describe)
            __kaf_topics
        ;;
        kaf_group_commit | kaf_group_delete | kaf_group_describe)
            __kaf_groups
        ;;
        *)
        ;;
    esac
}

_kaf_completion()
{
    last_command="kaf_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    must_have_one_noun+=("bash")
    must_have_one_noun+=("zsh")
    noun_aliases=()
}

_kaf_config_add-cluster()
{
    last_command="kaf_config_add-cluster"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--broker-version=")
    two_word_flags+=("--broker-version")
    local_nonpersistent_flags+=("--broker-version=")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_config_add-eventhub()
{
    last_command="kaf_config_add-eventhub"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--eh-connstring=")
    two_word_flags+=("--eh-connstring")
    local_nonpersistent_flags+=("--eh-connstring=")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_config_current-context()
{
    last_command="kaf_config_current-context"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_config_get-clusters()
{
    last_command="kaf_config_get-clusters"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-headers")
    local_nonpersistent_flags+=("--no-headers")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_config_import()
{
    last_command="kaf_config_import"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    must_have_one_noun+=("ccloud")
    noun_aliases=()
}

_kaf_config_remove-cluster()
{
    last_command="kaf_config_remove-cluster"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_config_select-cluster()
{
    last_command="kaf_config_select-cluster"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_config_use-cluster()
{
    last_command="kaf_config_use-cluster"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_config()
{
    last_command="kaf_config"

    command_aliases=()

    commands=()
    commands+=("add-cluster")
    commands+=("add-eventhub")
    commands+=("current-context")
    commands+=("get-clusters")
    commands+=("import")
    commands+=("remove-cluster")
    commands+=("select-cluster")
    commands+=("use-cluster")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_consume()
{
    last_command="kaf_consume"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--commit")
    local_nonpersistent_flags+=("--commit")
    flags+=("--follow")
    flags+=("-f")
    local_nonpersistent_flags+=("--follow")
    flags+=("--group=")
    two_word_flags+=("--group")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--group=")
    flags+=("--key-proto-type=")
    two_word_flags+=("--key-proto-type")
    local_nonpersistent_flags+=("--key-proto-type=")
    flags+=("--offset=")
    two_word_flags+=("--offset")
    local_nonpersistent_flags+=("--offset=")
    flags+=("--partitions=")
    two_word_flags+=("--partitions")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--partitions=")
    flags+=("--proto-exclude=")
    two_word_flags+=("--proto-exclude")
    local_nonpersistent_flags+=("--proto-exclude=")
    flags+=("--proto-include=")
    two_word_flags+=("--proto-include")
    local_nonpersistent_flags+=("--proto-include=")
    flags+=("--proto-type=")
    two_word_flags+=("--proto-type")
    local_nonpersistent_flags+=("--proto-type=")
    flags+=("--raw")
    local_nonpersistent_flags+=("--raw")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_group_commit()
{
    last_command="kaf_group_commit"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--offset=")
    two_word_flags+=("--offset")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--offset=")
    flags+=("--partition=")
    two_word_flags+=("--partition")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--partition=")
    flags+=("--topic=")
    two_word_flags+=("--topic")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--topic=")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_group_delete()
{
    last_command="kaf_group_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_group_describe()
{
    last_command="kaf_group_describe"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_group_ls()
{
    last_command="kaf_group_ls"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-headers")
    local_nonpersistent_flags+=("--no-headers")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_group()
{
    last_command="kaf_group"

    command_aliases=()

    commands=()
    commands+=("commit")
    commands+=("delete")
    commands+=("describe")
    commands+=("ls")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_groups()
{
    last_command="kaf_groups"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-headers")
    local_nonpersistent_flags+=("--no-headers")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_node_ls()
{
    last_command="kaf_node_ls"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-headers")
    local_nonpersistent_flags+=("--no-headers")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_node()
{
    last_command="kaf_node"

    command_aliases=()

    commands=()
    commands+=("ls")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_nodes()
{
    last_command="kaf_nodes"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_produce()
{
    last_command="kaf_produce"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--header=")
    two_word_flags+=("--header")
    two_word_flags+=("-H")
    local_nonpersistent_flags+=("--header=")
    flags+=("--key=")
    two_word_flags+=("--key")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--key=")
    flags+=("--key-proto-type=")
    two_word_flags+=("--key-proto-type")
    local_nonpersistent_flags+=("--key-proto-type=")
    flags+=("--num=")
    two_word_flags+=("--num")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--num=")
    flags+=("--partition=")
    two_word_flags+=("--partition")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--partition=")
    flags+=("--partitioner=")
    two_word_flags+=("--partitioner")
    local_nonpersistent_flags+=("--partitioner=")
    flags+=("--proto-exclude=")
    two_word_flags+=("--proto-exclude")
    local_nonpersistent_flags+=("--proto-exclude=")
    flags+=("--proto-include=")
    two_word_flags+=("--proto-include")
    local_nonpersistent_flags+=("--proto-include=")
    flags+=("--proto-type=")
    two_word_flags+=("--proto-type")
    local_nonpersistent_flags+=("--proto-type=")
    flags+=("--timestamp=")
    two_word_flags+=("--timestamp")
    local_nonpersistent_flags+=("--timestamp=")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_query()
{
    last_command="kaf_query"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--grep=")
    two_word_flags+=("--grep")
    local_nonpersistent_flags+=("--grep=")
    flags+=("--key=")
    two_word_flags+=("--key")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--key=")
    flags+=("--key-proto-type=")
    two_word_flags+=("--key-proto-type")
    local_nonpersistent_flags+=("--key-proto-type=")
    flags+=("--proto-exclude=")
    two_word_flags+=("--proto-exclude")
    local_nonpersistent_flags+=("--proto-exclude=")
    flags+=("--proto-include=")
    two_word_flags+=("--proto-include")
    local_nonpersistent_flags+=("--proto-include=")
    flags+=("--proto-type=")
    two_word_flags+=("--proto-type")
    local_nonpersistent_flags+=("--proto-type=")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic_add-config()
{
    last_command="kaf_topic_add-config"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic_create()
{
    last_command="kaf_topic_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--compact")
    local_nonpersistent_flags+=("--compact")
    flags+=("--partitions=")
    two_word_flags+=("--partitions")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--partitions=")
    flags+=("--replicas=")
    two_word_flags+=("--replicas")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--replicas=")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic_delete()
{
    last_command="kaf_topic_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic_describe()
{
    last_command="kaf_topic_describe"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic_ls()
{
    last_command="kaf_topic_ls"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-headers")
    local_nonpersistent_flags+=("--no-headers")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic_set-config()
{
    last_command="kaf_topic_set-config"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic_update()
{
    last_command="kaf_topic_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--partition-assignments=")
    two_word_flags+=("--partition-assignments")
    local_nonpersistent_flags+=("--partition-assignments=")
    flags+=("--partitions=")
    two_word_flags+=("--partitions")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--partitions=")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topic()
{
    last_command="kaf_topic"

    command_aliases=()

    commands=()
    commands+=("add-config")
    commands+=("create")
    commands+=("delete")
    commands+=("describe")
    commands+=("ls")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("list")
        aliashash["list"]="ls"
    fi
    commands+=("set-config")
    commands+=("update")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_topics()
{
    last_command="kaf_topics"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--no-headers")
    local_nonpersistent_flags+=("--no-headers")
    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kaf_root_command()
{
    last_command="kaf"

    command_aliases=()

    commands=()
    commands+=("completion")
    commands+=("config")
    commands+=("consume")
    commands+=("group")
    commands+=("groups")
    commands+=("node")
    commands+=("nodes")
    commands+=("produce")
    commands+=("query")
    commands+=("topic")
    commands+=("topics")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--brokers=")
    two_word_flags+=("--brokers")
    two_word_flags+=("-b")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    two_word_flags+=("-c")
    flags+=("--config=")
    two_word_flags+=("--config")
    flags+=("--schema-registry=")
    two_word_flags+=("--schema-registry")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_kaf()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __kaf_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("kaf")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local nouns=()

    __kaf_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_kaf kaf
else
    complete -o default -o nospace -F __start_kaf kaf
fi

# ex: ts=4 sw=4 et filetype=sh
