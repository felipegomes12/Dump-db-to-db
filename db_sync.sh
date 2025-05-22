#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/db_config.txt"
IGNORE_FILE="$SCRIPT_DIR/ignore_tables.txt"

# Função para criar ou carregar arquivo de configuração
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Arquivo de configuração não encontrado. Criando novo..."
        echo "Informe as credenciais do banco de PRODUÇÃO:"
        read -p "Usuário: " PROD_USER
        read -s -p "Senha: " PROD_PASS; echo
        read -p "Host: " PROD_HOST
        read -p "Banco: " PROD_DB

        echo "Informe as credenciais do banco de HOMOLOGAÇÃO:"
        read -p "Usuário: " TEST_USER
        read -s -p "Senha: " TEST_PASS; echo
        read -p "Host: " TEST_HOST
        read -p "Banco: " TEST_DB

        cat <<EOF > "$CONFIG_FILE"
PROD_USER=$PROD_USER
PROD_PASS=$PROD_PASS
PROD_HOST=$PROD_HOST
PROD_DB=$PROD_DB
TEST_USER=$TEST_USER
TEST_PASS=$TEST_PASS
TEST_HOST=$TEST_HOST
TEST_DB=$TEST_DB
EOF
        echo "Arquivo de configuração criado em $CONFIG_FILE"
    fi

    # Carrega as variáveis do arquivo
    source "$CONFIG_FILE"
}

# Função para criar arquivo de ignorados se necessário
init_ignore_file() {
    if [ ! -f "$IGNORE_FILE" ]; then
        echo "# Tabelas a serem ignoradas" > "$IGNORE_FILE"
    fi
}

# Função para adicionar tabela ao ignore
add_ignore() {
    read -p "Nome da tabela para ignorar (ex: auth_user): " TABELA
    if grep -Fxq "$TABELA" "$IGNORE_FILE"; then
        echo "Tabela '$TABELA' já está na lista de ignorados."
    else
        echo "$TABELA" >> "$IGNORE_FILE"
        echo "Tabela '$TABELA' adicionada."
    fi
    exit 0
}

# Função para remover tabela do ignore
remove_ignore() {
    read -p "Nome da tabela para remover do ignore (ex: auth_user): " TABELA
    if grep -Fxq "$TABELA" "$IGNORE_FILE"; then
        grep -Fxv "$TABELA" "$IGNORE_FILE" > "${IGNORE_FILE}.tmp" && mv "${IGNORE_FILE}.tmp" "$IGNORE_FILE"
        echo "Tabela '$TABELA' removida da lista de ignorados."
    else
        echo "Tabela '$TABELA' não está na lista."
    fi
    exit 0
}

# Função para listar tabelas ignoradas
list_ignore() {
    echo "Tabelas atualmente ignoradas:"
    grep -vE '^\s*#|^\s*$' "$IGNORE_FILE" || echo "(nenhuma tabela ignorada)"
    exit 0
}

# Função principal: dump e restore
dump_and_restore() {
    echo "Iniciando sincronização do banco de dados..."

    IGNORE_PARAMS=""
    while IFS= read -r TABELA; do
        [[ "$TABELA" =~ ^#.*$ || -z "$TABELA" ]] && continue
        IGNORE_PARAMS+=" --ignore-table=${PROD_DB}.${TABELA}"
    done < "$IGNORE_FILE"

    echo "Dumping produção..."
    nice -n 19 ionice -c2 -n7 mysqldump -u "$PROD_USER" -p"$PROD_PASS" -h "$PROD_HOST" "$PROD_DB" \
    --max_allowed_packet=1024M --single-transaction --quick \
    $IGNORE_PARAMS | pv -L 10m > "$SCRIPT_DIR/dump_producao.sql"

    echo "Restaurando em homologação..."
    mysql -u "$TEST_USER" -p"$TEST_PASS" -h "$TEST_HOST" "$TEST_DB" < "$SCRIPT_DIR/dump_producao.sql"

    echo "Limpando dump..."
    rm "$SCRIPT_DIR/dump_producao.sql"
    echo "Sincronização concluída!"
}

### Execução ###
load_config
init_ignore_file

case "$1" in
    --add-ignore)
        add_ignore
        ;;
    --remove-ignore)
        remove_ignore
        ;;
    --list-ignore)
        list_ignore
        ;;
    *)
        dump_and_restore
        ;;
esac
