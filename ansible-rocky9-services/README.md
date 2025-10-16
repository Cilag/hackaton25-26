# 🚀 Installation automatisée des services Rocky 9 avec Ansible

Ce projet Ansible permet d'installer et de configurer automatiquement sur une VM Rocky 9 les services suivants :
- **Docker** : Conteneurisation des applications
- **Nginx** : Serveur web avec proxy reverse et SSL
- **Draw.io** : Éditeur de diagrammes en ligne
- **Stirling PDF** : Outil de manipulation de fichiers PDF

## 📋 Prérequis

### Sur votre machine de contrôle (là où vous lancez Ansible)
- Ansible >= 2.9
- Python 3.6+
- Module `docker` pour Python : `pip install docker`
- Module `docker-compose` pour Python : `pip install docker-compose`

### Sur la VM Rocky 9 cible
- Rocky Linux 9 installé et configuré
- Accès SSH avec clés ou mot de passe
- Utilisateur avec droits sudo ou accès root
- Connexion internet pour télécharger les packages

## 🛠️ Configuration initiale

### 1. Cloner ou télécharger le projet
```bash
git clone <votre-repo> ansible-rocky9-services
cd ansible-rocky9-services
```

### 2. Configurer l'inventaire
Éditez le fichier `inventory` et remplacez les valeurs par celles de votre VM :

```ini
[rocky9_servers]
rocky9-vm ansible_host=192.168.1.100 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
```

**Paramètres à modifier :**
- `ansible_host` : IP ou nom de domaine de votre VM Rocky 9
- `ansible_user` : Utilisateur SSH (root ou utilisateur avec sudo)
- `ansible_ssh_private_key_file` : Chemin vers votre clé SSH privée

### 3. Tester la connexion
```bash
ansible rocky9_servers -m ping
```

Vous devriez voir :
```
rocky9-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## 🚀 Déploiement

### Installation complète
```bash
ansible-playbook -i inventory site.yml
```

### Installation par composants (optionnel)
```bash
# Docker seulement
ansible-playbook -i inventory site.yml --tags docker

# Nginx seulement
ansible-playbook -i inventory site.yml --tags nginx

# Draw.io seulement
ansible-playbook -i inventory site.yml --tags drawio

# Stirling PDF seulement
ansible-playbook -i inventory site.yml --tags stirling-pdf
```

### Mode verbose (pour debug)
```bash
ansible-playbook -i inventory site.yml -vvv
```

## 📊 Vérification de l'installation

### 1. Services système
Connectez-vous à votre VM Rocky 9 et vérifiez :

```bash
# Status des services
systemctl status nginx
systemctl status docker
systemctl status drawio
systemctl status stirling-pdf

# Vérification des ports
ss -tulnp | grep -E ':80|:443|:8080|:8081'

# Containers Docker
docker ps
```

### 2. Tests d'accès web
Ouvrez votre navigateur et testez :

- **Page d'accueil** : `https://IP_DE_VOTRE_VM/`
- **Draw.io** : `https://IP_DE_VOTRE_VM/drawio/`
- **Stirling PDF** : `https://IP_DE_VOTRE_VM/pdf/`

⚠️ **Note SSL** : Le certificat SSL est auto-signé, votre navigateur affichera un avertissement de sécurité. Cliquez sur "Avancé" puis "Continuer vers le site" ou "Accepter le risque".

## 🔧 Configuration avancée

### Variables personnalisables
Éditez `group_vars/all.yml` pour personnaliser :

```yaml
# Domaine (utilisez votre IP ou nom de domaine)
domain_name: "votre-domaine.com"

# Ports des services
drawio_port: 8080
stirling_pdf_port: 8081

# Configuration SSL
enable_ssl: true
ssl_certificate_path: /etc/nginx/ssl
```

### Certificat SSL personnalisé
Pour utiliser votre propre certificat SSL :

1. Copiez vos fichiers sur le serveur :
```bash
scp votre-certificat.crt root@IP_VM:/etc/nginx/ssl/server.crt
scp votre-cle-privee.key root@IP_VM:/etc/nginx/ssl/server.key
```

2. Redémarrez Nginx :
```bash
systemctl restart nginx
```

## 🔒 Sécurité

### Mesures de sécurité implémentées

1. **Firewall** : Seuls les ports 80 et 443 sont ouverts
2. **SSL/TLS** : Chiffrement des communications web
3. **Headers sécurisés** : Protection contre XSS, clickjacking, etc.
4. **Docker sécurisé** : Configuration avec `no-new-privileges`
5. **SELinux** : Configuration des permissions réseau pour Nginx

### Recommandations supplémentaires

1. **Changer les mots de passe par défaut**
2. **Configurer des sauvegardes régulières**
3. **Surveiller les logs** : `/var/log/nginx/` et `journalctl -u docker`
4. **Mettre à jour régulièrement** les images Docker

## 🛠️ Gestion des services

### Commandes utiles

```bash
# Redémarrer tous les services
systemctl restart nginx docker drawio stirling-pdf

# Voir les logs
journalctl -u nginx -f
journalctl -u docker -f
docker logs drawio
docker logs stirling-pdf

# Mise à jour des images Docker
cd /opt/docker-apps/drawio && docker-compose pull && docker-compose up -d
cd /opt/docker-apps/stirling-pdf && docker-compose pull && docker-compose up -d

# Arrêter/démarrer les containers
docker stop drawio stirling-pdf
docker start drawio stirling-pdf
```

### Sauvegarde des données

```bash
# Sauvegarde configurations Stirling PDF
tar -czf stirling-pdf-backup-$(date +%Y%m%d).tar.gz /opt/docker-apps/stirling-pdf/

# Sauvegarde configurations Nginx
tar -czf nginx-backup-$(date +%Y%m%d).tar.gz /etc/nginx/
```

## 🐛 Dépannage

### Problèmes courants

#### 1. Ansible ne peut pas se connecter
```bash
# Vérifier la connectivité SSH
ssh -i ~/.ssh/id_rsa root@IP_VM

# Tester avec mot de passe si les clés ne marchent pas
ansible-playbook -i inventory site.yml --ask-pass
```

#### 2. Docker ne démarre pas
```bash
# Vérifier les logs
journalctl -u docker -n 50

# Redémarrer manuellement
systemctl stop docker
systemctl start docker
```

#### 3. Nginx ne démarre pas
```bash
# Tester la configuration
nginx -t

# Vérifier les logs
tail -f /var/log/nginx/error.log
```

#### 4. Services web inaccessibles
```bash
# Vérifier le firewall
firewall-cmd --list-all

# Vérifier que les containers tournent
docker ps

# Vérifier les ports
ss -tulnp | grep -E ':80|:443|:8080|:8081'
```

### Logs importants
```bash
# Logs système
/var/log/messages
journalctl -xe

# Logs Nginx
/var/log/nginx/access.log
/var/log/nginx/error.log

# Logs Docker
journalctl -u docker
docker logs <nom_container>

# Logs Ansible (lors de l'exécution)
./ansible.log
```

## 🔄 Désinstallation

Pour supprimer tous les services installés :

```bash
# Arrêter les services
systemctl stop nginx docker drawio stirling-pdf

# Supprimer les containers
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null

# Supprimer les packages
dnf remove -y nginx docker-ce docker-ce-cli containerd.io

# Supprimer les fichiers de configuration
rm -rf /opt/docker-apps
rm -rf /etc/nginx
rm -rf /etc/systemd/system/drawio.service
rm -rf /etc/systemd/system/stirling-pdf.service

# Recharger systemd
systemctl daemon-reload
```

## 📞 Support

En cas de problème :

1. Vérifiez les logs mentionnés dans la section dépannage
2. Testez étape par étape avec les tags Ansible
3. Vérifiez la connectivité réseau et les permissions
4. Consultez la documentation officielle des services

## 📝 Structure du projet

```
ansible-rocky9-services/
├── site.yml                 # Playbook principal
├── inventory                # Configuration des serveurs
├── ansible.cfg             # Configuration Ansible
├── group_vars/
│   └── all.yml             # Variables globales
├── roles/
│   ├── docker/             # Installation Docker
│   ├── nginx/              # Configuration Nginx + SSL
│   ├── drawio/             # Déploiement Draw.io
│   └── stirling-pdf/       # Déploiement Stirling PDF
└── README.md               # Cette documentation
```

---
**Créé avec ❤️ par Ansible pour Rocky Linux 9**