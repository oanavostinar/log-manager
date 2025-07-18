#!/bin/bash

# culori
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"


	echo -e "${GREEN}"
echo "=============================================="
echo "      █▓▒░   LOG MANAGER   ░▒▓█"
echo "=============================================="
echo -e "${RESET}"

# configurare director
DISTRO=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
DIR="$HOME/practica/loguri_centralizate"
mkdir -p "$DIR"

print_header() {
    echo -e "\n${CYAN}==============================================${RESET}"
    echo -e "${CYAN}>> $(date '+%Y-%m-%d %H:%M:%S') <<${RESET}"
    echo -e "${CYAN}==============================================${RESET}"
}

# copiere log
copiere_log() {
    local sursa=$1
    local destinatie=$2
    if [[ -f "$sursa" ]]; then
        cp "$sursa" "$destinatie" 2>/dev/null
        echo -e "${GREEN}|good|${RESET} $sursa -> $destinatie"
    fi
}

# centralizare loguri
centralize_logs() {
	print_header
    echo -e "\n${CYAN}Centralizare loguri pentru $DISTRO in $DIR${RESET}"

    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "linuxmint" ]]; then
        copiere_log /var/log/syslog "$DIR/syslog.log"
        copiere_log /var/log/auth.log "$DIR/auth.log"
        copiere_log /var/log/wtmp "$DIR/wtmp.log"
        copiere_log /var/log/apt/history.log "$DIR/apt_history.log"
    elif [[ "$DISTRO" == "fedora" ]]; then
        copiere_log /var/log/messages "$DIR/messages.log"
        journalctl -u sshd > "$DIR/sshd.log" 2>/dev/null && echo -e "${GREEN}|good|${RESET} sshd.log creat"
        copiere_log /var/log/wtmp "$DIR/wtmp.log"
        copiere_log /var/log/dnf.rpm.log "$DIR/dnf_log.log"
    else
        echo -e "${RED}|eroare| Distributie nesuportata: $DISTRO${RESET}"
        exit 1
    fi

    journalctl > "$DIR/system_journal.log" 2>/dev/null && echo -e "${GREEN}|good|${RESET} Export complet journalctl -> system_journal.log"
    copiere_log /var/log/nginx/access.log "$DIR/nginx_access.log"
    copiere_log /var/log/nginx/error.log "$DIR/nginx_error.log"
    copiere_log /var/log/apache2/access.log "$DIR/apache_access.log"
    copiere_log /var/log/apache2/error.log "$DIR/apache_error.log"
}

# verificare existenta
check_file() {
    if [[ ! -f "$1" ]]; then
        echo -e "${RED}Fisierul '$1' nu exista.${RESET}"
        return 1
    fi
}

# filtrare cuvant cheie
filter_by_keyword() {
    check_file "$1" || return
    echo -ne "${YELLOW}Cuvant cheie: ${RESET}"
    read kw
    echo -e "${CYAN}-- Rezultate pentru: $kw --${RESET}"

    if [[ "$1" == *wtmp.log ]]; then
        last -f "$1" | grep -i --color=always "$kw" | tee /tmp/rezultat.log
    else
        grep -i --color=always "$kw" "$1" | tee /tmp/rezultat.log
    fi

    echo -e "\n${GREEN}Total rezultate: $(wc -l < /tmp/rezultat.log)${RESET}"
}

# filtrare dupa data
filter_by_date() {
    check_file "$1" || return
    echo -ne "${YELLOW}Data (ex: 2025-07-17): ${RESET}"
    read input_date

    if ! date -d "$input_date" &>/dev/null; then
        echo -e "${RED}Data invalida! Format corect: YYYY-MM-DD${RESET}"
        return
    fi

    echo -e "${CYAN}-- Rezultate pentru data: $input_date --${RESET}"

    if [[ "$1" == *wtmp.log ]]; then
        last -f "$1" | grep --color=always "$input_date" | tee /tmp/rezultat.log
    elif [[ "$1" == *apache_access.log || "$1" == *apache_error.log ]]; then
        apache_date=$(date -d "$input_date" +"%d/%b/%Y")
        grep --color=always "\[$apache_date" "$1" | tee /tmp/rezultat.log
    else
        grep --color=always "$input_date" "$1" | tee /tmp/rezultat.log
    fi

    echo -e "\n${GREEN}Total rezultate: $(wc -l < /tmp/rezultat.log)${RESET}"
}

# filtrare dupa nivel
filter_by_level() {
    check_file "$1" || return
    echo -ne "${YELLOW}Nivel (ex: error, warning): ${RESET}"
    read lvl
    echo -e "${CYAN}-- Rezultate pentru nivel: $lvl --${RESET}"

    if [[ "$1" == *wtmp.log ]]; then
        last -f "$1" | grep -i --color=always "$lvl" | tee /tmp/rezultat.log
    else
        grep -i --color=always "$lvl" "$1" | tee /tmp/rezultat.log
    fi

    echo -e "\n${GREEN}Total rezultate: $(wc -l < /tmp/rezultat.log)${RESET}"
}

# detectare probleme securitate
detect_security_issues() {
    echo -e "\n${RED}-- Detectare Probleme de Securitate --${RESET}"
    if [[ ! -f "$DIR/auth.log" ]]; then
        echo -e "${YELLOW}[WARN] auth.log nu a fost gasit!${RESET}"
        return
    fi

    echo -e "\nAutentificari esuate:"
    grep -i "Failed password" "$DIR/auth.log"

    echo -e "\nComenzi sudo nereusite:"
    grep -i "authentication failure" "$DIR/auth.log"

    echo -e "\nInstalare unelte care pot fi periculoase:"
    grep -Ei "install(ed)? (nmap|netcat|nc|gcc|hydra|john|a=ircrack)" "$DIR"/* 2>/dev/null

    echo -e "\nUltimele sesiuni deschise:"
    grep -i "session opened" "$DIR/auth.log" | tail -n 5

    echo -e "\nUltimele sesiuni inchise:"
    grep -i "session closed" "$DIR/auth.log" | tail -n 5
}

# MENIU
while true; do
    echo -e "\n${CYAN}====== MENIU LOG MANAGER ======${RESET}"
    echo "1. Centralizeaza loguri"
    echo "2. Filtrare log dupa cuvant cheie"
    echo "3. Filtrare log dupa data"
    echo "4. Filtrare log dupa nivel (error/warning)"
    echo "5. Detectare probleme de securitate"
    echo "0. Iesire"
    echo -ne "${YELLOW}Alege o optiune: ${RESET}"
    read opt

    case $opt in
        1) centralize_logs ;;
        2|3|4)
            echo -e "\n${CYAN}Loguri disponibile in $DIR:${RESET}"
            ls "$DIR"
            echo -ne "${YELLOW}Alege fisierul (ex: syslog.log): ${RESET}"
            read f
            filepath="$DIR/$f"
            case $opt in
                2) filter_by_keyword "$filepath" ;;
                3) filter_by_date "$filepath" ;;
                4) filter_by_level "$filepath" ;;
            esac
            ;;
        5) detect_security_issues ;;
        0) break ;;
        *) echo -e "${RED}Optiunea nu exista.${RESET}" ;;
    esac
done

