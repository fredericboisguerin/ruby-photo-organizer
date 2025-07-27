# Ruby Photo Organizer

Un organisateur de photos Ruby qui analyse, déduplique et organise vos photos par date.

## Fonctionnalités

- **Analyse récursive** de toute l'arborescence source
- **Déduplication intelligente** basée sur le hash perceptuel des images
- **Organisation par date** (année/mois/jour) extraite des métadonnées EXIF ou des fichiers
- **Export CSV** détaillé de l'analyse
- **Support multi-format** (JPEG, PNG, TIFF, BMP, GIF)
- **Compatibilité cross-platform** avec les disques formatés Windows

## Compatibilité avec les disques Windows

✅ **Support complet des disques externes Windows** montés sur macOS :
- Chemins comme `/Volumes/MonDisqueWindows/Photos` sont supportés
- Nettoyage automatique des caractères interdits (`< > : " | ? *`)
- Évitement des noms réservés Windows (`CON`, `PRN`, `AUX`, etc.)
- Gestion intelligente des déplacements cross-device
- Test d'accessibilité en écriture avant traitement

### Exemples de chemins supportés
```bash
# Disque externe Windows
ruby photo_organizer.rb "/Volumes/DISQUE_PHOTOS" "/Users/john/Photos_Cleaned" "/Users/john/Duplicates"

# Dossier réseau Windows
ruby photo_organizer.rb "/Volumes/NAS/Photos" "/Users/john/Photos_Organized" "/Users/john/Photos_Duplicates"
```

## Installation

1. Installer les dépendances :
```bash
bundle install
```

2. Installer les dépendances système (pour VIPS) :
```bash
# macOS
brew install vips

# Ubuntu/Debian
sudo apt-get install libvips-dev

# CentOS/RHEL
sudo yum install vips-devel
```

## Utilisation

```bash
ruby photo_organizer.rb <chemin_source> <chemin_uniques> <chemin_duplicatas>
```

### Paramètres

- **chemin_source** : Chemin absolu du dossier contenant les photos à analyser
- **chemin_uniques** : Chemin absolu où seront déplacées les photos uniques
- **chemin_duplicatas** : Chemin absolu où seront déplacées les photos dupliquées

### Exemple

```bash
ruby photo_organizer.rb /Users/john/Photos /Users/john/Photos_Organized /Users/john/Photos_Duplicates
```

## Structure de sortie

### Photos uniques
```
chemin_uniques/
├── 2024/
│   ├── 01/
│   │   ├── 15/
│   │   │   ├── IMG_001.jpg
│   │   │   └── IMG_002.png
│   └── 02/
└── analyse.csv
```

### Photos dupliquées
```
chemin_duplicatas/
├── 2024/
│   ├── 01/
│   │   ├── 15/
│   │   │   ├── a1b2c3d4/
│   │   │   │   ├── IMG_001_2.jpg
│   │   │   │   └── IMG_001_3.jpg
```

## Rapport CSV

Le fichier `analyse.csv` contient :
- Chemin relatif original
- Type de fichier
- Nom du fichier
- Date de la photo
- Hash de l'image
- Chemin original

## Algorithme de déduplication

Le projet utilise **dhash-vips** pour calculer un hash perceptuel des images, ce qui permet de détecter les duplicatas même si :
- Les fichiers ont des noms différents
- Les métadonnées diffèrent légèrement
- La compression varie

En cas d'échec du hash perceptuel, un fallback MD5 est utilisé.
