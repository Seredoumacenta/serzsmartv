#!/data/data/com.termux/files/usr/bin/bash

# ============================================
# serziam CODE GENERATOR
# Générateur de codes d'accès mensuels
# Même algorithme que le script principal
# ============================================

# === CONFIGURATION (identique au script principal) ===
SECRET_SEED="TV_MONTHLY_2024_SECURE_2024"

# === COULEURS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ============================================
# ALGORITHME DE GÉNÉRATION (IDENTIQUE)
# ============================================

generate_code() {
    local month="$1"
    
    if command -v md5sum >/dev/null; then
        echo -n "${month}${SECRET_SEED}" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]'
    elif command -v md5 >/dev/null; then
        echo -n "${month}${SECRET_SEED}" | md5 | cut -c1-8 | tr '[:lower:]' '[:upper:]'
    else
        # Fallback avec sha256
        echo -n "${month}${SECRET_SEED}" | sha256sum 2>/dev/null | cut -c1-8 | tr '[:lower:]' '[:upper:]' || echo "ERROR"
    fi
}

# ============================================
# FONCTIONS UTILITAIRES
# ============================================

get_month_name() {
    local month_code="$1"
    local year="${month_code:0:4}"
    local month="${month_code:4:2}"
    
    if command -v date >/dev/null; then
        date -d "${year}-${month}-01" "+%B %Y" 2>/dev/null || echo "$month_code"
    else
        case $month in
            01) echo "Janvier $year" ;;
            02) echo "Février $year" ;;
            03) echo "Mars $year" ;;
            04) echo "Avril $year" ;;
            05) echo "Mai $year" ;;
            06) echo "Juin $year" ;;
            07) echo "Juillet $year" ;;
            08) echo "Août $year" ;;
            09) echo "Septembre $year" ;;
            10) echo "Octobre $year" ;;
            11) echo "Novembre $year" ;;
            12) echo "Décembre $year" ;;
            *) echo "$month_code" ;;
        esac
    fi
}

get_current_month() {
    date +%Y%m 2>/dev/null || echo "202501"
}

get_next_month() {
    local current="$1"
    local year="${current:0:4}"
    local month=$((10#${current:4:2}))
    
    month=$((month + 1))
    if [[ $month -gt 12 ]]; then
        month=1
        year=$((year + 1))
    fi
    
    printf "%04d%02d" "$year" "$month"
}

get_previous_month() {
    local current="$1"
    local year="${current:0:4}"
    local month=$((10#${current:4:2}))
    
    month=$((month - 1))
    if [[ $month -lt 1 ]]; then
        month=12
        year=$((year - 1))
    fi
    
    printf "%04d%02d" "$year" "$month"
}

# ============================================
# AFFICHAGE DES CODES
# ============================================

show_code() {
    local month="$1"
    local code=$(generate_code "$month")
    local month_name=$(get_month_name "$month")
    
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -e "${WHITE}  $month_name${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Code d'accès : ${GREEN}$code${NC}"
    echo ""
    echo -e "${YELLOW}  Format: 8 caractères majuscules${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo ""
}

show_range() {
    local start_month="$1"
    local count="$2"
    local direction="${3:-next}"  # next ou prev
    
    echo ""
    echo -e "${CYAN}┌────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${WHITE}            CODES GÉNÉRÉS                    ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────┤${NC}"
    
    local current="$start_month"
    for ((i=0; i<count; i++)); do
        local code=$(generate_code "$current")
        local name=$(get_month_name "$current")
        printf "${CYAN}│${NC} ${YELLOW}%-12s${NC} ${GREEN}%-8s${NC} ${WHITE}%-15s${CYAN}│${NC}\n" "$current" "$code" "$name"
        
        if [[ "$direction" == "next" ]]; then
            current=$(get_next_month "$current")
        else
            current=$(get_previous_month "$current")
        fi
    done
    
    echo -e "${CYAN}└────────────────────────────────────────────┘${NC}"
    echo ""
}

# ============================================
# MENU PRINCIPAL
# ============================================

show_menu() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║         serziam CODE GENERATOR v1.0            ║"
    echo "║     Générateur de codes d'accès mensuels       ║"
    echo "║     Même algorithme que le script principal    ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "1. 📅 Code du mois actuel"
    echo "2. 📆 Code du mois prochain"
    echo "3. 📆 Code du mois précédent"
    echo "4. 🔢 Code pour un mois spécifique"
    echo "5. 📊 12 prochains mois"
    echo "6. 📊 12 mois précédents"
    echo "7. 📋 Année complète (12 mois)"
    echo "8. 💾 Exporter vers fichier"
    echo "0. 🚪 Quitter"
    echo ""
}

# ============================================
# FONCTIONS DU MENU
# ============================================

code_current() {
    clear
    local current=$(get_current_month)
    show_code "$current"
    read -p "Appuyez sur Entrée pour continuer..."
}

code_next() {
    clear
    local current=$(get_current_month)
    local next=$(get_next_month "$current")
    show_code "$next"
    read -p "Appuyez sur Entrée pour continuer..."
}

code_previous() {
    clear
    local current=$(get_current_month)
    local prev=$(get_previous_month "$current")
    show_code "$prev"
    read -p "Appuyez sur Entrée pour continuer..."
}

code_specific() {
    clear
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo -e "${WHITE}  CODE POUR UN MOIS SPÉCIFIQUE${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo ""
    echo "Entrez le mois au format YYYYMM (ex: 202502 pour Février 2025)"
    echo ""
    read -p "Mois : " user_month
    
    if [[ ! "$user_month" =~ ^[0-9]{6}$ ]]; then
        echo ""
        echo -e "${RED}❌ Format invalide. Utilisez YYYYMM (6 chiffres)${NC}"
        read -p "Appuyez sur Entrée..."
        return
    fi
    
    show_code "$user_month"
    read -p "Appuyez sur Entrée pour continuer..."
}

code_next_12() {
    clear
    local current=$(get_current_month)
    show_range "$current" 12 "next"
    read -p "Appuyez sur Entrée pour continuer..."
}

code_prev_12() {
    clear
    local current=$(get_current_month)
    show_range "$current" 12 "prev"
    read -p "Appuyez sur Entrée pour continuer..."
}

code_full_year() {
    clear
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo -e "${WHITE}  GÉNÉRATION D'UNE ANNÉE COMPLÈTE${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo ""
    read -p "Année (ex: 2025) : " year
    
    if [[ ! "$year" =~ ^[0-9]{4}$ ]]; then
        echo ""
        echo -e "${RED}❌ Format invalide. Utilisez 4 chiffres${NC}"
        read -p "Appuyez sur Entrée..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${WHITE}              CODES POUR L'ANNÉE $year                ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────┤${NC}"
    
    for month in {01..12}; do
        local month_code="${year}${month}"
        local code=$(generate_code "$month_code")
        local month_name=$(get_month_name "$month_code")
        printf "${CYAN}│${NC} ${YELLOW}%-10s${NC} ${GREEN}%-8s${NC} ${WHITE}%-15s${CYAN}│${NC}\n" "$month_code" "$code" "$month_name"
    done
    
    echo -e "${CYAN}└─────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

export_codes() {
    clear
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo -e "${WHITE}  EXPORTATION DES CODES${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo ""
    
    local filename="codes_export_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "serziam CODES GÉNÉRÉS - $(date)"
        echo "========================================"
        echo "Algorithme: MD5 (8 premiers caractères)"
        echo "Secret: $SECRET_SEED"
        echo "========================================"
        echo ""
        
        local current=$(get_current_month)
        local temp="$current"
        
        echo "12 PROCHAINS MOIS :"
        echo "-------------------"
        for ((i=0; i<12; i++)); do
            local code=$(generate_code "$temp")
            local name=$(get_month_name "$temp")
            printf "%-10s %-8s %s\n" "$temp" "$code" "$name"
            temp=$(get_next_month "$temp")
        done
        
        echo ""
        echo "12 MOIS PRÉCÉDENTS :"
        echo "--------------------"
        temp="$current"
        for ((i=0; i<12; i++)); do
            temp=$(get_previous_month "$temp")
        done
        for ((i=0; i<12; i++)); do
            local code=$(generate_code "$temp")
            local name=$(get_month_name "$temp")
            printf "%-10s %-8s %s\n" "$temp" "$code" "$name"
            temp=$(get_next_month "$temp")
        done
        
    } > "$filename"
    
    echo -e "${GREEN}✅ Fichier créé : $filename${NC}"
    echo -e "${CYAN}📁 Emplacement : $(pwd)/$filename${NC}"
    echo ""
    
    # Afficher les premières lignes
    echo "Aperçu :"
    echo "--------"
    head -15 "$filename"
    echo ""
    
    read -p "Appuyez sur Entrée pour continuer..."
}

# ============================================
# VERSION LIGNE DE COMMANDE
# ============================================

cli_mode() {
    case "$1" in
        "current"|"now")
            local month=$(get_current_month)
            generate_code "$month"
            ;;
        "next")
            local month=$(get_current_month)
            local next=$(get_next_month "$month")
            generate_code "$next"
            ;;
        "prev"|"previous")
            local month=$(get_current_month)
            local prev=$(get_previous_month "$month")
            generate_code "$prev"
            ;;
        [0-9][0-9][0-9][0-9][0-9][0-9])
            generate_code "$1"
            ;;
        "range")
            local start="${2:-$(get_current_month)}"
            local count="${3:-12}"
            local dir="${4:-next}"
            local m="$start"
            for ((i=0; i<count; i++)); do
                echo "$(get_month_name "$m"): $(generate_code "$m")"
                if [[ "$dir" == "next" ]]; then
                    m=$(get_next_month "$m")
                else
                    m=$(get_previous_month "$m")
                fi
            done
            ;;
        "help"|"-h"|"--help")
            echo "serziam CODE GENERATOR"
            echo ""
            echo "Usage: $0 [option] [arguments]"
            echo ""
            echo "Options sans argument :"
            echo "  current    - Code du mois actuel"
            echo "  next       - Code du mois prochain"
            echo "  prev       - Code du mois précédent"
            echo "  menu       - Mode interactif (défaut)"
            echo ""
            echo "Options avec arguments :"
            echo "  $0 202502   - Code pour Février 2025"
            echo "  $0 range [début] [nb] [next/prev]"
            echo "              - Générer une plage de codes"
            echo ""
            echo "Exemples :"
            echo "  $0 range 202501 6 next"
            echo "  $0 range 202512 6 prev"
            ;;
        *)
            if [[ -n "$1" ]]; then
                echo "Option inconnue: $1"
                echo "Utilisez '$0 help' pour l'aide"
                exit 1
            fi
            ;;
    esac
}

# ============================================
# PROGRAMME PRINCIPAL
# ============================================

main() {
    # Mode CLI si arguments fournis
    if [[ $# -gt 0 ]]; then
        cli_mode "$@"
        exit 0
    fi
    
    # Mode interactif
    while true; do
        show_menu
        read -p "Votre choix (0-8) : " choice
        
        case $choice in
            1) code_current ;;
            2) code_next ;;
            3) code_previous ;;
            4) code_specific ;;
            5) code_next_12 ;;
            6) code_prev_12 ;;
            7) code_full_year ;;
            8) export_codes ;;
            0) 
                echo -e "${GREEN}Au revoir !${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}❌ Choix invalide${NC}"
                sleep 1
                ;;
        esac
    done
}

# Lancer le programme
main "$@"
