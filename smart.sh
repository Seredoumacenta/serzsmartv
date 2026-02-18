#!/data/data/com.termux/files/usr/bin/bash

# ============================================
# serziam SMART TV - Version Stricte
# Codes en arrière-plan - Validation obligatoire
# Gestion des navigateurs incluse
# ============================================

set -e

# ============================================
# CONFIGURATION
# ============================================

CONFIG_DIR="$HOME/.tv_manager"
CHANNELS_FILE="$CONFIG_DIR/channels.conf"
ACCESS_FILE="$CONFIG_DIR/access.conf"
LOG_FILE="$CONFIG_DIR/access.log"
URLS_FILE="$CONFIG_DIR/urls.dat"
CODES_FILE="$CONFIG_DIR/codes.db"
BROWSERS_FILE="$CONFIG_DIR/browsers.conf"

SECRET_SEED="TV_MONTHLY_2024_SECURE_2024"
VALIDITY_SECONDS=2592000  # 30 jours

# Codes de recharge (60000) - SEULS ÉLÉMENTS AFFICHÉS
ORANGE_MONEY="*144*1*1*622001839*60000#"
MOBILE_MONEY="*440*1*1*663199359*60000#"

# ============================================
# COULEURS
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ============================================
# FONCTIONS D'AFFICHAGE
# ============================================

header() {
    clear 2>/dev/null || echo -e "\n\n"
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║              serziam SMART TV                  ║"
    echo "║         📺 GESTIONNAIRE DE CHAÎNES TV         ║"
    echo "║         🔐 ACCÈS MENSUEL STRICT                ║"
    echo "║         Codes Recharge: 60000                  ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
title() { echo -e "${PURPLE}📌 $1${NC}"; }

# Pause pour TV
tv_pause() {
    local message="${1:-Appuyez sur OK pour continuer...}"
    echo ""
    echo -e "${YELLOW}$message${NC}"
    echo -e "${CYAN}En attente...${NC}"
    read -t 5 dummy 2>/dev/null || sleep 3
}

# Lecture sécurisée
tv_read() {
    local prompt="$1"
    local var_name="$2"
    echo ""
    echo -e "${YELLOW}$prompt${NC}"
    read -t 30 "$var_name" 2>/dev/null || eval "$var_name=''"
}

# Lecture visible pour le code
tv_read_code() {
    local prompt="$1"
    local var_name="$2"
    echo ""
    echo -e "${YELLOW}$prompt${NC}"
    echo -e "${GREEN}Saisissez votre code d'accès mensuel${NC}"
    read "$var_name"
    echo ""
}

# ============================================
# GESTION DES NAVIGATEURS
# ============================================

# Liste des navigateurs supportés
declare -A BROWSERS=(
    ["com.android.chrome"]="Google Chrome"
    ["org.mozilla.firefox"]="Firefox"
    ["com.opera.browser"]="Opera"
    ["com.microsoft.emmx"]="Microsoft Edge"
    ["com.brave.browser"]="Brave"
    ["com.duckduckgo.mobile.android"]="DuckDuckGo"
    ["org.mozilla.focus"]="Firefox Focus"
    ["com.kiwibrowser.browser"]="Kiwi Browser"
    ["com.vivaldi.browser"]="Vivaldi"
    ["com.yandex.browser"]="Yandex Browser"
    ["app.lokke.main"]="Lokke Browser"
    ["com.termux"]="Termux"
    ["mark.via.gp"]="Via Browser"
    ["acr.browser.barebones"]="Lightning Browser"
)

# Détecter les navigateurs installés
detect_browsers() {
    local browsers=()
    
    if ! command -v pm >/dev/null; then
        echo ""
        return
    fi
    
    for package in "${!BROWSERS[@]}"; do
        if pm list packages 2>/dev/null | grep -q "$package"; then
            browsers+=("$package")
        fi
    done
    
    printf '%s\n' "${browsers[@]}"
}

# Obtenir le nom du navigateur
get_browser_name() {
    local package="$1"
    echo "${BROWSERS[$package]:-$package}"
}

# Sauvegarder le navigateur par défaut
set_default_browser() {
    local package="$1"
    echo "$package" > "$BROWSERS_FILE"
    chmod 600 "$BROWSERS_FILE" 2>/dev/null || true
}

# Obtenir le navigateur par défaut
get_default_browser() {
    if [[ -f "$BROWSERS_FILE" ]] && [[ -s "$BROWSERS_FILE" ]]; then
        cat "$BROWSERS_FILE"
    else
        # Chercher Chrome par défaut
        if pm list packages 2>/dev/null | grep -q "com.android.chrome"; then
            echo "com.android.chrome"
        else
            # Premier navigateur détecté
            local first=$(detect_browsers | head -1)
            echo "${first:-com.android.chrome}"
        fi
    fi
}

# Menu de sélection du navigateur
browser_selection_menu() {
    while true; do
        header
        title "SÉLECTION DU NAVIGATEUR"
        echo ""
        
        # Afficher le navigateur actuel
        local current=$(get_default_browser)
        local current_name=$(get_browser_name "$current")
        echo -e "Navigateur actuel : ${GREEN}$current_name${NC}"
        echo ""
        
        # Détecter les navigateurs installés
        local browsers=($(detect_browsers))
        
        if [[ ${#browsers[@]} -eq 0 ]]; then
            warning "Aucun navigateur détecté"
            echo ""
            echo "1. 🔍 Rechercher à nouveau"
            echo "2. ↩️  Retour"
            echo ""
            
            local choice=""
            tv_read "Votre choix : " choice
            
            case $choice in
                1) continue ;;
                2) return ;;
                *) error "Choix invalide"; sleep 1 ;;
            esac
            continue
        fi
        
        echo -e "${CYAN}Navigateurs détectés :${NC}"
        echo ""
        
        local i=1
        declare -A browser_map
        
        for package in "${browsers[@]}"; do
            local name=$(get_browser_name "$package")
            printf "  ${YELLOW}%2d.${NC} %s\n" "$i" "$name"
            browser_map[$i]="$package"
            i=$((i+1))
        done
        echo ""
        
        local choice=""
        tv_read "Choisissez un navigateur (1-$((i-1))) ou 0 pour retour : " choice
        
        if [[ "$choice" == "0" ]]; then
            return
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $((i-1)) ]]; then
            local selected="${browser_map[$choice]}"
            local selected_name=$(get_browser_name "$selected")
            
            set_default_browser "$selected"
            success "Navigateur par défaut : $selected_name"
            
            # Option pour tester
            echo ""
            warning "Tester l'ouverture avec $selected_name ?"
            echo "1. Oui"
            echo "2. Non"
            echo ""
            
            local test_choice=""
            tv_read "Votre choix (1/2) : " test_choice
            
            if [[ "$test_choice" == "1" ]]; then
                info "Test d'ouverture..."
                if command -v am >/dev/null; then
                    am start -a android.intent.action.VIEW -d "https://example.com" 2>/dev/null
                    success "Test lancé"
                else
                    error "Impossible de tester"
                fi
                tv_pause
            fi
        else
            error "Choix invalide"
            sleep 1
        fi
    done
}

# Ouvrir une URL avec le navigateur par défaut
open_url_with_browser() {
    local url="$1"
    local browser=$(get_default_browser)
    local browser_name=$(get_browser_name "$browser")
    
    info "Ouverture avec $browser_name..."
    
    # Méthode 1: Intent explicite
    if command -v am >/dev/null; then
        am start -a android.intent.action.VIEW -d "$url" 2>/dev/null && return 0
    fi
    
    # Méthode 2: termux-open-url
    if command -v termux-open-url >/dev/null; then
        termux-open-url "$url" 2>/dev/null && return 0
    fi
    
    # Méthode 3: Intent avec package spécifique
    if command -v am >/dev/null; then
        am start -a android.intent.action.VIEW -d "$url" -n "$browser/.App" 2>/dev/null && return 0
    fi
    
    error "Impossible d'ouvrir l'URL"
    return 1
}

# ============================================
# GÉNÉRATION DES CODES (COMPLÈTEMENT CACHÉE)
# ============================================

generate_code() {
    local month="$1"
    if command -v md5sum >/dev/null; then
        echo -n "${month}${SECRET_SEED}" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]'
    elif command -v md5 >/dev/null; then
        echo -n "${month}${SECRET_SEED}" | md5 | cut -c1-8 | tr '[:lower:]' '[:upper:]'
    else
        # Fallback sécurisé
        echo -n "${month}${SECRET_SEED}" | sha256sum 2>/dev/null | cut -c1-8 | tr '[:lower:]' '[:upper:]' || echo "ERROR"
    fi
}

init_codes() {
    [[ -f "$CODES_FILE" ]] || touch "$CODES_FILE"
    chmod 600 "$CODES_FILE" 2>/dev/null || true
    
    local current=$(date +%Y%m)
    local y=${current:0:4}
    local m=${current:4:2}
    
    # Générer 24 mois à l'avance (2 ans)
    for i in {0..23}; do
        local target_m=$((10#$m + i))
        local target_y=$y
        while [[ $target_m -gt 12 ]]; do
            target_m=$((target_m - 12))
            target_y=$((target_y + 1))
        done
        local month_code=$(printf "%04d%02d" "$target_y" "$target_m")
        
        if ! grep -q "^${month_code}:" "$CODES_FILE" 2>/dev/null; then
            local code=$(generate_code "$month_code")
            echo "${month_code}:${code}" >> "$CODES_FILE"
        fi
    done
    
    sort -t':' -k1 -n "$CODES_FILE" -o "$CODES_FILE" 2>/dev/null || true
    chmod 600 "$CODES_FILE" 2>/dev/null || true
}

# Vérification stricte du code (NE RIEN AFFICHER)
verify_code() {
    local month="$1"
    local user_code="$2"
    
    [[ ! -f "$CODES_FILE" ]] && return 1
    
    # Nettoyer les entrées
    user_code=$(echo "$user_code" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
    
    # Recherche dans la base de données (SANS AFFICHAGE)
    local stored_code=$(grep "^${month}:" "$CODES_FILE" 2>/dev/null | cut -d':' -f2 | tr -d '[:space:]')
    
    [[ -n "$stored_code" && "$user_code" == "$stored_code" ]]
}

# ============================================
# GESTION DE L'ACCÈS (STRICTE)
# ============================================

validate_access() {
    local month=$(date +%Y%m)
    local now=$(date +%s)
    local expire=$((now + VALIDITY_SECONDS))
    local month_name=$(date +"%B %Y")
    
    # Sauvegarder l'accès
    local temp=$(mktemp 2>/dev/null || echo "/tmp/tv_access_$$")
    [[ -f "$ACCESS_FILE" ]] && grep -v "^${month}:" "$ACCESS_FILE" > "$temp" 2>/dev/null || true
    echo "${month}:${now}:${expire}" >> "$temp"
    mv "$temp" "$ACCESS_FILE" 2>/dev/null
    chmod 600 "$ACCESS_FILE" 2>/dev/null || true
    
    local expire_date=$(date -d "@$expire" '+%d/%m/%Y' 2>/dev/null || echo "30 jours")
    success "✅ Accès activé pour $month_name jusqu'au $expire_date"
    
    # Log sécurisé
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ACCÈS ACTIVÉ - $month_name" >> "$LOG_FILE"
    chmod 600 "$LOG_FILE" 2>/dev/null || true
    
    sleep 3
}

is_valid() {
    local month=$(date +%Y%m)
    
    [[ ! -f "$ACCESS_FILE" ]] && return 1
    
    local entry=$(grep "^${month}:" "$ACCESS_FILE" 2>/dev/null)
    [[ -z "$entry" ]] && return 1
    
    local expire=$(echo "$entry" | cut -d':' -f3)
    local now=$(date +%s)
    
    [[ -n "$expire" && $now -lt $expire ]]
}

days_left() {
    local month=$(date +%Y%m)
    local entry=$(grep "^${month}:" "$ACCESS_FILE" 2>/dev/null)
    
    [[ -z "$entry" ]] && echo "0" && return
    
    local expire=$(echo "$entry" | cut -d':' -f3)
    local now=$(date +%s)
    local left=$(( (expire - now) / 86400 ))
    [[ $left -lt 0 ]] && echo "0" || echo "$left"
}

# ============================================
# PAGE DE CODE (OBLIGATOIRE - STRICTE)
# ============================================

show_recharge_codes() {
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo -e "${YELLOW}        📱 CODES DE RECHARGE              ${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}ORANGE MONEY (60000)${NC}"
    echo "$ORANGE_MONEY"
    echo ""
    echo -e "${GREEN}MOBILE MONEY (60000)${NC}"
    echo "$MOBILE_MONEY"
    echo ""
    echo -e "${YELLOW}══════════════════════════════════════════${NC}"
    echo ""
}

code_validation_page() {
    local month=$(date +%Y%m)
    local month_name=$(date +"%B %Y")
    local attempts=3
    
    while true; do
        header
        echo -e "${RED}══════════════════════════════════════════${NC}"
        echo -e "${WHITE}🔐 ACTIVATION MENSUELLE OBLIGATOIRE${NC}"
        echo -e "${RED}══════════════════════════════════════════${NC}"
        echo ""
        echo -e "Mois : ${WHITE}$month_name${NC}"
        echo -e "Tentatives restantes : ${YELLOW}$attempts${NC}"
        echo ""
        
        # Afficher uniquement les codes de recharge
        show_recharge_codes
        
        echo -e "${CYAN}────────────────────────────────────────${NC}"
        echo ""
        
        local user_code=""
        tv_read_code "ENTREZ VOTRE CODE D'ACCÈS : " user_code
        
        # Vérification stricte (SANS RIEN AFFICHER)
        if verify_code "$month" "$user_code"; then
            echo ""
            validate_access
            return 0
        else
            attempts=$((attempts - 1))
            echo ""
            error "❌ CODE INVALIDE - ACCÈS REFUSÉ"
            echo ""
            
            if [[ $attempts -le 0 ]]; then
                echo ""
                warning "⚠️  TROP DE TENTATIVES ÉCHOUÉES"
                echo ""
                echo "1. 🔄 RÉESSAYER"
                echo "2. 🚪 QUITTER"
                echo ""
                
                local choice=""
                tv_read "VOTRE CHOIX (1/2) : " choice
                
                if [[ "$choice" == "2" ]]; then
                    echo -e "${GREEN}Au revoir${NC}"
                    exit 0
                else
                    attempts=3
                fi
            else
                tv_pause "Appuyez sur OK pour réessayer"
            fi
        fi
    done
}

# Vérification stricte - PAS DE SORTIE SANS CODE VALIDE
strict_access_control() {
    while true; do
        if is_valid; then
            local days=$(days_left)
            if [[ $days -gt 0 ]]; then
                info "Accès actif - $days jour(s) restant(s)"
                return 0
            fi
        fi
        # BLOQUÉ ICI TANT QUE CODE NON VALIDE
        code_validation_page
    done
}

# ============================================
# GESTION DES CHAÎNES
# ============================================

init_config() {
    [[ -d "$CONFIG_DIR" ]] || mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR" 2>/dev/null || true
    
    # Chaînes par défaut
    if [[ ! -f "$CHANNELS_FILE" ]]; then
        cat > "$CHANNELS_FILE" << 'EOF'
Worldstv|streaming
TousTV|live
TV PAYS DU MONDE|international
EOF
        chmod 644 "$CHANNELS_FILE"
    fi
    
    # URLs cachées
    if [[ ! -f "$URLS_FILE" ]]; then
        cat > "$URLS_FILE" << 'EOF'
Worldstv|https://worldstvmobile.com/category/
TousTV|https://vavoo.to/
TV PAYS DU MONDE|https://famelack.com/
EOF
        chmod 600 "$URLS_FILE"
    fi
}

get_channel_url() {
    local channel_name="$1"
    [[ -f "$URLS_FILE" ]] && grep "^${channel_name}|" "$URLS_FILE" 2>/dev/null | cut -d'|' -f2 | head -1
}

list_channels() {
    echo -e "${CYAN}┌────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${WHITE}         CHAÎNES DISPONIBLES          ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────┤${NC}"
    
    local i=1
    while IFS='|' read -r name cat; do
        [[ "$name" =~ ^# ]] && continue
        printf "${CYAN}│${NC} ${YELLOW}%2d.${NC} %-20s ${GREEN}%s${NC}\n" "$i" "$name" "[$cat]"
        i=$((i+1))
    done < "$CHANNELS_FILE"
    
    if [[ $i -eq 1 ]]; then
        echo -e "${CYAN}│${NC} ${RED}Aucune chaîne configurée${NC}           ${CYAN}│${NC}"
    fi
    
    echo -e "${CYAN}└────────────────────────────────────┘${NC}"
}

open_channel() {
    header
    title "OUVRIR UNE CHAÎNE"
    echo ""
    list_channels
    echo ""
    
    local num=""
    tv_read "Numéro de la chaîne : " num
    
    [[ ! "$num" =~ ^[0-9]+$ ]] && { error "Numéro invalide"; tv_pause; return; }
    
    local channel_line=$(sed -n "${num}p" "$CHANNELS_FILE" 2>/dev/null)
    [[ -z "$channel_line" ]] && { error "Chaîne inexistante"; tv_pause; return; }
    
    local channel_name=$(echo "$channel_line" | cut -d'|' -f1)
    local channel_url=$(get_channel_url "$channel_name")
    
    [[ -z "$channel_url" ]] && { error "URL non disponible"; tv_pause; return; }
    
    if open_url_with_browser "$channel_url"; then
        success "Ouverture de $channel_name"
    fi
    
    tv_pause
}

add_channel() {
    header
    title "AJOUTER UNE CHAÎNE"
    echo ""
    
    local name=""
    local url=""
    local cat=""
    
    tv_read "Nom de la chaîne : " name
    tv_read "URL : " url
    tv_read "Catégorie : " cat
    
    if [[ -n "$name" && -n "$url" && -n "$cat" ]]; then
        echo "$name|$cat" >> "$CHANNELS_FILE"
        echo "$name|$url" >> "$URLS_FILE"
        success "Chaîne '$name' ajoutée"
    else
        error "Tous les champs sont requis"
    fi
    
    tv_pause
}

delete_channel() {
    header
    title "SUPPRIMER UNE CHAÎNE"
    echo ""
    list_channels
    echo ""
    
    local num=""
    tv_read "Numéro à supprimer : " num
    
    [[ ! "$num" =~ ^[0-9]+$ ]] && { error "Numéro invalide"; tv_pause; return; }
    
    local channel_line=$(sed -n "${num}p" "$CHANNELS_FILE" 2>/dev/null)
    [[ -z "$channel_line" ]] && { error "Chaîne inexistante"; tv_pause; return; }
    
    local channel_name=$(echo "$channel_line" | cut -d'|' -f1)
    
    echo ""
    warning "Supprimer '$channel_name' ?"
    echo "1. Oui"
    echo "2. Non"
    echo ""
    
    local confirm=""
    tv_read "Votre choix (1/2) : " confirm
    
    if [[ "$confirm" == "1" ]]; then
        sed -i "${num}d" "$CHANNELS_FILE" 2>/dev/null
        sed -i "/^${channel_name}|/d" "$URLS_FILE" 2>/dev/null
        success "Chaîne supprimée"
    else
        info "Annulé"
    fi
    
    tv_pause
}

# ============================================
# MENU PRINCIPAL
# ============================================

show_status() {
    header
    title "STATUT"
    echo ""
    
    local current_month=$(date +"%B %Y")
    echo -e "Mois : ${WHITE}$current_month${NC}"
    
    if is_valid; then
        local days=$(days_left)
        echo -e "Accès : ${GREEN}ACTIF${NC} - $days jour(s)"
    else
        echo -e "Accès : ${RED}BLOQUÉ${NC}"
    fi
    
    local browser=$(get_default_browser)
    local browser_name=$(get_browser_name "$browser")
    echo -e "Navigateur : ${CYAN}$browser_name${NC}"
    
    local channels=$(grep -c "^[^#]" "$CHANNELS_FILE" 2>/dev/null || echo "0")
    echo -e "Chaînes : ${CYAN}$channels${NC}"
    
    tv_pause
}

show_next_month_code() {
    header
    title "CODE MOIS PROCHAIN"
    echo ""
    echo -e "${RED}⚠️  INFORMATION IMPORTANTE${NC}"
    echo ""
    echo "Le code du mois prochain est disponible"
    echo "uniquement via les canaux officiels."
    echo ""
    echo "Contactez votre fournisseur d'accès"
    echo "pour obtenir le code de ${YELLOW}$(date -d "+1 month" +"%B %Y" 2>/dev/null)${NC}"
    echo ""
    show_recharge_codes
    tv_pause
}

main_menu() {
    while true; do
        header
        
        if is_valid; then
            local days=$(days_left)
            echo -e " ${GREEN}●${NC} ACCÈS ACTIF - $days jour(s)"
            local browser=$(get_default_browser)
            local browser_name=$(get_browser_name "$browser")
            echo -e " ${BLUE}●${NC} NAVIGATEUR - $browser_name"
        fi
        echo ""
        
        echo "1. 📡 OUVRIR UNE CHAÎNE"
        echo "2. 📋 LISTER LES CHAÎNES"
        echo "3. ➕ AJOUTER UNE CHAÎNE"
        echo "4. 🗑️  SUPPRIMER UNE CHAÎNE"
        echo "5. 🌐 SÉLECTIONNER NAVIGATEUR"
        echo "6. 🔄 CODE MOIS PROCHAIN"
        echo "7. 📊 STATUT"
        echo "8. 🔐 RENOUVELLER"
        echo "0. 🚪 QUITTER"
        echo ""
        
        local choice=""
        tv_read "VOTRE CHOIX (0-8) : " choice
        
        case $choice in
            1) open_channel ;;
            2) header; list_channels; tv_pause ;;
            3) add_channel ;;
            4) delete_channel ;;
            5) browser_selection_menu ;;
            6) show_next_month_code ;;
            7) show_status ;;
            8) return 1 ;;  # Force le renouvellement
            0) echo -e "${GREEN}Au revoir${NC}"; exit 0 ;;
            *) error "Choix invalide"; tv_pause ;;
        esac
    done
}

# ============================================
# BOUCLE PRINCIPALE - STRICTE
# ============================================

main() {
    # Initialisation silencieuse
    init_config
    init_codes
    
    # Initialisation du fichier navigateur si absent
    if [[ ! -f "$BROWSERS_FILE" ]]; then
        get_default_browser > "$BROWSERS_FILE"
    fi
    
    while true; do
        # CONTRÔLE STRICT - BLOQUÉ TANT QUE PAS VALIDE
        strict_access_control
        
        # MENU - ACCESSIBLE UNIQUEMENT SI CODE VALIDE
        if ! main_menu; then
            continue  # Retour au contrôle strict
        fi
    done
}

# LANCEMENT
main
