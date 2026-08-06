# Tunnel SSH pour PostgreSQL - Guide d'utilisation

Ce guide explique comment créer, vérifier et détruire un tunnel SSH pour accéder à la base de données PostgreSQL distante via l'alias `myfreebox`.

## Configuration

- **Alias SSH** : `myfreebox` (défini dans `~/.zshrc`)
- **Connexion** : `alvin@91.171.4.184 -p 31456`
- **Port PostgreSQL distant** : `5432`
- **Port local** : `5433` (pour éviter les conflits avec les services Docker locaux)

## 1. Créer le tunnel SSH

Pour créer le tunnel SSH en arrière-plan :

```bash
ssh -f -N -L 5433:localhost:5432 alvin@91.171.4.184 -p 31456
```

**Explication des options :**
- `-f` : Exécute SSH en arrière-plan
- `-N` : N'exécute aucune commande distante (tunnel uniquement)
- `-L 5433:localhost:5432` : Redirige le port local 5433 vers localhost:5432 sur la machine distante

**Alternative avec l'alias :**
```bash
ssh -f -N -L 5433:localhost:5432 myfreebox
```

## 2. Vérifier que le tunnel fonctionne

### Vérifier que le processus SSH est actif

```bash
ps aux | grep "ssh.*5433" | grep -v grep
```

Vous devriez voir un processus SSH actif avec les détails de la connexion.

### Tester la connexion PostgreSQL

Une fois le tunnel créé, vous pouvez tester la connexion à PostgreSQL :

```bash
psql -h localhost -p 5433 -U votre_utilisateur -d votre_database
```

Ou avec une commande de test simple :

```bash
psql -h localhost -p 5433 -U postgres -c "SELECT version();"
```

### Vérifier que le port local écoute

```bash
lsof -i :5433
```

Cette commande affichera les processus utilisant le port 5433.

## 3. Détruire le tunnel SSH

### Méthode 1 : Tuer le processus par PID

Trouvez d'abord le PID du processus :

```bash
ps aux | grep "ssh.*5433" | grep -v grep | awk '{print $2}'
```

Puis tuez-le :

```bash
kill <PID>
```

### Méthode 2 : Tuer tous les tunnels SSH sur le port 5433

```bash
pkill -f "ssh.*5433"
```

### Méthode 3 : Tuer tous les tunnels SSH vers myfreebox

```bash
pkill -f "ssh.*myfreebox"
```

## Utilisation dans les applications

Une fois le tunnel créé, vous pouvez configurer vos applications pour utiliser `localhost:5433` au lieu de l'adresse distante.

### Exemple avec Docker Compose

Dans votre fichier `docker-compose.yml`, vous pouvez utiliser :

```yaml
environment:
  - DB_HOST=host.docker.internal  # ou 172.17.0.1 selon votre configuration
  - DB_PORT=5433
```

### Exemple avec variables d'environnement

Dans votre fichier `.env` :

```env
DB_HOST=localhost
DB_PORT=5433
DB_NAME=votre_database
DB_USER=votre_utilisateur
DB_PASSWORD=votre_mot_de_passe
```

## Dépannage

### Le tunnel ne se connecte pas

1. Vérifiez que l'alias `myfreebox` est bien défini :
   ```bash
   alias myfreebox
   ```

2. Testez la connexion SSH directe :
   ```bash
   ssh alvin@91.171.4.184 -p 31456
   ```

3. Vérifiez que le port 5433 n'est pas déjà utilisé :
   ```bash
   lsof -i :5433
   ```

### Le tunnel se ferme automatiquement

Si le tunnel se ferme après quelques minutes, vous pouvez utiliser `autossh` pour le maintenir actif :

```bash
autossh -M 20000 -f -N -L 5433:localhost:5432 alvin@91.171.4.184 -p 31456
```

### Voir les logs du tunnel

Si vous avez créé le tunnel sans l'option `-f`, vous verrez les logs directement. Pour un tunnel en arrière-plan, vous pouvez vérifier les logs système :

```bash
tail -f /var/log/system.log | grep ssh
```

## Notes importantes

- Le tunnel doit rester actif pendant toute la durée d'utilisation de la base de données
- Si vous fermez votre terminal, le tunnel peut se fermer (sauf s'il est en arrière-plan avec `-f`)
- Assurez-vous de détruire le tunnel une fois terminé pour libérer les ressources
- Le port local 5433 est choisi pour éviter les conflits avec les services Docker locaux qui utilisent souvent 5434

