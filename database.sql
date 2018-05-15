-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               10.2.14-MariaDB - MariaDB Server
-- Server OS:                    Linux
-- HeidiSQL Version:             9.5.0.5196
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Dumping database structure for app
DROP DATABASE IF EXISTS `app`;
CREATE DATABASE IF NOT EXISTS `app` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `app`;

-- Dumping structure for table app.user
DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `login` char(32) NOT NULL COMMENT 'optionally used for auth',
  `email` char(64) DEFAULT NULL COMMENT 'can be used for auth',
  `email_verified` tinyint(4) NOT NULL DEFAULT 0,
  `timezone` tinyint(4) DEFAULT NULL,
  `active` tinyint(4) NOT NULL DEFAULT 1,
  `password` char(64) DEFAULT NULL COMMENT 'bcrypt passsword',
  `last_login_ip` char(15) DEFAULT NULL,
  `registration_ip` char(15) DEFAULT NULL,
  `login_count` int(11) NOT NULL DEFAULT 0,
  `failed_login_count` tinyint(4) NOT NULL DEFAULT 0,
  `suspend_till_date` timestamp NULL DEFAULT NULL COMMENT 'suspend user till date if failed login attempt exceeded norm',
  `create_date` timestamp NULL DEFAULT current_timestamp(),
  `update_date` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `login` (`login`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table app.user_email
DROP TABLE IF EXISTS `user_email`;
CREATE TABLE IF NOT EXISTS `user_email` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `email` varchar(64) NOT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT 0,
  `token` varchar(32) NOT NULL,
  `token_valid_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `create_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `update_date` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `FK_user_email_master` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table app.user_facebook
DROP TABLE IF EXISTS `user_facebook`;
CREATE TABLE IF NOT EXISTS `user_facebook` (
  `user_id` int(10) unsigned NOT NULL,
  `facebook_id` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table app.user_ip
DROP TABLE IF EXISTS `user_ip`;
CREATE TABLE IF NOT EXISTS `user_ip` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `ip` char(15) NOT NULL,
  `insert_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table app.user_password
DROP TABLE IF EXISTS `user_password`;
CREATE TABLE IF NOT EXISTS `user_password` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `token` char(32) NOT NULL,
  `token_valid_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `used` tinyint(3) unsigned NOT NULL,
  `create_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `update_date` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `FK_user_password_master` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table app.user_profile
DROP TABLE IF EXISTS `user_profile`;
CREATE TABLE IF NOT EXISTS `user_profile` (
  `user_id` int(10) unsigned NOT NULL,
  `first_name` varchar(128) DEFAULT NULL,
  `last_name` varchar(128) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `gender` enum('male','female') DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `FK_user_profile_master` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for function app.user_email_token_create
DROP FUNCTION IF EXISTS `user_email_token_create`;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `user_email_token_create`(
	`in_user_id` INT,
	`in_user_email` CHAR(64)
 CHARSET utf8




) RETURNS char(32) CHARSET utf8
    COMMENT 'CREATE AND GET USER EMAIL TOKEN'
BEGIN
		
		DECLARE user_email_token CHAR(32);
		
		SET user_email_token = MD5(UUID());

		INSERT INTO user_email
		SET
		user_email.user_id=in_user_id,
		user_email.email=in_user_email,
		user_email.token=user_email_token,
		user_email.token_valid_date = NOW() + INTERVAL 24 HOUR;
		
		IF ROW_COUNT()>0 THEN
			RETURN user_email_token;		
		END IF;
		
		RETURN "";

END//
DELIMITER ;

-- Dumping structure for function app.user_email_token_verify
DROP FUNCTION IF EXISTS `user_email_token_verify`;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `user_email_token_verify`(
	`in_user_id` INT,
	`in_user_email_token` CHAR(32)


) RETURNS tinyint(4)
    COMMENT 'VERIFY USER EMAIL TOKEN AND UPDATE USER'
BEGIN
	/*
		THIS 
	*/
	UPDATE user_email
	SET user_email.verified=1
	WHERE
	user_email.user_id=in_user_id AND 
	user_email.token=in_user_email_token AND
	user_email.token_valid_date>=NOW();
	IF ROW_COUNT()>0 THEN
		RETURN 1;
	END IF;
	RETURN 0;
END//
DELIMITER ;

-- Dumping structure for trigger app.user_after_insert
DROP TRIGGER IF EXISTS `user_after_insert`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `user_after_insert` AFTER INSERT ON `user` FOR EACH ROW BEGIN

	/* 
		CREATE USER PROFILE
	*/
	INSERT INTO user_profile
	SET
	user_id=NEW.id;
	
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger app.user_after_update
DROP TRIGGER IF EXISTS `user_after_update`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `user_after_update` AFTER UPDATE ON `user` FOR EACH ROW BEGIN

	/*
		LOG LOGIN IP
	*/
	IF NEW.login_count>OLD.login_count AND NEW.last_login_ip IS NOT NULL THEN
		INSERT INTO user_ip
		SET
		user_ip.user_id=NEW.id,
		user_ip.ip=NEW.last_login_ip;
	END IF;

END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger app.user_before_update
DROP TRIGGER IF EXISTS `user_before_update`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `user_before_update` BEFORE UPDATE ON `user` FOR EACH ROW BEGIN

	/*
		IF EMAIL CHANGED SET email_verified FIELD TO 0
	*/
	IF NEW.email IS NOT NULL AND (OLD.email IS NULL OR NEW.email!=OLD.email) THEN
		SET NEW.email_verified=0;
	END IF;

END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger app.user_email_after_update
DROP TRIGGER IF EXISTS `user_email_after_update`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
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
		
		-- REMOVE ALL UNVERIFIED USER TOKENS WITH SAME EMAIL
		DELETE FROM user_email
		WHERE 
		user_email.user_id=NEW.user_id AND
		user_email.email=NEW.email AND
		user_email.verified=0;

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
