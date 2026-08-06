# Instructions pour créer la table auth_group

## Problème de permissions

L'utilisateur `local` n'a pas les permissions nécessaires pour créer des tables dans le schéma public.

## Solutions

### Option 1: Exécuter avec un superutilisateur (Recommandé)

```bash
psql -h localhost -p 5433 -U postgres -d The-patisry -f 01_auth_group_fix.sql
```

### Option 2: Donner les permissions à l'utilisateur local

Connectez-vous en tant que superutilisateur (postgres) et exécutez:

```sql
-- Donner les permissions à l'utilisateur local
GRANT CREATE ON SCHEMA public TO local;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO local;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO local;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO local;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO local;
```

Puis ré-exécutez le script:
```bash
psql -h localhost -p 5433 -U local -d The-patisry -f 01_auth_group_fix.sql
```

### Option 3: Créer la table manuellement avec un superutilisateur

Connectez-vous en tant que postgres et exécutez:

```sql
-- Créer la table
CREATE TABLE IF NOT EXISTS auth_group (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) UNIQUE NOT NULL
);

-- Insérer les groupes
INSERT INTO auth_group (id, name) VALUES 
    (1, 'Admin'),
    (2, 'User'),
    (3, 'Baker')
ON CONFLICT (id) DO NOTHING;

-- Ajouter la contrainte FK
ALTER TABLE accounts_user 
ADD CONSTRAINT accounts_user_group_id_fkey 
FOREIGN KEY (group_id) REFERENCES auth_group(id) ON DELETE SET NULL;

-- Donner les permissions à l'utilisateur local
GRANT SELECT, INSERT, UPDATE, DELETE ON auth_group TO local;
GRANT USAGE, SELECT ON SEQUENCE auth_group_id_seq TO local;
```

## Vérification

Après exécution, vérifiez que la table existe:

```sql
SELECT id, name FROM auth_group ORDER BY id;
```

Vous devriez voir:
- ID: 1, Name: Admin
- ID: 2, Name: User
- ID: 3, Name: Baker

