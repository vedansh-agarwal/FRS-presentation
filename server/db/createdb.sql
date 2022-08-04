/* Creating database */
DROP SCHEMA IF EXISTS `FRS-test`;
CREATE SCHEMA `FRS-test`;
USE `FRS-test`;

/* Creating admin table */
CREATE TABLE `FRS-test`.`admin` (
  `username` VARCHAR(20) NOT NULL,
  `password` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`username`));
  
/* Creating admin logs table */
CREATE TABLE `FRS-test`.`admin_log` (
  `change_id` INT NOT NULL AUTO_INCREMENT,
  `change_by` VARCHAR(20) NOT NULL,
  `change_on` VARCHAR(36) NOT NULL,
  `change_type` VARCHAR(6) NOT NULL,
  `change_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`change_id`));

/* Creating user table */
CREATE TABLE `FRS-test`.`user` (
  `user_id` VARCHAR(36) NOT NULL,
  `base_img` VARCHAR(100) NOT NULL,
  `img_ext` VARCHAR(10) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `mob_no` VARCHAR(20) NOT NULL UNIQUE,
  `gender` VARCHAR(1) NOT NULL,
  `roll_no` VARCHAR(45) NOT NULL,
  `class` VARCHAR(45) NOT NULL,
  `captured_count` INT NOT NULL DEFAULT 0,
  `date_created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `last_modified_by` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`user_id`));
  
/* Creating user change log table */
CREATE TABLE `FRS-test`.`user_change_log` (
  `change_id` INT NOT NULL AUTO_INCREMENT,
  `change_by` VARCHAR(45) NOT NULL,
  `change_type` VARCHAR(6) NOT NULL,
  `change_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `user_id` VARCHAR(45) NOT NULL,
  `base_img` VARCHAR(45) NOT NULL,
  `img_ext` VARCHAR(45) NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `mob_no` VARCHAR(45) NOT NULL,
  `gender` VARCHAR(45) NOT NULL,
  `roll_no` VARCHAR(45) NOT NULL,
  `class` VARCHAR(45) NOT NULL,
  `date_created` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`change_id`));

/* Creating user capture log table */
CREATE TABLE `FRS-test`.`user_capture_log` (
  `capture_id` INT NOT NULL AUTO_INCREMENT,
  `img_name` VARCHAR(50) NOT NULL,
  `recognition_status` VARCHAR(5) NOT NULL,
  `user_id` VARCHAR(36) NULL,
  `in/out` VARCHAR(3) NOT NULL,
  `date_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`capture_id`));

/* Trigger for creating log on insert user */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `create_log_on_insert` AFTER INSERT ON `user` FOR EACH ROW BEGIN
	INSERT INTO `admin_log` (`change_by`, `change_on`, `change_type`)
    VALUE (NEW.`last_modified_by`, NEW.`user_id`, "INSERT");
    INSERT INTO `user_change_log` (`change_by`, `change_type`, `user_id`, `base_img`, `img_ext`, `name`, `mob_no`, `gender`, `roll_no`, `class`, `date_created`) 
    VALUE (NEW.`last_modified_by`, "INSERT", NEW.`user_id`, NEW.`base_img`, NEW.`img_ext`, NEW.`name`, NEW.`mob_no`, NEW.`gender`, NEW.`roll_no`, NEW.`class`, NEW.`date_created`);
END$$
DELIMITER ;

/* Trigger for creating log on update user */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `create_log_on_update` AFTER UPDATE ON `user` FOR EACH ROW BEGIN
    IF (NEW.`base_img` != OLD.`base_img` OR NEW.`name` != OLD.`name` OR NEW.`mob_no` != OLD.`mob_no` OR NEW.`gender` != OLD.`gender` OR NEW.`roll_no` != OLD.`roll_no` OR NEW.`class` != OLD.`class`) THEN
        INSERT INTO `admin_log` (`change_by`, `change_on`, `change_type`)
		VALUE (NEW.`last_modified_by`, NEW.`user_id`, "UPDATE");
        INSERT INTO `user_change_log` (`change_by`, `change_type`, `user_id`, `base_img`, `img_ext`, `name`, `mob_no`, `gender`, `roll_no`, `class`, `date_created`) 
		VALUE (NEW.`last_modified_by`, "UPDATE", NEW.`user_id`, NEW.`base_img`, NEW.`img_ext`, NEW.`name`, NEW.`mob_no`, NEW.`gender`, NEW.`roll_no`, NEW.`class`, NEW.`date_created`);
    END IF;
END$$
DELIMITER ;

/* Trigger for creating log on delete user */
DELIMITER $$
CREATE DEFINER = CURRENT_USER TRIGGER `FRS-test`.`create_log_on_delete` AFTER DELETE ON `user` FOR EACH ROW
BEGIN
	INSERT INTO `admin_log` (`change_by`, `change_on`, `change_type`)
	VALUE (OLD.`last_modified_by`, OLD.`user_id`, "DELETE");
	INSERT INTO `user_change_log` (`change_by`, `change_type`, `user_id`, `base_img`, `img_ext`, `name`, `mob_no`, `gender`, `roll_no`, `class`, `date_created`) 
	VALUE (OLD.`last_modified_by`, "DELETE", OLD.`user_id`, OLD.`base_img`, OLD.`img_ext`, OLD.`name`, OLD.`mob_no`, OLD.`gender`, OLD.`roll_no`, OLD.`class`, OLD.`date_created`);
END$$
DELIMITER ;

/* Get user view */
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `FRS-test`.`get_user` AS
    SELECT 
		`FRS-test`.`user`.`user_id` AS `user_id`,
        `FRS-test`.`user`.`base_img` AS `base_img`,
        `FRS-test`.`user`.`name` AS `name`,
        `FRS-test`.`user`.`mob_no` AS `mob_no`,
        `FRS-test`.`user`.`gender` AS `gender`,
        `FRS-test`.`user`.`roll_no` AS `city`,
        `FRS-test`.`user`.`class` AS `department`,
        `FRS-test`.`user`.`date_created` AS `date_created`
    FROM
        `FRS-test`.`user`;

/* Delete user procedure */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_user`(IN usr_id VARCHAR(36), IN last_modifier VARCHAR(20))
BEGIN
	UPDATE `user` SET `last_modified_by` = last_modifier WHERE `user_id` = usr_id;
	SELECT `base_img` FROM `user` WHERE `user_id` = usr_id;
    DELETE FROM `user` WHERE `user_id` = usr_id;
END$$
DELIMITER ;

/* Increment capture_count procedure */
DELIMITER $$
CREATE PROCEDURE `record_user_capture` (IN img VARCHAR(50), IN usr_id VARCHAR(36), IN in_sts VARCHAR(3))
BEGIN
	IF (usr_id != "unrecognized") THEN
		UPDATE `user` SET `captured_count` = `captured_count`+1 WHERE `user_id` = usr_id;
        SET @cap_cnt = (SELECT `captured_count` FROM `user` WHERE `user_id` = usr_id);
        SET @user_name = (SELECT `name` FROM `user` WHERE `user_id` = usr_id);
        SET @city = (SELECT `roll_no` FROM `user` WHERE `user_id` = usr_id);
        SET @department = (SELECT `class` FROM `user` WHERE `user_id` = usr_id);
        SET @img_name = CONCAT(@cap_cnt, "==", img);
        INSERT INTO `user_capture_log` (`img_name`, `recognition_status`, `user_id`, `in/out`) 
        VALUES (@img_name, "TRUE", usr_id, in_sts);
        SELECT @img_name, @user_name, @city, @department;
    END IF;
    IF (usr_id = "unrecognized") THEN
		INSERT INTO `user_capture_log` (`img_name`, `recognition_status`, `in/out`) 
        VALUES (img, "FALSE", in_sts);
    END IF;
END$$
DELIMITER ;

/* Inserting dummy admin values */
INSERT INTO `FRS-test`.`admin` (`username`, `password`) VALUES ('vedansh', 'password');
