-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               5.6.36 - MySQL Community Server (GPL)
-- Server OS:                    Win64
-- HeidiSQL Version:             9.4.0.5125
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Dumping database structure for core
DROP DATABASE IF EXISTS `core`;
CREATE DATABASE IF NOT EXISTS `core` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `core`;

-- Dumping structure for table core.user
DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `login` char(32) DEFAULT NULL COMMENT 'optionally used for auth',
  `email` char(64) DEFAULT NULL COMMENT 'can be used for auth',
  `email_verified` tinyint(4) DEFAULT '0' COMMENT '0-not verified 1-verified',
  `last_verified_email` char(64) DEFAULT NULL COMMENT 'users last verified email',
  `timezone` tinyint(4) DEFAULT NULL,
  `active` tinyint(4) DEFAULT '1' COMMENT 'disable user manually',
  `password` char(64) DEFAULT NULL COMMENT 'bcrypt passsword',
  `last_login_ip` char(15) DEFAULT NULL,
  `registration_ip` char(15) DEFAULT NULL,
  `login_count` int(11) NOT NULL DEFAULT '0',
  `failed_login_count` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'failed login attempt count',
  `suspend_till_date` timestamp NULL DEFAULT NULL COMMENT 'suspend user till date if failed login attempt exceeded norm',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `login` (`login`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table core.user_email
DROP TABLE IF EXISTS `user_email`;
CREATE TABLE IF NOT EXISTS `user_email` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `email` varchar(64) NOT NULL,
  `token` varchar(32) NOT NULL,
  `verified` tinyint(4) NOT NULL,
  `create_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `FK_user_email_master` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table core.user_facebook
DROP TABLE IF EXISTS `user_facebook`;
CREATE TABLE IF NOT EXISTS `user_facebook` (
  `user_id` int(10) unsigned NOT NULL,
  `facebook_id` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table core.user_ip
DROP TABLE IF EXISTS `user_ip`;
CREATE TABLE IF NOT EXISTS `user_ip` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `ip` char(15) NOT NULL,
  `insert_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table core.user_password
DROP TABLE IF EXISTS `user_password`;
CREATE TABLE IF NOT EXISTS `user_password` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `token` char(32) NOT NULL,
  `used` tinyint(3) unsigned NOT NULL,
  `create_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `FK_user_password_master` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table core.user_profile
DROP TABLE IF EXISTS `user_profile`;
CREATE TABLE IF NOT EXISTS `user_profile` (
  `user_id` int(10) unsigned NOT NULL,
  `name_first` varchar(128) DEFAULT NULL,
  `name_last` varchar(128) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `gender` enum('male','female') DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `FK_user_profile_master` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for trigger core.user_after_insert
DROP TRIGGER IF EXISTS `user_after_insert`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `user_after_insert` AFTER INSERT ON `user` FOR EACH ROW BEGIN
	/* CREATE PROFILE */
	INSERT INTO user_profile
	SET
	user_id=NEW.id;
	/*
		CREATE EMAIL VERIFY TOKEN IF EMAIL IS PRESENT FOR NEW USER
	*/
	IF NEW.email Is NOT NULL THEN
		INSERT INTO user_email
		SET
		user_email.user_id=NEW.id,
		user_email.email=NEW.email,
		user_email.token=MD5(UUID());
	END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger core.user_after_update
DROP TRIGGER IF EXISTS `user_after_update`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `user_after_update` AFTER UPDATE ON `user` FOR EACH ROW BEGIN
	/*
		CREATE EMAIL TOKEN IF EMAIL CHAINGED
	*/
	IF NEW.email Is NOT NULL AND (OLD.email IS NULL OR OLD.email!=NEW.email) THEN
		INSERT INTO user_email
		SET
		user_email.user_id=NEW.id,
		user_email.email=NEW.email,
		user_email.token=MD5(UUID());
	END IF;

	IF NEW.login_count>OLD.login_count AND NEW.last_login_ip IS NOT NULL THEN
		INSERT INTO user_ip
		SET
		user_ip.user_id=NEW.id,
		user_ip.ip=NEW.last_login_ip;
	END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger core.user_before_update
DROP TRIGGER IF EXISTS `user_before_update`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `user_before_update` BEFORE UPDATE ON `user` FOR EACH ROW BEGIN
	/*
		1. SAVE LAST VERIFIED EMAIL
		2. RESET EMAIL VERIFIED FLAG
	*/
	IF NEW.email IS NOT NULL AND OLD.email IS NOT NULL AND NEW.email!=OLD.email THEN
		IF OLD.email_verified=1 THEN
			SET NEW.last_verified_email=OLD.email;
		END IF;
		SET NEW.email_verified=0;
	END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger core.user_email_after_update
DROP TRIGGER IF EXISTS `user_email_after_update`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `user_email_after_update` AFTER UPDATE ON `user_email` FOR EACH ROW BEGIN
	/*
		IF EMAIL VERIFIED UPDATE user.email_verified FIELD
	*/
	IF NEW.verified=1 AND
		OLD.verified=0 AND
		NEW.user_id=OLD.user_id AND
		NEW.email=OLD.email
		THEN

		UPDATE user
		SET
		user.email_verified=1
		WHERE
		user.id=NEW.user_id AND
		user.email=NEW.email;

	END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
