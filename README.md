# ExploreCMEO.jl: Explorer les curriculums du Ministère (MÉO)

| <img src="https://raw.githubusercontent.com/alainman-krh/ExploreCMEODonnees.jl/master/images/ExploreCMEO_fleche.png" width="850"> |
| :---: |

<a name="Description"></a>
## Description

ExploreCMEO facilite le visionnement des attentes et les contenus d'apprentissages des Curriculums du Ministère de l'Éducation de l'Ontario (MÉO).
 - Une seule application pour tout les curriculums (une fois les données toutes entrées dans ExploreCMEO).
 - Exploration plus rapide qu'avec les sources pdf ou web.
 - Schéma de numérotation cohérent pour domaines/attentes/contenus pour tous les sujets.
 - Copie des données plus facile!
   - Ex: pas besoin de ré-assembler les contenus d'apprentissage qui ont des bris de ligne dans les .pdf.

## Table des matières
 1. [Description](#Description)
 1. [Installation](#Installation)
    1. [Installation: Étapes supplémentaires (Windows)](#InstallationWin)
 1. [Info: Certains sous-modules clés](#SousModules)
 1. [Problèmes identifiés](#Problemes)

<a name="Installation"></a>
## Installation
 1. Télécharger & installer une version récente du language de programmation (scientifique) Julia:
    - <https://julialang.org/downloads/></br>
(Initié par un groupe de recherche du MIT).
 1. Lancer cette nouvelle installation de Julia.
 1. Ajouter le "package" à partir de la fenêtre Julia:
    - Insérer la commande suivante dans la console `julia>`.</br>
`using Pkg; Pkg.add(url="https://github.com/alainman-krh/ExploreCMEO.jl")`
    - INFO: Dans la console pour Windows, le bouton de droite peut être utilisé pour coller la commande.
    - Ne pas oublier d'utiliser la touche `<ENTER>` pour exécuter la commande.

***ATTENTION: Le lancement de ExploreCMEO sera très lent (peut-être dizaine de minutes) la première fois. Ceci est une limitation du système d'exécution de Julia lorsqu'on utilise des "packages" plus complexes (GTK/Cairo).***

<a name="InstallationWin"></a>
### Installation: Étapes supplémentaires (Windows)
Pour faciliter l'utilisation sous windows, il faut créer un raccourci lancer ExploreCMEO.

Premièrement, il faut générer l'expression qu exécutera le script `lancer_explorecmeo.jl`:
 1. À partir de la console console `julia>`, exécuter:</br>
`using ExploreCMEO; ExploreCMEO.show_launcher_info()`
    - Le résultat devrait ressembler un peu comme:</br>
`"C:\Users\alain\AppData\Local\Programs\Julia 1.5.1\bin\julia.exe" -L "C:\Users\alain\.julia\packages\ExploreCMEO\9WB2s\lancer_explorecmeo.jl"`
    - C'est ce qu'on appèle l'expression de lancement:</br>
`[EXPR_LANCEMENT] = "C:\Users\alain\AppData\Local\ [...]`

Ensuite, il faut créer le raccourci windows lui-même:
 1. Sur le "bureau" de l'ordinateur:
    - Cliquer du `<bouton-droite>(souris)`.
    - Sélectionner: `Nouveau > Raccourci`.
    - **Emplacement de l'élément (Cible):** `[EXPR_LANCEMENT]`</br>
**NOTE:** il  ne faut pas écrire "`[EXPR_LANCEMENT]`". Il faut plutôt copier la valeur qu'on vient d'obtenir en exécutant `show_launcher_info()`.
    - Cliquer `Suivant`.
    - Nom du raccourci: `ExploreCMEO`.
    - Cliquer `Terminer`.
 1. Sur le nouveau raccourci `ExploreCMEO` ("bureau" de l'ordinateur):
    - Cliquer du `<bouton-droite>(souris)`.
    - Sélectionner: `Propriétés`.
    - **Démarrer dans:** `%USERPROFILE%\Documents`
      - Ce paramêtre contrôle où ExploreCMEO va télécharger/entreposer les données du curriculum.
      - Il est donc possible de choisir n'importe quel autre emplacement désiré pour entreposer les données.
    - Cliquer `OK`.

<a name="SousModules"></a>
## Info: Certains sous-modules clés
ExploreCMEO.jl dépend de certains modules clés:
 - [ExploreCMEODonnées.jl](https://github.com/alainman-krh/ExploreCMEODonnees.jl): Contient le fichier contentant les données du curriculum.
 - Gtk.jl/GTK+ 3: Interface graphique portable (Windows/Linux/macOS/...).
 - HDF5.jl/HDF5: Format de données hierachique (bien adapté pour l'information structurée du curriculum).
   - Conçu par le "National Center for Supercomputing Applications".

<a name="Problemes"></a>
## Problèmes identifiés
 - À faire: Il faut une connection à l'internet pour télécharger les données du curriculum à la première exécution de l'application ExploreCMEO.
 - Cette application fut développé à la vitesse. Plusieurs éléments ne se comportent donc pas de façon typique pour un interface graphique (GUI) moderne.
 - De plus, je ne suis pas un expert dans le système GTK. Plusieures fonctionnalités ne sont donc pas parfaitement façonnées.

### Compatibilité

Il est impossible de déterminer la compatibilité de ce logiciel avec toutes les configurations disponibles.  Par contre, ce module fut testé en utilisant l'environnement suivant:

- Windows 10 / Linux / Julia-1.5.1 / Gtk.jl v1.1.5 (GTK+ 3) / Cairo.jl v1.0.5 / HDF5.jl v0.12.5
