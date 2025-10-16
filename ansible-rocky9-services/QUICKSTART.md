# Guide de démarrage rapide

## 🚀 Installation en 3 étapes

### 1. Préparer l'environnement
```bash
# Installer les dépendances Python
pip install -r requirements.txt

# Rendre le script exécutable (Linux/Mac)
chmod +x deploy.sh
```

### 2. Configurer votre VM
Éditez le fichier `inventory` :
```ini
[rocky9_servers]
votre-vm ansible_host=VOTRE_IP ansible_user=root
```

### 3. Lancer l'installation
```bash
# Méthode 1 : Script interactif (recommandé)
./deploy.sh

# Méthode 2 : Ansible direct
ansible-playbook -i inventory site.yml
```

## 🌐 Accès aux services

Après l'installation, accédez à vos services :

- **Page d'accueil** : https://VOTRE_IP/
- **Draw.io** : https://VOTRE_IP/drawio/  
- **Stirling PDF** : https://VOTRE_IP/pdf/

⚠️ Acceptez le certificat SSL auto-signé dans votre navigateur.

## 🔧 Commandes utiles

```bash
# Vérifier l'état des services
ansible rocky9_servers -i inventory -m shell -a "systemctl status nginx docker"

# Redémarrer un service
ansible rocky9_servers -i inventory -m shell -a "systemctl restart nginx"

# Voir les containers Docker
ansible rocky9_servers -i inventory -m shell -a "docker ps"
```

Pour plus de détails, consultez le [README.md](README.md) complet.