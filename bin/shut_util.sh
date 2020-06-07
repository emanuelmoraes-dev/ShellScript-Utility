#!/bin/bash

# shut-util@2.0.0
# Script contendo vários utilitários
#
# Autor: Emanuel Moraes de Almeida
# Email: emanuelmoraes297@gmail.com
# Github: https://github.com/emanuelmoraes-dev

# Exibe na saída padrão uma string de um array unido por meio
# de um separador
#
# shut_util_join "<sep>" "${<array>[@]}"
function shut_util_join {
    local sep="$1"
    shift
    local rt="$1"
    shift

    for v in "$@"; do
        rt="${rt}${sep}${v}"
    done

    printf "$rt\n"
}

# Verifica se uma string está dentro de um array. Se a string
# estiver no array, finaliza-se a função corretamente. Caso
# contrário, a função é encerrada com erro
#
# shut_util_contains "<string>" "${<array>[@]}"
function shut_util_contains {
    if [ "$#" = 0 ]; then
        return 0
    fi

    local target="$1"
    shift

    local index=0
    for key in "$@"; do
        if [ "$key" = "$target" ]; then
            return 0
        fi

        let index=$index+1
    done

    return 1
}

# Cria um array de uma string por meio de um separador
#
# Parâmetros:
#     0: Nome do array global com o resultado
#     1: Separador
#     2: String a ser convertida em array
#
# shut_util_array "<array_name>" "<separador>" <string>
function shut_util_array {
    local array_name="$1"
    shift

    local sep="$1"
    local len_sep=${#sep}
    local i_last_sep
    let i_last_sep=$len_sep-1
    shift

    local args="$@"
    local len_args=${#args}

    local shut_util_return=()
    local i_return=0

    if [ "$len_args" != "0" ]; then
        shut_util_return[0]=""
    fi

    local ch
    local sub
    for ((i = 0; i < len_args; i++)); do
        ch="${args:i:1}"
        sub="${args:i:len_sep}"

        if [ -z "$sep" ]; then
            shut_util_return[$i_return]="${ch}"
            let i_return=$i_return+1
        elif [ "$sub" = "$sep" ]; then
            let i_return=$i_return+1
            shut_util_return[$i_return]=""
            let i=$i+$i_last_sep
        else
            shut_util_return[$i_return]="${shut_util_return[i_return]}${ch}"
        fi
    done

    declare -g -a $array_name=("${shut_util_return[@]}")
}

# Retorna na saída padrão o index da primeira
# ocorrência de uma determinada string em um
# array
#
# shut_util_findex "<string>" "${array[@]}"
function shut_util_findex {
    local target="$1"
    shift

    local index=-1
    local i=0

    while [ "$#" != 0 ]; do
        if [ "$1" = "$target" ]; then
            index=$i
            break
        fi
        let i=$i+1
        shift
    done

    echo $index
}

# Verifica se o caracter é uma letra. Se for
# uma letra a função é encerrada com sucesso.
# Caso contrário é encerrada com erro.
function shut_util_is_letter {
    case "$1" in
        a) return 0;;
        b) return 0;;
        c) return 0;;
        d) return 0;;
        e) return 0;;
        f) return 0;;
        g) return 0;;
        h) return 0;;
        i) return 0;;
        j) return 0;;
        k) return 0;;
        l) return 0;;
        m) return 0;;
        n) return 0;;
        o) return 0;;
        p) return 0;;
        q) return 0;;
        r) return 0;;
        s) return 0;;
        t) return 0;;
        u) return 0;;
        v) return 0;;
        w) return 0;;
        x) return 0;;
        y) return 0;;
        z) return 0;;
        A) return 0;;
        B) return 0;;
        C) return 0;;
        D) return 0;;
        E) return 0;;
        F) return 0;;
        G) return 0;;
        H) return 0;;
        I) return 0;;
        J) return 0;;
        K) return 0;;
        L) return 0;;
        M) return 0;;
        N) return 0;;
        O) return 0;;
        P) return 0;;
        Q) return 0;;
        R) return 0;;
        S) return 0;;
        T) return 0;;
        U) return 0;;
        V) return 0;;
        W) return 0;;
        X) return 0;;
        Y) return 0;;
        Z) return 0;;
        *) return 1;;
    esac
}

# Ecoa na saída padrão uma string substituindo todos
# os caracteres de uma string que são letras por
# underline
#
# Parâmetro: String a ter os caracteres  convertidos
function shut_util_adapter_to_variable_name {
    local target="$@"
    local len_target="${#target}"
    local rt=""
    local ch=""
    for ((i = 0; i < len_target; i++)); do
        ch="${target:i:1}"

        if [ "$ch" != "_" ] && ! shut_util_is_letter "$ch"; then
            rt="${rt}_"
        else
            rt="${rt}${ch}"
        fi
    done
    echo "$rt"
}
