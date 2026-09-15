SET NAMES utf8;
SET time_zone = `+00:00`;
SET foreign_key_checks = 0;
SET sql_mode = `NO_AUTO_VALUE_ON_ZERO`;
SET NAMES utf8mb4;
-- création & sélection de la base de donnée, modifiable si existe déjà
CREATE DATABASE `db_ministage`; 
USE `db_ministage`;
--
--
-- creation table logactionutilisateur
DROP TABLE IF EXISTS `logactionutilisateur`;
CREATE TABLE `logactionutilisateur`(
	`id` int NOT NULL AUTO_INCREMENT,
	`action` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`temps` date NOT NULL,
	`idUtilisateur` int NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idUtilisateur` (`idUtilisateur`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_academie
DROP TABLE IF EXISTS `t_academie`;
CREATE TABLE `t_academie`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_etablissement
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
	KEY `idtype`(`idtype`),
	KEY `idacademie` (`idacademie`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_fonction
DROP  TABLE IF EXISTS `t_fonction`;
CREATE TABLE `t_fonction`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_formation
DROP  TABLE IF EXISTS `t_formation`;
CREATE TABLE `t_formation`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idtype` int NOT NULL,
	`nom` varchar(250) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idtype` (`idtype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_formationfavorite
DROP  TABLE IF EXISTS `t_formationfavorite`;
CREATE TABLE `t_formationfavorite`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idformation` int NOT NULL,
	`idutilisateur` int NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idformation` (`idformation`),
	KEY `idutilisateur` (`idutilisateur`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_ministage
DROP TABLE IF EXISTS `t_ministage`;
CREATE TABLE `t_ministage`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idOffrant` int NOT NULL,
	`idformation` int NOT NULL,
	`civilite` varchar(4) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nomProf` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`date`date NOT NULL,
	`hfin` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`hdebut` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nbplace` int NOT NULL,
	`nbplacereste` int NOT NULL,
	`lieu` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idOffrant` (`idOffrant`),
	KEY `idformation` (`idformation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_profil
DROP  TABLE IF EXISTS `t_profil`;
CREATE TABLE `t_profil`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_typeetab
DROP  TABLE IF EXISTS `t_typeetab`;
CREATE TABLE `t_typeetab`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nomcourt` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_typeformation
DROP  TABLE IF EXISTS `t_typeformation`;
CREATE TABLE `t_typeformation`(
	`id` int NOT NULL AUTO_INCREMENT,
	`nom` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`nomcourt` varchar(13) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_utilisateur
DROP  TABLE IF EXISTS `t_utilisateur`;
CREATE TABLE `t_utilisateur`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idprofil` int NOT NULL ,
	`idfonction` int NULL ,
	`id_etablissement` int NULL ,
	`identifiant` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`mdp` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`nom` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`prenom` varchar(25) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`mail` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`tel` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`important` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
	`important2` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`clauses_texte` text CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`rattacher` int NULL ,
	PRIMARY KEY (`id`),
	KEY `idprofil` (`idprofil`),
	KEY `idfonction` (`idfonction`),
	KEY `id_etablissement` (`id_etablissement`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- creation table t_reservation
DROP  TABLE IF EXISTS `t_reservation`;
CREATE TABLE `t_reservation`(
	`id` int NOT NULL AUTO_INCREMENT,
	`idmini` int NOT NULL ,
	`idReservant` int NOT NULL ,
	`idEtabOrigine` int NULL ,
	`nom` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`prenom` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NULL,
	`confirmation` tinyint(1) NOT NULL,
	`rappel` smallint NOT NULL,
	`absence` smallint NOT NULL,
	PRIMARY KEY (`id`),
	KEY `idmini` (`idmini`),
	KEY `idReservant` (`idReservant`),
	KEY `idEtabOrigine` (`idEtabOrigine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
--
-- toute mention de t_utilisateur & idprofil pourrait potentiellement être remplacé par t_profil & id , pas sûr
--
-- constraintes t_etablissement
ALTER TABLE `t_etablissement`
ADD CONSTRAINT `FK_EtablissementToTypeEtab` FOREIGN KEY (`idtype`) REFERENCES `t_typeetab` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_EtablissementToAcademie` FOREIGN KEY (`idacademie`) REFERENCES `t_academie` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
--
-- constraintes t_ministage
ALTER TABLE `t_ministage`
ADD CONSTRAINT `FK_MinistageToUtilisateur` FOREIGN KEY (`idOffrant`) REFERENCES `t_utilisateur` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_MinistageToFormation` FOREIGN KEY (`idformation`) REFERENCES `t_formation` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
--
-- constraintes t_reservation
ALTER TABLE `t_reservation`
ADD CONSTRAINT `FK_ReservationToMinistage` FOREIGN KEY (`idmini`) REFERENCES `t_ministage` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_ReservationToUtilisateur` FOREIGN KEY (`idReservant`) REFERENCES `t_utilisateur` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_ReservationToEtab` FOREIGN KEY (`idEtabOrigine`) REFERENCES `t_etablissement` (`id`) ON DELETE CASCADE ON UPDATE CASCADE; -- inutile
--
-- constraintes t_formation
ALTER TABLE `t_formation`
ADD CONSTRAINT `FK_FormationToTypeFormation` FOREIGN KEY (`idtype`) REFERENCES `t_typeformation` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
--
-- constraintes t_formationfavorite
ALTER TABLE `t_formationfavorite`
ADD CONSTRAINT `FK_FormationfavToFormation` FOREIGN KEY (`idformation`) REFERENCES `t_formation` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_FormationfavToUtilisateur` FOREIGN KEY (`idutilisateur`) REFERENCES `t_utilisateur` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
--
-- constraintes t_utilisateur
ALTER TABLE `t_utilisateur`
ADD CONSTRAINT `FK_UtilisateurToFonction` FOREIGN KEY (`idfonction`) REFERENCES `t_fonction` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_UtilisateurToProfil` FOREIGN KEY (`idprofil`) REFERENCES `t_profil` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `FK_UtilisateurToEtablissement` FOREIGN KEY (`id_etablissement`) REFERENCES `t_etablissement` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
--
-- constraintes logactionutilisateur
ALTER TABLE `logactionutilisateur`
ADD CONSTRAINT `Fk_LogActionToUtilisateur` FOREIGN KEY (`idUtilisateur`) REFERENCES `t_utilisateur` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
