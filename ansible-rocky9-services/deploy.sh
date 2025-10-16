#!/bin/bash

# Script de déploiement automatique des services Rocky 9
# Auteur: Assistant Ansible
# Version: 1.0

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
INVENTORY_FILE="inventory"
PLAYBOOK_FILE="site.yml"
LOG_FILE="deployment.log"

# Fonctions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    Déployeur de services Rocky 9 - Ansible    ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_prerequisites() {
    print_info "Vérification des prérequis..."
    
    # Vérifier Ansible
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible n'est pas installé"
        exit 1
    fi
    print_success "Ansible trouvé : $(ansible --version | head -1)"
    
    # Vérifier Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 n'est pas installé"
        exit 1
    fi
    print_success "Python3 trouvé : $(python3 --version)"
    
    # Vérifier les modules Python requis
    for module in docker docker-compose; do
        if ! python3 -c "import ${module//-/_}" &> /dev/null; then
            print_warning "Module Python $module non trouvé. Installation recommandée : pip install $module"
        else
            print_success "Module Python $module trouvé"
        fi
    done
}

check_inventory() {
    print_info "Vérification de l'inventaire..."
    
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        print_error "Fichier inventaire '$INVENTORY_FILE' non trouvé"
        exit 1
    fi
    
    # Test de connectivité
    print_info "Test de connectivité avec les serveurs..."
    if ansible rocky9_servers -i "$INVENTORY_FILE" -m ping &> /dev/null; then
        print_success "Connectivité OK avec tous les serveurs"
    else
        print_error "Impossible de se connecter aux serveurs. Vérifiez votre inventaire."
        print_info "Tentez : ansible rocky9_servers -i $INVENTORY_FILE -m ping"
        exit 1
    fi
}

show_menu() {
    echo
    print_info "Options de déploiement :"
    echo "1) Installation complète (recommandée)"
    echo "2) Installation Docker uniquement"
    echo "3) Installation Nginx uniquement"  
    echo "4) Installation Draw.io uniquement"
    echo "5) Installation Stirling PDF uniquement"
    echo "6) Test de connectivité seulement"
    echo "7) Afficher l'état des services"
    echo "q) Quitter"
    echo
    read -p "Votre choix [1-7, q] : " choice
}

run_playbook() {
    local tags="$1"
    local description="$2"
    
    print_info "Démarrage : $description"
    echo "Début du déploiement : $(date)" >> "$LOG_FILE"
    
    local cmd="ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE"
    if [[ -n "$tags" ]]; then
        cmd="$cmd --tags $tags"
    fi
    
    print_info "Commande exécutée : $cmd"
    
    if $cmd 2>&1 | tee -a "$LOG_FILE"; then
        print_success "$description terminée avec succès !"
        echo "Fin du déploiement : $(date)" >> "$LOG_FILE"
    else
        print_error "$description échouée. Consultez $LOG_FILE pour les détails."
        exit 1
    fi
}

show_service_status() {
    print_info "Vérification de l'état des services..."
    
    ansible rocky9_servers -i "$INVENTORY_FILE" -m shell -a "
        echo '=== Services systemd ==='
        systemctl is-active nginx docker drawio stirling-pdf 2>/dev/null || echo 'Certains services ne sont pas actifs'
        echo
        echo '=== Containers Docker ==='
        docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'Docker non disponible'
        echo  
        echo '=== Ports en écoute ==='
        ss -tulnp | grep -E ':80|:443|:8080|:8081' || echo 'Aucun port de service trouvé'
    " || print_error "Impossible de vérifier l'état des services"
}

main() {
    print_header
    
    # Vérifications initiales
    check_prerequisites
    check_inventory
    
    while true; do
        show_menu
        
        case $choice in
            1)
                run_playbook "" "Installation complète de tous les services"
                ;;
            2)
                run_playbook "docker" "Installation de Docker"
                ;;
            3)
                run_playbook "nginx" "Installation de Nginx"
                ;;
            4)
                run_playbook "drawio" "Installation de Draw.io"
                ;;
            5)
                run_playbook "stirling-pdf" "Installation de Stirling PDF"
                ;;
            6)
                print_info "Test de connectivité..."
                ansible rocky9_servers -i "$INVENTORY_FILE" -m ping
                ;;
            7)
                show_service_status
                ;;
            q|Q)
                print_info "Arrêt du script."
                exit 0
                ;;
            *)
                print_error "Option invalide. Veuillez choisir entre 1-7 ou q."
                ;;
        esac
        
        echo
        read -p "Appuyez sur Entrée pour continuer..."
    done
}

# Gestion des signaux
trap 'print_error "Script interrompu par l'utilisateur"; exit 1' INT TERM

# Point d'entrée
main