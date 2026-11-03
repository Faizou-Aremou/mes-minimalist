#!/bin/bash

# ==============================================================================
# Script interactif d'initialisation de dépôt et gestion GitHub (gh CLI)
# ==============================================================================

set -e

# Couleurs pour la mise en forme du terminal
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Initialisation interactive du dépôt GitHub ===${NC}\n"

# 1. Vérification de l'existence de GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}Erreur: L'outil 'gh' CLI n'est pas installé. Installez-le (ex: brew install gh ou apt install gh) avant de continuer.${NC}"
    exit 1
fi

# 2. Saisie interactive des paramètres du dépôt
read -p "Nom du dépôt [mes-minimalist] : " REPO_NAME
REPO_NAME=${REPO_NAME:-mes-minimalist}

read -p "Visibilité (1: public, 2: private) [1] : " VISIBILITY_CHOICE
if [ "$VISIBILITY_CHOICE" = "2" ]; then
    VISIBILITY_FLAG="--private"
else
    VISIBILITY_FLAG="--public"
fi

read -p "Description du dépôt [Manufacturing Execution System (MES) minimaliste] : " REPO_DESC
REPO_DESC=${REPO_DESC:-"Manufacturing Execution System (MES) minimaliste"}

echo -e "\n${GREEN}--> Création et clonage du dépôt ${REPO_NAME}...${NC}"
gh repo create "$REPO_NAME" $VISIBILITY_FLAG --clone --description "$REPO_DESC"
cd "$REPO_NAME"

# 3. Saisie et création interactive des Labels
echo -e "\n${CYAN}=== Configuration des Labels ===${NC}"
read -p "Voulez-vous injecter d'abord les labels par défaut (backend, frontend, database, iot) ? (O/n) : " ADD_DEFAULT_LABELS
ADD_DEFAULT_LABELS=${ADD_DEFAULT_LABELS:-O}

if [[ "$ADD_DEFAULT_LABELS" =~ ^[Oo]$ ]]; then
    gh label create "backend" --color "0E8A16" --description "Chantiers API et logique métier" --force 2>/dev/null || true
    gh label create "frontend" --color "1D76DB" --description "Interface Angular" --force 2>/dev/null || true
    gh label create "database" --color "D93F0B" --description "Schéma PostgreSQL" --force 2>/dev/null || true
    gh label create "iot" --color "5319E7" --description "Connectivité MQTT et Raspberry Pi" --force 2>/dev/null || true
    echo -e "${GREEN}Labels par défaut ajoutés.${NC}"
fi

# Boucle pour ajouter des labels personnalisés
while true; do
    read -p "Ajouter un label personnalisé ? (o/N) : " ADD_CUSTOM_LABEL
    if [[ ! "$ADD_CUSTOM_LABEL" =~ ^[Oo]$ ]]; then
        break
    fi
    read -p "  Nom du label (ex: infra) : " LABEL_NAME
    read -p "  Couleur Hex sans # (ex: 0E8A16, FF5733) : " LABEL_COLOR
    read -p "  Description (optionnel) : " LABEL_DESC
    
    if [ -n "$LABEL_NAME" ]; then
        gh label create "$LABEL_NAME" --color "${LABEL_COLOR:-000000}" --description "$LABEL_DESC" --force
        echo -e "  ${GREEN}Label '$LABEL_NAME' créé avec succès.${NC}"
    fi
done

# 4. Saisie et création interactive des Issues
echo -e "\n${CYAN}=== Configuration des Issues ===${NC}"
read -p "Voulez-vous générer automatiquement les 5 issues du Module 1 ? (O/n) : " ADD_DEFAULT_ISSUES
ADD_DEFAULT_ISSUES=${ADD_DEFAULT_ISSUES:-O}

if [[ "$ADD_DEFAULT_ISSUES" =~ ^[Oo]$ ]]; then
    echo -e "${GREEN}Création des issues du Module 1...${NC}"
    
    gh issue create \
      --title "[DB] Initialisation du schéma PostgreSQL pour le référentiel équipements" \
      --label "database" \
      --body "## Objectif
Mettre en place la persistance relationnelle pour le référentiel des machines et leur historique d'état.

## Tâches
- [ ] Script DDL SQL pour la table \`machine\` (\`id\`, \`name\`, \`type\`, \`current_status\`, \`ip_address\`, \`last_heartbeat\`).
- [ ] Table \`machine_state_history\` (\`id\`, \`machine_id\`, \`state\`, \`start_time\`, \`end_time\`, \`reason\`).
- [ ] Indexation sur \`current_status\` et \`last_heartbeat\`."

    gh issue create \
      --title "[Backend] Endpoints REST CRUD pour la gestion des machines" \
      --label "backend" \
      --body "## Objectif
Fournir les API nécessaires au front-end pour déclarer, lister, modifier et supprimer un équipement.

## Tâches
- [ ] Définir les DTOs et entités.
- [ ] \`GET /api/v1/machines\` (liste avec filtres).
- [ ] \`GET /api/v1/machines/{id}\` (détail).
- [ ] \`POST /api/v1/machines\` (création).
- [ ] \`PUT /api/v1/machines/{id}\` (mise à jour)."

    gh issue create \
      --title "[Backend/IoT] Automate d'état et détection du Timeout (Heartbeat)" \
      --label "backend","iot" \
      --body "## Objectif
Gérer dynamiquement les changements d'état des machines et basculer l'équipement en \`OFFLINE\` en cas de perte de signal.

## Tâches
- [ ] Souscripteur MQTT sur \`factory/machine/{id}/status\`.
- [ ] Tâche planifiée (scheduler) vérifiant le dépassement de timeout (> 10s).
- [ ] Historisation des changements dans \`machine_state_history\`."

    gh issue create \
      --title "[Frontend] Composant Angular d'affichage du parc machine (Equipment Cards)" \
      --label "frontend" \
      --body "## Objectif
Offrir une interface opérateur visuelle pour surveiller l'état de chaque machine en temps réel.

## Tâches
- [ ] Service Angular \`EquipmentService\`.
- [ ] Composant \`EquipmentCardComponent\` avec indicateurs couleur.
- [ ] Rafraîchissement dynamique RxJS/WebSocket."

    gh issue create \
      --title "[IoT/Simulation] Script Python/Node.js de simulation de présence machine (Heartbeat MQTT)" \
      --label "iot" \
      --body "## Objectif
Simuler le comportement d'un automate/Raspberry Pi.

## Tâches
- [ ] Publication régulière d'un payload JSON sur Mosquitto.
- [ ] Simulation d'interruption brusque (passage en \`OFFLINE\`)."
fi

# Boucle interactive pour la création d'issues sur mesure
while true; do
    echo ""
    read -p "Créer une issue personnalisée ? (o/N) : " ADD_CUSTOM_ISSUE
    if [[ ! "$ADD_CUSTOM_ISSUE" =~ ^[Oo]$ ]]; then
        break
    fi
    
    read -p "  Titre de l'issue : " ISSUE_TITLE
    read -p "  Label(s) associés (séparés par une virgule, ex: backend,iot) : " ISSUE_LABELS
    echo "  Description / Corps de l'issue (Appuyez sur Entrée, saisissez le texte, puis faites Ctrl+D pour valider) :"
    ISSUE_BODY=$(cat)
    
    if [ -n "$ISSUE_TITLE" ]; then
        if [ -n "$ISSUE_LABELS" ]; then
            gh issue create --title "$ISSUE_TITLE" --label "$ISSUE_LABELS" --body "$ISSUE_BODY"
        else
            gh issue create --title "$ISSUE_TITLE" --body "$ISSUE_BODY"
        fi
        echo -e "  ${GREEN}Issue '$ISSUE_TITLE' créée.${NC}"
    fi
done

echo -e "\n${GREEN}=== Initialisation terminée avec succès ! ===${NC}"
echo -e "Dépôt configuré dans le répertoire local : ${CYAN}$(pwd)${NC}"