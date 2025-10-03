# Scalingo Grafana Tempo Buildpack

Ce buildpack vise à déployer une instance de Grafana Tempo sur la plateforme PaaS [Scalingo](https://scalingo.com/). Grafana Tempo est un backend de traçage distribué open-source, facile à utiliser et à grande échelle, conçu pour le stockage de traces à faible coût.

## Configuration

Ce buildpack offre une flexibilité accrue pour la configuration de Tempo, permettant de définir `tempo.yaml` via un fichier local, une variable d'environnement complète, ou un template enrichi par des variables d'environnement spécifiques, avec une hiérarchie de priorité claire.

### Hiérarchie de la Configuration

La configuration de Tempo est appliquée selon la priorité suivante (du plus élevé au plus bas) :

1.  **Fichier de l'application (`app/tempo.yaml`)** : Si ce fichier est présent à la racine de votre application, il sera utilisé directement.
2.  **Variable d'environnement complète (`TEMPO_CONFIG_YAML`)** : Si le fichier local n'est pas trouvé, le contenu de cette variable d'environnement sera utilisé pour générer le fichier de configuration.
3.  **Template par défaut du buildpack (`tempo.yaml.erb`)** : Utilisé si aucune autre configuration n'est fournie, enrichi par des variables d'environnement spécifiques.

### Variables d'environnement spécifiques

Lorsque vous utilisez le template par défaut du buildpack, les variables d'environnement suivantes peuvent être utilisées pour configurer des aspects clés de Tempo :

*   `TEMPO_VERSION` (par défaut : `2.4.0`) : Permet de spécifier la version de Grafana Tempo à installer.
    ```shell
    $ scalingo env-set TEMPO_VERSION=2.5.0
    ```
*   `TEMPO_GRPC_LISTEN_PORT` (par défaut : `9095`) : Port d'écoute gRPC pour le serveur Tempo. Le port HTTP est automatiquement géré par la variable `$PORT` de Scalingo.

#### Configuration du Stockage (S3 compatible)

Tempo est conçu pour utiliser le stockage objet (S3, GCS, Azure Blob Storage) pour ses données de traces. Ce buildpack supporte la configuration d'un backend S3 compatible via les variables d'environnement suivantes :

*   `TEMPO_STORAGE_TRACE_BY_ID_BACKEND` (par défaut : `s3`) : Backend de stockage pour les traces par ID.
*   `TEMPO_STORAGE_WAL_PATH` (par défaut : `/tmp/tempo/wal`) : Chemin pour le Write-Ahead Log (WAL).
*   `TEMPO_STORAGE_S3_BUCKET` : Nom du bucket S3 où les traces seront stockées. **Obligatoire pour le stockage S3.**
*   `TEMPO_STORAGE_S3_ENDPOINT` : Endpoint de votre service S3 (ex: `s3.fr-par.scw.cloud` pour Scaleway). **Obligatoire pour le stockage S3.**
*   `TEMPO_STORAGE_S3_ACCESS_KEY_ID` : Clé d'accès pour votre bucket S3. **Obligatoire pour le stockage S3.**
*   `TEMPO_STORAGE_S3_SECRET_ACCESS_KEY` : Clé secrète pour votre bucket S3. **Obligatoire pour le stockage S3.**
*   `TEMPO_STORAGE_S3_INSECURE` (par défaut : `false`) : Définir à `true` pour utiliser HTTP au lieu de HTTPS pour la connexion S3 (non recommandé en production).

### Options de configuration avancées

#### Configuration complète de `tempo.yaml` via variable d'environnement

Vous pouvez fournir le contenu complet de votre fichier `tempo.yaml` via la variable d'environnement `TEMPO_CONFIG_YAML`. Cela surchargera le template par défaut et les variables d'environnement spécifiques.

```shell
$ scalingo env-set TEMPO_CONFIG_YAML=\'\'\'
server:
  # Le port HTTP est géré par Scalingo via $PORT
  grpc_listen_port: 9095
distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:
storage:
  trace_by_id:
    backend: s3
  wal:
    path: /tmp/tempo/wal
  s3:
    bucket: my-tempo-bucket
    endpoint: s3.fr-par.scw.cloud
    access_key_id: YOUR_S3_ACCESS_KEY
    secret_access_key: YOUR_S3_SECRET_KEY
\'\'\'
```

#### Utilisation d'un fichier de configuration local

Pour un contrôle maximal, vous pouvez inclure votre propre fichier `tempo.yaml` à la racine de votre dépôt d'application. Le buildpack détectera et utilisera ce fichier directement.

**Exemple de structure de dépôt :**

```
my-tempo-app/
├── app.json
├── tempo.yaml
└── ...
```

## Exemples d'utilisation

### Déploiement simple avec configuration par défaut et stockage S3

1.  Créez un dépôt Git pour votre application.
2.  Configurez les variables d'environnement minimales pour le stockage S3 :
    ```shell
    $ scalingo create my-tempo-app
    $ scalingo --app my-tempo-app env-set TEMPO_STORAGE_S3_BUCKET=my-tempo-bucket
    $ scalingo --app my-tempo-app env-set TEMPO_STORAGE_S3_ENDPOINT=s3.fr-par.scw.cloud
    $ scalingo --app my-tempo-app env-set TEMPO_STORAGE_S3_ACCESS_KEY_ID=YOUR_S3_ACCESS_KEY
    $ scalingo --app my-tempo-app env-set TEMPO_STORAGE_S3_SECRET_ACCESS_KEY=YOUR_S3_SECRET_KEY
    ```
3.  Poussez votre application (même vide) vers Scalingo avec ce buildpack.
    ```bash
    git init
    scalingo git-setup --app my-tempo-app
    git commit -m "Initial commit for Tempo"
    git push scalingo master
    ```

### Déploiement avec `tempo.yaml` local

1.  Créez un fichier `tempo.yaml` à la racine de votre application :

    **`tempo.yaml` :**
    ```yaml
    server:
      # Le port HTTP est géré par Scalingo via $PORT
      grpc_listen_port: 9095

    distributor:
      receivers:
        otlp:
          protocols:
            grpc:
            http:

    storage:
      trace_by_id:
        backend: s3
      wal:
        path: /tmp/tempo/wal
      s3:
        bucket: my-custom-tempo-bucket
        endpoint: s3.fr-par.scw.cloud
        access_key_id: YOUR_S3_ACCESS_KEY
        secret_access_key: YOUR_S3_SECRET_KEY
    ```
2.  Ajoutez ce fichier à votre dépôt Git, commitez et poussez vers Scalingo.
    ```bash
    git add tempo.yaml
    git commit -m "Ajout de la configuration locale de Tempo"
    git push scalingo master
    ```

### Définition de la version de Tempo

Pour utiliser une version spécifique de Tempo, définissez la variable d'environnement `TEMPO_VERSION` avant le déploiement :

```shell
$ scalingo --app my-tempo-app env-set TEMPO_VERSION=2.5.0
$ git push scalingo master # Redéployer pour appliquer la nouvelle version
```

---

**Auteur :** Manus AI
**Date :** 02 Octobre 2025

