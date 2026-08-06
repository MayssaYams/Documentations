# Guide de Déploiement sur Freebox

Ce document présente différentes approches pour déployer vos services Django sur votre Freebox via l'alias SSH `myfreebox`.

## Configuration Actuelle

- **Alias SSH** : `myfreebox` → `alvin@91.171.4.184 -p 31456`
- **Services** : 14 services Django (auth, admin, analytics, baker, display, favorite, message, notification, order, payment, product, review, search, subscription, user)
- **Base de données** : PostgreSQL déjà accessible via tunnel SSH (port 5433 local → 5432 distant)

## Approches de Déploiement

### Option 1 : Déploiement Direct avec systemd (Recommandé pour production)

**Avantages :**
- Gestion automatique des services (démarrage au boot, redémarrage automatique)
- Logs centralisés via journald
- Gestion simple avec `systemctl`
- Pas de dépendance Docker

**Prérequis sur Freebox :**
- Python 3.8+ installé
- PostgreSQL déjà configuré
- Accès SSH avec privilèges sudo

**Structure proposée :**
```
/home/alvin/services/
├── auth-service/
│   ├── venv/
│   ├── .env
│   └── ...
├── admin-service/
├── ...
└── deploy/
    ├── deploy.sh          # Script de déploiement
    ├── systemd/           # Fichiers systemd
    └── nginx/             # Configuration nginx (pour plus tard)
```

**Fichiers systemd à créer :**
- `auth-service.service`
- `admin-service.service`
- `analytics-service.service`
- etc.

**Exemple de fichier systemd (`/etc/systemd/system/auth-service.service`) :**
```ini
[Unit]
Description=Auth Service Django
After=network.target postgresql.service

[Service]
Type=simple
User=alvin
WorkingDirectory=/home/alvin/services/auth-service
Environment="PATH=/home/alvin/services/auth-service/venv/bin"
ExecStart=/home/alvin/services/auth-service/venv/bin/python manage.py runserver 0.0.0.0:8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

---

### Option 2 : Déploiement avec Docker Compose

**Avantages :**
- Isolation des services
- Gestion des dépendances simplifiée
- Facile à migrer vers d'autres environnements
- Versioning des environnements

**Prérequis sur Freebox :**
- Docker et Docker Compose installés
- Accès SSH

**Structure proposée :**
```
/home/alvin/services/
├── docker-compose.yml     # Orchestration de tous les services
├── .env                   # Variables d'environnement globales
├── services/
│   ├── auth-service/
│   ├── admin-service/
│   └── ...
└── nginx/
    └── nginx.conf         # Reverse proxy (pour plus tard)
```

**Exemple de `docker-compose.yml` :**
```yaml
version: '3.8'

services:
  auth-service:
    build: ./auth-service
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      - db
    restart: unless-stopped

  admin-service:
    build: ./admin-service
    ports:
      - "8001:8001"
    env_file:
      - .env
    depends_on:
      - db
    restart: unless-stopped

  # ... autres services

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myTestPatisry
      POSTGRES_USER: local
      POSTGRES_PASSWORD: admin
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

---

### Option 3 : Déploiement avec Supervisor

**Avantages :**
- Simple à configurer
- Gestion des processus Python
- Logs par service
- Pas besoin de privilèges root pour la configuration

**Prérequis sur Freebox :**
- Supervisor installé
- Python 3.8+

**Exemple de configuration (`/etc/supervisor/conf.d/auth-service.conf`) :**
```ini
[program:auth-service]
command=/home/alvin/services/auth-service/venv/bin/python manage.py runserver 0.0.0.0:8000
directory=/home/alvin/services/auth-service
user=alvin
autostart=true
autorestart=true
stderr_logfile=/var/log/auth-service.err.log
stdout_logfile=/var/log/auth-service.out.log
environment=DB_HOST="localhost",DB_PORT="5432"
```

---

### Option 4 : Déploiement avec PM2 (Node.js Process Manager)

**Avantages :**
- Très simple à utiliser
- Monitoring intégré
- Redémarrage automatique
- Gestion des logs

**Prérequis sur Freebox :**
- Node.js et npm installés
- PM2 installé globalement

**Exemple de `ecosystem.config.js` :**
```javascript
module.exports = {
  apps: [
    {
      name: 'auth-service',
      script: 'manage.py',
      interpreter: '/home/alvin/services/auth-service/venv/bin/python',
      cwd: '/home/alvin/services/auth-service',
      args: 'runserver 0.0.0.0:8000',
      env: {
        DB_HOST: 'localhost',
        DB_PORT: '5432'
      },
      autorestart: true,
      watch: false
    },
    // ... autres services
  ]
};
```

---

## Script de Déploiement Automatisé

### Script de déploiement via SSH (`deploy.sh`)

Ce script peut être exécuté depuis votre machine locale pour déployer sur la Freebox :

```bash
#!/bin/bash
# deploy.sh - Déploiement automatique sur Freebox

FREEBOX_HOST="myfreebox"
SERVICES_DIR="/home/alvin/services"
LOCAL_BACKEND_DIR="/Users/anzembani/Documents/Personel/Dev/Backend"

# Liste des services
SERVICES=(
    "auth-service:8000"
    "admin-service:8001"
    "analytics-service:8002"
    "baker-service:8010"
    "display-service:8011"
    "favorite-service:8012"
    "message-service:8013"
    "notification-service:8014"
    "order-service:8015"
    "payment-service:8016"
    "product-service:8002"
    "review-service:8017"
    "search-service:8018"
    "subscription-service:8019"
    "user-service:8020"
)

echo "🚀 Déploiement sur Freebox..."

# Créer le répertoire des services sur la Freebox
ssh $FREEBOX_HOST "mkdir -p $SERVICES_DIR"

# Déployer chaque service
for service_port in "${SERVICES[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    echo "📦 Déploiement de $service..."
    
    # Synchroniser les fichiers (exclure venv, __pycache__, etc.)
    rsync -avz --exclude 'venv' --exclude '__pycache__' --exclude '*.pyc' \
        --exclude '.env' \
        "$LOCAL_BACKEND_DIR/$service/" \
        "$FREEBOX_HOST:$SERVICES_DIR/$service/"
    
    # Créer l'environnement virtuel et installer les dépendances
    ssh $FREEBOX_HOST << EOF
        cd $SERVICES_DIR/$service
        if [ ! -d "venv" ]; then
            python3 -m venv venv
        fi
        source venv/bin/activate
        pip install -q -r requirements.txt
EOF
    
    echo "✅ $service déployé"
done

echo "🎉 Déploiement terminé!"
```

---

## Configuration des Ports

### Mapping des ports par service

| Service | Port Local | Port Freebox (suggesté) |
|---------|-----------|------------------------|
| auth-service | 8000 | 8000 |
| admin-service | 8001 | 8001 |
| analytics-service | 8002 | 8002 |
| baker-service | 8010 | 8010 |
| display-service | 8011 | 8011 |
| favorite-service | 8012 | 8012 |
| message-service | 8013 | 8013 |
| notification-service | 8014 | 8014 |
| order-service | 8015 | 8015 |
| payment-service | 8016 | 8016 |
| product-service | 8002 | 8021 |
| review-service | 8017 | 8017 |
| search-service | 8018 | 8018 |
| subscription-service | 8019 | 8019 |
| user-service | 8020 | 8020 |

**Note :** Vous mentionnez que vous vous occuperez de l'exposition des ports plus tard. Pour l'instant, les services peuvent écouter sur `0.0.0.0` pour être accessibles depuis le réseau local de la Freebox.

---

## Configuration de la Base de Données

### Option A : Utiliser PostgreSQL directement sur Freebox

Si PostgreSQL est déjà installé sur la Freebox, configurez simplement les `.env` :

```env
DB_HOST=localhost
DB_PORT=5432
POSTGRES_DB=myTestPatisry
POSTGRES_USER=local
POSTGRES_PASSWORD=admin
```

### Option B : Continuer avec le tunnel SSH (développement)

Pour le développement, vous pouvez continuer à utiliser le tunnel SSH depuis votre machine locale.

---

## Étapes de Déploiement Recommandées

### Phase 1 : Préparation (une seule fois)

1. **Vérifier l'environnement sur Freebox :**
   ```bash
   ssh myfreebox "python3 --version && which python3"
   ```

2. **Créer la structure de répertoires :**
   ```bash
   ssh myfreebox "mkdir -p ~/services && mkdir -p ~/services/logs"
   ```

3. **Installer les dépendances système (si nécessaire) :**
   ```bash
   ssh myfreebox "sudo apt-get update && sudo apt-get install -y python3-venv python3-pip"
   ```

### Phase 2 : Déploiement Initial

1. **Utiliser le script de déploiement :**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

2. **Ou déployer manuellement un service de test :**
   ```bash
   # Depuis votre machine locale
   rsync -avz --exclude 'venv' --exclude '__pycache__' \
       /Users/anzembani/Documents/Personel/Dev/Backend/auth-service/ \
       myfreebox:~/services/auth-service/
   
   # Sur la Freebox
   ssh myfreebox
   cd ~/services/auth-service
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   cp .env.example .env  # Puis éditer avec les bonnes valeurs
   python manage.py runserver 0.0.0.0:8000
   ```

### Phase 3 : Automatisation (choisir une option)

1. **Option systemd :**
   ```bash
   # Créer les fichiers .service
   # Copier vers /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable auth-service
   sudo systemctl start auth-service
   ```

2. **Option Supervisor :**
   ```bash
   sudo supervisorctl reread
   sudo supervisorctl update
   sudo supervisorctl start auth-service
   ```

3. **Option PM2 :**
   ```bash
   pm2 start ecosystem.config.js
   pm2 save
   pm2 startup  # Pour démarrer au boot
   ```

---

## Scripts Utiles

### Script de démarrage de tous les services (`start_all_services.sh`)

```bash
#!/bin/bash
# À exécuter sur la Freebox

SERVICES_DIR="$HOME/services"
SERVICES=(
    "auth-service:8000"
    "admin-service:8001"
    # ... autres services
)

for service_port in "${SERVICES[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    cd "$SERVICES_DIR/$service"
    source venv/bin/activate
    nohup python manage.py runserver 0.0.0.0:$port > ../logs/${service}.log 2>&1 &
    echo "Started $service on port $port (PID: $!)"
done
```

### Script de vérification de l'état (`check_services.sh`)

```bash
#!/bin/bash
# À exécuter sur la Freebox

SERVICES=("auth-service:8000" "admin-service:8001" ...)

for service_port in "${SERVICES[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/admin/ | grep -q "200\|301\|302"; then
        echo "✅ $service (port $port) - OK"
    else
        echo "❌ $service (port $port) - DOWN"
    fi
done
```

---

## Prochaines Étapes (pour plus tard)

1. **Configuration Nginx comme reverse proxy :**
   - Un seul point d'entrée (port 80/443)
   - Routing vers les différents services
   - SSL/TLS avec Let's Encrypt

2. **Exposition des ports via Freebox :**
   - Configuration du routeur Freebox
   - Redirection de ports
   - Ou utilisation de Freebox OS pour l'exposition

3. **Monitoring et logs :**
   - Centralisation des logs
   - Monitoring de santé des services
   - Alertes en cas de problème

4. **CI/CD :**
   - Automatisation du déploiement
   - Tests avant déploiement
   - Rollback automatique en cas d'erreur

---

## Recommandation

Pour commencer, je recommande **l'Option 1 (systemd)** car :
- ✅ Intégration native avec Linux
- ✅ Gestion robuste des services
- ✅ Logs centralisés
- ✅ Démarrage automatique au boot
- ✅ Pas de dépendances supplémentaires

Une fois que vous serez à l'aise avec le déploiement, vous pourrez migrer vers Docker Compose si vous souhaitez plus d'isolation et de portabilité.

---

## Questions ou Besoin d'Aide ?

N'hésitez pas à demander de l'aide pour :
- Créer les fichiers systemd pour tous vos services
- Configurer le script de déploiement automatisé
- Mettre en place la configuration Nginx
- Automatiser le processus complet

