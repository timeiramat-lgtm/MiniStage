# TP Discover - Base de données Ministages v2

## 1 et 2. Vérification de la cohérence

En comparant `creationDB.sql` avec les cinq points de l'annexe 1, plusieurs règles ne sont pas respectées.

**Règle 3.1 (type adapté)**
- `logactionutilisateur.temps` est en `date` alors qu'un journal d'actions doit garder l'heure exacte de chaque événement. Il faut un `datetime`.
- `t_etablissement.cp` (code postal) est en `int` dans la version 1. Un code postal peut commencer par un zéro (01000) ou contenir des lettres selon les pays, et il n'a aucun sens de faire une opération arithmétique dessus. Le bon type est `varchar`.

**Règle 3.3 (NOT NULL sur les champs obligatoires)**
- `t_utilisateur.important2` et `t_utilisateur.clauses_texte` sont marqués `NOT NULL` dans le script alors que le schéma de production les décrit comme nullables. Un champ qui n'est pas toujours renseigné ne doit pas être obligatoire.

**Règle 2.2 (ON DELETE / ON UPDATE appropriés)**
- Toutes les clés étrangères utilisent `ON DELETE CASCADE`, copié tel quel depuis la version 1, sans distinction de cas.
- Pour `logactionutilisateur`, cascader la suppression signifie que supprimer un utilisateur efface aussi son historique d'actions. Un journal d'audit sert justement à garder une trace même après la suppression du compte, donc cascader ici va à l'encontre du but de la table.
- Pour `t_reservation.idEtabOrigine`, la colonne est déjà nullable. `ON DELETE SET NULL` conserve la réservation et casse juste le lien vers l'établissement d'origine, alors que `CASCADE` supprimerait toute la réservation.

**Règle 4.1 / séparation des responsabilités**
- La version 1 mélangeait les informations d'établissement à l'intérieur de `t_utilisateur` (`nometab`, `ville`, `adresse`, `RNE`...). C'est corrigé dans la version 2 avec une table `t_etablissement` séparée, ce qui est la bonne direction.

## 3. Analyse du script

**a. Différence entre `varchar(N)` et `text`**

`varchar(N)` stocke une chaîne de longueur variable jusqu'à N caractères. MySQL connaît la limite à l'avance, ce qui permet d'indexer directement la colonne et de trier dessus efficacement. On l'utilise pour des valeurs courtes et bornées : un nom, un code postal, un identifiant.

`text` stocke un contenu de taille variable sans limite pratique fixée dans la définition de colonne (jusqu'à 65 535 octets pour un `TEXT` classique). Il ne peut pas être indexé directement sur toute sa longueur, seulement sur un préfixe. On l'utilise pour du contenu long : une description, un commentaire libre, du texte encodé.

**b. `utf8mb3` et `utf8mb4`**

`utf8mb3` encode chaque caractère sur 1 à 3 octets. Cela couvre la majorité des langues mais pas les emojis ni certains caractères rares (idéogrammes chinois étendus par exemple). `utf8mb4` encode sur 1 à 4 octets et couvre l'intégralité de l'Unicode.

Le script utilise `utf8mb3` sur toutes les tables parce qu'elles ont été créées à une époque où MySQL appelait par défaut ce jeu de caractères "utf8" tout court, avant que l'utilisation de `utf8mb4` ne se généralise pour un support Unicode complet. Les deux se retrouvent dans un même script quand une base ancienne évolue sans que ses tables existantes soient migrées.

**c. `AUTO_INCREMENT`**

`AUTO_INCREMENT` génère automatiquement un entier croissant unique à chaque nouvelle ligne, sans que l'application ait besoin de calculer elle-même une valeur pour la clé primaire. Il est présent sur toutes les tables du script car c'est la stratégie de clé primaire retenue partout : simple à mettre en place et rapide à indexer.

Ça pose plusieurs problèmes. La valeur expose indirectement le nombre de lignes de la table (un identifiant `id=42` révèle qu'il y a au moins 42 utilisateurs). Les suppressions ou les transactions annulées créent des trous dans la séquence, donc l'identifiant ne peut pas servir à compter les enregistrements. Et deux bases indépendantes qui génèrent chacune leurs propres identifiants auto-incrémentés ne peuvent pas être fusionnées sans conflit, puisque les deux auront des lignes avec le même `id`.

**d. Effet de `ON DELETE CASCADE`**

Quand la ligne référencée dans la table parente est supprimée, MySQL supprime automatiquement toutes les lignes des tables enfants qui pointent vers elle par clé étrangère. Ça évite les clés étrangères orphelines. C'est adapté quand la ligne enfant n'a aucun sens sans son parent, mais ça devient risqué pour des données qu'on veut garder par ailleurs, comme un historique ou un log, où la relation devrait plutôt utiliser `SET NULL`.

**e. `cp` en `int` plutôt qu'en `varchar`**

Dans la version 1, le code postal est stocké en `int`. Un entier ne garde pas les zéros de tête (01000 devient 1000) et ne peut pas contenir de lettres, ce qui casse les formats de codes postaux étrangers. Ça laisse aussi croire qu'on peut faire des calculs sur cette valeur, ce qui n'a pas de sens pour un code postal. Le risque concret est la perte ou la déformation de données réelles. La version 2 corrige ça en passant à `varchar(5)`.

**f. Rôle des contraintes `KEY`**

Une `KEY` (ou `INDEX`) ne restreint pas les valeurs de la colonne, elle construit une structure de recherche qui accélère les filtres et les jointures sur cette colonne. Dans ce script, chaque colonne de clé étrangère reçoit une `KEY` du même nom, pour que rechercher ou joindre sur cette colonne n'oblige pas MySQL à parcourir toute la table ligne par ligne.

## 4. Incohérences entre le script et le schéma de production

| Emplacement | Script actuel | Schéma cible (annexe 2) | Problème |
|---|---|---|---|
| `logactionutilisateur.temps` | `date` | `datetime` | perd l'heure de l'action |
| `logactionutilisateur.idUtilisateur` | `int` + clé étrangère vers `t_utilisateur` | `char(32)` | type différent, et le schéma ne montre aucun lien tracé vers `t_utilisateur` sur cette table |
| `t_utilisateur.important2` | `NOT NULL` | nullable | champ rendu obligatoire à tort |
| `t_utilisateur.clauses_texte` | `NOT NULL` | nullable | champ rendu obligatoire à tort |
| Lignes 2 et 4 du script | `` `+00:00` `` et `` `NO_AUTO_VALUE_ON_ZERO` `` entre guillemets obliques | chaînes de texte | les guillemets obliques désignent un nom de colonne ou de table en SQL, pas une valeur littérale : le script ne s'exécute pas tel quel |

## 5. Script corrigé

```sql
SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `db_ministage`;
USE `db_ministage`;

-- table logactionutilisateur
DROP TABLE IF EXISTS `logactionutilisateur`;
CREATE TABLE `logactionutilisateur`(
	`id` int NOT NULL AUTO_INCREMENT,
	`action` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`temps` datetime NOT NULL,
	`idUtilisateur` char(32) NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
-- idUtilisateur reste un identifiant indépendant de t_utilisateur, sans clé
-- étrangère : le journal doit survivre à la suppression du compte concerné.

-- table t_academie
DROP TABLE IF EXISTS `t_academie`;
CREATE TABLE `t_academie`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_etablissement
DROP TABLE IF EXISTS `t_etablissement`;
CREATE TABLE `t_etablissement`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nom_court` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`idtype` int NULL,
	`idacademie` int NULL,
	`adresse` varchar(150) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`ville` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`cp` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`mailetab` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`RNE` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`logo` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`cachet` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`tel` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	PRIMARY KEY (`id`),
	KEY `idtype` (`idtype`),
	KEY `idacademie` (`idacademie`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_fonction
DROP TABLE IF EXISTS `t_fonction`;
CREATE TABLE `t_fonction`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_formation
DROP TABLE IF EXISTS `t_formation`;
CREATE TABLE `t_formation`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idtype` int NOT NULL,
	`nom` varchar(250) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idtype` (`idtype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_formationfavorite
DROP TABLE IF EXISTS `t_formationfavorite`;
CREATE TABLE `t_formationfavorite`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idformation` int NOT NULL,
	`idutilisateur` int NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idformation` (`idformation`),
	KEY `idutilisateur` (`idutilisateur`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_ministage
DROP TABLE IF EXISTS `t_ministage`;
CREATE TABLE `t_ministage`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idOffrant` int NOT NULL,
	`idformation` int NOT NULL,
	`civilite` varchar(4) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nomProf` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`date` date NOT NULL,
	`hdebut` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`hfin` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nbplace` int NOT NULL,
	`nbplacereste` int NOT NULL,
	`lieu` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idOffrant` (`idOffrant`),
	KEY `idformation` (`idformation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_profil
DROP TABLE IF EXISTS `t_profil`;
CREATE TABLE `t_profil`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_typeetab
DROP TABLE IF EXISTS `t_typeetab`;
CREATE TABLE `t_typeetab`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nomcourt` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_typeformation
DROP TABLE IF EXISTS `t_typeformation`;
CREATE TABLE `t_typeformation`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nomcourt` varchar(13) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_utilisateur
DROP TABLE IF EXISTS `t_utilisateur`;
CREATE TABLE `t_utilisateur`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idprofil` int NOT NULL,
	`idfonction` int NULL,
	`id_etablissement` int NULL,
	`identifiant` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`mdp` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`nom` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`prenom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`mail` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`tel` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`important` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`important2` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`clauses_texte` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`rattacher` int NULL,
	PRIMARY KEY (`id`),
	KEY `idprofil` (`idprofil`),
	KEY `idfonction` (`idfonction`),
	KEY `id_etablissement` (`id_etablissement`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- table t_reservation
DROP TABLE IF EXISTS `t_reservation`;
CREATE TABLE `t_reservation`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idmini` int NOT NULL,
	`idReservant` int NOT NULL,
	`idEtabOrigine` int NULL,
	`nom` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`prenom` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`confirmation` tinyint(1) NOT NULL,
	`rappel` smallint NOT NULL,
	`absence` smallint NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idmini` (`idmini`),
	KEY `idReservant` (`idReservant`),
	KEY `idEtabOrigine` (`idEtabOrigine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- contraintes t_etablissement
ALTER TABLE `t_etablissement`
ADD CONSTRAINT `FK_EtablissementToTypeEtab` FOREIGN KEY (`idtype`) REFERENCES `t_typeetab` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_EtablissementToAcademie` FOREIGN KEY (`idacademie`) REFERENCES `t_academie` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- contraintes t_ministage
ALTER TABLE `t_ministage`
ADD CONSTRAINT `FK_MinistageToUtilisateur` FOREIGN KEY (`idOffrant`) REFERENCES `t_utilisateur` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_MinistageToFormation` FOREIGN KEY (`idformation`) REFERENCES `t_formation` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- contraintes t_reservation
ALTER TABLE `t_reservation`
ADD CONSTRAINT `FK_ReservationToMinistage` FOREIGN KEY (`idmini`) REFERENCES `t_ministage` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_ReservationToUtilisateur` FOREIGN KEY (`idReservant`) REFERENCES `t_utilisateur` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_ReservationToEtab` FOREIGN KEY (`idEtabOrigine`) REFERENCES `t_etablissement` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
-- SET NULL au lieu de CASCADE : la réservation reste, seul le lien vers
-- l'établissement d'origine disparaît si celui-ci est supprimé.

-- contraintes t_formation
ALTER TABLE `t_formation`
ADD CONSTRAINT `FK_FormationToTypeFormation` FOREIGN KEY (`idtype`) REFERENCES `t_typeformation` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- contraintes t_formationfavorite
ALTER TABLE `t_formationfavorite`
ADD CONSTRAINT `FK_FormationfavToFormation` FOREIGN KEY (`idformation`) REFERENCES `t_formation` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_FormationfavToUtilisateur` FOREIGN KEY (`idutilisateur`) REFERENCES `t_utilisateur` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- contraintes t_utilisateur
ALTER TABLE `t_utilisateur`
ADD CONSTRAINT `FK_UtilisateurToFonction` FOREIGN KEY (`idfonction`) REFERENCES `t_fonction` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_UtilisateurToProfil` FOREIGN KEY (`idprofil`) REFERENCES `t_profil` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_UtilisateurToEtablissement` FOREIGN KEY (`id_etablissement`) REFERENCES `t_etablissement` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- contraintes logactionutilisateur : aucune, voir remarque plus haut
```

## 6. Jeu de données de test

Les insertions respectent l'ordre des dépendances : les tables sans clé étrangère d'abord, puis celles qui les référencent.

```sql
INSERT INTO `t_academie` (`nom`) VALUES ('Nantes');

INSERT INTO `t_typeetab` (`nom`, `nomcourt`) VALUES ('Lycée général', 'LYC');

INSERT INTO `t_etablissement` (`nom`, `nom_court`, `idtype`, `idacademie`, `adresse`, `ville`, `cp`, `mailetab`, `tel`)
VALUES ('Lycée Aristide Briand', 'Briand', 1, 1, '2 rue des Écoles', 'Saint-Nazaire', '44600', 'contact@briand.fr', '0240000000');

INSERT INTO `t_profil` (`nom`) VALUES ('Administrateur'), ('Enseignant');

INSERT INTO `t_fonction` (`nom`) VALUES ('Professeur principal');

INSERT INTO `t_typeformation` (`nom`, `nomcourt`) VALUES ('Formation générale', 'GEN');

INSERT INTO `t_formation` (`idtype`, `nom`) VALUES (1, 'Bac Général');

INSERT INTO `t_utilisateur` (`idprofil`, `idfonction`, `id_etablissement`, `identifiant`, `mdp`, `nom`, `prenom`, `mail`, `tel`, `important`)
VALUES (2, 1, 1, 'jdupont', 'hash_du_mot_de_passe', 'Dupont', 'Julie', 'j.dupont@briand.fr', '0600000000', 'Aucune remarque');

INSERT INTO `t_ministage` (`idOffrant`, `idformation`, `civilite`, `nomProf`, `date`, `hdebut`, `hfin`, `nbplace`, `nbplacereste`, `lieu`)
VALUES (1, 1, 'Mme', 'Dupont', '2026-10-15', '09:00', '11:00', 5, 4, 'Salle 12');

INSERT INTO `t_reservation` (`idmini`, `idReservant`, `idEtabOrigine`, `nom`, `prenom`, `confirmation`, `rappel`, `absence`)
VALUES (1, 1, 1, 'Martin', 'Léo', 1, 0, 0);

INSERT INTO `t_formationfavorite` (`idformation`, `idutilisateur`) VALUES (1, 1);

INSERT INTO `logactionutilisateur` (`action`, `temps`, `idUtilisateur`)
VALUES ('connexion', NOW(), 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4');
```

Ce jeu couvre une chaîne complète : un établissement rattaché à une académie, un utilisateur rattaché à cet établissement, un ministage qu'il propose, une réservation sur ce ministage, une formation mise en favori, et une ligne de log. Il permet de vérifier que les clés étrangères se comportent comme prévu, notamment en testant une suppression sur `t_etablissement` pour confirmer que la réservation liée garde son `idEtabOrigine` à `NULL` au lieu de disparaître.
