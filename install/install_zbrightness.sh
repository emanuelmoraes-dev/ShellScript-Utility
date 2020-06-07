#!/bin/bash

DIRNAME="$(dirname "$0")"

# NOME DAS LIBS GLOBAIS A SEREM IMPORTADAS
PARAMETER_HELPER_NAME="parameter-helper"
GENDESK_NAME="gendesk"

# VARIÁVEIS GLOBAIS
DESKTOP_ENTRY_NAME="Brightness control"
DESKTOP_ENTRY_COMMENT="Graphical utility for brightness adjustment"

if [ $(echo $LANG | cut -b1-2) = "pt" ]; then
    DESKTOP_ENTRY_NAME="Controle de brilho"
    DESKTOP_ENTRY_COMMENT="Utilitário gráfico para controle de brilho"
fi

# CÓDIGOS DE ERRO DE SISTEMA (1-29)
ERR_9X11X_NOT_ADMIN=1

# CÓDIGOS DE ERRO DO SCRIPT (90-119)
ERR_9X11X_UNEXPECTED=90
## NOT FOUND (9X)
ERR_9X11X_NOT_FOUND_PARAMETER_HELPER=91
ERR_9X11X_NOT_FOUND_GENDESK=92
ERR_9X11X_NOT_FOUND_ZENITY=93
## INVALID (10X)
ERR_9X11X_INVALID_BACKLIGHT_FILE=101

# CORES
RED="\e[31;1m"
GREEN="\e[33;1m"
END_COLOR="\e[m"

# TEMAS
ERROR_THEME="$RED"
INFO_THEME="$GREEN"

# Mostra mensagem de ajuda
function helpout {
    echo "    Script que instala um utilitario para alterar o brilho da tela. Os"
    echo "    parâmetros que iniciam por -- possuem maior prioridade"
    echo
    echo "    Parâmetros:"
    echo "        --unsafe: cria um serviço no SystemD que desprotege o"
    echo "            arquivo de controle do brilho, permitindo sua edição por"
    echo "            qualquer usuário (não recomendado)"
    echo "        --enable-unsafe: cria e habilita a inicialização automática do"
    echo "            serviço criado no SystemD que desprotege o arquivo de"
    echo "            controle do brilho, permitindo sua edição por qualquer"
    echo "            usuário (não recomendado)"
    echo "        --start-unsafe: cria e inicializa o serviço criado no SystemD"
    echo "            que desprotege o arquivo de controle do brilho, permitindo"
    echo "            sua edição por qualquer usuário (não recomendado)"
    echo "        --gui: habilita a opção --gui no binário \"zbrightness\","
    echo "            que abre uma interface gráfica para alteração do brilho"
    echo "            (Requer Zenity instalado)"
    echo "        --desktop-entry: cria um lançador da aplicação gráfica. (Requer"
    echo "            a opção --gui habilitada)"
    echo "        --cli: habilita o uso do terminal para alteração do brilho"
    echo "        --backlight-file: caminho do arquivo responsável pela iluminação"
    echo "            da tela. Se não passado, tal arquivo será buscado pelo"
    echo "            comando \$(find /sys/class/backlight/*/* -iname \"brightness\")."
    echo "            Exemplos:"
    echo "                /sys/class/backlight/intel_backlight/brightness"
    echo "                /sys/class/backlight/acpi_video0/brightness"
    echo "        --min: usado para informar o valor mínimo de brilho."
    echo "            Valor padrão: 75"
    echo "        --max: usado para informar o valor máximo de brilho. Se não"
    echo "            informado, será obtido o valor máximo registrado na máquina."
    echo "            Se o valor máximo informado for maior que o valor máximo"
    echo "            registrado na máquina, o valor usado será o registrado na"
    echo "            máquina, e o valor passado pelo usuário será descartado"
    echo "        --binary-name: nome do binário a ser inserido em /usr/bin."
    echo "            Valor padrão: zbrightness"
    echo "        --config-file: nome do caminho do arquivo onde ficará definido"
    echo "            os comandos a serem executaos pelo SystemD. Se não fornecido"
    echo "            o caminho será definido para \"/etc/zbrigthness_rc\" (Requer"
    echo "            --unsafe)"
    echo "        --service-name: nome do serviço adicionado ao SystemD. Se não"
    echo "            definido, o valor será \"zbrightness_permissions\" (Requer"
    echo "            --unsafe)"
    echo "        --name: Nome da aplicação a ser exibido no menu."
    echo "            Valor padrão: $DESKTOP_ENTRY_NAME"
    echo "        --exec: Comando de execução da aplicação. É altamente"
    echo "            recomendado que flags, como o %f, não sejam inseridos aqui. "
    echo "            Caso alguma flag seja necessária, insira ela no parâmetro"
    echo "            --flag-exec. O valor padrão é definido pela opção --binary-name"
    echo "        --icon: Caminho onde se encontra o ícone da aplicação. Opcional"
    echo "        --categories: Lista de categorias separadas por espaço."
    echo "            Valor padrão: Utility"
    echo "        --filename: Nome do arquivo \".desktop\". Se não passado, usa-se o"
    echo "            mesmo valor presente no parâmetro --name"
    echo "        --flag-exec: Flags a serem inseridas ao final do conteúdo da chave"
    echo "            'Exec' do [Desktop Entry]. Opcional"
    echo "        --comment: Comentário sobre a aplicação."
    echo "            Valor padrão: $DESKTOP_ENTRY_COMMENT"
    echo
    echo "    Atalhos:"
    echo "        -G = --gui --desktop-entry"
    echo "        -gksu = --gui --desktop-entry --exec gksudo <zbrightness> # (Pode"
    echo "            mudar de acordo com a opção --binary-name)"
    echo "        -beesu = --gui --desktop-entry --exec beesu <zbrightness> # (Pode"
    echo "            mudar de acordo com a opção --binary-name)"
    echo "        -U = --enable-unsafe --start-unsafe"
    echo "        -C = --cli"
    echo "        -M = --max"
    echo "        -m = --min"
    echo "        -b = --binary-name"
    echo "        -n = --name"
    echo "        -e = --exec"
    echo "        -i = --icon"
    echo "        -c = --categories"
    echo "        -f = --filename"
    echo "        -fe = --flag-exec"
    echo "        -ct = --comment"
    echo
    echo "    Script criado baseado no trabalho de Rodrigo, cujo link de seu"
    echo "    artigo é \"http://linuxlike.blogspot.com.br/2012/02/controle-de-brilho-para-o-lubuntu-lxde.html\""
    echo
    echo "    Autor: Emanuel Moraes de Almeida"
    echo "    Email: emanuelmoraes297@gmail.com"
    echo "    Github: https://github.com/emanuelmoraes-dev"
    echo
}

function logerr {
    local message="$@"
    printf >&2 "${ERROR_THEME}\n  ${message}${END_COLOR}\n"
}

function log {
    local message="$@"
    printf >&2 "${INFO_THEME}\n  ${message}${END_COLOR}\n"
}

# Ecoa mensagem de erro em erro padrão e código do erro em saída padrão
#
#EX: m="Erro interno! Algo inesperado ocorreu" e=100 helperr -v
function helperr {
    local err="$?"

    if [ -z "$err" ] || [ "$err" = "0" ]; then
        err=$ERR_9X11X_UNEXPECTED
    fi

    if [ "$e" ]; then
        err=$e
    fi

    local message="$m"

    if [ -z "$message" ]; then
        message="Erro interno! Algo inesperado ocorreu. Código: $_err!"
    fi

    if [ "$1" == "-v" ]; then
        helpout >&2
    fi

    logerr "$message"
    echo $err
}

# Ecoa na saída padrão a lib para processar os parâmetros nomeados
function get_parameter_helper {
    local PARAMETER_HELPER="$DIRNAME/../bin/parameter-helper"

    if ! [ -f "$PARAMETER_HELPER" ]; then
        if type -P "$PARAMETER_HELPER_NAME" 1>/dev/null 2>/dev/null; then
            PARAMETER_HELPER="$PARAMETER_HELPER_NAME"
        else
            return $(m="Erro! \"$PARAMETER_HELPER_NAME\" não encontrado!" e=$ERR_9X11X_NOT_FOUND_PARAMETER_HELPER helperr)
        fi
    fi

    echo $PARAMETER_HELPER
}

# Ecoa na saída padrão a lib para gerar lançador de aplicativo
function get_gendesk {
    local GENDESK="$DIRNAME/../bin/gendesk"

    if ! [ -f "$GENDESK" ]; then
        if type -P "$GENDESK_NAME" 1>/dev/null 2>/dev/null; then
            GENDESK="$GENDESK_NAME"
        else
            return $(m="Erro! \"$GENDESK_NAME\" não encontrado!" e=$ERR_9X11X_NOT_FOUND_GENDESK helperr)
        fi
    fi

    echo $GENDESK
}

# Processa os parâmetros nomeados e joga em variáveis globais
function parameters {
    local PARAMETER_HELPER="$(get_parameter_helper)" || return $?
    GENDESK="$(get_gendesk)" || return $?

    source $PARAMETER_HELPER --create-exists-array --params -help -unsafe -enable-unsafe -start-unsafe -gui -desktop-entry -cli -backlight-file -min -max -binary-name -config-file -service-name -name -exec -icon -categories -filename -flag-exec -comment G gksu beesu U C M m b n e i c f fe ct @@ "$@" || return $(m="Erro! Argumentos inválidos!" helperr -v)

    # Flags sobre os parâmetros

    present_gksu=0
    present_beesu=0
    present_backlight_file=0

    # Declaração de parâmetros sem valor

    present_help=0 # 0
    present_unsafe=0 # 1
    present_enable_unsafe=0 # 2
    present_start_unsafe=0 # 3
    present_gui=0 # 4
    present_desktop_entry=0 # 5
    present_cli=0 # 6

    # Declaração de parâmetros nomeados com valor

    backlight_file_param="$(find /sys/class/backlight/*/* -iname "brightness")" # 7
    min_param=75 # 8
    max_param="" # 9
    binary_name_param=zbrightness # 10
    config_file_param="/etc/zbrigthness_rc" # 11
    service_name_param="zbrightness_permissions" # 12

    # Declaração de parâmetros para o gendesk

    name_param="$DESKTOP_ENTRY_NAME" # 13
    exec_param="" # 14
    icon_param="$DIRNAME/../icons/zbrightness_icon.png" # 15
    categories_param=() # 16
    filename_param="" # 17
    flag_exec_param="" # 18
    comment_param="$DESKTOP_ENTRY_COMMENT" # 19

    if [ "${shut_parameterHelper_exists[20]}" = 1 ]; then # -G
        present_gui=1
        present_desktop_entry=1
    fi

    if [ "${shut_parameterHelper_exists[21]}" = 1 ]; then # -gksu
        present_gui=1
        present_gksu=1
    fi

    if [ "${shut_parameterHelper_exists[22]}" = 1 ]; then # -beesu
        present_gui=1
        present_beesu=1
    fi

    if [ "${shut_parameterHelper_exists[23]}" = 1 ]; then # -U
        present_unsafe=1
        present_enable_unsafe=1
        present_start_unsafe=1
    fi

    if [ "${shut_parameterHelper_exists[24]}" = 1 ]; then # -C
        present_cli=1
    fi

    if [ "${shut_parameterHelper_exists[25]}" = 1 ]; then # -M
        max_param="${shut_parameterHelper_args[25]}"
    fi

    if [ "${shut_parameterHelper_exists[26]}" = 1 ]; then # -m
        min_param="${shut_parameterHelper_args[26]}"
    fi

    if [ "${shut_parameterHelper_exists[27]}" = 1 ]; then # -b
        binary_name_param="${shut_parameterHelper_args[27]}"
    fi

    if [ "${shut_parameterHelper_exists[28]}" = 1 ]; then # -n
        name_param="${shut_parameterHelper_args[28]}"
    fi

    if [ "${shut_parameterHelper_exists[29]}" = 1 ]; then # -e
        exec_param="${shut_parameterHelper_args[29]}"
    fi

    if [ "${shut_parameterHelper_exists[30]}" = 1 ]; then # -i
        icon_param="${shut_parameterHelper_args[30]}"
    fi

    if [ "${shut_parameterHelper_exists[31]}" = 1 ]; then # -c
        categories_param="${shut_parameterHelper_args[31]}"
    fi

    if [ "${shut_parameterHelper_exists[32]}" = 1 ]; then # -f
        filename_param="${shut_parameterHelper_args[32]}"
    fi

    if [ "${shut_parameterHelper_exists[33]}" = 1 ]; then # -fe
        flag_exec_param="${shut_parameterHelper_args[33]}"
    fi

    if [ "${shut_parameterHelper_exists[34]}" = 1 ]; then # -ct
        comment_param="${shut_parameterHelper_args[34]}"
    fi

    # Verifica a existência de parâmetros sem valor

    if [ "${shut_parameterHelper_exists[0]}" = 1 ]; then # --help
        present_help=1
    fi

    if [ "${shut_parameterHelper_exists[1]}" = 1 ]; then # --unsafe
        present_unsafe=1
    fi

    if [ "${shut_parameterHelper_exists[2]}" = 1 ]; then # --enable-unsafe
        present_unsafe=1
        present_enable_unsafe=1
    fi

    if [ "${shut_parameterHelper_exists[3]}" = 1 ]; then # --start-unsafe
        present_unsafe=1
        present_start_unsafe=1
    fi

    if [ "${shut_parameterHelper_exists[4]}" = 1 ]; then # --gui
        present_gui=1
    fi

    if [ "${shut_parameterHelper_exists[5]}" = 1 ]; then # --desktop-entry
        present_desktop_entry=1
    fi

    if [ "${shut_parameterHelper_exists[6]}" = 1 ]; then # --cli
        present_cli=1
    fi

    # Atribui os valores aos parâmetros nomeados com valor

    if [ "${shut_parameterHelper_exists[7]}" = 1 ]; then # --backlight-file
        present_backlight_file=1
        shut_util_array $'\n' "${shut_parameterHelper_args[7]}"
        backlight_file_param="${shut_util_return[@]}"
    fi

    if [ "${shut_parameterHelper_exists[8]}" = 1 ]; then # --min
        min_param="${shut_parameterHelper_args[8]}"
    fi

    if [ "${shut_parameterHelper_exists[9]}" = 1 ]; then # --max
        max_param="${shut_parameterHelper_args[9]}"
    fi

    if [ "${shut_parameterHelper_exists[10]}" = 1 ]; then # --binary-name
        binary_name_param="${shut_parameterHelper_args[10]}"
    fi

    if [ "${shut_parameterHelper_exists[11]}" = 1 ]; then # --config-file
        shut_util_array $'\n' "${shut_parameterHelper_args[11]}"
        config_file_param="${shut_util_return[@]}"
    fi

    if [ "${shut_parameterHelper_exists[12]}" = 1 ]; then # --service-name
        shut_util_array $'\n' "${shut_parameterHelper_args[12]}"
        service_name_param="${shut_util_return[@]}"
    fi

    # Atribui os valores dos parâmetros para passar para o "gendesk"

    if [ "${shut_parameterHelper_exists[13]}" = 1 ]; then # --name
        shut_util_array $'\n' "${shut_parameterHelper_args[13]}"
        name_param="${shut_util_return[@]}"
    fi

    if [ "${shut_parameterHelper_exists[14]}" = 1 ]; then # --exec
        shut_util_array $'\n' "${shut_parameterHelper_args[14]}"
        exec_param="${shut_util_return[@]}"
    fi

    if [ "${shut_parameterHelper_exists[15]}" = 1 ]; then # --icon
        shut_util_array $'\n' "${shut_parameterHelper_args[15]}"
        icon_param="${shut_util_return[@]}"
    fi

    if [ "${shut_parameterHelper_exists[16]}" = 1 ]; then # --categories
        shut_util_array $'\n' "${shut_parameterHelper_args[16]}"
        categories_param=("${shut_util_return[@]}")
    fi

    if [ "${shut_parameterHelper_exists[17]}" = 1 ]; then # --filename
        shut_util_array $'\n' "${shut_parameterHelper_args[17]}"
        filename_param="${shut_util_return[@]}"
    fi

    if [ "${shut_parameterHelper_exists[18]}" = 1 ]; then # --flag-exec
        shut_util_array $'\n' "${shut_parameterHelper_args[18]}"
        flag_exec_param="${shut_util_return[@]}"
    fi

    if [ "${shut_parameterHelper_exists[19]}" = 1 ]; then # --comment
        shut_util_array $'\n' "${shut_parameterHelper_args[19]}"
        comment_param="${shut_util_return[@]}"
    fi
}

# Obtém (pelo usuário) o caminho do arquivo responsável pela iluminação da tela
function input_backlight_file {
    # Se o caminho do arquivo responsável pela iluminação da tela for inválido
    if ! [ -f "$backlight_file_param" ]; then
        echo "  Não foi possível encontrar o arquivo \"brightness\" que contém o número"
        echo "  de iluminação da tela. Por favor, procure manualmente este arquivo"
        echo "  geralmente nomeado de \"brightness\" e geralmente localizado em alguma"
        echo "  sub-pasta da pasta /sys/class/backlight. Ao localizar tal arquivo,"
        echo "  digite seu caminho:"
        echo
        echo "  Exemplos de possíveis valores:"
        echo "  /sys/class/backlight/intel_backlight/brightness"
        echo "  /sys/class/backlight/acpi_video0/brightness"
        echo

        read backlight_file_param
    fi

    # Enquanto o caminho do arquivo responsável pela iluminação da tela for inválido
    while ! [ -f "$backlight_file_param" ]; do
        echo "  O caminho \"$backlight_file_param\""
        echo "  não existe. Por favor, digite novamente:"
        echo

        read backlight_file_param
    done
}

# Faz todas as verificações e configurações necessárias antes da instalação
function config {
    if [ "$present_help" = 1 ]; then
        helpout
        return 0
    fi

    if [ "$present_unsafe" = 1 ] && [ "$(id -u)" != "0" ]; then
        return $(m="Erro! É necessário permissão administrativa para habilitar o\n  modo inseguro" e=$ERR_9X11X_NOT_ADMIN heperr)
    fi

    if [ "$present_gui" = 1 ] && ! type -P zenity 1>/dev/null 2>/dev/null; then
        return $(m="Erro: dependência \"zenity\" não encontrada!\n  Por favor instale a dependência \"zenity\"" e=$ERR_9X11X_NOT_FOUND_ZENITY heperr)
    fi

    if [ "$present_backlight_file" = 0 ]; then
        # Obtém (pelo usuário) o caminho do arquivo responsável pela iluminação da tela
        input_backlight_file || return $?
    elif ! [ -f "$backlight_file_param" ]; then
        return $(m="Valor de --backlight-file inválido!" e=$ERR_9X11X_INVALID_BACKLIGHT_FILE helperr)
    fi

    # Obtém o nome da pasta contendo o arquivo responsável pela iluminação da tela
    backlight_folder="$(dirname "$backlight_file_param")" &&
}

function install_unsafe {
    if [ "$present_unsafe" = 0 ]; then
        return 0
    fi

    log "* Gerando Serviço ${service_name_param}.service ..."
    log "** Gerando Arquivo de Configuração ${config_file_param} ..."
}

function install {

}

function main {
    (
        # Processa os parâmetros nomeados e joga em variáveis globais
        parameters "$@" &&

        # Faz todas as verificações e configurações necessárias antes da instalação
        config &&

        # Instala zbrightness
        install
    ) || (
        return $?
    )
}

main "$@" # Executa função principal

echo "chmod 666 $folder/brightness" >/etc/zbrigthness_rc
chmod 700 /etc/zbrigthness_rc

echo \
    "[Unit]
Description=Atribuição de Permissão de Escrita e Leitura para arquivo $folder/brightness
ConditionPathExists=/etc/zbrigthness_rc

[Service]
Type=forking
ExecStart=/etc/zbrigthness_rc start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target" >/etc/systemd/system/zbrightness_permissions

echo "$> inicializando Serviço zbrightness_permissions.service ..."

sudo systemctl enable zbrightness_permissions || (
    echo "Error: Não foi possível habilitar o serviço 'zbrightness_permissions'"
    exit 200
)
sudo systemctl start zbrightness_permissions || (
    echo "Error: Não foi possível inicializar o serviço 'zbrightness_permissions'"
    exit 201
)

echo "$> Extraindo zbrightness ..."

echo '#!/bin/bash' >/bin/zbrightness
echo '' >>/bin/zbrightness
echo "folder=$folder" >>/bin/zbrightness

echo 'value=$(cat $folder/brightness)
value_max=$(cat $folder/max_brightness)

if [ $(echo $LANG | cut -b1-2) = "pt" ]
then
    title_text="Controle de brilho"
    scale_text="Ajuste de intensidade (75 a $value_max)"
else
    title_text="Brightness control"
    scale_text="Intensity adjustment (75 to $value_max)"
fi

new_value=$(zenity --scale --title "$title_text" --text \
"$scale_text" --min-value 75 --max-value $value_max --value \
$value --step 1)

echo -n $new_value > $folder/brightness' >>/bin/zbrightness

chmod +x /bin/zbrightness

echo "$> Gerando Lançador de Aplicativo ..."

echo '[Desktop Entry]
Name=Controle de brilho
Categories=Settings;
Exec=/bin/zbrightness
Icon=/usr/share/icons/zbrightness_icon.png
Terminal=false
Type=Application' >/usr/share/applications/zbrightness.desktop

echo "$> Extraindo Ícone ..."

# if ! ; then
#     echo "    Não foi possível gerar o ícone padrão da aplicação"
# else
#     echo ""
#     echo "    Ícone da aplicação gerado"
# fi

echo "
    Para que o atalho do teclado de DIMINUIR o brilho funcione,
    adicione nas configurações de seu computador um atalho de teclado
    com o seguinte comando:

    /bin/bash -c 'v=\$(cat $folder/brightness); let v=\$v-300; if [ \$v -lt 75 ]; then v=75; fi; echo -n \$v > $folder/brightness'"

read a

echo "
    Para que o atalho do teclado de AUMENTAR o brilho funcione,
    adicione nas configurações de seu computador um atalho de teclado
    com o seguinte comando:

    /bin/bash -c 'v=\$(cat $folder/brightness); value_max=$(cat $folder/max_brightness); let v=\$v+300; if [ \$v -gt \$value_max ]; then v=\$value_max; fi; echo -n \$v > $folder/brightness'"

read a

echo
echo "    zbrightness instalado com sucesso!"
