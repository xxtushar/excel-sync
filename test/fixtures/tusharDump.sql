CREATE DATABASE  IF NOT EXISTS `avyra` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `avyra`;
-- MySQL dump 10.13  Distrib 8.0.40, for Win64 (x86_64)
--
-- Host: localhost    Database: avyra
-- ------------------------------------------------------
-- Server version	9.1.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `dy_invoices`
--

DROP TABLE IF EXISTS `dy_invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_invoices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `inv_id` varchar(20) NOT NULL,
  `booking_id` int NOT NULL,
  `inv_amount` decimal(10,2) NOT NULL,
  `inv_cgst` decimal(10,2) NOT NULL,
  `inv_sgst` decimal(10,2) NOT NULL,
  `inv_total` decimal(10,2) NOT NULL,
  `inv_datetime` datetime NOT NULL,
  `inv_duedate` datetime NOT NULL,
  `inv_from_date` datetime NOT NULL,
  `inv_to_date` datetime NOT NULL,
  `inv_generated_by` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Inv_Id` (`inv_id`),
  KEY `dy_invoice-fk_booking_ID_idx` (`booking_id`),
  KEY `fk_booking_id_idx` (`booking_id`),
  KEY `dy_invoice-fk_user_id_idx` (`inv_generated_by`),
  CONSTRAINT `dy_invoice-fk_booking_id` FOREIGN KEY (`booking_id`) REFERENCES `dy_pg_bookings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `dy_invoice-fk_user_id` FOREIGN KEY (`inv_generated_by`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=532 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_invoices`
--

LOCK TABLES `dy_invoices` WRITE;
/*!40000 ALTER TABLE `dy_invoices` DISABLE KEYS */;
INSERT INTO `dy_invoices` VALUES (275,'INV-20260825-000566',566,10400.00,0.00,0.00,10400.00,'2026-08-25 16:55:13','2026-08-30 16:55:13','2026-08-01 00:00:00','2026-08-31 00:00:00',541),(530,'INV-20260825-000567',829,10000.00,0.00,0.00,10000.00,'2026-08-25 16:55:13','2026-08-30 16:55:13','2026-08-01 00:00:00','2026-08-31 00:00:00',779),(531,'INV-20260825-000568',824,10000.00,0.00,0.00,10000.00,'2026-08-25 16:55:13','2026-08-30 16:55:13','2026-08-01 00:00:00','2026-08-31 00:00:00',779);
/*!40000 ALTER TABLE `dy_invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_payments_info`
--

DROP TABLE IF EXISTS `dy_payments_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_payments_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `payment_id` varchar(35) NOT NULL,
  `inv_id` int NOT NULL,
  `payment_mode_id` int NOT NULL,
  `razor_pay_order_id` varchar(50) DEFAULT NULL,
  `razor_pay_payment_datetime` datetime DEFAULT NULL,
  `payment_status` int DEFAULT NULL,
  `cash_payment` decimal(10,2) DEFAULT NULL,
  `actual_payment` decimal(10,2) DEFAULT NULL,
  `balance` decimal(10,2) DEFAULT NULL,
  `payment_date` datetime DEFAULT NULL,
  `remarks` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Payment_Id` (`payment_id`),
  KEY `dy_payments_info-fk_inv_id` (`inv_id`),
  KEY `dy_payment_info_fk_payment_mode_idx` (`payment_mode_id`),
  KEY `dy_payments_info_fk_pay_status_idx` (`payment_status`),
  CONSTRAINT `dy_payment_info_fk_payment_mode` FOREIGN KEY (`payment_mode_id`) REFERENCES `st_pg_pay_mode` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `dy_payments_info-fk_inv_id` FOREIGN KEY (`inv_id`) REFERENCES `dy_invoices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `dy_payments_info_fk_pay_status` FOREIGN KEY (`payment_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1034 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_payments_info`
--

LOCK TABLES `dy_payments_info` WRITE;
/*!40000 ALTER TABLE `dy_payments_info` DISABLE KEYS */;
INSERT INTO `dy_payments_info` VALUES (777,'PAY-20260825-000275',275,2,'ORDER-20260825-000275','2026-08-25 16:56:05',27,5400.00,5000.00,5400.00,'2026-08-25 16:56:05','Partial payment - Rs.5000 of Rs.10400'),(1033,'PYM-18092026-001',530,2,NULL,'2026-09-18 15:51:25',19,0.00,10000.00,NULL,'2026-09-18 15:51:25',NULL);
/*!40000 ALTER TABLE `dy_payments_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_alerts`
--

DROP TABLE IF EXISTS `dy_pg_alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_alerts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `alert_cat` int NOT NULL,
  `alert_receiver_role` int NOT NULL,
  `alert_receiver` int DEFAULT NULL,
  `alert_title` varchar(45) NOT NULL,
  `alert_description` varchar(150) DEFAULT NULL,
  `alert_priority` int NOT NULL,
  `pg_id` int NOT NULL,
  `alert_status` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_alert_new_category_idx` (`alert_cat`),
  KEY `fk_alert_new_pg_idx` (`pg_id`),
  KEY `fk_alert_new_priority_idx` (`alert_priority`),
  KEY `fk_alert_new_receiver_idx` (`alert_receiver`),
  KEY `fk_alert_new_role_idx` (`alert_receiver_role`),
  KEY `fk_alert_new_status_idx` (`alert_status`),
  CONSTRAINT `fk_alert_new_category` FOREIGN KEY (`alert_cat`) REFERENCES `st_pg_alrt_cat` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alert_new_pg` FOREIGN KEY (`pg_id`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alert_new_priority` FOREIGN KEY (`alert_priority`) REFERENCES `st_pg_alert_priority` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alert_new_receiver` FOREIGN KEY (`alert_receiver`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alert_new_role` FOREIGN KEY (`alert_receiver_role`) REFERENCES `st_pg_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alert_new_status` FOREIGN KEY (`alert_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=145 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_alerts`
--

LOCK TABLES `dy_pg_alerts` WRITE;
/*!40000 ALTER TABLE `dy_pg_alerts` DISABLE KEYS */;
INSERT INTO `dy_pg_alerts` VALUES (2,1,2,10,'Monthly Rent Payment Due','Monthly rent payment for the current billing cycle is due within three days.',2,10,1),(3,2,3,10,'Maintenance Request Assigned','A new maintenance request has been assigned to you for immediate review.',2,10,1),(4,2,3,10,'Maintenance Request Assigned','A new maintenance request has been assigned to you for immediate review.',2,10,1),(6,2,2,531,'Demo Alert 10 - Green Valley Residency','Demo alert 10 generated for Green Valley Residency',1,9,1),(7,1,2,530,'Demo Alert 9 - Green Valley Residency','Demo alert 9 generated for Green Valley Residency',3,9,1),(8,8,2,529,'Demo Alert 8 - Green Valley Residency','Demo alert 8 generated for Green Valley Residency',2,9,1),(9,7,2,528,'Demo Alert 7 - Green Valley Residency','Demo alert 7 generated for Green Valley Residency',1,9,1),(10,6,2,527,'Demo Alert 6 - Green Valley Residency','Demo alert 6 generated for Green Valley Residency',3,9,1),(11,5,2,526,'Demo Alert 5 - Green Valley Residency','Demo alert 5 generated for Green Valley Residency',2,9,1),(12,4,2,525,'Demo Alert 4 - Green Valley Residency','Demo alert 4 generated for Green Valley Residency',1,9,1),(13,3,2,524,'Demo Alert 3 - Green Valley Residency','Demo alert 3 generated for Green Valley Residency',3,9,1),(14,2,2,12,'Demo Alert 2 - Green Valley Residency','Demo alert 2 generated for Green Valley Residency',2,9,1),(15,1,2,10,'Demo Alert 1 - Green Valley Residency','Demo alert 1 generated for Green Valley Residency',1,9,1),(16,2,2,541,'Demo Alert 10 - Urban Nest Premium PG','Demo alert 10 generated for Urban Nest Premium PG',1,10,1),(17,1,2,540,'Demo Alert 9 - Urban Nest Premium PG','Demo alert 9 generated for Urban Nest Premium PG',3,10,1),(18,8,2,539,'Demo Alert 8 - Urban Nest Premium PG','Demo alert 8 generated for Urban Nest Premium PG',2,10,1),(19,7,2,538,'Demo Alert 7 - Urban Nest Premium PG','Demo alert 7 generated for Urban Nest Premium PG',1,10,1),(20,6,2,537,'Demo Alert 6 - Urban Nest Premium PG','Demo alert 6 generated for Urban Nest Premium PG',3,10,1),(21,5,2,536,'Demo Alert 5 - Urban Nest Premium PG','Demo alert 5 generated for Urban Nest Premium PG',2,10,1),(22,4,2,535,'Demo Alert 4 - Urban Nest Premium PG','Demo alert 4 generated for Urban Nest Premium PG',1,10,1),(23,3,2,534,'Demo Alert 3 - Urban Nest Premium PG','Demo alert 3 generated for Urban Nest Premium PG',3,10,1),(24,2,2,533,'Demo Alert 2 - Urban Nest Premium PG','Demo alert 2 generated for Urban Nest Premium PG',2,10,1),(25,1,2,532,'Demo Alert 1 - Urban Nest Premium PG','Demo alert 1 generated for Urban Nest Premium PG',1,10,1),(26,2,2,551,'Demo Alert 10 - Urban Nest Premium','Demo alert 10 generated for Urban Nest Premium',1,13,1),(27,1,2,550,'Demo Alert 9 - Urban Nest Premium','Demo alert 9 generated for Urban Nest Premium',3,13,1),(28,8,2,549,'Demo Alert 8 - Urban Nest Premium','Demo alert 8 generated for Urban Nest Premium',2,13,1),(29,7,2,548,'Demo Alert 7 - Urban Nest Premium','Demo alert 7 generated for Urban Nest Premium',1,13,1),(30,6,2,547,'Demo Alert 6 - Urban Nest Premium','Demo alert 6 generated for Urban Nest Premium',3,13,1),(31,5,2,546,'Demo Alert 5 - Urban Nest Premium','Demo alert 5 generated for Urban Nest Premium',2,13,1),(32,4,2,545,'Demo Alert 4 - Urban Nest Premium','Demo alert 4 generated for Urban Nest Premium',1,13,1),(33,3,2,544,'Demo Alert 3 - Urban Nest Premium','Demo alert 3 generated for Urban Nest Premium',3,13,1),(34,2,2,543,'Demo Alert 2 - Urban Nest Premium','Demo alert 2 generated for Urban Nest Premium',2,13,1),(35,1,2,542,'Demo Alert 1 - Urban Nest Premium','Demo alert 1 generated for Urban Nest Premium',1,13,1),(36,2,2,561,'Demo Alert 10 - Urban Nest Elite','Demo alert 10 generated for Urban Nest Elite',1,14,1),(37,1,2,560,'Demo Alert 9 - Urban Nest Elite','Demo alert 9 generated for Urban Nest Elite',3,14,1),(38,8,2,559,'Demo Alert 8 - Urban Nest Elite','Demo alert 8 generated for Urban Nest Elite',2,14,1),(39,7,2,558,'Demo Alert 7 - Urban Nest Elite','Demo alert 7 generated for Urban Nest Elite',1,14,1),(40,6,2,557,'Demo Alert 6 - Urban Nest Elite','Demo alert 6 generated for Urban Nest Elite',3,14,1),(41,5,2,556,'Demo Alert 5 - Urban Nest Elite','Demo alert 5 generated for Urban Nest Elite',2,14,1),(42,4,2,555,'Demo Alert 4 - Urban Nest Elite','Demo alert 4 generated for Urban Nest Elite',1,14,1),(43,3,2,554,'Demo Alert 3 - Urban Nest Elite','Demo alert 3 generated for Urban Nest Elite',3,14,1),(44,2,2,553,'Demo Alert 2 - Urban Nest Elite','Demo alert 2 generated for Urban Nest Elite',2,14,1),(45,1,2,552,'Demo Alert 1 - Urban Nest Elite','Demo alert 1 generated for Urban Nest Elite',1,14,1),(46,2,2,571,'Demo Alert 10 - Urban Nest Comfort','Demo alert 10 generated for Urban Nest Comfort',1,15,1),(47,1,2,570,'Demo Alert 9 - Urban Nest Comfort','Demo alert 9 generated for Urban Nest Comfort',3,15,1),(48,8,2,569,'Demo Alert 8 - Urban Nest Comfort','Demo alert 8 generated for Urban Nest Comfort',2,15,1),(49,7,2,568,'Demo Alert 7 - Urban Nest Comfort','Demo alert 7 generated for Urban Nest Comfort',1,15,1),(50,6,2,567,'Demo Alert 6 - Urban Nest Comfort','Demo alert 6 generated for Urban Nest Comfort',3,15,1),(51,5,2,566,'Demo Alert 5 - Urban Nest Comfort','Demo alert 5 generated for Urban Nest Comfort',2,15,1),(52,4,2,565,'Demo Alert 4 - Urban Nest Comfort','Demo alert 4 generated for Urban Nest Comfort',1,15,1),(53,3,2,564,'Demo Alert 3 - Urban Nest Comfort','Demo alert 3 generated for Urban Nest Comfort',3,15,1),(54,2,2,563,'Demo Alert 2 - Urban Nest Comfort','Demo alert 2 generated for Urban Nest Comfort',2,15,1),(55,1,2,562,'Demo Alert 1 - Urban Nest Comfort','Demo alert 1 generated for Urban Nest Comfort',1,15,1),(56,2,2,581,'Demo Alert 10 - Urban Nest Heights','Demo alert 10 generated for Urban Nest Heights',1,16,1),(57,1,2,580,'Demo Alert 9 - Urban Nest Heights','Demo alert 9 generated for Urban Nest Heights',3,16,1),(58,8,2,579,'Demo Alert 8 - Urban Nest Heights','Demo alert 8 generated for Urban Nest Heights',2,16,1),(59,7,2,578,'Demo Alert 7 - Urban Nest Heights','Demo alert 7 generated for Urban Nest Heights',1,16,1),(60,6,2,577,'Demo Alert 6 - Urban Nest Heights','Demo alert 6 generated for Urban Nest Heights',3,16,1),(61,5,2,576,'Demo Alert 5 - Urban Nest Heights','Demo alert 5 generated for Urban Nest Heights',2,16,1),(62,4,2,575,'Demo Alert 4 - Urban Nest Heights','Demo alert 4 generated for Urban Nest Heights',1,16,1),(63,3,2,574,'Demo Alert 3 - Urban Nest Heights','Demo alert 3 generated for Urban Nest Heights',3,16,1),(64,2,2,573,'Demo Alert 2 - Urban Nest Heights','Demo alert 2 generated for Urban Nest Heights',2,16,1),(65,1,2,572,'Demo Alert 1 - Urban Nest Heights','Demo alert 1 generated for Urban Nest Heights',1,16,1),(66,2,2,591,'Demo Alert 10 - Urban Nest Residency','Demo alert 10 generated for Urban Nest Residency',1,17,1),(67,1,2,590,'Demo Alert 9 - Urban Nest Residency','Demo alert 9 generated for Urban Nest Residency',3,17,1),(68,8,2,589,'Demo Alert 8 - Urban Nest Residency','Demo alert 8 generated for Urban Nest Residency',2,17,1),(69,7,2,588,'Demo Alert 7 - Urban Nest Residency','Demo alert 7 generated for Urban Nest Residency',1,17,1),(70,6,2,587,'Demo Alert 6 - Urban Nest Residency','Demo alert 6 generated for Urban Nest Residency',3,17,1),(71,5,2,586,'Demo Alert 5 - Urban Nest Residency','Demo alert 5 generated for Urban Nest Residency',2,17,1),(72,4,2,585,'Demo Alert 4 - Urban Nest Residency','Demo alert 4 generated for Urban Nest Residency',1,17,1),(73,3,2,584,'Demo Alert 3 - Urban Nest Residency','Demo alert 3 generated for Urban Nest Residency',3,17,1),(74,2,2,583,'Demo Alert 2 - Urban Nest Residency','Demo alert 2 generated for Urban Nest Residency',2,17,1),(75,1,2,582,'Demo Alert 1 - Urban Nest Residency','Demo alert 1 generated for Urban Nest Residency',1,17,1),(76,2,2,601,'Demo Alert 10 - Urban Nest Royale','Demo alert 10 generated for Urban Nest Royale',1,18,1),(77,1,2,600,'Demo Alert 9 - Urban Nest Royale','Demo alert 9 generated for Urban Nest Royale',3,18,1),(78,8,2,599,'Demo Alert 8 - Urban Nest Royale','Demo alert 8 generated for Urban Nest Royale',2,18,1),(79,7,2,598,'Demo Alert 7 - Urban Nest Royale','Demo alert 7 generated for Urban Nest Royale',1,18,1),(80,6,2,597,'Demo Alert 6 - Urban Nest Royale','Demo alert 6 generated for Urban Nest Royale',3,18,1),(81,5,2,596,'Demo Alert 5 - Urban Nest Royale','Demo alert 5 generated for Urban Nest Royale',2,18,1),(82,4,2,595,'Demo Alert 4 - Urban Nest Royale','Demo alert 4 generated for Urban Nest Royale',1,18,1),(83,3,2,594,'Demo Alert 3 - Urban Nest Royale','Demo alert 3 generated for Urban Nest Royale',3,18,1),(84,2,2,593,'Demo Alert 2 - Urban Nest Royale','Demo alert 2 generated for Urban Nest Royale',2,18,1),(85,1,2,592,'Demo Alert 1 - Urban Nest Royale','Demo alert 1 generated for Urban Nest Royale',1,18,1),(86,2,2,611,'Demo Alert 10 - Urban Nest Paradise','Demo alert 10 generated for Urban Nest Paradise',1,19,1),(87,1,2,610,'Demo Alert 9 - Urban Nest Paradise','Demo alert 9 generated for Urban Nest Paradise',3,19,1),(88,8,2,609,'Demo Alert 8 - Urban Nest Paradise','Demo alert 8 generated for Urban Nest Paradise',2,19,1),(89,7,2,608,'Demo Alert 7 - Urban Nest Paradise','Demo alert 7 generated for Urban Nest Paradise',1,19,1),(90,6,2,607,'Demo Alert 6 - Urban Nest Paradise','Demo alert 6 generated for Urban Nest Paradise',3,19,1),(91,5,2,606,'Demo Alert 5 - Urban Nest Paradise','Demo alert 5 generated for Urban Nest Paradise',2,19,1),(92,4,2,605,'Demo Alert 4 - Urban Nest Paradise','Demo alert 4 generated for Urban Nest Paradise',1,19,1),(93,3,2,604,'Demo Alert 3 - Urban Nest Paradise','Demo alert 3 generated for Urban Nest Paradise',3,19,1),(94,2,2,603,'Demo Alert 2 - Urban Nest Paradise','Demo alert 2 generated for Urban Nest Paradise',2,19,1),(95,1,2,602,'Demo Alert 1 - Urban Nest Paradise','Demo alert 1 generated for Urban Nest Paradise',1,19,1),(133,5,2,NULL,'house cleaning','House cleaning in all rooms',1,9,1),(134,1,4,NULL,'fee','please pay due fee',1,9,1),(138,1,1,783,'Rent Reminder',NULL,1,9,24),(139,1,1,782,'Rent Reminder',NULL,1,9,24),(140,1,1,585,'Rent Reminder',NULL,1,9,24),(141,3,4,NULL,'Agreement Update','Please update your aggrement',1,9,1),(142,1,1,585,'Rent Reminder',NULL,1,9,24),(143,1,1,785,'Rent Reminder',NULL,1,9,24),(144,2,2,NULL,'Please update lease','please update lease',1,9,1);
/*!40000 ALTER TABLE `dy_pg_alerts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_amns_map`
--

DROP TABLE IF EXISTS `dy_pg_amns_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_amns_map` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pg_info` int DEFAULT NULL,
  `amns_info` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_amns_id_data_idx` (`amns_info`),
  KEY `fk_pg_info_id_data_idx` (`pg_info`),
  CONSTRAINT `fk_pg_amns_id_data` FOREIGN KEY (`amns_info`) REFERENCES `st_pg_amns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_info_id_data` FOREIGN KEY (`pg_info`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=135 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_amns_map`
--

LOCK TABLES `dy_pg_amns_map` WRITE;
/*!40000 ALTER TABLE `dy_pg_amns_map` DISABLE KEYS */;
INSERT INTO `dy_pg_amns_map` VALUES (2,9,1),(3,9,2),(4,10,2),(7,10,1),(8,9,10),(9,9,9),(10,9,8),(11,9,7),(12,9,6),(13,9,5),(14,9,4),(15,9,3),(16,13,10),(17,13,9),(18,13,8),(19,13,7),(20,13,6),(21,13,5),(22,13,4),(23,13,3),(24,13,2),(25,13,1),(26,17,10),(27,17,9),(28,17,8),(29,17,7),(30,17,6),(31,17,5),(32,17,4),(33,17,3),(34,17,2),(35,17,1),(36,10,10),(37,10,9),(38,10,8),(39,10,7),(40,10,6),(41,10,5),(42,10,4),(43,10,3),(44,14,10),(45,14,9),(46,14,8),(47,14,7),(48,14,6),(49,14,5),(50,14,4),(51,14,3),(52,14,2),(53,14,1),(54,18,10),(55,18,9),(56,18,8),(57,18,7),(58,18,6),(59,18,5),(60,18,4),(61,18,3),(62,18,2),(63,18,1),(64,15,10),(65,15,9),(66,15,8),(67,15,7),(68,15,6),(69,15,5),(70,15,4),(71,15,3),(72,15,2),(73,15,1),(74,19,10),(75,19,9),(76,19,8),(77,19,7),(78,19,6),(79,19,5),(80,19,4),(81,19,3),(82,19,2),(83,19,1),(84,16,10),(85,16,9),(86,16,8),(87,16,7),(88,16,6),(89,16,5),(90,16,4),(91,16,3),(92,16,2),(93,16,1);
/*!40000 ALTER TABLE `dy_pg_amns_map` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_bed_info`
--

DROP TABLE IF EXISTS `dy_pg_bed_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_bed_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `room_info` int DEFAULT NULL,
  `bed_number` int DEFAULT NULL,
  `bed_status` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_bed_status_id_idx` (`bed_status`),
  KEY `fk_room_info_idx` (`room_info`),
  CONSTRAINT `fk_bed_status_id` FOREIGN KEY (`bed_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_room_info` FOREIGN KEY (`room_info`) REFERENCES `dy_pg_room_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=532 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_bed_info`
--

LOCK TABLES `dy_pg_bed_info` WRITE;
/*!40000 ALTER TABLE `dy_pg_bed_info` DISABLE KEYS */;
INSERT INTO `dy_pg_bed_info` VALUES (127,279,1,3),(128,278,1,5),(208,281,1,5),(209,280,1,5),(316,279,2,3),(317,278,2,3);
/*!40000 ALTER TABLE `dy_pg_bed_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_bookings`
--

DROP TABLE IF EXISTS `dy_pg_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `bkg_no` varchar(25) DEFAULT NULL,
  `pg_id` int DEFAULT NULL,
  `room_id` int DEFAULT NULL,
  `bed_id` int DEFAULT NULL,
  `bkg_date` datetime DEFAULT NULL,
  `planned_check_in_date` datetime DEFAULT NULL,
  `actual_check_in_date` datetime DEFAULT NULL,
  `planned_check_out_date` datetime DEFAULT NULL,
  `actual_check_out_date` datetime DEFAULT NULL,
  `bkg_status` int DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `modified_time` datetime DEFAULT NULL,
  `created_by` int DEFAULT NULL,
  `modified_by` int DEFAULT NULL,
  `remarks` text,
  `monthly_rent` decimal(10,2) DEFAULT NULL,
  `secuirty_deposit` decimal(10,2) DEFAULT NULL,
  `ac_charge` decimal(10,2) DEFAULT NULL,
  `dth_charge` decimal(10,2) DEFAULT NULL,
  `oven_charge` decimal(10,2) DEFAULT NULL,
  `water_charge` decimal(10,2) DEFAULT NULL,
  `laundry_charge` decimal(10,2) DEFAULT NULL,
  `parking_charge` decimal(10,2) DEFAULT NULL,
  `refrigerator_charge` decimal(10,2) DEFAULT NULL,
  `electricity_fixed_charge` decimal(10,2) DEFAULT NULL,
  `electricity_meter_charge` decimal(10,2) DEFAULT NULL,
  `notice_period_time` int DEFAULT NULL,
  `guest_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_pg_id_data_idx` (`pg_id`),
  KEY `fk_room_id_data_idx` (`room_id`),
  KEY `fk_bed_id_data_idx` (`bed_id`),
  KEY `fk_bkg_sts_id_idx` (`bkg_status`),
  KEY `fk_user_created_data_idx` (`created_by`),
  KEY `fk_user_modified_data_idx` (`modified_by`),
  KEY `fk_guest_data` (`guest_id`),
  CONSTRAINT `fk_bed_id_data` FOREIGN KEY (`bed_id`) REFERENCES `dy_pg_bed_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_bkg_sts_id` FOREIGN KEY (`bkg_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_guest_data` FOREIGN KEY (`guest_id`) REFERENCES `dy_pg_guest_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_id_data` FOREIGN KEY (`pg_id`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_room_id_data` FOREIGN KEY (`room_id`) REFERENCES `dy_pg_room_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_created_data` FOREIGN KEY (`created_by`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_modified_data` FOREIGN KEY (`modified_by`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=830 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Table for recording bookings';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_bookings`
--

LOCK TABLES `dy_pg_bookings` WRITE;
/*!40000 ALTER TABLE `dy_pg_bookings` DISABLE KEYS */;
INSERT INTO `dy_pg_bookings` VALUES (566,'BKG-20260825-020',9,281,208,'2026-08-25 16:50:23','2026-09-14 16:50:23','2026-09-11 13:29:36','2026-09-25 16:50:23',NULL,5,'2026-08-25 16:50:23','2026-09-11 13:29:36',541,779,'Demo booking - 9 - 20',8000.00,16000.00,500.00,200.00,0.00,300.00,400.00,500.00,300.00,200.00,0.00,30,200),(824,'BKG-20260831-001',9,278,128,NULL,'2026-09-11 00:00:00','2026-09-12 15:39:20','2026-10-10 00:00:00',NULL,5,'2026-08-31 05:15:35','2026-09-10 15:40:49',782,779,'Requires AC,Nonveg, Geaser',10000.00,20000.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,30,266),(826,'BKG-20260831-002',9,279,127,NULL,'2026-08-16 00:00:00','2026-08-16 00:00:00','2026-09-11 00:00:00','2026-09-11 09:40:44',3,'2026-08-31 14:20:19','2026-09-11 09:40:44',783,779,'Requires AC,Nonveg, Geaser',10000.00,20000.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,30,267),(829,'BKG-20260912-002',9,280,209,NULL,'2026-09-16 00:00:00',NULL,'2026-10-15 00:00:00',NULL,5,'2026-09-12 06:13:26',NULL,785,779,'Requires AC,Nonveg, Geaser',10000.00,20000.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,5,269);
/*!40000 ALTER TABLE `dy_pg_bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_chrgs_info`
--

DROP TABLE IF EXISTS `dy_pg_chrgs_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_chrgs_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pg_id` int DEFAULT NULL,
  `charge_type` int DEFAULT NULL,
  `charge_cost` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_chrg_type_idx_idx` (`charge_type`),
  KEY `fk_pg_data_idx_idx` (`pg_id`),
  CONSTRAINT `fk_pg_chrg_type_idx` FOREIGN KEY (`charge_type`) REFERENCES `st_pg_chrgs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_data_idx` FOREIGN KEY (`pg_id`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_chrgs_info`
--

LOCK TABLES `dy_pg_chrgs_info` WRITE;
/*!40000 ALTER TABLE `dy_pg_chrgs_info` DISABLE KEYS */;
/*!40000 ALTER TABLE `dy_pg_chrgs_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_events_info`
--

DROP TABLE IF EXISTS `dy_pg_events_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_events_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `event_date` datetime DEFAULT NULL,
  `event_title` varchar(45) DEFAULT NULL,
  `event_description` varchar(150) DEFAULT NULL,
  `pg_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_id_ev_idx` (`pg_id`),
  CONSTRAINT `fk_pg_id_ev` FOREIGN KEY (`pg_id`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_events_info`
--

LOCK TABLES `dy_pg_events_info` WRITE;
/*!40000 ALTER TABLE `dy_pg_events_info` DISABLE KEYS */;
INSERT INTO `dy_pg_events_info` VALUES (1,'2026-08-15 10:00:00','Independence Day Celebration','PG community celebration event',10),(2,'2026-09-15 10:00:00','ganesh chaturthi Celebration','PG community celebration event',10),(3,'2026-09-28 20:03:04','Food Event','Demo PG community event - Green Valley Residency',9),(4,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Green Valley Residency',9),(5,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Green Valley Residency',9),(6,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Green Valley Residency',9),(7,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Green Valley Residency',9),(8,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Premium PG',10),(9,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Premium PG',10),(10,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Premium PG',10),(11,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Premium PG',10),(12,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Premium PG',10),(13,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Premium',13),(14,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Premium',13),(15,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Premium',13),(16,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Premium',13),(17,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Premium',13),(18,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Elite',14),(19,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Elite',14),(20,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Elite',14),(21,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Elite',14),(22,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Elite',14),(23,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Comfort',15),(24,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Comfort',15),(25,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Comfort',15),(26,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Comfort',15),(27,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Comfort',15),(28,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Heights',16),(29,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Heights',16),(30,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Heights',16),(31,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Heights',16),(32,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Heights',16),(33,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Residency',17),(34,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Residency',17),(35,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Residency',17),(36,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Residency',17),(37,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Residency',17),(38,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Royale',18),(39,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Royale',18),(40,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Royale',18),(41,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Royale',18),(42,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Royale',18),(43,'2026-09-28 20:03:04','Food Event','Demo PG community event - Urban Nest Paradise',19),(44,'2026-09-21 20:03:04','Movie Night','Demo PG community event - Urban Nest Paradise',19),(45,'2026-09-14 20:03:04','Festival Celebration','Demo PG community event - Urban Nest Paradise',19),(46,'2026-09-07 20:03:04','Sports Day','Demo PG community event - Urban Nest Paradise',19),(47,'2026-08-31 20:03:04','Community Meeting','Demo PG community event - Urban Nest Paradise',19),(66,'2026-09-19 14:00:00','Ganesh Chaturthi Celebrations','Gather near Ganesh pandal for pooja ceremony',9);
/*!40000 ALTER TABLE `dy_pg_events_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_guest_history`
--

DROP TABLE IF EXISTS `dy_pg_guest_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_guest_history` (
  `id` int NOT NULL AUTO_INCREMENT,
  `guest_info` int DEFAULT NULL,
  `pg_info` int DEFAULT NULL,
  `check_in_time` datetime DEFAULT NULL,
  `check_out_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_info_data_idx` (`pg_info`),
  CONSTRAINT `fk_pg_info_data` FOREIGN KEY (`pg_info`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_guest_history`
--

LOCK TABLES `dy_pg_guest_history` WRITE;
/*!40000 ALTER TABLE `dy_pg_guest_history` DISABLE KEYS */;
INSERT INTO `dy_pg_guest_history` VALUES (4,8,10,'2026-08-20 10:30:00','2026-08-21 09:00:00'),(5,9,10,'2026-08-20 12:30:00','2026-08-21 09:00:00');
/*!40000 ALTER TABLE `dy_pg_guest_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_guest_info`
--

DROP TABLE IF EXISTS `dy_pg_guest_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_guest_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `guest_type` int DEFAULT NULL,
  `guest_status` int DEFAULT NULL,
  `perm_address` varchar(45) DEFAULT NULL,
  `pg_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `emergency-contact` varchar(45) DEFAULT NULL,
  `emergency_contact_name` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_guest_status_idx` (`guest_status`),
  KEY `fk_new_guest_type_idx` (`guest_type`),
  KEY `fk_pg_id_idx` (`pg_id`),
  KEY `fk_user_id_idx` (`user_id`),
  CONSTRAINT `fk_guest_status` FOREIGN KEY (`guest_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_new_guest_type` FOREIGN KEY (`guest_type`) REFERENCES `st_pg_gst_typ` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_id` FOREIGN KEY (`pg_id`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=270 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_guest_info`
--

LOCK TABLES `dy_pg_guest_info` WRITE;
/*!40000 ALTER TABLE `dy_pg_guest_info` DISABLE KEYS */;
INSERT INTO `dy_pg_guest_info` VALUES (137,1,4,'anwar sk , Madhapur, Hyderabad',9,10,'9800000001','Ramesh Kumar'),(138,2,4,'king pin , Kondapur, Hyderabad',10,12,'9800000002','Suresh Sharma'),(139,3,5,'Arjun Kumar, Gachibowli, Hyderabad',13,524,'9800000003','Mahesh Reddy'),(140,4,4,'Priya Sharma, Kukatpally, Hyderabad',14,525,'9800000004','Rajesh Patel'),(141,5,4,'Rahul Reddy, Hitech City, Hyderabad',15,526,'9800000005','Anil Rao'),(142,6,5,'Sneha Patel, Madhapur, Hyderabad',16,527,'9800000006','Prakash Verma'),(143,7,4,'Vikram Rao, Kondapur, Hyderabad',17,528,'9800000007','Venkat Naidu'),(144,8,4,'Ananya Verma, Gachibowli, Hyderabad',18,529,'9800000008','Mohan Gupta'),(145,9,5,'Karthik Singh, Kukatpally, Hyderabad',19,530,'9800000009','Ravi Singh'),(146,10,4,'Pooja Naidu, Hitech City, Hyderabad',9,531,'9800000010','Kiran Nair'),(147,1,4,'Rohit Gupta, Madhapur, Hyderabad',10,532,'9800000011','Ramesh Kumar'),(148,2,5,'Divya Iyer, Kondapur, Hyderabad',13,533,'9800000012','Suresh Sharma'),(149,3,4,'Aditya Nair, Gachibowli, Hyderabad',14,534,'9800000013','Mahesh Reddy'),(150,4,4,'Meera Das, Kukatpally, Hyderabad',15,535,'9800000014','Rajesh Patel'),(151,5,5,'Sanjay Chowdary, Hitech City, Hyderabad',16,536,'9800000015','Anil Rao'),(152,6,4,'Kavya Mishra, Madhapur, Hyderabad',17,537,'9800000016','Prakash Verma'),(153,7,4,'Nikhil Raju, Kondapur, Hyderabad',18,538,'9800000017','Venkat Naidu'),(154,8,5,'Swathi Varma, Gachibowli, Hyderabad',19,539,'9800000018','Mohan Gupta'),(155,9,4,'Akhil Krishna, Kukatpally, Hyderabad',9,540,'9800000019','Ravi Singh'),(156,10,4,'Neha Mehta, Hitech City, Hyderabad',10,541,'9800000020','Kiran Nair'),(157,1,5,'Varun Joshi, Madhapur, Hyderabad',13,542,'9800000021','Ramesh Kumar'),(158,2,4,'Sravani Agarwal, Kondapur, Hyderabad',14,543,'9800000022','Suresh Sharma'),(159,3,4,'Arjun Kumar, Gachibowli, Hyderabad',15,544,'9800000023','Mahesh Reddy'),(160,4,5,'Priya Sharma, Kukatpally, Hyderabad',16,545,'9800000024','Rajesh Patel'),(161,5,4,'Rahul Reddy, Hitech City, Hyderabad',17,546,'9800000025','Anil Rao'),(162,6,4,'Sneha Patel, Madhapur, Hyderabad',18,547,'9800000026','Prakash Verma'),(163,7,5,'Vikram Rao, Kondapur, Hyderabad',19,548,'9800000027','Venkat Naidu'),(164,8,4,'Ananya Verma, Gachibowli, Hyderabad',9,549,'9800000028','Mohan Gupta'),(165,9,4,'Karthik Singh, Kukatpally, Hyderabad',10,550,'9800000029','Ravi Singh'),(166,10,5,'Pooja Naidu, Hitech City, Hyderabad',13,551,'9800000030','Kiran Nair'),(167,1,4,'Rohit Gupta, Madhapur, Hyderabad',14,552,'9800000031','Ramesh Kumar'),(168,2,4,'Divya Iyer, Kondapur, Hyderabad',15,553,'9800000032','Suresh Sharma'),(169,3,5,'Aditya Nair, Gachibowli, Hyderabad',16,554,'9800000033','Mahesh Reddy'),(170,4,4,'Meera Das, Kukatpally, Hyderabad',17,555,'9800000034','Rajesh Patel'),(171,5,4,'Sanjay Chowdary, Hitech City, Hyderabad',18,556,'9800000035','Anil Rao'),(172,6,5,'Kavya Mishra, Madhapur, Hyderabad',19,557,'9800000036','Prakash Verma'),(173,7,4,'Nikhil Raju, Kondapur, Hyderabad',9,558,'9800000037','Venkat Naidu'),(174,8,4,'Swathi Varma, Gachibowli, Hyderabad',10,559,'9800000038','Mohan Gupta'),(175,9,5,'Akhil Krishna, Kukatpally, Hyderabad',13,560,'9800000039','Ravi Singh'),(176,10,4,'Neha Mehta, Hitech City, Hyderabad',14,561,'9800000040','Kiran Nair'),(177,1,4,'Varun Joshi, Madhapur, Hyderabad',15,562,'9800000041','Ramesh Kumar'),(178,2,5,'Sravani Agarwal, Kondapur, Hyderabad',16,563,'9800000042','Suresh Sharma'),(179,3,4,'Arjun Kumar, Gachibowli, Hyderabad',17,564,'9800000043','Mahesh Reddy'),(180,4,4,'Priya Sharma, Kukatpally, Hyderabad',18,565,'9800000044','Rajesh Patel'),(181,5,5,'Rahul Reddy, Hitech City, Hyderabad',19,566,'9800000045','Anil Rao'),(182,6,4,'Sneha Patel, Madhapur, Hyderabad',9,567,'9800000046','Prakash Verma'),(183,7,4,'Vikram Rao, Kondapur, Hyderabad',10,568,'9800000047','Venkat Naidu'),(184,8,5,'Ananya Verma, Gachibowli, Hyderabad',13,569,'9800000048','Mohan Gupta'),(185,9,4,'Karthik Singh, Kukatpally, Hyderabad',14,570,'9800000049','Ravi Singh'),(186,10,4,'Pooja Naidu, Hitech City, Hyderabad',15,571,'9800000050','Kiran Nair'),(187,1,5,'Rohit Gupta, Madhapur, Hyderabad',16,572,'9800000051','Ramesh Kumar'),(188,2,4,'Divya Iyer, Kondapur, Hyderabad',17,573,'9800000052','Suresh Sharma'),(189,3,4,'Aditya Nair, Gachibowli, Hyderabad',18,574,'9800000053','Mahesh Reddy'),(190,4,5,'Meera Das, Kukatpally, Hyderabad',19,575,'9800000054','Rajesh Patel'),(191,5,4,'Sanjay Chowdary, Hitech City, Hyderabad',9,576,'9800000055','Anil Rao'),(192,6,4,'Kavya Mishra, Madhapur, Hyderabad',10,577,'9800000056','Prakash Verma'),(193,7,5,'Nikhil Raju, Kondapur, Hyderabad',13,578,'9800000057','Venkat Naidu'),(194,8,4,'Swathi Varma, Gachibowli, Hyderabad',14,579,'9800000058','Mohan Gupta'),(195,9,4,'Akhil Krishna, Kukatpally, Hyderabad',15,580,'9800000059','Ravi Singh'),(196,10,5,'Neha Mehta, Hitech City, Hyderabad',16,581,'9800000060','Kiran Nair'),(197,1,4,'Varun Joshi, Madhapur, Hyderabad',17,582,'9800000061','Ramesh Kumar'),(198,2,4,'Sravani Agarwal, Kondapur, Hyderabad',18,583,'9800000062','Suresh Sharma'),(199,3,5,'Arjun Kumar, Gachibowli, Hyderabad',19,584,'9800000063','Mahesh Reddy'),(200,4,4,'Priya Sharma, Kukatpally, Hyderabad',9,585,'9800000064','Rajesh Patel'),(201,5,4,'Rahul Reddy, Hitech City, Hyderabad',10,586,'9800000065','Anil Rao'),(202,6,5,'Sneha Patel, Madhapur, Hyderabad',13,587,'9800000066','Prakash Verma'),(203,7,4,'Vikram Rao, Kondapur, Hyderabad',14,588,'9800000067','Venkat Naidu'),(204,8,4,'Ananya Verma, Gachibowli, Hyderabad',15,589,'9800000068','Mohan Gupta'),(205,9,5,'Karthik Singh, Kukatpally, Hyderabad',16,590,'9800000069','Ravi Singh'),(206,10,4,'Pooja Naidu, Hitech City, Hyderabad',17,591,'9800000070','Kiran Nair'),(207,1,4,'Rohit Gupta, Madhapur, Hyderabad',18,592,'9800000071','Ramesh Kumar'),(208,2,5,'Divya Iyer, Kondapur, Hyderabad',19,593,'9800000072','Suresh Sharma'),(209,3,4,'Aditya Nair, Gachibowli, Hyderabad',9,594,'9800000073','Mahesh Reddy'),(210,4,4,'Meera Das, Kukatpally, Hyderabad',10,595,'9800000074','Rajesh Patel'),(211,5,5,'Sanjay Chowdary, Hitech City, Hyderabad',13,596,'9800000075','Anil Rao'),(212,6,4,'Kavya Mishra, Madhapur, Hyderabad',14,597,'9800000076','Prakash Verma'),(213,7,4,'Nikhil Raju, Kondapur, Hyderabad',15,598,'9800000077','Venkat Naidu'),(214,8,5,'Swathi Varma, Gachibowli, Hyderabad',16,599,'9800000078','Mohan Gupta'),(215,9,4,'Akhil Krishna, Kukatpally, Hyderabad',17,600,'9800000079','Ravi Singh'),(216,10,4,'Neha Mehta, Hitech City, Hyderabad',18,601,'9800000080','Kiran Nair'),(217,1,5,'Varun Joshi, Madhapur, Hyderabad',19,602,'9800000081','Ramesh Kumar'),(218,2,4,'Sravani Agarwal, Kondapur, Hyderabad',9,603,'9800000082','Suresh Sharma'),(219,3,4,'Arjun Kumar, Gachibowli, Hyderabad',10,604,'9800000083','Mahesh Reddy'),(220,4,5,'Priya Sharma, Kukatpally, Hyderabad',13,605,'9800000084','Rajesh Patel'),(221,5,4,'Rahul Reddy, Hitech City, Hyderabad',14,606,'9800000085','Anil Rao'),(222,6,4,'Sneha Patel, Madhapur, Hyderabad',15,607,'9800000086','Prakash Verma'),(223,7,5,'Vikram Rao, Kondapur, Hyderabad',16,608,'9800000087','Venkat Naidu'),(224,8,4,'Ananya Verma, Gachibowli, Hyderabad',17,609,'9800000088','Mohan Gupta'),(225,9,4,'Karthik Singh, Kukatpally, Hyderabad',18,610,'9800000089','Ravi Singh'),(226,10,5,'Pooja Naidu, Hitech City, Hyderabad',19,611,'9800000090','Kiran Nair'),(227,1,4,'Rohit Gupta, Madhapur, Hyderabad',9,612,'9800000091','Ramesh Kumar'),(228,2,4,'Divya Iyer, Kondapur, Hyderabad',10,613,'9800000092','Suresh Sharma'),(229,3,5,'Aditya Nair, Gachibowli, Hyderabad',13,614,'9800000093','Mahesh Reddy'),(230,4,4,'Meera Das, Kukatpally, Hyderabad',14,615,'9800000094','Rajesh Patel'),(231,5,4,'Sanjay Chowdary, Hitech City, Hyderabad',15,616,'9800000095','Anil Rao'),(232,6,5,'Kavya Mishra, Madhapur, Hyderabad',16,617,'9800000096','Prakash Verma'),(233,7,4,'Nikhil Raju, Kondapur, Hyderabad',17,618,'9800000097','Venkat Naidu'),(234,8,4,'Swathi Varma, Gachibowli, Hyderabad',18,619,'9800000098','Mohan Gupta'),(235,9,5,'Akhil Krishna, Kukatpally, Hyderabad',19,620,'9800000099','Ravi Singh'),(236,10,4,'Neha Mehta, Hitech City, Hyderabad',9,621,'9800000100','Kiran Nair'),(266,1,5,'h-141/52,Hyderabad',9,779,'8899007766','Puli'),(267,2,4,'h-no-5-143-somajiguda,hyderabad',9,783,'8899007766','head'),(268,4,4,'road-no-4,h-no-6/4,Bengaluru',9,784,'8899007766','Josh'),(269,5,4,'road-no-4,h-no-6/4,Bengaluru',9,785,'8899007766','jas');
/*!40000 ALTER TABLE `dy_pg_guest_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_info`
--

DROP TABLE IF EXISTS `dy_pg_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pg_id` varchar(45) DEFAULT NULL,
  `pg_name` varchar(45) DEFAULT NULL,
  `pg_owner` int DEFAULT NULL,
  `pg_cat` int DEFAULT NULL,
  `pg_type_id` int DEFAULT NULL,
  `pg_desc_id` int DEFAULT NULL,
  `pg_address` varchar(150) DEFAULT NULL,
  `pg_city` int DEFAULT NULL,
  `pg_state` int DEFAULT NULL,
  `pg_landmark` varchar(45) DEFAULT NULL,
  `pg_pincode` int DEFAULT NULL,
  `pg_major_area` varchar(45) DEFAULT NULL,
  `pg_primary_contact_no` varchar(15) DEFAULT NULL,
  `pg_alternate_contact_no` varchar(15) DEFAULT NULL,
  `pg_email` varchar(45) DEFAULT NULL,
  `pg_map_url` varchar(150) DEFAULT NULL,
  `pg_create_time` datetime DEFAULT NULL,
  `pg_update_time` datetime DEFAULT NULL,
  `pg_documents_path` varchar(250) DEFAULT NULL,
  `pg_status` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_category_idx` (`pg_cat`),
  KEY `fk_pg_city_idx` (`pg_city`),
  KEY `fk_pg_description_idx` (`pg_desc_id`),
  KEY `fk_pg_new_status_idx` (`pg_status`),
  KEY `fk_pg_owner_idx` (`pg_owner`),
  KEY `fk_pg_state_idx` (`pg_state`),
  KEY `fk_pg_type_idx` (`pg_type_id`),
  CONSTRAINT `fk_pg_category` FOREIGN KEY (`pg_cat`) REFERENCES `st_pg_cat` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_city` FOREIGN KEY (`pg_city`) REFERENCES `st_pg_ctys` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_description` FOREIGN KEY (`pg_desc_id`) REFERENCES `st_pg_description` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_new_status` FOREIGN KEY (`pg_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_owner` FOREIGN KEY (`pg_owner`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_state` FOREIGN KEY (`pg_state`) REFERENCES `st_pg_state` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_type` FOREIGN KEY (`pg_type_id`) REFERENCES `st_pg_type` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_info`
--

LOCK TABLES `dy_pg_info` WRITE;
/*!40000 ALTER TABLE `dy_pg_info` DISABLE KEYS */;
INSERT INTO `dy_pg_info` VALUES (9,'Green_Valley_Residency_anwar_sk _9','Green Valley Residency',779,1,1,1,'12, Lake View Road, Madhapur',1,1,'Near Metro Station',500081,'Madhapur','9876543210','9123456780','admin@greenvalleyresidency.com','https://maps.google.com/?q=Green+Valley+Residency',NULL,NULL,'Pgdata/Green_Valley_Residency_anwar_sk _9',1),(10,'Urban_Nest_Premium_PG_king_pin _10','Urban Nest Premium PG',779,2,1,2,'45, Jubilee Hills Road, Hyderabad',1,1,'Near Apollo Hospital',500033,'Jubilee Hills','9867452310','9012345678','contact@urbannestpremium.com','https://maps.google.com/?q=Urban+Nest+Premium+PG',NULL,NULL,'Pgdata/Urban_Nest_Premium_PG_king_pin _10',1),(13,'Urban_Nest_Premium_PG_anwar_sk__10','Urban Nest Premium',10,1,1,1,'1, Urban_Nest_Premium Road, Hyderabad',1,1,'Near Urban Nest Premium Landmark 1',500001,'Urban_Nest_Premium_Area_1','9650000001','9750000001','urbannestpremium.anwar.sk .10@gmail.com','https://maps.google.com/?q=Urban_Nest_Premium_1','2026-08-24 14:50:15','2026-08-24 14:50:15','Pgdata/UrbanNestPremium/10',10),(14,'Urban_Nest_Elite_PG_king_pin__12','Urban Nest Elite',12,2,2,2,'2, Urban_Nest_Elite Road, Hyderabad',2,1,'Near Urban Nest Elite Landmark 2',500002,'Urban_Nest_Elite_Area_2','9650000002','9750000002','urbannestelite.king.pin .12@gmail.com','https://maps.google.com/?q=Urban_Nest_Elite_2','2026-08-24 14:50:15','2026-08-24 14:50:15','Pgdata/UrbanNestElite/12',10),(15,'Urban_Nest_Comfort_PG_Arjun_Kumar_524','Urban Nest Comfort',524,3,3,3,'3, Urban_Nest_Comfort Road, Hyderabad',3,1,'Near Urban Nest Comfort Landmark 3',500003,'Urban_Nest_Comfort_Area_3','9650000003','9750000003','urbannestcomfort.arjun.kumar.524@gmail.com','https://maps.google.com/?q=Urban_Nest_Comfort_3','2026-08-24 14:50:15','2026-08-24 14:50:15','Pgdata/UrbanNestComfort/524',10),(16,'Urban_Nest_Heights_PG_Priya_Sharma_525','Urban Nest Heights',525,4,4,4,'4, Urban_Nest_Heights Road, Hyderabad',4,1,'Near Urban Nest Heights Landmark 4',500004,'Urban_Nest_Heights_Area_4','9650000004','9750000004','urbannestheights.priya.sharma.525@gmail.com','https://maps.google.com/?q=Urban_Nest_Heights_4','2026-08-24 14:50:15','2026-08-24 14:50:15','Pgdata/UrbanNestHeights/525',10),(17,'Urban_Nest_Residency_PG_Rahul_Reddy_526','Urban Nest Residency',526,1,5,5,'5, Urban_Nest_Residency Road, Hyderabad',5,1,'Near Urban Nest Residency Landmark 5',500005,'Urban_Nest_Residency_Area_5','9650000005','9750000005','urbannestresidency.rahul.reddy.526@gmail.com','https://maps.google.com/?q=Urban_Nest_Residency_5','2026-08-24 14:50:15','2026-08-24 14:50:15','Pgdata/UrbanNestResidency/526',10),(18,'Urban_Nest_Royale_PG_Sneha_Patel_527','Urban Nest Royale',527,2,6,1,'6, Urban_Nest_Royale Road, Hyderabad',6,1,'Near Urban Nest Royale Landmark 6',500006,'Urban_Nest_Royale_Area_6','9650000006','9750000006','urbannestroyale.sneha.patel.527@gmail.com','https://maps.google.com/?q=Urban_Nest_Royale_6','2026-08-24 14:50:15','2026-08-24 14:50:15','Pgdata/UrbanNestRoyale/527',10),(19,'Urban_Nest_Paradise_PG_Vikram_Rao_528','Urban Nest Paradise',528,3,7,2,'7, Urban_Nest_Paradise Road, Hyderabad',7,1,'Near Urban Nest Paradise Landmark 7',500007,'Urban_Nest_Paradise_Area_7','9650000007','9750000007','urbannestparadise.vikram.rao.528@gmail.com','https://maps.google.com/?q=Urban_Nest_Paradise_7','2026-08-24 14:50:15','2026-08-24 14:50:15','Pgdata/UrbanNestParadise/528',10);
/*!40000 ALTER TABLE `dy_pg_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_kyc_info`
--

DROP TABLE IF EXISTS `dy_pg_kyc_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_kyc_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `guest_info` int DEFAULT NULL,
  `pg_info` int DEFAULT NULL,
  `kyc_type` int DEFAULT NULL,
  `kyc_number` varchar(45) DEFAULT NULL,
  `kyc_document_path` varchar(45) DEFAULT NULL,
  `kyc_document_expiry_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_kyc_guest_idx` (`guest_info`),
  KEY `fk_kyc_pg_idx` (`pg_info`),
  KEY `fk_kyc_type_idx` (`kyc_type`),
  CONSTRAINT `fk_kyc_guest` FOREIGN KEY (`guest_info`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_kyc_pg` FOREIGN KEY (`pg_info`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_kyc_type` FOREIGN KEY (`kyc_type`) REFERENCES `st_pg_kyc_type` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=386 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_kyc_info`
--

LOCK TABLES `dy_pg_kyc_info` WRITE;
/*!40000 ALTER TABLE `dy_pg_kyc_info` DISABLE KEYS */;
INSERT INTO `dy_pg_kyc_info` VALUES (131,10,9,1,'AADHAAR0000000001','KYC/1.pdf','2028-08-24 16:52:50'),(132,12,10,2,'AADHAAR0000000002','KYC/2.pdf','2028-08-24 16:52:50'),(133,524,13,3,'PAN0000000003','KYC/3.pdf','2028-08-24 16:52:50'),(134,525,14,4,'AADHAAR0000000004','KYC/4.pdf','2028-08-24 16:52:50'),(135,526,15,5,'AADHAAR0000000005','KYC/5.pdf','2028-08-24 16:52:50'),(136,527,16,6,'PAN0000000006','KYC/6.pdf','2028-08-24 16:52:50'),(137,528,17,7,'AADHAAR0000000007','KYC/7.pdf','2028-08-24 16:52:50'),(138,529,18,8,'AADHAAR0000000008','KYC/8.pdf','2028-08-24 16:52:50'),(139,530,19,9,'PAN0000000009','KYC/9.pdf','2028-08-24 16:52:50'),(140,531,9,10,'AADHAAR0000000010','KYC/10.pdf','2028-08-24 16:52:50'),(141,532,10,11,'AADHAAR0000000011','KYC/11.pdf','2028-08-24 16:52:50'),(142,533,13,12,'PAN0000000012','KYC/12.pdf','2028-08-24 16:52:50'),(143,534,14,13,'AADHAAR0000000013','KYC/13.pdf','2028-08-24 16:52:50'),(144,535,15,1,'AADHAAR0000000014','KYC/14.pdf','2028-08-24 16:52:50'),(145,536,16,2,'PAN0000000015','KYC/15.pdf','2028-08-24 16:52:50'),(146,537,17,3,'AADHAAR0000000016','KYC/16.pdf','2028-08-24 16:52:50'),(147,538,18,4,'AADHAAR0000000017','KYC/17.pdf','2028-08-24 16:52:50'),(148,539,19,5,'PAN0000000018','KYC/18.pdf','2028-08-24 16:52:50'),(149,540,9,6,'AADHAAR0000000019','KYC/19.pdf','2028-08-24 16:52:50'),(150,541,10,7,'AADHAAR0000000020','KYC/20.pdf','2028-08-24 16:52:50'),(151,542,13,8,'PAN0000000021','KYC/21.pdf','2028-08-24 16:52:50'),(152,543,14,9,'AADHAAR0000000022','KYC/22.pdf','2028-08-24 16:52:50'),(153,544,15,10,'AADHAAR0000000023','KYC/23.pdf','2028-08-24 16:52:50'),(154,545,16,11,'PAN0000000024','KYC/24.pdf','2028-08-24 16:52:50'),(155,546,17,12,'AADHAAR0000000025','KYC/25.pdf','2028-08-24 16:52:50'),(156,547,18,13,'AADHAAR0000000026','KYC/26.pdf','2028-08-24 16:52:50'),(157,548,19,1,'PAN0000000027','KYC/27.pdf','2028-08-24 16:52:50'),(158,549,9,2,'AADHAAR0000000028','KYC/28.pdf','2028-08-24 16:52:50'),(159,550,10,3,'AADHAAR0000000029','KYC/29.pdf','2028-08-24 16:52:50'),(160,551,13,4,'PAN0000000030','KYC/30.pdf','2028-08-24 16:52:50'),(161,552,14,5,'AADHAAR0000000031','KYC/31.pdf','2028-08-24 16:52:50'),(162,553,15,6,'AADHAAR0000000032','KYC/32.pdf','2028-08-24 16:52:50'),(163,554,16,7,'PAN0000000033','KYC/33.pdf','2028-08-24 16:52:50'),(164,555,17,8,'AADHAAR0000000034','KYC/34.pdf','2028-08-24 16:52:50'),(165,556,18,9,'AADHAAR0000000035','KYC/35.pdf','2028-08-24 16:52:50'),(166,557,19,10,'PAN0000000036','KYC/36.pdf','2028-08-24 16:52:50'),(167,558,9,11,'AADHAAR0000000037','KYC/37.pdf','2028-08-24 16:52:50'),(168,559,10,12,'AADHAAR0000000038','KYC/38.pdf','2028-08-24 16:52:50'),(169,560,13,13,'PAN0000000039','KYC/39.pdf','2028-08-24 16:52:50'),(170,561,14,1,'AADHAAR0000000040','KYC/40.pdf','2028-08-24 16:52:50'),(171,562,15,2,'AADHAAR0000000041','KYC/41.pdf','2028-08-24 16:52:50'),(172,563,16,3,'PAN0000000042','KYC/42.pdf','2028-08-24 16:52:50'),(173,564,17,4,'AADHAAR0000000043','KYC/43.pdf','2028-08-24 16:52:50'),(174,565,18,5,'AADHAAR0000000044','KYC/44.pdf','2028-08-24 16:52:50'),(175,566,19,6,'PAN0000000045','KYC/45.pdf','2028-08-24 16:52:50'),(176,567,9,7,'AADHAAR0000000046','KYC/46.pdf','2028-08-24 16:52:50'),(177,568,10,8,'AADHAAR0000000047','KYC/47.pdf','2028-08-24 16:52:50'),(178,569,13,9,'PAN0000000048','KYC/48.pdf','2028-08-24 16:52:50'),(179,570,14,10,'AADHAAR0000000049','KYC/49.pdf','2028-08-24 16:52:50'),(180,571,15,11,'AADHAAR0000000050','KYC/50.pdf','2028-08-24 16:52:50'),(181,572,16,12,'PAN0000000051','KYC/51.pdf','2028-08-24 16:52:50'),(182,573,17,13,'AADHAAR0000000052','KYC/52.pdf','2028-08-24 16:52:50'),(183,574,18,1,'AADHAAR0000000053','KYC/53.pdf','2028-08-24 16:52:50'),(184,575,19,2,'PAN0000000054','KYC/54.pdf','2028-08-24 16:52:50'),(185,576,9,3,'AADHAAR0000000055','KYC/55.pdf','2028-08-24 16:52:50'),(186,577,10,4,'AADHAAR0000000056','KYC/56.pdf','2028-08-24 16:52:50'),(187,578,13,5,'PAN0000000057','KYC/57.pdf','2028-08-24 16:52:50'),(188,579,14,6,'AADHAAR0000000058','KYC/58.pdf','2028-08-24 16:52:50'),(189,580,15,7,'AADHAAR0000000059','KYC/59.pdf','2028-08-24 16:52:50'),(190,581,16,8,'PAN0000000060','KYC/60.pdf','2028-08-24 16:52:50'),(191,582,17,9,'AADHAAR0000000061','KYC/61.pdf','2028-08-24 16:52:50'),(192,583,18,10,'AADHAAR0000000062','KYC/62.pdf','2028-08-24 16:52:50'),(193,584,19,11,'PAN0000000063','KYC/63.pdf','2028-08-24 16:52:50'),(194,585,9,12,'AADHAAR0000000064','KYC/64.pdf','2028-08-24 16:52:50'),(195,586,10,13,'AADHAAR0000000065','KYC/65.pdf','2028-08-24 16:52:50'),(196,587,13,1,'PAN0000000066','KYC/66.pdf','2028-08-24 16:52:50'),(197,588,14,2,'AADHAAR0000000067','KYC/67.pdf','2028-08-24 16:52:50'),(198,589,15,3,'AADHAAR0000000068','KYC/68.pdf','2028-08-24 16:52:50'),(199,590,16,4,'PAN0000000069','KYC/69.pdf','2028-08-24 16:52:50'),(200,591,17,5,'AADHAAR0000000070','KYC/70.pdf','2028-08-24 16:52:50'),(201,592,18,6,'AADHAAR0000000071','KYC/71.pdf','2028-08-24 16:52:50'),(202,593,19,7,'PAN0000000072','KYC/72.pdf','2028-08-24 16:52:50'),(203,594,9,8,'AADHAAR0000000073','KYC/73.pdf','2028-08-24 16:52:50'),(204,595,10,9,'AADHAAR0000000074','KYC/74.pdf','2028-08-24 16:52:50'),(205,596,13,10,'PAN0000000075','KYC/75.pdf','2028-08-24 16:52:50'),(206,597,14,11,'AADHAAR0000000076','KYC/76.pdf','2028-08-24 16:52:50'),(207,598,15,12,'AADHAAR0000000077','KYC/77.pdf','2028-08-24 16:52:50'),(208,599,16,13,'PAN0000000078','KYC/78.pdf','2028-08-24 16:52:50'),(209,600,17,1,'AADHAAR0000000079','KYC/79.pdf','2028-08-24 16:52:50'),(210,601,18,2,'AADHAAR0000000080','KYC/80.pdf','2028-08-24 16:52:50'),(211,602,19,3,'PAN0000000081','KYC/81.pdf','2028-08-24 16:52:50'),(212,603,9,4,'AADHAAR0000000082','KYC/82.pdf','2028-08-24 16:52:50'),(213,604,10,5,'AADHAAR0000000083','KYC/83.pdf','2028-08-24 16:52:50'),(214,605,13,6,'PAN0000000084','KYC/84.pdf','2028-08-24 16:52:50'),(215,606,14,7,'AADHAAR0000000085','KYC/85.pdf','2028-08-24 16:52:50'),(216,607,15,8,'AADHAAR0000000086','KYC/86.pdf','2028-08-24 16:52:50'),(217,608,16,9,'PAN0000000087','KYC/87.pdf','2028-08-24 16:52:50'),(218,609,17,10,'AADHAAR0000000088','KYC/88.pdf','2028-08-24 16:52:50'),(219,610,18,11,'AADHAAR0000000089','KYC/89.pdf','2028-08-24 16:52:50'),(220,611,19,12,'PAN0000000090','KYC/90.pdf','2028-08-24 16:52:50'),(221,612,9,13,'AADHAAR0000000091','KYC/91.pdf','2028-08-24 16:52:50'),(222,613,10,1,'AADHAAR0000000092','KYC/92.pdf','2028-08-24 16:52:50'),(223,614,13,2,'PAN0000000093','KYC/93.pdf','2028-08-24 16:52:50'),(224,615,14,3,'AADHAAR0000000094','KYC/94.pdf','2028-08-24 16:52:50'),(225,616,15,4,'AADHAAR0000000095','KYC/95.pdf','2028-08-24 16:52:50'),(226,617,16,5,'PAN0000000096','KYC/96.pdf','2028-08-24 16:52:50'),(227,618,17,6,'AADHAAR0000000097','KYC/97.pdf','2028-08-24 16:52:50'),(228,619,18,7,'AADHAAR0000000098','KYC/98.pdf','2028-08-24 16:52:50'),(229,620,19,8,'PAN0000000099','KYC/99.pdf','2028-08-24 16:52:50'),(230,621,9,9,'AADHAAR0000000100','KYC/100.pdf','2028-08-24 16:52:50'),(231,622,10,10,'AADHAAR0000000101','KYC/101.pdf','2028-08-24 16:52:50'),(232,623,13,11,'PAN0000000102','KYC/102.pdf','2028-08-24 16:52:50'),(233,624,14,12,'AADHAAR0000000103','KYC/103.pdf','2028-08-24 16:52:50'),(234,625,15,13,'AADHAAR0000000104','KYC/104.pdf','2028-08-24 16:52:50'),(235,626,16,1,'PAN0000000105','KYC/105.pdf','2028-08-24 16:52:50'),(236,627,17,2,'AADHAAR0000000106','KYC/106.pdf','2028-08-24 16:52:50'),(237,628,18,3,'AADHAAR0000000107','KYC/107.pdf','2028-08-24 16:52:50'),(238,629,19,4,'PAN0000000108','KYC/108.pdf','2028-08-24 16:52:50'),(239,630,9,5,'AADHAAR0000000109','KYC/109.pdf','2028-08-24 16:52:50'),(240,631,10,6,'AADHAAR0000000110','KYC/110.pdf','2028-08-24 16:52:50'),(241,632,13,7,'PAN0000000111','KYC/111.pdf','2028-08-24 16:52:50'),(242,633,14,8,'AADHAAR0000000112','KYC/112.pdf','2028-08-24 16:52:50'),(243,634,15,9,'AADHAAR0000000113','KYC/113.pdf','2028-08-24 16:52:50'),(244,635,16,10,'PAN0000000114','KYC/114.pdf','2028-08-24 16:52:50'),(245,636,17,11,'AADHAAR0000000115','KYC/115.pdf','2028-08-24 16:52:50'),(246,637,18,12,'AADHAAR0000000116','KYC/116.pdf','2028-08-24 16:52:50'),(247,638,19,13,'PAN0000000117','KYC/117.pdf','2028-08-24 16:52:50'),(248,639,9,1,'AADHAAR0000000118','KYC/118.pdf','2028-08-24 16:52:50'),(249,640,10,2,'AADHAAR0000000119','KYC/119.pdf','2028-08-24 16:52:50'),(250,641,13,3,'PAN0000000120','KYC/120.pdf','2028-08-24 16:52:50'),(251,642,14,4,'AADHAAR0000000121','KYC/121.pdf','2028-08-24 16:52:50'),(252,643,15,5,'AADHAAR0000000122','KYC/122.pdf','2028-08-24 16:52:50'),(253,644,16,6,'PAN0000000123','KYC/123.pdf','2028-08-24 16:52:50'),(254,645,17,7,'AADHAAR0000000124','KYC/124.pdf','2028-08-24 16:52:50'),(255,646,18,8,'AADHAAR0000000125','KYC/125.pdf','2028-08-24 16:52:50'),(256,647,19,9,'PAN0000000126','KYC/126.pdf','2028-08-24 16:52:50'),(257,648,9,10,'AADHAAR0000000127','KYC/127.pdf','2028-08-24 16:52:50'),(258,649,10,11,'AADHAAR0000000128','KYC/128.pdf','2028-08-24 16:52:50'),(259,650,13,12,'PAN0000000129','KYC/129.pdf','2028-08-24 16:52:50'),(260,651,14,13,'AADHAAR0000000130','KYC/130.pdf','2028-08-24 16:52:50'),(261,652,15,1,'AADHAAR0000000131','KYC/131.pdf','2028-08-24 16:52:50'),(262,653,16,2,'PAN0000000132','KYC/132.pdf','2028-08-24 16:52:50'),(263,654,17,3,'AADHAAR0000000133','KYC/133.pdf','2028-08-24 16:52:50'),(264,655,18,4,'AADHAAR0000000134','KYC/134.pdf','2028-08-24 16:52:50'),(265,656,19,5,'PAN0000000135','KYC/135.pdf','2028-08-24 16:52:50'),(266,657,9,6,'AADHAAR0000000136','KYC/136.pdf','2028-08-24 16:52:50'),(267,658,10,7,'AADHAAR0000000137','KYC/137.pdf','2028-08-24 16:52:50'),(268,659,13,8,'PAN0000000138','KYC/138.pdf','2028-08-24 16:52:50'),(269,660,14,9,'AADHAAR0000000139','KYC/139.pdf','2028-08-24 16:52:50'),(270,661,15,10,'AADHAAR0000000140','KYC/140.pdf','2028-08-24 16:52:50'),(271,662,16,11,'PAN0000000141','KYC/141.pdf','2028-08-24 16:52:50'),(272,663,17,12,'AADHAAR0000000142','KYC/142.pdf','2028-08-24 16:52:50'),(273,664,18,13,'AADHAAR0000000143','KYC/143.pdf','2028-08-24 16:52:50'),(274,665,19,1,'PAN0000000144','KYC/144.pdf','2028-08-24 16:52:50'),(275,666,9,2,'AADHAAR0000000145','KYC/145.pdf','2028-08-24 16:52:50'),(276,667,10,3,'AADHAAR0000000146','KYC/146.pdf','2028-08-24 16:52:50'),(277,668,13,4,'PAN0000000147','KYC/147.pdf','2028-08-24 16:52:50'),(278,669,14,5,'AADHAAR0000000148','KYC/148.pdf','2028-08-24 16:52:50'),(279,670,15,6,'AADHAAR0000000149','KYC/149.pdf','2028-08-24 16:52:50'),(280,671,16,7,'PAN0000000150','KYC/150.pdf','2028-08-24 16:52:50'),(281,672,17,8,'AADHAAR0000000151','KYC/151.pdf','2028-08-24 16:52:50'),(282,673,18,9,'AADHAAR0000000152','KYC/152.pdf','2028-08-24 16:52:50'),(283,674,19,10,'PAN0000000153','KYC/153.pdf','2028-08-24 16:52:50'),(284,675,9,11,'AADHAAR0000000154','KYC/154.pdf','2028-08-24 16:52:50'),(285,676,10,12,'AADHAAR0000000155','KYC/155.pdf','2028-08-24 16:52:50'),(286,677,13,13,'PAN0000000156','KYC/156.pdf','2028-08-24 16:52:50'),(287,678,14,1,'AADHAAR0000000157','KYC/157.pdf','2028-08-24 16:52:50'),(288,679,15,2,'AADHAAR0000000158','KYC/158.pdf','2028-08-24 16:52:50'),(289,680,16,3,'PAN0000000159','KYC/159.pdf','2028-08-24 16:52:50'),(290,681,17,4,'AADHAAR0000000160','KYC/160.pdf','2028-08-24 16:52:50'),(291,682,18,5,'AADHAAR0000000161','KYC/161.pdf','2028-08-24 16:52:50'),(292,683,19,6,'PAN0000000162','KYC/162.pdf','2028-08-24 16:52:50'),(293,684,9,7,'AADHAAR0000000163','KYC/163.pdf','2028-08-24 16:52:50'),(294,685,10,8,'AADHAAR0000000164','KYC/164.pdf','2028-08-24 16:52:50'),(295,686,13,9,'PAN0000000165','KYC/165.pdf','2028-08-24 16:52:50'),(296,687,14,10,'AADHAAR0000000166','KYC/166.pdf','2028-08-24 16:52:50'),(297,688,15,11,'AADHAAR0000000167','KYC/167.pdf','2028-08-24 16:52:50'),(298,689,16,12,'PAN0000000168','KYC/168.pdf','2028-08-24 16:52:50'),(299,690,17,13,'AADHAAR0000000169','KYC/169.pdf','2028-08-24 16:52:50'),(300,691,18,1,'AADHAAR0000000170','KYC/170.pdf','2028-08-24 16:52:50'),(301,692,19,2,'PAN0000000171','KYC/171.pdf','2028-08-24 16:52:50'),(302,693,9,3,'AADHAAR0000000172','KYC/172.pdf','2028-08-24 16:52:50'),(303,694,10,4,'AADHAAR0000000173','KYC/173.pdf','2028-08-24 16:52:50'),(304,695,13,5,'PAN0000000174','KYC/174.pdf','2028-08-24 16:52:50'),(305,696,14,6,'AADHAAR0000000175','KYC/175.pdf','2028-08-24 16:52:50'),(306,697,15,7,'AADHAAR0000000176','KYC/176.pdf','2028-08-24 16:52:50'),(307,698,16,8,'PAN0000000177','KYC/177.pdf','2028-08-24 16:52:50'),(308,699,17,9,'AADHAAR0000000178','KYC/178.pdf','2028-08-24 16:52:50'),(309,700,18,10,'AADHAAR0000000179','KYC/179.pdf','2028-08-24 16:52:50'),(310,701,19,11,'PAN0000000180','KYC/180.pdf','2028-08-24 16:52:50'),(311,702,9,12,'AADHAAR0000000181','KYC/181.pdf','2028-08-24 16:52:50'),(312,703,10,13,'AADHAAR0000000182','KYC/182.pdf','2028-08-24 16:52:50'),(313,704,13,1,'PAN0000000183','KYC/183.pdf','2028-08-24 16:52:50'),(314,705,14,2,'AADHAAR0000000184','KYC/184.pdf','2028-08-24 16:52:50'),(315,706,15,3,'AADHAAR0000000185','KYC/185.pdf','2028-08-24 16:52:50'),(316,707,16,4,'PAN0000000186','KYC/186.pdf','2028-08-24 16:52:50'),(317,708,17,5,'AADHAAR0000000187','KYC/187.pdf','2028-08-24 16:52:50'),(318,709,18,6,'AADHAAR0000000188','KYC/188.pdf','2028-08-24 16:52:50'),(319,710,19,7,'PAN0000000189','KYC/189.pdf','2028-08-24 16:52:50'),(320,711,9,8,'AADHAAR0000000190','KYC/190.pdf','2028-08-24 16:52:50'),(321,712,10,9,'AADHAAR0000000191','KYC/191.pdf','2028-08-24 16:52:50'),(322,713,13,10,'PAN0000000192','KYC/192.pdf','2028-08-24 16:52:50'),(323,714,14,11,'AADHAAR0000000193','KYC/193.pdf','2028-08-24 16:52:50'),(324,715,15,12,'AADHAAR0000000194','KYC/194.pdf','2028-08-24 16:52:50'),(325,716,16,13,'PAN0000000195','KYC/195.pdf','2028-08-24 16:52:50'),(326,717,17,1,'AADHAAR0000000196','KYC/196.pdf','2028-08-24 16:52:50'),(327,718,18,2,'AADHAAR0000000197','KYC/197.pdf','2028-08-24 16:52:50'),(328,719,19,3,'PAN0000000198','KYC/198.pdf','2028-08-24 16:52:50'),(329,720,9,4,'AADHAAR0000000199','KYC/199.pdf','2028-08-24 16:52:50');
/*!40000 ALTER TABLE `dy_pg_kyc_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_rbac_permissions`
--

DROP TABLE IF EXISTS `dy_pg_rbac_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_rbac_permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `role_id` int DEFAULT NULL,
  `operation_id` int DEFAULT NULL,
  `component_id` int DEFAULT NULL,
  `description` varchar(150) DEFAULT NULL,
  `status` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_operation_id_data_idx` (`operation_id`),
  KEY `fk_role_id_data_idx` (`role_id`),
  KEY `fk_component_id_data_idx` (`component_id`),
  KEY `fk_status_id_idx` (`status`),
  CONSTRAINT `fk_component_id_data` FOREIGN KEY (`component_id`) REFERENCES `st_pg_components` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_operation_id_data` FOREIGN KEY (`operation_id`) REFERENCES `st_pg_operations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_id_data` FOREIGN KEY (`role_id`) REFERENCES `st_pg_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_status_id` FOREIGN KEY (`status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=302 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_rbac_permissions`
--

LOCK TABLES `dy_pg_rbac_permissions` WRITE;
/*!40000 ALTER TABLE `dy_pg_rbac_permissions` DISABLE KEYS */;
INSERT INTO `dy_pg_rbac_permissions` VALUES (1,1,1,1,'create pg',28),(2,1,1,2,'create floor',28),(3,1,1,3,'create bed',28),(4,1,1,4,'create room',28),(5,1,1,5,'create amenity',28),(6,1,1,6,'create invoice',28),(7,1,1,7,'create receipt',28),(8,1,1,8,'create payment',28),(9,1,1,9,'create user',28),(10,1,1,10,'create report',28),(11,1,1,11,'create document',28),(12,1,1,12,'create booking',28),(13,1,1,13,'create service request',28),(14,1,2,1,'view pg',28),(15,1,2,2,'view floor',28),(16,1,2,3,'view bed',28),(17,1,2,4,'view room',28),(18,1,2,5,'view amenity',28),(19,1,2,6,'view invoice',28),(20,1,2,7,'view receipt',28),(21,1,2,8,'view payment',28),(22,1,2,9,'view users',28),(23,1,2,10,'view reports',28),(24,1,2,11,'view documents',28),(25,1,2,12,'view bookings',28),(26,1,2,13,'view service requests',28),(28,1,3,1,'update pg',28),(29,1,3,2,'update floor',28),(30,1,3,3,'update bed',28),(31,1,3,4,'update room',28),(32,1,3,5,'update amenity',28),(33,1,3,6,'update invoice',28),(34,1,3,7,'update receipt',28),(35,1,3,8,'update payments',28),(36,1,3,9,'update users',28),(37,1,3,10,'update reports',28),(38,1,3,11,'update documents',28),(39,1,3,12,'update bookings',28),(40,1,3,13,'update service requests',28),(41,1,4,1,'delete pg',28),(42,1,4,2,'delete floor',28),(43,1,4,3,'delete bed',28),(44,1,4,4,'delete room',28),(45,1,4,5,'delete amenity',28),(46,1,4,6,'delete invoice',28),(47,1,4,7,'delete receipt',28),(48,1,4,8,'delete payments',28),(49,1,4,9,'delete users',28),(50,1,4,10,'delete reports',28),(51,1,4,11,'delete documents',28),(52,1,4,12,'delete bookings',28),(53,1,4,13,'delete service requests',28),(54,2,1,1,'create pg',28),(55,2,1,2,'create floor',28),(56,2,1,3,'create bed',28),(57,2,1,4,'create room',28),(58,2,1,5,'create amenity',28),(59,2,1,6,'create invoice',28),(60,2,1,7,'create receipt',28),(61,2,1,8,'create payments',28),(62,2,1,9,'create users',28),(63,2,1,10,'create reports',28),(64,2,1,11,'create documents',28),(65,2,1,12,'create bookings',28),(66,2,1,13,'create service requests',28),(67,2,2,1,'view pg',28),(68,2,2,2,'view floor',28),(69,2,2,3,'view bed',28),(70,2,2,4,'view room',28),(71,2,2,5,'view amenity',28),(72,2,2,6,'view invoice',28),(73,2,2,7,'view receipt',28),(74,2,2,8,'view payments',28),(75,2,2,9,'view users',28),(76,2,2,10,'view reports',28),(77,2,2,11,'view documents',28),(78,2,2,12,'view bookings',28),(79,2,2,13,'view service requests',28),(80,2,3,1,'update pg',28),(81,2,3,2,'update floor',28),(82,2,3,3,'update bed',28),(83,2,3,4,'update room',28),(84,2,3,5,'update amenity',28),(85,2,3,6,'update invoice',28),(86,2,3,7,'update receipt',28),(87,2,3,8,'update payments',28),(88,2,3,9,'update users',28),(89,2,3,10,'update reports',28),(90,2,3,11,'update documents',28),(91,2,3,12,'update bookings',28),(92,2,3,13,'update service requests',28),(93,2,4,1,'delete pg',28),(94,2,4,2,'delete floor',28),(95,2,4,3,'delete bed',28),(96,2,4,4,'delete room',28),(97,2,4,5,'delete amenity',28),(98,2,4,6,'delete invoice',28),(99,2,4,7,'delete receipt',28),(100,2,4,8,'delete payments',28),(101,2,4,9,'delete users',28),(102,2,4,10,'delete reports',28),(103,2,4,11,'delete documents',28),(104,2,4,12,'delete bookings',28),(105,2,4,13,'delete service requests',28),(106,3,1,1,'create pg',29),(107,3,1,2,'create floor',28),(108,3,1,3,'create bed',28),(109,3,1,4,'create room',28),(110,3,1,5,'create amenity',28),(111,3,1,6,'create invoice',28),(112,3,1,7,'create receipt',28),(113,3,1,8,'create payments',28),(114,3,1,9,'create users',28),(115,3,1,10,'create reports',28),(116,3,1,11,'create documents',28),(117,3,1,12,'create bookings',28),(118,3,1,13,'create service requests',28),(119,3,2,1,'view pg',28),(120,3,2,2,'view floor',28),(121,3,2,3,'view bed',28),(122,3,2,4,'view room',28),(123,3,2,5,'view amenity',28),(124,3,2,6,'view invoice',28),(125,3,2,7,'view receipt',28),(126,3,2,8,'view payments',28),(127,3,2,9,'view users',28),(128,3,2,10,'view reports',28),(129,3,2,11,'view documents',28),(130,3,2,12,'view bookings',28),(131,3,2,13,'view service requests',28),(132,3,3,1,'update pg',28),(133,3,3,2,'update floor',28),(134,3,3,3,'update bed',28),(135,3,3,4,'update room',28),(136,3,3,5,'update amenity',28),(137,3,3,6,'update invoice',28),(138,3,3,7,'update receipt',28),(139,3,3,8,'update payments',28),(140,3,3,9,'update users',28),(141,3,3,10,'update reports',29),(142,3,3,11,'update documents',28),(143,3,3,12,'update bookings',28),(144,3,3,13,'update service requests',28),(145,3,4,1,'delete pg',29),(146,3,4,2,'delete floor',28),(147,3,4,3,'delete bed',28),(148,3,4,4,'delete room',28),(149,3,4,5,'delete amenity',28),(150,3,4,6,'delete invoice',29),(151,3,4,7,'delete receipt',29),(152,3,4,8,'delete payments',29),(153,3,4,9,'delete users',29),(154,3,4,10,'delete reports',29),(155,3,4,11,'delete documents',29),(156,3,4,12,'delete bookings',29),(157,3,4,13,'delete service requests',29),(158,4,1,1,'create pg',29),(159,4,1,2,'create floor',29),(160,4,1,3,'create bed',29),(161,4,1,4,'create room',29),(162,4,1,5,'create amenity',29),(163,4,1,6,'create invoice',29),(164,4,1,7,'create receipt',29),(165,4,1,8,'create payments',28),(166,4,1,9,'create users',29),(167,4,1,10,'create reports',28),(168,4,1,11,'create documents',28),(169,4,1,12,'create bookings',29),(170,4,1,13,'create service requests',28),(171,4,2,1,'view pg',28),(172,4,2,2,'view floor',28),(173,4,2,3,'view bed',28),(174,4,2,4,'view room',28),(175,4,2,5,'view amenity',28),(176,4,2,6,'view invoice',28),(177,4,2,7,'view receipt',28),(178,4,2,8,'view payments',28),(179,4,2,9,'view users',29),(180,4,2,10,'view reports',28),(181,4,2,11,'view documents',28),(182,4,2,12,'view bookings',28),(183,4,2,13,'view service requests',28),(184,4,3,1,'update pg',29),(185,4,3,2,'update floor',29),(186,4,3,3,'update bed',29),(187,4,3,4,'update room',29),(188,4,3,5,'update amenity',29),(189,4,3,6,'update invoice',29),(190,4,3,7,'update receipt',29),(191,4,3,8,'update payments',29),(192,4,3,9,'update users',28),(193,4,3,10,'update reports',29),(194,4,3,11,'update documents',28),(195,4,3,12,'update bookings',29),(196,4,3,13,'update service requests',28),(197,4,4,1,'delete pg',29),(198,4,4,2,'delete floor',29),(199,4,4,3,'delete bed',29),(200,4,4,4,'delete room',29),(201,4,4,5,'delete amenity',29),(202,4,4,6,'delete invoice',29),(203,4,4,7,'delete receipt',29),(204,4,4,8,'delete payments',29),(205,4,4,9,'delete users',29),(206,4,4,10,'delete reports',29),(207,4,4,11,'delete documents',29),(208,4,4,12,'delete bookings',29),(209,4,4,13,'delete service requests',29),(210,5,1,1,'create pg',29),(211,5,1,2,'create floor',29),(212,5,1,3,'create bed',29),(213,5,1,4,'create room',29),(214,5,1,5,'create amenity',29),(215,5,1,6,'create invoice',29),(216,5,1,7,'create receipt',29),(217,5,1,8,'create payments',29),(218,5,1,9,'create users',29),(219,5,1,10,'create reports',29),(220,5,1,11,'create documents',29),(221,5,1,12,'create bookings',29),(222,5,1,13,'create service requests',29),(223,5,2,1,'view pg',28),(224,5,2,2,'view floor',28),(225,5,2,3,'view bed',28),(226,5,2,4,'view room',28),(227,5,2,5,'view amenity',28),(228,5,2,6,'view invoice',28),(229,5,2,7,'view receipt',28),(230,5,2,8,'view payments',28),(231,5,2,9,'view users',28),(232,5,2,10,'view reports',28),(233,5,2,11,'view documents',28),(234,5,2,12,'view bookings',28),(235,5,2,13,'view service requests',28),(236,5,3,1,'update pg',29),(237,5,3,2,'update floor',29),(238,5,3,3,'update bed',29),(239,5,3,4,'update room',29),(240,5,3,5,'update amenity',29),(241,5,3,6,'update invoice',29),(242,5,3,7,'update receipt',29),(243,5,3,8,'update payments',29),(244,5,3,9,'update users',29),(245,5,3,10,'update reports',29),(246,5,3,11,'update documents',29),(247,5,3,12,'update bookings',29),(248,5,3,13,'update service requests',28),(249,5,4,1,'delete pg',29),(250,5,4,2,'delete floor',29),(251,5,4,3,'delete bed',29),(252,5,4,4,'delete room',29),(253,5,4,5,'delete amenity',29),(254,5,4,6,'delete invoice',29),(255,5,4,7,'delete receipt',29),(256,5,4,8,'delete payments',29),(257,5,4,9,'delete users',29),(258,5,4,10,'delete reports',29),(259,5,4,11,'delete documents',29),(260,5,4,12,'delete bookings',29),(261,5,4,13,'delete service requests',29),(262,1,1,14,'create event',28),(263,1,1,15,'create alert',28),(264,1,2,14,'view event',28),(265,1,2,15,'view alert',28),(266,1,3,14,'update event',28),(267,1,3,15,'update alert',28),(268,1,4,14,'delete event',28),(269,1,4,15,'delete alert',28),(270,2,1,14,'create event',28),(271,2,1,15,'create alert',28),(272,2,2,14,'view event',28),(273,2,2,15,'view alert',28),(274,2,3,14,'update event',28),(275,2,3,15,'update alert',28),(276,2,4,14,'delete event',28),(277,2,4,15,'delete alert',28),(278,3,1,14,'create event',28),(279,3,1,15,'create alert',28),(280,3,2,14,'view event',28),(281,3,2,15,'view alert',28),(282,3,3,14,'update event',28),(283,3,3,15,'update alert',28),(284,3,4,14,'delete event',28),(285,3,4,15,'delete alert',28),(286,4,1,14,'create event',29),(287,4,1,15,'create alert',29),(288,4,2,14,'view event',28),(289,4,2,15,'view alert',28),(290,4,3,14,'update event',29),(291,4,3,15,'update alert',29),(292,4,4,14,'delete event',29),(293,4,4,15,'delete alert',29),(294,5,1,14,'create event',29),(295,5,1,15,'create alert',29),(296,5,2,14,'view event',28),(297,5,2,15,'view alert',28),(298,5,3,14,'update event',29),(299,5,3,15,'update alert',29),(300,5,4,14,'delete event',29),(301,5,4,15,'delete alert',29);
/*!40000 ALTER TABLE `dy_pg_rbac_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_requests`
--

DROP TABLE IF EXISTS `dy_pg_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pg_info` int DEFAULT NULL,
  `user_info` int DEFAULT NULL,
  `pg_status` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_req_new_pg_idx` (`pg_info`),
  KEY `fk_pg_req_new_status_idx` (`pg_status`),
  KEY `fk_pg_req_new_user_idx` (`user_info`),
  CONSTRAINT `fk_pg_req_new_pg` FOREIGN KEY (`pg_info`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_req_new_status` FOREIGN KEY (`pg_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_req_new_user` FOREIGN KEY (`user_info`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_requests`
--

LOCK TABLES `dy_pg_requests` WRITE;
/*!40000 ALTER TABLE `dy_pg_requests` DISABLE KEYS */;
INSERT INTO `dy_pg_requests` VALUES (1,10,10,4);
/*!40000 ALTER TABLE `dy_pg_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_room_info`
--

DROP TABLE IF EXISTS `dy_pg_room_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_room_info` (
  `id` int NOT NULL AUTO_INCREMENT,
  `room_name` varchar(20) DEFAULT NULL,
  `pg_info` int DEFAULT NULL,
  `room_type` int DEFAULT NULL,
  `bathroom_type` int DEFAULT NULL,
  `floor_info` int DEFAULT NULL,
  `has_tv` tinyint DEFAULT NULL,
  `has_ac` tinyint DEFAULT NULL,
  `has_balcony` tinyint DEFAULT NULL,
  `room_create_time` datetime DEFAULT NULL,
  `room_updated_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_bathroom_type_id_idx` (`bathroom_type`),
  KEY `fk_floor_info_id_idx` (`floor_info`),
  KEY `fk_pg_info_id_idx` (`pg_info`),
  KEY `fk_room_type_id_idx` (`room_type`),
  CONSTRAINT `fk_bathroom_type_id` FOREIGN KEY (`bathroom_type`) REFERENCES `st_pg_baths` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_floor_info_id` FOREIGN KEY (`floor_info`) REFERENCES `st_pg_floors` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_info_id` FOREIGN KEY (`pg_info`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_room_type_id` FOREIGN KEY (`room_type`) REFERENCES `st_pg_room_type` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=533 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_room_info`
--

LOCK TABLES `dy_pg_room_info` WRITE;
/*!40000 ALTER TABLE `dy_pg_room_info` DISABLE KEYS */;
INSERT INTO `dy_pg_room_info` VALUES (278,'F1-R05-PG009',9,2,1,1,1,1,0,'2026-08-24 15:48:26','2026-08-24 15:48:26'),(279,'F2-R05-PG009',9,2,1,2,1,1,1,'2026-08-24 15:48:26','2026-08-24 15:48:26'),(280,'F1-R04-PG009',9,1,2,1,0,1,1,'2026-08-24 15:48:26','2026-08-24 15:48:26'),(281,'F2-R04-PG009',9,1,2,2,0,1,0,'2026-08-24 15:48:26','2026-08-24 15:48:26');
/*!40000 ALTER TABLE `dy_pg_room_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_srv_reqs`
--

DROP TABLE IF EXISTS `dy_pg_srv_reqs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_srv_reqs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `requestor_info` int DEFAULT NULL,
  `request_assigned_to` int DEFAULT NULL,
  `service_title` varchar(45) DEFAULT NULL,
  `service_description` varchar(150) DEFAULT NULL,
  `request_create_date` datetime DEFAULT NULL,
  `request_eta_date` datetime DEFAULT NULL,
  `SLA` int DEFAULT NULL,
  `feedback` int DEFAULT NULL,
  `service_category` int DEFAULT NULL,
  `service_status` int DEFAULT NULL,
  `pg_id` int DEFAULT NULL,
  `feedback_summary` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_srv_new_assignee_idx` (`request_assigned_to`),
  KEY `fk_srv_new_category_idx` (`service_category`),
  KEY `fk_srv_new_feedback_idx` (`feedback`),
  KEY `fk_srv_new_pg_idx` (`pg_id`),
  KEY `fk_srv_new_requestor_idx` (`requestor_info`),
  KEY `fk_srv_new_status_idx` (`service_status`),
  CONSTRAINT `fk_srv_new_assignee` FOREIGN KEY (`request_assigned_to`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_srv_new_category` FOREIGN KEY (`service_category`) REFERENCES `st_pg_srv_cat` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_srv_new_feedback` FOREIGN KEY (`feedback`) REFERENCES `st_pg_experience_score` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_srv_new_pg` FOREIGN KEY (`pg_id`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_srv_new_requestor` FOREIGN KEY (`requestor_info`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_srv_new_status` FOREIGN KEY (`service_status`) REFERENCES `st_pg_cur_sts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=261 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_srv_reqs`
--

LOCK TABLES `dy_pg_srv_reqs` WRITE;
/*!40000 ALTER TABLE `dy_pg_srv_reqs` DISABLE KEYS */;
INSERT INTO `dy_pg_srv_reqs` VALUES (3,585,536,'Lockers Service Request 15','Demo lockers request generated for Green Valley Residency','2026-08-24 20:25:28','2026-09-01 00:25:28',4,5,7,13,9,'Service was so quick'),(135,779,644,'Aircondition Service Request 3','Demo aircondition request generated for Urban Nest Paradise','2026-08-24 20:25:28','2026-08-25 00:25:28',4,3,3,11,9,'Delayed service litttle bit'),(136,643,643,'Electrical Service Request 2','Demo electrical request generated for Urban Nest Paradise','2026-08-24 20:25:28','2026-08-25 00:25:28',4,2,2,12,9,'Did not solved the issue properly'),(137,642,642,'Plumbing Service Request 1','Demo plumbing request generated for Urban Nest Paradise','2026-08-24 20:25:28','2026-08-25 00:25:28',4,1,1,11,9,'i did not liked the service at all'),(258,779,645,'plumbing','plumbing','2026-09-10 18:42:23','2026-09-17 00:00:00',2,NULL,1,12,9,NULL),(259,779,656,'Power supply issue','Power is not coming in one plug','2026-09-11 12:32:51','2026-09-17 00:00:00',NULL,NULL,2,13,9,NULL),(260,779,597,'Tubelight is not working','Tubelight is not working','2026-09-17 05:39:19','2026-09-17 18:30:00',NULL,NULL,2,12,9,NULL);
/*!40000 ALTER TABLE `dy_pg_srv_reqs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_survey_results`
--

DROP TABLE IF EXISTS `dy_pg_survey_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_survey_results` (
  `id` int NOT NULL AUTO_INCREMENT,
  `guest_id` int DEFAULT NULL,
  `survey_item_id` int DEFAULT NULL,
  `experience_score` int DEFAULT NULL,
  `feedback_summary` varchar(200) DEFAULT NULL,
  `survey_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_survey_new_item_idx` (`survey_item_id`),
  KEY `fk_pg_survey_new_score_idx` (`experience_score`),
  KEY `fk_pg_survey_new_guest` (`guest_id`),
  CONSTRAINT `fk_pg_survey_new_guest` FOREIGN KEY (`guest_id`) REFERENCES `dy_pg_guest_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_survey_new_item` FOREIGN KEY (`survey_item_id`) REFERENCES `st_pg_survey_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_survey_new_score` FOREIGN KEY (`experience_score`) REFERENCES `st_pg_experience_score` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_survey_results`
--

LOCK TABLES `dy_pg_survey_results` WRITE;
/*!40000 ALTER TABLE `dy_pg_survey_results` DISABLE KEYS */;
/*!40000 ALTER TABLE `dy_pg_survey_results` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_pg_usr_map`
--

DROP TABLE IF EXISTS `dy_pg_usr_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_pg_usr_map` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `pg_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pg_map_new_pg_idx` (`pg_id`),
  KEY `fk_pg_map_new_user_idx` (`user_id`),
  CONSTRAINT `fk_pg_map_new_pg` FOREIGN KEY (`pg_id`) REFERENCES `dy_pg_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pg_map_new_user` FOREIGN KEY (`user_id`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=267 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_pg_usr_map`
--

LOCK TABLES `dy_pg_usr_map` WRITE;
/*!40000 ALTER TABLE `dy_pg_usr_map` DISABLE KEYS */;
INSERT INTO `dy_pg_usr_map` VALUES (6,779,9),(10,12,9),(11,720,9),(12,711,9),(13,702,9),(14,693,9),(15,684,9),(16,675,9),(17,666,9),(18,657,9),(19,648,9),(20,639,9),(21,630,9),(22,621,9),(23,612,9),(24,603,9),(25,594,9),(26,585,9),(27,576,9),(28,567,9),(29,558,9),(30,549,9),(31,540,9),(32,531,9),(33,10,9),(34,712,10),(35,703,10),(36,694,10),(37,685,10),(38,676,10),(39,667,10),(40,658,10),(41,649,10),(42,640,10),(43,631,10),(44,622,10),(45,613,10),(46,604,10),(47,595,10),(48,586,10),(49,577,10),(50,568,10),(51,559,10),(52,550,10),(53,541,10),(54,532,10),(55,12,10),(56,713,13),(57,704,13),(58,695,13),(59,686,13),(60,677,13),(61,668,13),(62,659,13),(63,650,13),(64,641,13),(65,632,13),(66,623,13),(67,614,13),(68,605,13),(69,596,13),(70,587,13),(71,578,13),(72,569,13),(73,560,13),(74,551,13),(75,542,13),(76,533,13),(77,524,13),(78,714,14),(79,705,14),(80,696,14),(81,687,14),(82,678,14),(83,669,14),(84,660,14),(85,651,14),(86,642,14),(87,633,14),(88,624,14),(89,615,14),(90,606,14),(91,597,14),(92,588,14),(93,579,14),(94,570,14),(95,561,14),(96,552,14),(97,543,14),(98,534,14),(99,525,14),(100,715,15),(101,706,15),(102,697,15),(103,688,15),(104,679,15),(105,670,15),(106,661,15),(107,652,15),(108,643,15),(109,634,15),(110,625,15),(111,616,15),(112,607,15),(113,598,15),(114,589,15),(115,580,15),(116,571,15),(117,562,15),(118,553,15),(119,544,15),(120,535,15),(121,526,15),(122,716,16),(123,707,16),(124,698,16),(125,689,16),(126,680,16),(127,671,16),(128,662,16),(129,653,16),(130,644,16),(131,635,16),(132,626,16),(133,617,16),(134,608,16),(135,599,16),(136,590,16),(137,581,16),(138,572,16),(139,563,16),(140,554,16),(141,545,16),(142,536,16),(143,527,16),(144,717,17),(145,708,17),(146,699,17),(147,690,17),(148,681,17),(149,672,17),(150,663,17),(151,654,17),(152,645,17),(153,636,17),(154,627,17),(155,618,17),(156,609,17),(157,600,17),(158,591,17),(159,582,17),(160,573,17),(161,564,17),(162,555,17),(163,546,17),(164,537,17),(165,528,17),(166,718,18),(167,709,18),(168,700,18),(169,691,18),(170,682,18),(171,673,18),(172,664,18),(173,655,18),(174,646,18),(175,637,18),(176,628,18),(177,619,18),(178,610,18),(179,601,18),(180,592,18),(181,583,18),(182,574,18),(183,565,18),(184,556,18),(185,547,18),(186,538,18),(187,529,18),(188,719,19),(189,710,19),(190,701,19),(191,692,19),(192,683,19),(193,674,19),(194,665,19),(195,656,19),(196,647,19),(197,638,19),(198,629,19),(199,620,19),(200,611,19),(201,602,19),(202,593,19),(203,584,19),(204,575,19),(205,566,19),(206,557,19),(207,548,19),(208,539,19),(209,530,19),(266,779,9);
/*!40000 ALTER TABLE `dy_pg_usr_map` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_receipts`
--

DROP TABLE IF EXISTS `dy_receipts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_receipts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `receipt_id` varchar(20) NOT NULL,
  `payment_id` int NOT NULL,
  `payment_datetime` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `receipt_id` (`receipt_id`),
  KEY `payment_id_fk_idx` (`payment_id`),
  CONSTRAINT `dy_receipt-fk_payment_id` FOREIGN KEY (`payment_id`) REFERENCES `dy_payments_info` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=774 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_receipts`
--

LOCK TABLES `dy_receipts` WRITE;
/*!40000 ALTER TABLE `dy_receipts` DISABLE KEYS */;
INSERT INTO `dy_receipts` VALUES (519,'REC-20260825-000777',777,'2026-08-25 16:56:05');
/*!40000 ALTER TABLE `dy_receipts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_user`
--

DROP TABLE IF EXISTS `dy_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `univ_user_id` varchar(70) DEFAULT NULL,
  `first_name` varchar(45) DEFAULT NULL,
  `last_name` varchar(45) DEFAULT NULL,
  `email_id` varchar(45) DEFAULT NULL,
  `mobile_no` varchar(15) DEFAULT NULL,
  `ref_code` varchar(10) DEFAULT NULL,
  `mobile_verified` tinyint DEFAULT NULL,
  `email_verified` tinyint DEFAULT NULL,
  `passwd` varchar(512) DEFAULT NULL,
  `signuptime` timestamp NULL DEFAULT NULL,
  `gender_id` int DEFAULT NULL,
  `last_updated` timestamp NULL DEFAULT NULL,
  `customer_id` varchar(45) DEFAULT NULL,
  `is_active` tinyint DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  `project_category` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `univ_user_id_UNIQUE` (`univ_user_id`),
  KEY `fk_gen_id_idx` (`gender_id`)
) ENGINE=InnoDB AUTO_INCREMENT=786 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_user`
--

LOCK TABLES `dy_user` WRITE;
/*!40000 ALTER TABLE `dy_user` DISABLE KEYS */;
INSERT INTO `dy_user` VALUES (10,'IzjwGjsa2zZOman0n8lishY5Slsh','anwar','sk ','anwar@gmail.com','7993599496',NULL,1,1,NULL,'2026-08-19 06:35:19',1,'2026-08-21 23:48:42',NULL,1,1,NULL),(12,'IAAJHir1q5LhLUA0XhNXt9wNvmHr','king','pin ','king@gmail.com','9912251419',NULL,1,1,NULL,'2026-08-19 22:03:22',1,'2026-08-19 22:03:22',NULL,1,1,NULL),(524,'23520cd71a5ee31c68b315f9effc9f660b939bdeab2d69fff8811cc99e39d49e','Arjun','Kumar','arjun.kumar001@gmail.com','9650000001','REF-000001',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000001',1,1,NULL),(525,'4adc908c4b8361925c221175c61b6d1291e5a11eee40ece3e6ffbd795fe72457','Priya','Sharma','priya.sharma002@gmail.com','9650000002','REF-000002',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000002',1,1,NULL),(526,'fc1e24d4594f7113edb93bb6377fa53093e5162ef95ff295bfeabf89cd854c19','Rahul','Reddy','rahul.reddy003@gmail.com','9650000003','REF-000003',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000003',1,1,NULL),(527,'de79dfd56242a491450561d99a060b74c398fd39842793de21da1526d68a6c84','Sneha','Patel','sneha.patel004@gmail.com','9650000004','REF-000004',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000004',1,1,NULL),(528,'ec44f28de3925cfbd4ae014e74ce0cbe390814b4a8e41d1c93f7ba4ffc89bd3a','Vikram','Rao','vikram.rao005@gmail.com','9650000005','REF-000005',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000005',1,1,NULL),(529,'43d334daaf6c7f57536c32a8f0ccc0d5e430e146a2313ac33752e8c0502263b6','Ananya','Verma','ananya.verma006@gmail.com','9650000006','REF-000006',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000006',1,1,NULL),(530,'1d708d4359ee9449224d4a88e30692f62306ddc7817111f18644a91b55b47099','Karthik','Singh','karthik.singh007@gmail.com','9650000007','REF-000007',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000007',1,1,NULL),(531,'adee851e46997560c06102524e5b5dea7b43076ffa094f526c6a1fb591fb9787','Pooja','Naidu','pooja.naidu008@gmail.com','9650000008','REF-000008',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000008',1,1,NULL),(532,'730767610318aad97279d8d2efc0cc1b6f33f4a08dfcec5ad3f2851ad4e5da70','Rohit','Gupta','rohit.gupta009@gmail.com','9650000009','REF-000009',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000009',1,1,NULL),(533,'e44b34c86341950ccb46481d0e63f24848485db45b66a30c7a9af44bc2502303','Divya','Iyer','divya.iyer010@gmail.com','9650000010','REF-000010',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000010',1,1,NULL),(534,'f27337a49581054be77d3cbae8da737e957eff67ac454cd06940bbf74bbae8a8','Aditya','Nair','aditya.nair011@gmail.com','9650000011','REF-000011',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000011',1,1,NULL),(535,'3b9580a5e3498d4085ff8f29e62c2964bad9f2c6c01c963c74474db58940ab2d','Meera','Das','meera.das012@gmail.com','9650000012','REF-000012',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000012',1,1,NULL),(536,'4443c16500084fc1e92affb63b14c3ff54eb4e0419b05bb4b3b9e37ba031eab7','Sanjay','Chowdary','sanjay.chowdary013@gmail.com','9650000013','REF-000013',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000013',1,1,NULL),(537,'418cd3e1b93429520ed973ba1d02e32924e8a6ef57fceb12e630ea5e272f5092','Kavya','Mishra','kavya.mishra014@gmail.com','9650000014','REF-000014',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000014',1,1,NULL),(538,'36116b4ef91355dd9932a718e58a15558c7df6a7069d1757aa57fccbed8f4573','Nikhil','Raju','nikhil.raju015@gmail.com','9650000015','REF-000015',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000015',1,1,NULL),(539,'a003422fc7374d31d41e5d1c18fe59e46409307e728ff7ef2d0083e7ac86232e','Swathi','Varma','swathi.varma016@gmail.com','9650000016','REF-000016',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000016',1,1,NULL),(540,'f8e6cda0da1ce6f360edeffc07bd4d422523bd2080fc44cc2cee59dbd22d6d17','Akhil','Krishna','akhil.krishna017@gmail.com','9650000017','REF-000017',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000017',1,1,NULL),(541,'41d2266ee39f8d08c5a9f5ee23a09e9896333c34f8d271427bcfd77cb4471684','Neha','Mehta','neha.mehta018@gmail.com','9650000018','REF-000018',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000018',1,1,NULL),(542,'a5324168fc8c8cdef8bdb5a3ad4afb698f60f67ae2cf417433f59d7858981235','Varun','Joshi','varun.joshi019@gmail.com','9650000019','REF-000019',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000019',1,1,NULL),(543,'afb812627d66e4f031810f20cc0fe381e39228d76444e0879441b634e0c04f41','Sravani','Agarwal','sravani.agarwal020@gmail.com','9650000020','REF-000020',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000020',1,1,NULL),(544,'005989181b7563cb59d9adcc3f0c5d5273f57b60f94ef9aadfef10e26d075a41','Arjun','Kumar','arjun.kumar021@gmail.com','9650000021','REF-000021',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000021',1,1,NULL),(545,'d3afcac30f8750ae42f95b45ac42b6c7c4f958b20e0acf3bcaa57e7fe192dae1','Priya','Sharma','priya.sharma022@gmail.com','9650000022','REF-000022',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000022',1,1,NULL),(546,'42c59a887dbc5489f27d551c987a4368fc9ed4928bb8d705b4bba41f384bf7ed','Rahul','Reddy','rahul.reddy023@gmail.com','9650000023','REF-000023',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000023',1,1,NULL),(547,'3130934465ed1995d47f3e9273e58b78239524ede35580481a766a7a67f18774','Sneha','Patel','sneha.patel024@gmail.com','9650000024','REF-000024',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000024',1,1,NULL),(548,'fd364cf25d9df89b249170e03a1b078db12c954952d1bc97509d25f3559e3830','Vikram','Rao','vikram.rao025@gmail.com','9650000025','REF-000025',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000025',1,1,NULL),(549,'dcbe140727c0b5c0a679ae3c9ca80c64628301c9636fcd1cf2e60eaacb31eb61','Ananya','Verma','ananya.verma026@gmail.com','9650000026','REF-000026',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000026',1,1,NULL),(550,'69d50c4ac676259313b74ac18e93d2ddd0545ded19a73682eb02ceb72a768b13','Karthik','Singh','karthik.singh027@gmail.com','9650000027','REF-000027',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000027',1,1,NULL),(551,'f3610a09ddbf8c1cb436facb784a868c4351b94ce94d56c1a784a77647d8d7cb','Pooja','Naidu','pooja.naidu028@gmail.com','9650000028','REF-000028',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000028',1,1,NULL),(552,'227dee5a3f822e65b3dd8154c55cfa7ebbb763fe5720f016706c455780fe158f','Rohit','Gupta','rohit.gupta029@gmail.com','9650000029','REF-000029',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000029',1,1,NULL),(553,'fd497d1bc073919429fe4a5f26a40c7db7b55ef888fc3fcdc7860d0b61edfeda','Divya','Iyer','divya.iyer030@gmail.com','9650000030','REF-000030',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000030',1,1,NULL),(554,'1d3fa2c3a7bfd5f010e652c00b7709bdaeb4cc7dd0a8a594387e1ba0675de342','Aditya','Nair','aditya.nair031@gmail.com','9650000031','REF-000031',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000031',1,1,NULL),(555,'c335fe8144f3f0104d2b1ea69ae6c4c5593d76d129da3747ab2b6c6720050bdf','Meera','Das','meera.das032@gmail.com','9650000032','REF-000032',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000032',1,1,NULL),(556,'d80b766aa289406144b7bca033223503dfd03da1a7876822c1019207246781fa','Sanjay','Chowdary','sanjay.chowdary033@gmail.com','9650000033','REF-000033',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000033',1,1,NULL),(557,'6d2d8f50316ac55e1f0ccef793b16573563f4d41080bc1bd95ed312da06aba50','Kavya','Mishra','kavya.mishra034@gmail.com','9650000034','REF-000034',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000034',1,1,NULL),(558,'8047a8ef5cfd97647343ec2953afc5832e1dd23bd09a54888be1b09bad9ccd09','Nikhil','Raju','nikhil.raju035@gmail.com','9650000035','REF-000035',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000035',1,1,NULL),(559,'ac574a933e7c00bfef405eb3ebddc85891f6edbe3788b6b34af03e9602956788','Swathi','Varma','swathi.varma036@gmail.com','9650000036','REF-000036',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000036',1,1,NULL),(560,'08321a684c74428cddec91059073dacd5877664d6c4b51d36729336ea4a725ca','Akhil','Krishna','akhil.krishna037@gmail.com','9650000037','REF-000037',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000037',1,1,NULL),(561,'f56aed61679df75dcf102aefe7829b43a08e31bd54e8992792e0eeb1691335f3','Neha','Mehta','neha.mehta038@gmail.com','9650000038','REF-000038',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000038',1,1,NULL),(562,'6d3b68b67414dba9f65ff91b461833fbcadcd0361f82deeecf034910ddffe089','Varun','Joshi','varun.joshi039@gmail.com','9650000039','REF-000039',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000039',1,1,NULL),(563,'768afaeb46a505c385d88380fe05061aed4ab36151865b1e4c2f64fd1e1bcf8b','Sravani','Agarwal','sravani.agarwal040@gmail.com','9650000040','REF-000040',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000040',1,1,NULL),(564,'69979d7480da286906377bf7920718152db1e480a3a9c7cd17fa3995a8551ab9','Arjun','Kumar','arjun.kumar041@gmail.com','9650000041','REF-000041',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000041',1,1,NULL),(565,'6a6a1f375d4754b9951b8e8d872707ab66b897d9aa0703ac0e987949b26f7fc7','Priya','Sharma','priya.sharma042@gmail.com','9650000042','REF-000042',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000042',1,1,NULL),(566,'ee48540cd081029ad5618fd3711bb0c724d7860bbad5e61e2ff7d73230e8b47c','Rahul','Reddy','rahul.reddy043@gmail.com','9650000043','REF-000043',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000043',1,1,NULL),(567,'bf5841e6adeca608ea2411b5e3d10d6da53907327b70a04ce2f13f8f069ce109','Sneha','Patel','sneha.patel044@gmail.com','9650000044','REF-000044',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000044',1,1,NULL),(568,'724ce6b119e9a6d94df7a229ac50781b57e375d27f8664283047404125f0baa0','Vikram','Rao','vikram.rao045@gmail.com','9650000045','REF-000045',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000045',1,1,NULL),(569,'9f4fa7022223bf229ff01e7866168618473962f2fbcf405c48c11e7700919b04','Ananya','Verma','ananya.verma046@gmail.com','9650000046','REF-000046',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000046',1,1,NULL),(570,'2bcbf22cb23e444d9e3761dc2fa8fdb8bc0ddd2dc244689e59e89f7bd923e747','Karthik','Singh','karthik.singh047@gmail.com','9650000047','REF-000047',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000047',1,1,NULL),(571,'64110002a0d713d16323f357d9884921344e4ca4f2e79fe9448900cbc9c2a76b','Pooja','Naidu','pooja.naidu048@gmail.com','9650000048','REF-000048',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000048',1,1,NULL),(572,'ad5150c56f7d85778499d3b67ae5d23064c2808d8aea12c343cd958c6df91414','Rohit','Gupta','rohit.gupta049@gmail.com','9650000049','REF-000049',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000049',1,1,NULL),(573,'f774290a8bf13da065dfafb0711e12230b64dfb856de4acee413856756957794','Divya','Iyer','divya.iyer050@gmail.com','9650000050','REF-000050',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000050',1,1,NULL),(574,'fb7b626598050dc55869ba1e704123c19c4f2d82f22ab980e67104ec1fdb1384','Aditya','Nair','aditya.nair051@gmail.com','9650000051','REF-000051',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000051',1,1,NULL),(575,'842fef8e423188880f8378b86b3e6de0fdabdcd3e876335e7e2d7719209e2575','Meera','Das','meera.das052@gmail.com','9650000052','REF-000052',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000052',1,1,NULL),(576,'a2f4cd0efc7318ad1ac90303223cc359eb94cbacca4eab41eed4385d3d730938','Sanjay','Chowdary','sanjay.chowdary053@gmail.com','9650000053','REF-000053',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000053',1,1,NULL),(577,'99b457ef47455a5d100fe403f8fff240b7b4788e3e5731624a88b43739678ffc','Kavya','Mishra','kavya.mishra054@gmail.com','9650000054','REF-000054',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000054',1,1,NULL),(578,'8f83427d73a3c4a9bfa5105124daa9528b8fe71c777e0222dca3e01c4a652709','Nikhil','Raju','nikhil.raju055@gmail.com','9650000055','REF-000055',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000055',1,1,NULL),(579,'8a9cd2a79a8483e768d6cc26916cf3858e5e16ec1a0c0c7d1a91d998529dfce0','Swathi','Varma','swathi.varma056@gmail.com','9650000056','REF-000056',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000056',1,1,NULL),(580,'b3dc6219fdeaed907b73ce8cbb51375852e7906d0d9b2f454d79eb0f4e43b4c7','Akhil','Krishna','akhil.krishna057@gmail.com','9650000057','REF-000057',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000057',1,1,NULL),(581,'5389c553379388a35ba8447f80df2344fe9ef4e6728f479bfac2752c1feeb753','Neha','Mehta','neha.mehta058@gmail.com','9650000058','REF-000058',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000058',1,1,NULL),(582,'d60efc3642c3858f981c51e6bbc982d4f4f508ad912a9fe62168ee7369d4878b','Varun','Joshi','varun.joshi059@gmail.com','9650000059','REF-000059',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000059',1,1,NULL),(583,'5dbf54c158b0f0302de21fdd97ccfedb490bc15ba05299dc3e27c1b00ac35dbb','Sravani','Agarwal','sravani.agarwal060@gmail.com','9650000060','REF-000060',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000060',1,1,NULL),(584,'d284646c1261474377eb57f2936ae5ffdf9411f2fb2d06770ee6ced454d83199','Arjun','Kumar','arjun.kumar061@gmail.com','9650000061','REF-000061',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000061',1,1,NULL),(585,'6c06662c8eca24fb037ad6c66fb482bac5063a70509025150190fa542678b99f','Priya','Sharma','priya.sharma062@gmail.com','9650000062','REF-000062',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000062',1,1,NULL),(586,'ba102012bf724817e2754f0fd0cfef683744458761616d1358ad94b1d4026d4a','Rahul','Reddy','rahul.reddy063@gmail.com','9650000063','REF-000063',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000063',1,1,NULL),(587,'4c633d9d105a492907ea8e80d7f1e3dea2211155248b5165407f624e708804b1','Sneha','Patel','sneha.patel064@gmail.com','9650000064','REF-000064',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000064',1,1,NULL),(588,'61bc130e3087b44ff2f3963bc04181d49c6fc4d87a915dfe29b081185c5c02cb','Vikram','Rao','vikram.rao065@gmail.com','9650000065','REF-000065',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000065',1,1,NULL),(589,'6d47b334b84bc863214ae4ca8316271be51df888fff18ca5392a12d05c7de4f4','Ananya','Verma','ananya.verma066@gmail.com','9650000066','REF-000066',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000066',1,1,NULL),(590,'00b94006c9502a322259632aeef2295a73c7e5acde6cecc301a1935138f33356','Karthik','Singh','karthik.singh067@gmail.com','9650000067','REF-000067',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000067',1,1,NULL),(591,'2b573dde900c5ddc476dd222a2e917297fecc0dc97a40d72c16fd9a487ccc647','Pooja','Naidu','pooja.naidu068@gmail.com','9650000068','REF-000068',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000068',1,1,NULL),(592,'d8c20b0c0794d212259aba37f12bef53bb969f471e63a54e6e59a5b1913d4a4d','Rohit','Gupta','rohit.gupta069@gmail.com','9650000069','REF-000069',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000069',1,1,NULL),(593,'a09ca19384af3c708f5e7f8ace96909154995c0947b0a3727a4f843d52aaea26','Divya','Iyer','divya.iyer070@gmail.com','9650000070','REF-000070',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000070',1,1,NULL),(594,'8c43eec333fe10a4c087c2306f729448f46f5a4a34c5bb165ef02cb1cac8ff28','Aditya','Nair','aditya.nair071@gmail.com','9650000071','REF-000071',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000071',1,1,NULL),(595,'5184699c60620f5b1346d266a5ea4d251637951771f60dd6eb00c62bedff924d','Meera','Das','meera.das072@gmail.com','9650000072','REF-000072',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000072',1,1,NULL),(596,'969ce654bc848faf7da091e420d8985b6b5afa4fca5c68412e232b57f6030a5c','Sanjay','Chowdary','sanjay.chowdary073@gmail.com','9650000073','REF-000073',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000073',1,1,NULL),(597,'04be52b358449ff5139f7a98b1ef28eb3dbc4f2bd89670b834ef9d88260f430c','Kavya','Mishra','kavya.mishra074@gmail.com','9650000074','REF-000074',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000074',1,1,NULL),(598,'61f85ae08dfff37d1b33ab49cfb45b10a9454cb6f0088f4488c2d96f96a6b7d0','Nikhil','Raju','nikhil.raju075@gmail.com','9650000075','REF-000075',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000075',1,1,NULL),(599,'f3b20fad18f8885e4e865eda70207cf411a08dc82c104a75d333aa6e027094ef','Swathi','Varma','swathi.varma076@gmail.com','9650000076','REF-000076',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000076',1,1,NULL),(600,'4ec3d980aca888315b6fe891ba14dee64ea8f423f7b5ab1fdfce17e22c4de959','Akhil','Krishna','akhil.krishna077@gmail.com','9650000077','REF-000077',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000077',1,1,NULL),(601,'b6c01d3449bc2323b7d3339caa06d7458f8ec3fabca556bd39c6ed19307b64d0','Neha','Mehta','neha.mehta078@gmail.com','9650000078','REF-000078',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000078',1,1,NULL),(602,'d76af82f273b00f7f380bea9b676acf63cc68bdf90a431c5705094672c92ef6f','Varun','Joshi','varun.joshi079@gmail.com','9650000079','REF-000079',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000079',1,1,NULL),(603,'bdbd900cc3075862156f65cdfa0a95d0d504a69326d7d3a58235fb32a5453048','Sravani','Agarwal','sravani.agarwal080@gmail.com','9650000080','REF-000080',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000080',1,1,NULL),(604,'a18a7149a503441d1d5c5c832a40e42ad948cfb443c4ca3951db590d490efe32','Arjun','Kumar','arjun.kumar081@gmail.com','9650000081','REF-000081',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000081',1,1,NULL),(605,'21fb99a40f4b4423239e00e194b48c99dc8337d8868b992171cb1c799f178cb4','Priya','Sharma','priya.sharma082@gmail.com','9650000082','REF-000082',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000082',1,1,NULL),(606,'f8803729e54bbb3e7582443059fdd0145d1c747e20de3d43e66db531dd154bd6','Rahul','Reddy','rahul.reddy083@gmail.com','9650000083','REF-000083',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000083',1,1,NULL),(607,'2751d7c3b2e5e56ecfba14e8a36a49ec633cac22330adb35fe702bd686fc7326','Sneha','Patel','sneha.patel084@gmail.com','9650000084','REF-000084',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000084',1,1,NULL),(608,'ac0bb4095e6d08c2c957129d82e8d64aa38307d74bdd192be7da6e9c80e66524','Vikram','Rao','vikram.rao085@gmail.com','9650000085','REF-000085',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000085',1,1,NULL),(609,'e4b7ced78ac8a847e8421df2cb01a763a66347f6c4415636a638bb999ae51742','Ananya','Verma','ananya.verma086@gmail.com','9650000086','REF-000086',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000086',1,1,NULL),(610,'a232cd0f2dab1515aa1922581eca01a39d6245e66e3fdc391f207eeb6a593ba1','Karthik','Singh','karthik.singh087@gmail.com','9650000087','REF-000087',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000087',1,1,NULL),(611,'53a5ca403214eae0eae468d1419d6c4ef0e35c4d5b8b2be082d2da726ba35ddd','Pooja','Naidu','pooja.naidu088@gmail.com','9650000088','REF-000088',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000088',1,1,NULL),(612,'3f63186fe1aaa08088c4d665e5a090fe20b5d30828ad39d7888d426d30c9731f','Rohit','Gupta','rohit.gupta089@gmail.com','9650000089','REF-000089',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000089',1,1,NULL),(613,'0a7dcb8305ab13d6faeec02e743ccee33c0a369dd75bb6bbd30b2c61cfe77710','Divya','Iyer','divya.iyer090@gmail.com','9650000090','REF-000090',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000090',1,1,NULL),(614,'6628b7df67035ca87b774521e11fe3a62fb279211cc60983d036ed17d44aaf44','Aditya','Nair','aditya.nair091@gmail.com','9650000091','REF-000091',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000091',1,1,NULL),(615,'d5bb14443bcec5f83b44d45a6351a7c4a83a5b36621863190df21fc3fe3a3437','Meera','Das','meera.das092@gmail.com','9650000092','REF-000092',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000092',1,1,NULL),(616,'bf0c996ff67acf4573f2b1ce4a7c065c76ad3d0b0b65321590387bb0d2e44d04','Sanjay','Chowdary','sanjay.chowdary093@gmail.com','9650000093','REF-000093',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000093',1,1,NULL),(617,'2f662216b104fbb1dfb9f240cb1b9a476af0b515d0a595e14ca2a1d2569bbe8b','Kavya','Mishra','kavya.mishra094@gmail.com','9650000094','REF-000094',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000094',1,1,NULL),(618,'a72013ee9148e8e08d6a0bcca1ae36d94c0cf3dc36d7f6e8565bdf0cccd84b77','Nikhil','Raju','nikhil.raju095@gmail.com','9650000095','REF-000095',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000095',1,1,NULL),(619,'1a0d38ca24c68128bd03f29c334535a514ed5c704109eaab58f3da1fdad5c11b','Swathi','Varma','swathi.varma096@gmail.com','9650000096','REF-000096',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000096',1,1,NULL),(620,'e24eb15f83c573590278bcbd6752221044e28e52dd881f1119ceccd57e591433','Akhil','Krishna','akhil.krishna097@gmail.com','9650000097','REF-000097',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000097',1,1,NULL),(621,'ce7234c187802b157482cd2773521031d93cf20bd8f5b95db6269b86f9d79621','Neha','Mehta','neha.mehta098@gmail.com','9650000098','REF-000098',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000098',1,1,NULL),(622,'25d57ea108ebd59d3e0537cb8dc91aa8611d5b282343fe7e12deb96614d7204f','Varun','Joshi','varun.joshi099@gmail.com','9650000099','REF-000099',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000099',1,1,NULL),(623,'85ede0d857b5f7f709bab3be782587c6b768d42ab89e2dacb9c365b60afbb81c','Sravani','Agarwal','sravani.agarwal100@gmail.com','9650000100','REF-000100',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000100',1,1,NULL),(624,'b88fa328ded33add5137f8f7064cb20c8a12a366e425c80ff1bc37aeaaa7aea9','Arjun','Kumar','arjun.kumar101@gmail.com','9650000101','REF-000101',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000101',1,1,NULL),(625,'ff060da61254153ea5479434649f033d8779a0b4696328232aa7ec6ab50a1a25','Priya','Sharma','priya.sharma102@gmail.com','9650000102','REF-000102',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000102',1,1,NULL),(626,'78d6c2381e83a587789941f5e4f3a844d386028048851eeada30176e36f0da21','Rahul','Reddy','rahul.reddy103@gmail.com','9650000103','REF-000103',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000103',1,1,NULL),(627,'c37dfcd9fe18096ba88206690f13d46b38db2d1770bf8fb9d2f83306cfe78b91','Sneha','Patel','sneha.patel104@gmail.com','9650000104','REF-000104',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000104',1,1,NULL),(628,'20fdac18d72c2debefd87056de841be3d9c3ef706531e4dec0c1234311f9502b','Vikram','Rao','vikram.rao105@gmail.com','9650000105','REF-000105',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000105',1,1,NULL),(629,'2a84c9afd077902badf6cf8e1ef1215d7fac2260b2ae0b101e51c314a27e56e5','Ananya','Verma','ananya.verma106@gmail.com','9650000106','REF-000106',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000106',1,1,NULL),(630,'46692f32e85a8b2564f9b2940012482ec5c6e44b1d4134f4c8bb88f9c63eebe9','Karthik','Singh','karthik.singh107@gmail.com','9650000107','REF-000107',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000107',1,1,NULL),(631,'8cd9c04797488a9e7ca3f47b237ae625dfd7bfb5cc934a3d98f2b5be47083c13','Pooja','Naidu','pooja.naidu108@gmail.com','9650000108','REF-000108',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000108',1,1,NULL),(632,'99a21e5c0a548952927a092d36ef63bb6c763e4e12ecb4ebbd5ac42a7e16fc17','Rohit','Gupta','rohit.gupta109@gmail.com','9650000109','REF-000109',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000109',1,1,NULL),(633,'6f5d84e87c31deadc745986bb3eb25f13797f47b6fd9b852c4b4f15caee923b3','Divya','Iyer','divya.iyer110@gmail.com','9650000110','REF-000110',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000110',1,1,NULL),(634,'c2ca0b15389a5a0c86ff313f0285ae53f89219e0ad28baea2ff138c0dbd0c558','Aditya','Nair','aditya.nair111@gmail.com','9650000111','REF-000111',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000111',1,1,NULL),(635,'66bd5d22aa90a4cab82b68a11bf281862554e44cf9b53065df65099e8616267f','Meera','Das','meera.das112@gmail.com','9650000112','REF-000112',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000112',1,1,NULL),(636,'c57ef2c7fa867dd8bccee5a472b4db69a09a1eabcd62c1b04c16f43ad0b080ea','Sanjay','Chowdary','sanjay.chowdary113@gmail.com','9650000113','REF-000113',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000113',1,1,NULL),(637,'ab768f034d6d27deabde46f1409ef9bc64f8c96f8e3b1a4aa82056b1e1099957','Kavya','Mishra','kavya.mishra114@gmail.com','9650000114','REF-000114',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000114',1,1,NULL),(638,'28e0519adaf6e55975353f385a8462d7fa9cd5f37210f35d568f8584b78e9f05','Nikhil','Raju','nikhil.raju115@gmail.com','9650000115','REF-000115',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000115',1,1,NULL),(639,'d0673df9131b14410bd2d7aed9b2e22cbff9e0641b20e425d2f425bb30e4241e','Swathi','Varma','swathi.varma116@gmail.com','9650000116','REF-000116',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000116',1,1,NULL),(640,'1bcd7ec37362e9167b9d3e7c38118a74291ebefaabb878b9f3822657480de806','Akhil','Krishna','akhil.krishna117@gmail.com','9650000117','REF-000117',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000117',1,1,NULL),(641,'daac23367e443261dd7e9c697d95031a2c59f88fd196d77091c9a10615673ffc','Neha','Mehta','neha.mehta118@gmail.com','9650000118','REF-000118',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000118',1,1,NULL),(642,'b90bd36ab607998bb0bd782f103ad57929bd723b65f5f93bd06a127b27d4fed4','Varun','Joshi','varun.joshi119@gmail.com','9650000119','REF-000119',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000119',1,1,NULL),(643,'6222a6d6b57918d0f3d1a552d7352b3bed542f73090ed429e140b46c248c1cc0','Sravani','Agarwal','sravani.agarwal120@gmail.com','9650000120','REF-000120',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000120',1,1,NULL),(644,'91dadd97013e9773479ae206a275411a913294e78e5030be343dc83572bf5624','Arjun','Kumar','arjun.kumar121@gmail.com','9650000121','REF-000121',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000121',1,1,NULL),(645,'187db6d958356a98fd399d12b78e6043b10c1b2b9a278a041f708291927f6fff','Priya','Sharma','priya.sharma122@gmail.com','9650000122','REF-000122',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000122',1,1,NULL),(646,'757f623a54ba1e873bc841876d41492badd1153946a9a165656b9fa7d1fc9ff6','Rahul','Reddy','rahul.reddy123@gmail.com','9650000123','REF-000123',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000123',1,1,NULL),(647,'15e985ad4f23443fe1c724b2c10efd4f2dcb32374b5abaeba7b220c54bb2df5a','Sneha','Patel','sneha.patel124@gmail.com','9650000124','REF-000124',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000124',1,1,NULL),(648,'181ad59c7a3aa9ec857ce21f4cdc902df02986e6d292cdbcb9584adc3aab2e99','Vikram','Rao','vikram.rao125@gmail.com','9650000125','REF-000125',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000125',1,1,NULL),(649,'275961f07e8bdee938eed70ad04bab8056b31a2845a0d589226cc0321baab133','Ananya','Verma','ananya.verma126@gmail.com','9650000126','REF-000126',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000126',1,1,NULL),(650,'16504ad48b898eb4c2af5614e7bfe8f148387ed569b0dcd6e5bf1221053cc981','Karthik','Singh','karthik.singh127@gmail.com','9650000127','REF-000127',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000127',1,1,NULL),(651,'8a1b6518c86dd6557dc0f0b25d39343fcb73192c59a16878ac93e6c494b6788b','Pooja','Naidu','pooja.naidu128@gmail.com','9650000128','REF-000128',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000128',1,1,NULL),(652,'de1c314aeab2cf6287979429dcc969a58b59299d6aed6731491ef54b0b6c16fa','Rohit','Gupta','rohit.gupta129@gmail.com','9650000129','REF-000129',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000129',1,1,NULL),(653,'e90e886db94927b97d3f8680cd2b42ff60be7d6b23bed5f2763aee42f2200270','Divya','Iyer','divya.iyer130@gmail.com','9650000130','REF-000130',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000130',1,1,NULL),(654,'8b906bd4d48324a3992e2aab4f057993ddc1b82f944a6461022149596749511f','Aditya','Nair','aditya.nair131@gmail.com','9650000131','REF-000131',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000131',1,1,NULL),(655,'bcccf9753b9eafb3704717ee5e8e3aecea1d02e79510f3c16c2668da69beeb71','Meera','Das','meera.das132@gmail.com','9650000132','REF-000132',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000132',1,1,NULL),(656,'05b51aa20be9ffef95631b31894d75683aaaeb224b6be994593a305af598ee38','Sanjay','Chowdary','sanjay.chowdary133@gmail.com','9650000133','REF-000133',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000133',1,1,NULL),(657,'fbeadf087d8c59f2cfbfe836d72a2a65c5336189fca773cc402917b63fcffb9f','Kavya','Mishra','kavya.mishra134@gmail.com','9650000134','REF-000134',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000134',1,1,NULL),(658,'83edd77811b87343128228167be22cff4a0b9aba2be1aeed58a9269e58cc87d5','Nikhil','Raju','nikhil.raju135@gmail.com','9650000135','REF-000135',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000135',1,1,NULL),(659,'1d1e18635fa2e61aff942fc174f3b47433660e496d9f758dcb1a40920b1ffd6e','Swathi','Varma','swathi.varma136@gmail.com','9650000136','REF-000136',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000136',1,1,NULL),(660,'f66d43e1369cee23bfd0c541d46d3d1d8b4780cc8e6d834a7030bad7f1e77e03','Akhil','Krishna','akhil.krishna137@gmail.com','9650000137','REF-000137',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000137',1,1,NULL),(661,'a557b4b782be1a1d326d48564e896a0f7213b51d507d3fcc813b87af064a3607','Neha','Mehta','neha.mehta138@gmail.com','9650000138','REF-000138',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000138',1,1,NULL),(662,'b2ada72968a337cf185358a2d8417b87503ab13b0877fab1caf5e4203bd392c2','Varun','Joshi','varun.joshi139@gmail.com','9650000139','REF-000139',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000139',1,1,NULL),(663,'4eaee4ebfd598bdf4b69d01060cf387993e32249407801b575a7365bc2720bd1','Sravani','Agarwal','sravani.agarwal140@gmail.com','9650000140','REF-000140',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000140',1,1,NULL),(664,'ef524f96bd56c30b438c293e1bb3e50c1dc839aadb4ce5a7718be09161eea157','Arjun','Kumar','arjun.kumar141@gmail.com','9650000141','REF-000141',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000141',1,1,NULL),(665,'52fe9d40ef6326eb43d74a42b77ed2bbe41a88f3c1be84df32ecade5309fe683','Priya','Sharma','priya.sharma142@gmail.com','9650000142','REF-000142',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000142',1,1,NULL),(666,'8207c7b0adda4f82584830face9d68f17e3822ea1fe8bcfc9f717fb3c1c335b9','Rahul','Reddy','rahul.reddy143@gmail.com','9650000143','REF-000143',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000143',1,1,NULL),(667,'7bb4e734d351b5328db426debcdf003ea1fd4fa8766b4f2330ce88a263c75b8c','Sneha','Patel','sneha.patel144@gmail.com','9650000144','REF-000144',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000144',1,1,NULL),(668,'5f4139f41ec029d6866e97de5ea8fd646d018f892ebe3c4b5ac43f2467d353f7','Vikram','Rao','vikram.rao145@gmail.com','9650000145','REF-000145',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000145',1,1,NULL),(669,'01d86191d9b0a1200b0dee3c3bcf645e5672b51d6510952299ded05e7c3d3c81','Ananya','Verma','ananya.verma146@gmail.com','9650000146','REF-000146',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000146',1,1,NULL),(670,'46ff4c5945dca8e2bb4f47a7bed49f797610f87b28cc11e714ebef1eea52365f','Karthik','Singh','karthik.singh147@gmail.com','9650000147','REF-000147',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000147',1,1,NULL),(671,'7d341e49bef7206195e2572c2513b5f9207792d847838370af8237a18034a6d6','Pooja','Naidu','pooja.naidu148@gmail.com','9650000148','REF-000148',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000148',1,1,NULL),(672,'5c89d4c30defccd1b9073f3f8282e69b08dc7d08cfcf2892f2733d13f79bbd48','Rohit','Gupta','rohit.gupta149@gmail.com','9650000149','REF-000149',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000149',1,1,NULL),(673,'a60a3f85eea14deb04803577b68de413bc15051f2e9c5bf6bb55e1aedb383a0b','Divya','Iyer','divya.iyer150@gmail.com','9650000150','REF-000150',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000150',1,1,NULL),(674,'a8b42047e306da03d1d63cbe310a3d8db076475e56ccdc04e5995109de2b3172','Aditya','Nair','aditya.nair151@gmail.com','9650000151','REF-000151',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000151',1,1,NULL),(675,'85a562dd9d86344cb14934ce9763b8d224f2414347e1188d899560bb534db3e2','Meera','Das','meera.das152@gmail.com','9650000152','REF-000152',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000152',1,1,NULL),(676,'5ed92cd580abef68d3878909e2ea4fa982e65596d0759882f31f97e36e3182e9','Sanjay','Chowdary','sanjay.chowdary153@gmail.com','9650000153','REF-000153',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000153',1,1,NULL),(677,'1bdfab7cca34ffebf8fc62a0240cc93a18e701276fe38540096d3fff181a45e9','Kavya','Mishra','kavya.mishra154@gmail.com','9650000154','REF-000154',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000154',1,1,NULL),(678,'eb60f03ccaefbcd63dfdf4c24456af5010e2971f3410891e70f9d59cac8be6c3','Nikhil','Raju','nikhil.raju155@gmail.com','9650000155','REF-000155',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000155',1,1,NULL),(679,'f0b245bfd58f3db28fb837234c5283241cfe25a6a7c8329231893dfd0f1d8f45','Swathi','Varma','swathi.varma156@gmail.com','9650000156','REF-000156',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000156',1,1,NULL),(680,'63a7aafc9c9c91a3090f2e114b27c87c26edbd0aca5bb1ad17a6e433f3bd7875','Akhil','Krishna','akhil.krishna157@gmail.com','9650000157','REF-000157',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000157',1,1,NULL),(681,'1e5bfbaa7d2ebeed79faf7bd45367a1cecf1a7670401db7220cf5ed9f70668f3','Neha','Mehta','neha.mehta158@gmail.com','9650000158','REF-000158',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000158',1,1,NULL),(682,'244b2a67b49481b05ba0efc1a626b60dee1081b1a1ac71a1d019b9be5a0d3d82','Varun','Joshi','varun.joshi159@gmail.com','9650000159','REF-000159',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000159',1,1,NULL),(683,'5b50e7a58215e1eb5fc2179f57fa0647ec22b6550771708d7e8288a91125e267','Sravani','Agarwal','sravani.agarwal160@gmail.com','9650000160','REF-000160',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000160',1,1,NULL),(684,'56ecae35680f2ae5630058d12a9abf9829346bd6336299260316a9918d85e933','Arjun','Kumar','arjun.kumar161@gmail.com','9650000161','REF-000161',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000161',1,1,NULL),(685,'0142e7e711c175ce123d2f9de4373b69fa8668e20a37a3385f9f1b7bca38e3e5','Priya','Sharma','priya.sharma162@gmail.com','9650000162','REF-000162',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000162',1,1,NULL),(686,'ccf94e49f38cbb7de878a0607ebf9b9ab0215ef4b2baac8e2f069d1507f3aeb1','Rahul','Reddy','rahul.reddy163@gmail.com','9650000163','REF-000163',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000163',1,1,NULL),(687,'ca34f9c6c88b8d5ae9f7e717deeb583df8310f8e92deb37a3f3f15ab18ea5daa','Sneha','Patel','sneha.patel164@gmail.com','9650000164','REF-000164',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000164',1,1,NULL),(688,'950c48538c4b4519ed27caf52b1191cb568594ba657ec0e149715971e7b34301','Vikram','Rao','vikram.rao165@gmail.com','9650000165','REF-000165',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000165',1,1,NULL),(689,'1fa0f5450e882593247919b5d73e9e6a3a8a5e78bb0eb6d7d720427d5d10efbe','Ananya','Verma','ananya.verma166@gmail.com','9650000166','REF-000166',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000166',1,1,NULL),(690,'ebf26ac6db72baac6c78042b435615122ff0e4543c1fbb90e803dea3cebbe0fa','Karthik','Singh','karthik.singh167@gmail.com','9650000167','REF-000167',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000167',1,1,NULL),(691,'04d7dd55784a85b37664026b13db218e0ae8cd50c33541e60af0fe555c2737be','Pooja','Naidu','pooja.naidu168@gmail.com','9650000168','REF-000168',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000168',1,1,NULL),(692,'ab5e46227c60375c284ea6728c42170e4fc09ca82fff87cf52bbab452346ebaf','Rohit','Gupta','rohit.gupta169@gmail.com','9650000169','REF-000169',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000169',1,1,NULL),(693,'2ed9a79e6b761d1a0b685ae04c7f505ce794b3519b75810ffc9e6948584be4d0','Divya','Iyer','divya.iyer170@gmail.com','9650000170','REF-000170',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000170',1,1,NULL),(694,'45ea8cfd4622738ee7959e03656d40584532e698212779db7dc04415e4e88211','Aditya','Nair','aditya.nair171@gmail.com','9650000171','REF-000171',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000171',1,1,NULL),(695,'72e6e0bce0b9ceacf8b594b7adc055d4615f28cf9fdbd975da81b6be0cd8354d','Meera','Das','meera.das172@gmail.com','9650000172','REF-000172',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000172',1,1,NULL),(696,'f98ec464d045474ba87a232be88cf4049939397f953d82d09e087d48db334363','Sanjay','Chowdary','sanjay.chowdary173@gmail.com','9650000173','REF-000173',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000173',1,1,NULL),(697,'e72eb9aa171c3934ebe72e43c408c009379c986eef73e3d14a8a7eb8942e8a8d','Kavya','Mishra','kavya.mishra174@gmail.com','9650000174','REF-000174',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000174',1,1,NULL),(698,'49662b6b6cbfbcaf91ca6ec29c4fa31742b513c6ed88a7e554425b3a24d384ec','Nikhil','Raju','nikhil.raju175@gmail.com','9650000175','REF-000175',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000175',1,1,NULL),(699,'7f4e1e84025f8b9ef2da0db2aff2b50a7f458e65e917a535cc08c20784dbde98','Swathi','Varma','swathi.varma176@gmail.com','9650000176','REF-000176',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000176',1,1,NULL),(700,'e151031fdec319744f8b50559d0a1d645759104c7355fb7516efa20ce6b34599','Akhil','Krishna','akhil.krishna177@gmail.com','9650000177','REF-000177',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000177',1,1,NULL),(701,'775c5a7b4fb8fb7597eb2a3961d1602d44e035fc476fdb74c63d3d46239014d2','Neha','Mehta','neha.mehta178@gmail.com','9650000178','REF-000178',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000178',1,1,NULL),(702,'c3153e57258ab3c6d7c8ce00b0f6a30d97f69e65e9306f8921a9466c6c8b0e33','Varun','Joshi','varun.joshi179@gmail.com','9650000179','REF-000179',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000179',1,1,NULL),(703,'ee191d46c573d04c95ced3765e78121bc5840e9e68c7337e0fd3cd61ceff373a','Sravani','Agarwal','sravani.agarwal180@gmail.com','9650000180','REF-000180',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000180',1,1,NULL),(704,'1eef9412336d0161d127228a0b3dad527219485b3372828c8fc178f2a88f86e9','Arjun','Kumar','arjun.kumar181@gmail.com','9650000181','REF-000181',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000181',1,1,NULL),(705,'316d47ce20cb4f137456304139bf1515b5beb85d28bea1493bf50f6f316e36b9','Priya','Sharma','priya.sharma182@gmail.com','9650000182','REF-000182',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000182',1,1,NULL),(706,'654a42baedaa05173d810b72667002ad0a7fac72b29c5e3b517f9b22d7902ace','Rahul','Reddy','rahul.reddy183@gmail.com','9650000183','REF-000183',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000183',1,1,NULL),(707,'b9f2a689732f90af9e7a0acc2c46cf2264fc4329cfc03b4427f809f281b46e02','Sneha','Patel','sneha.patel184@gmail.com','9650000184','REF-000184',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000184',1,1,NULL),(708,'0e1eef459559d7de6e2a9a6b04decc542c5e19cd5f33559aff2d7faf3aa5e39a','Vikram','Rao','vikram.rao185@gmail.com','9650000185','REF-000185',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000185',1,1,NULL),(709,'5ba90f772a23b24087141f05dbb347ec48e642122f250c3984d75e82ac1a1e6e','Ananya','Verma','ananya.verma186@gmail.com','9650000186','REF-000186',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000186',1,1,NULL),(710,'916d4de2cfb8967142b75368f7f477816cfab7238bbaa223a05942e50aefdd00','Karthik','Singh','karthik.singh187@gmail.com','9650000187','REF-000187',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000187',1,1,NULL),(711,'df9f3511a248717e36ca9ec64d2eb7850f044d9602efcc1aca14cda3976e13c3','Pooja','Naidu','pooja.naidu188@gmail.com','9650000188','REF-000188',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000188',1,1,NULL),(712,'09d0255dcd3d84cd58e98bb1e84ccbb5255b7113170bb8c3a18005f6d149df20','Rohit','Gupta','rohit.gupta189@gmail.com','9650000189','REF-000189',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000189',1,1,NULL),(713,'c4c4dfa183ed7691d58faa0e187fdac04e883366c587743b1c391bbade1d8fd8','Divya','Iyer','divya.iyer190@gmail.com','9650000190','REF-000190',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000190',1,1,NULL),(714,'6f3833025c3dc4f190666eb133cc49939c3e30abadcfd635a79c0d6714d09f36','Aditya','Nair','aditya.nair191@gmail.com','9650000191','REF-000191',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000191',1,1,NULL),(715,'77a8f1cf8527d9bf4cef666e461bbf138ef6945293f3bba3dd2e74e46ad72151','Meera','Das','meera.das192@gmail.com','9650000192','REF-000192',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000192',1,1,NULL),(716,'46baa5cfe18eb3cd38264ce9106b35a1c4b6d41b944d08ca996aa5530732ebfd','Sanjay','Chowdary','sanjay.chowdary193@gmail.com','9650000193','REF-000193',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000193',1,1,NULL),(717,'63302ff6ec197b87e5357d894571e86f0333f614dc943e47867a2666e0b28ff8','Kavya','Mishra','kavya.mishra194@gmail.com','9650000194','REF-000194',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000194',1,1,NULL),(718,'4ac8d2f65a91d9087209ee989ebc4f1cd1983db65e1f0dba917c2e45cc92f5b9','Nikhil','Raju','nikhil.raju195@gmail.com','9650000195','REF-000195',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000195',1,1,NULL),(719,'bc0f3fd7bb7ff3490ffeedb749e387e7d6de0ca87b5f84e877232ff3c143dc38','Swathi','Varma','swathi.varma196@gmail.com','9650000196','REF-000196',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',2,'2026-08-24 08:22:52','CUST-000196',1,1,NULL),(720,'a7cb89f647942dbbeaa5e164a30b0864be1a4462cfc92466713ddd936930f516','Akhil','Krishna','akhil.krishna197@gmail.com','9650000197','REF-000197',1,1,'$2b$10$REPLACE_WITH_YOUR_BCRYPT_HASH','2026-08-24 08:22:52',1,'2026-08-24 08:22:52','CUST-000197',1,1,NULL),(779,'TxpeGjWZy7QbvjGTV9G7Qsu7TAZ2','Shiva Kumar','Enduri','shivakumar52616@gmail.com','9912251451',NULL,1,1,NULL,'2026-08-25 10:21:02',1,'2026-08-27 12:41:18',NULL,1,1,NULL),(782,'97a0c45740da93e48f8fef8bca342498cd079003e6b20ff4b1c7a4b9c8af88ba','Abhishek','Sharma','danchikottudu@gmail.com','6789012345',NULL,NULL,NULL,NULL,'2026-08-30 23:45:35',1,'2026-08-30 23:45:35',NULL,1,1,NULL),(783,'e32a26be82ba28a5fe49ffa974bfeab0b5a71786c80cab02ee87644f2292d01d','Travis','Head','head@gmail.com','9912251454',NULL,NULL,NULL,NULL,'2026-08-31 08:50:19',1,'2026-08-31 08:50:19',NULL,1,1,NULL),(784,'37cd9e59d4cf7fa20e5fa783a89773fbfd9c7f91216ae0ae01f9dbbafa5e67c8','Josh','Hazelwood','josh@gmail.com','7788990099',NULL,NULL,NULL,NULL,'2026-09-12 00:25:52',1,'2026-09-12 00:25:52',NULL,1,1,NULL),(785,'f3bac3ad14fe527b5568df8872a1e17186c66a26cacd118d89c9e1ff5762d2de','Jaswanth','REddy','jas@gmail.com','8899007766',NULL,NULL,NULL,NULL,'2026-09-12 00:43:25',1,'2026-09-12 00:43:25',NULL,1,1,NULL);
/*!40000 ALTER TABLE `dy_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_user_profile`
--

DROP TABLE IF EXISTS `dy_user_profile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_user_profile` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `current_city` varchar(45) DEFAULT NULL,
  `conv_mode_id` int DEFAULT NULL,
  `alt_email_id` varchar(45) DEFAULT NULL,
  `alt_mobile_no` varchar(20) DEFAULT NULL,
  `allow_promotion_campaign` int DEFAULT NULL,
  `Interests` tinytext,
  `last_updated` datetime DEFAULT NULL,
  `is_active` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_profile_user_idx` (`user_id`),
  CONSTRAINT `fk_profile_user` FOREIGN KEY (`user_id`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=256 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_user_profile`
--

LOCK TABLES `dy_user_profile` WRITE;
/*!40000 ALTER TABLE `dy_user_profile` DISABLE KEYS */;
INSERT INTO `dy_user_profile` VALUES (1,544,'Mumbai',NULL,'alternate544@example.com','8000000544',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(2,590,'Hyderabad',NULL,'alternate590@example.com','8000000590',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(3,685,'Hyderabad',NULL,'alternate685@example.com','8000000685',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(4,669,'Mumbai',NULL,'alternate669@example.com','8000000669',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(5,597,'Vijayawada',NULL,'alternate597@example.com','8000000597',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(6,691,'Bengaluru',NULL,'alternate691@example.com','8000000691',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(7,656,'Bengaluru',NULL,'alternate656@example.com','8000000656',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(8,560,'Hyderabad',NULL,'alternate560@example.com','8000000560',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(9,712,'Vijayawada',NULL,'alternate712@example.com','8000000712',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(10,613,'Chennai',NULL,'alternate613@example.com','8000000613',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(11,708,'Chennai',NULL,'alternate708@example.com','8000000708',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(12,647,'Vijayawada',NULL,'alternate647@example.com','8000000647',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(13,650,'Hyderabad',NULL,'alternate650@example.com','8000000650',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(14,648,'Chennai',NULL,'alternate648@example.com','8000000648',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(15,645,'Hyderabad',NULL,'alternate645@example.com','8000000645',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(16,619,'Mumbai',NULL,'alternate619@example.com','8000000619',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(17,640,'Hyderabad',NULL,'alternate640@example.com','8000000640',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(18,677,'Vijayawada',NULL,'alternate677@example.com','8000000677',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(19,659,'Mumbai',NULL,'alternate659@example.com','8000000659',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(20,554,'Mumbai',NULL,'alternate554@example.com','8000000554',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(21,530,'Hyderabad',NULL,'alternate530@example.com','8000000530',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(22,681,'Bengaluru',NULL,'alternate681@example.com','8000000681',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(23,704,'Mumbai',NULL,'alternate704@example.com','8000000704',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(24,689,'Mumbai',NULL,'alternate689@example.com','8000000689',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(25,628,'Chennai',NULL,'alternate628@example.com','8000000628',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(26,605,'Hyderabad',NULL,'alternate605@example.com','8000000605',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(27,552,'Vijayawada',NULL,'alternate552@example.com','8000000552',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(28,524,'Mumbai',NULL,'alternate524@example.com','8000000524',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(29,682,'Vijayawada',NULL,'alternate682@example.com','8000000682',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(30,622,'Vijayawada',NULL,'alternate622@example.com','8000000622',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(31,607,'Vijayawada',NULL,'alternate607@example.com','8000000607',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(32,649,'Mumbai',NULL,'alternate649@example.com','8000000649',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(33,638,'Chennai',NULL,'alternate638@example.com','8000000638',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(34,629,'Mumbai',NULL,'alternate629@example.com','8000000629',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(35,591,'Bengaluru',NULL,'alternate591@example.com','8000000591',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(36,570,'Hyderabad',NULL,'alternate570@example.com','8000000570',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(37,693,'Chennai',NULL,'alternate693@example.com','8000000693',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(38,617,'Vijayawada',NULL,'alternate617@example.com','8000000617',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(39,547,'Vijayawada',NULL,'alternate547@example.com','8000000547',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(40,705,'Hyderabad',NULL,'alternate705@example.com','8000000705',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(41,538,'Chennai',NULL,'alternate538@example.com','8000000538',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(42,535,'Hyderabad',NULL,'alternate535@example.com','8000000535',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(43,612,'Vijayawada',NULL,'alternate612@example.com','8000000612',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(44,537,'Vijayawada',NULL,'alternate537@example.com','8000000537',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(45,541,'Bengaluru',NULL,'alternate541@example.com','8000000541',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(46,546,'Bengaluru',NULL,'alternate546@example.com','8000000546',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(47,529,'Mumbai',NULL,'alternate529@example.com','8000000529',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(48,536,'Bengaluru',NULL,'alternate536@example.com','8000000536',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(49,694,'Mumbai',NULL,'alternate694@example.com','8000000694',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(50,630,'Hyderabad',NULL,'alternate630@example.com','8000000630',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(51,716,'Bengaluru',NULL,'alternate716@example.com','8000000716',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(52,670,'Hyderabad',NULL,'alternate670@example.com','8000000670',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(53,698,'Chennai',NULL,'alternate698@example.com','8000000698',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(54,718,'Chennai',NULL,'alternate718@example.com','8000000718',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(55,525,'Hyderabad',NULL,'alternate525@example.com','8000000525',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(56,587,'Vijayawada',NULL,'alternate587@example.com','8000000587',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(57,663,'Chennai',NULL,'alternate663@example.com','8000000663',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(58,600,'Hyderabad',NULL,'alternate600@example.com','8000000600',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(59,595,'Hyderabad',NULL,'alternate595@example.com','8000000595',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(60,665,'Hyderabad',NULL,'alternate665@example.com','8000000665',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(61,581,'Bengaluru',NULL,'alternate581@example.com','8000000581',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(62,611,'Bengaluru',NULL,'alternate611@example.com','8000000611',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(63,684,'Mumbai',NULL,'alternate684@example.com','8000000684',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(64,683,'Chennai',NULL,'alternate683@example.com','8000000683',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(65,709,'Mumbai',NULL,'alternate709@example.com','8000000709',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(66,672,'Vijayawada',NULL,'alternate672@example.com','8000000672',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(67,583,'Chennai',NULL,'alternate583@example.com','8000000583',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(68,676,'Bengaluru',NULL,'alternate676@example.com','8000000676',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(69,668,'Chennai',NULL,'alternate668@example.com','8000000668',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(70,588,'Chennai',NULL,'alternate588@example.com','8000000588',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(71,598,'Chennai',NULL,'alternate598@example.com','8000000598',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(72,643,'Chennai',NULL,'alternate643@example.com','8000000643',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(73,717,'Vijayawada',NULL,'alternate717@example.com','8000000717',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(74,680,'Hyderabad',NULL,'alternate680@example.com','8000000680',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(75,571,'Bengaluru',NULL,'alternate571@example.com','8000000571',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(76,706,'Bengaluru',NULL,'alternate706@example.com','8000000706',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(77,614,'Mumbai',NULL,'alternate614@example.com','8000000614',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(78,635,'Hyderabad',NULL,'alternate635@example.com','8000000635',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(79,564,'Mumbai',NULL,'alternate564@example.com','8000000564',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(80,550,'Hyderabad',NULL,'alternate550@example.com','8000000550',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(81,565,'Hyderabad',NULL,'alternate565@example.com','8000000565',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(82,585,'Hyderabad',NULL,'alternate585@example.com','8000000585',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(83,557,'Vijayawada',NULL,'alternate557@example.com','8000000557',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(84,562,'Vijayawada',NULL,'alternate562@example.com','8000000562',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(85,589,'Mumbai',NULL,'alternate589@example.com','8000000589',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(86,714,'Mumbai',NULL,'alternate714@example.com','8000000714',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(87,633,'Chennai',NULL,'alternate633@example.com','8000000633',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(88,568,'Chennai',NULL,'alternate568@example.com','8000000568',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(89,695,'Hyderabad',NULL,'alternate695@example.com','8000000695',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(90,532,'Vijayawada',NULL,'alternate532@example.com','8000000532',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(91,646,'Bengaluru',NULL,'alternate646@example.com','8000000646',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(92,563,'Chennai',NULL,'alternate563@example.com','8000000563',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(93,701,'Bengaluru',NULL,'alternate701@example.com','8000000701',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(94,715,'Hyderabad',NULL,'alternate715@example.com','8000000715',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(95,626,'Bengaluru',NULL,'alternate626@example.com','8000000626',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(96,667,'Vijayawada',NULL,'alternate667@example.com','8000000667',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(97,671,'Bengaluru',NULL,'alternate671@example.com','8000000671',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(98,699,'Mumbai',NULL,'alternate699@example.com','8000000699',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(99,558,'Chennai',NULL,'alternate558@example.com','8000000558',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(100,666,'Bengaluru',NULL,'alternate666@example.com','8000000666',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(101,658,'Chennai',NULL,'alternate658@example.com','8000000658',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(102,575,'Hyderabad',NULL,'alternate575@example.com','8000000575',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(103,675,'Hyderabad',NULL,'alternate675@example.com','8000000675',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(104,623,'Chennai',NULL,'alternate623@example.com','8000000623',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(105,651,'Bengaluru',NULL,'alternate651@example.com','8000000651',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(106,579,'Mumbai',NULL,'alternate579@example.com','8000000579',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(107,654,'Mumbai',NULL,'alternate654@example.com','8000000654',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(108,594,'Mumbai',NULL,'alternate594@example.com','8000000594',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(109,631,'Bengaluru',NULL,'alternate631@example.com','8000000631',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(110,578,'Chennai',NULL,'alternate578@example.com','8000000578',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(111,710,'Hyderabad',NULL,'alternate710@example.com','8000000710',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(112,644,'Mumbai',NULL,'alternate644@example.com','8000000644',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(113,688,'Chennai',NULL,'alternate688@example.com','8000000688',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(114,596,'Bengaluru',NULL,'alternate596@example.com','8000000596',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(115,632,'Vijayawada',NULL,'alternate632@example.com','8000000632',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(116,577,'Vijayawada',NULL,'alternate577@example.com','8000000577',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(117,569,'Mumbai',NULL,'alternate569@example.com','8000000569',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(118,539,'Mumbai',NULL,'alternate539@example.com','8000000539',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(119,593,'Chennai',NULL,'alternate593@example.com','8000000593',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(120,604,'Mumbai',NULL,'alternate604@example.com','8000000604',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(121,610,'Hyderabad',NULL,'alternate610@example.com','8000000610',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(122,576,'Bengaluru',NULL,'alternate576@example.com','8000000576',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(123,542,'Vijayawada',NULL,'alternate542@example.com','8000000542',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(124,661,'Bengaluru',NULL,'alternate661@example.com','8000000661',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(125,673,'Chennai',NULL,'alternate673@example.com','8000000673',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(126,618,'Chennai',NULL,'alternate618@example.com','8000000618',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(127,720,'Hyderabad',NULL,'alternate720@example.com','8000000720',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(128,674,'Mumbai',NULL,'alternate674@example.com','8000000674',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(129,692,'Vijayawada',NULL,'alternate692@example.com','8000000692',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(130,637,'Vijayawada',NULL,'alternate637@example.com','8000000637',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(131,608,'Chennai',NULL,'alternate608@example.com','8000000608',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(132,559,'Mumbai',NULL,'alternate559@example.com','8000000559',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(133,572,'Vijayawada',NULL,'alternate572@example.com','8000000572',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(134,531,'Bengaluru',NULL,'alternate531@example.com','8000000531',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(135,543,'Chennai',NULL,'alternate543@example.com','8000000543',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(136,662,'Vijayawada',NULL,'alternate662@example.com','8000000662',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(137,580,'Hyderabad',NULL,'alternate580@example.com','8000000580',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(138,601,'Bengaluru',NULL,'alternate601@example.com','8000000601',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(139,624,'Mumbai',NULL,'alternate624@example.com','8000000624',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(140,642,'Vijayawada',NULL,'alternate642@example.com','8000000642',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(141,707,'Vijayawada',NULL,'alternate707@example.com','8000000707',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(142,586,'Bengaluru',NULL,'alternate586@example.com','8000000586',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(143,719,'Mumbai',NULL,'alternate719@example.com','8000000719',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(144,655,'Hyderabad',NULL,'alternate655@example.com','8000000655',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(145,603,'Chennai',NULL,'alternate603@example.com','8000000603',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(146,616,'Bengaluru',NULL,'alternate616@example.com','8000000616',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(147,567,'Vijayawada',NULL,'alternate567@example.com','8000000567',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(148,634,'Mumbai',NULL,'alternate634@example.com','8000000634',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(149,702,'Vijayawada',NULL,'alternate702@example.com','8000000702',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(150,555,'Hyderabad',NULL,'alternate555@example.com','8000000555',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(151,627,'Vijayawada',NULL,'alternate627@example.com','8000000627',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(152,713,'Chennai',NULL,'alternate713@example.com','8000000713',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(153,636,'Bengaluru',NULL,'alternate636@example.com','8000000636',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(154,687,'Vijayawada',NULL,'alternate687@example.com','8000000687',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(155,686,'Bengaluru',NULL,'alternate686@example.com','8000000686',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(156,621,'Bengaluru',NULL,'alternate621@example.com','8000000621',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(157,639,'Mumbai',NULL,'alternate639@example.com','8000000639',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(158,584,'Mumbai',NULL,'alternate584@example.com','8000000584',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(159,545,'Hyderabad',NULL,'alternate545@example.com','8000000545',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(160,615,'Hyderabad',NULL,'alternate615@example.com','8000000615',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(161,582,'Vijayawada',NULL,'alternate582@example.com','8000000582',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(162,602,'Vijayawada',NULL,'alternate602@example.com','8000000602',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(163,556,'Bengaluru',NULL,'alternate556@example.com','8000000556',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(164,592,'Vijayawada',NULL,'alternate592@example.com','8000000592',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(165,641,'Bengaluru',NULL,'alternate641@example.com','8000000641',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(166,549,'Mumbai',NULL,'alternate549@example.com','8000000549',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(167,652,'Vijayawada',NULL,'alternate652@example.com','8000000652',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(168,527,'Vijayawada',NULL,'alternate527@example.com','8000000527',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(169,711,'Bengaluru',NULL,'alternate711@example.com','8000000711',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(170,700,'Hyderabad',NULL,'alternate700@example.com','8000000700',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(171,620,'Hyderabad',NULL,'alternate620@example.com','8000000620',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(172,533,'Chennai',NULL,'alternate533@example.com','8000000533',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(173,609,'Mumbai',NULL,'alternate609@example.com','8000000609',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(174,697,'Vijayawada',NULL,'alternate697@example.com','8000000697',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(175,653,'Chennai',NULL,'alternate653@example.com','8000000653',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(176,678,'Chennai',NULL,'alternate678@example.com','8000000678',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(177,690,'Hyderabad',NULL,'alternate690@example.com','8000000690',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(178,528,'Chennai',NULL,'alternate528@example.com','8000000528',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(179,703,'Chennai',NULL,'alternate703@example.com','8000000703',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(180,566,'Bengaluru',NULL,'alternate566@example.com','8000000566',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(181,664,'Mumbai',NULL,'alternate664@example.com','8000000664',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(182,679,'Mumbai',NULL,'alternate679@example.com','8000000679',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(183,534,'Mumbai',NULL,'alternate534@example.com','8000000534',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(184,551,'Bengaluru',NULL,'alternate551@example.com','8000000551',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(185,599,'Mumbai',NULL,'alternate599@example.com','8000000599',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(186,561,'Bengaluru',NULL,'alternate561@example.com','8000000561',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(187,660,'Hyderabad',NULL,'alternate660@example.com','8000000660',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(188,573,'Chennai',NULL,'alternate573@example.com','8000000573',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(189,606,'Bengaluru',NULL,'alternate606@example.com','8000000606',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(190,540,'Hyderabad',NULL,'alternate540@example.com','8000000540',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(191,696,'Bengaluru',NULL,'alternate696@example.com','8000000696',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(192,574,'Mumbai',NULL,'alternate574@example.com','8000000574',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(193,657,'Vijayawada',NULL,'alternate657@example.com','8000000657',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(194,526,'Bengaluru',NULL,'alternate526@example.com','8000000526',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(195,548,'Chennai',NULL,'alternate548@example.com','8000000548',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(196,553,'Chennai',NULL,'alternate553@example.com','8000000553',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(197,625,'Hyderabad',NULL,'alternate625@example.com','8000000625',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(198,12,'Vijayawada',NULL,'alternate12@example.com','8000000012',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1),(199,10,'Hyderabad',NULL,'alternate10@example.com','8000000010',1,'PG,Travel,Food,Technology','2026-08-24 14:41:56',1);
/*!40000 ALTER TABLE `dy_user_profile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dy_user_roles`
--

DROP TABLE IF EXISTS `dy_user_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dy_user_roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `role_id` int DEFAULT NULL,
  `is_active` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `dy_user_roles_ibfk_1_idx` (`user_id`),
  KEY `st_roles_ib_idx` (`role_id`),
  CONSTRAINT `dy_user_roles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `dy_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `st_roles_ib` FOREIGN KEY (`role_id`) REFERENCES `st_pg_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=266 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dy_user_roles`
--

LOCK TABLES `dy_user_roles` WRITE;
/*!40000 ALTER TABLE `dy_user_roles` DISABLE KEYS */;
INSERT INTO `dy_user_roles` VALUES (1,779,4,1),(3,12,2,1),(5,544,1,1),(6,590,1,1),(7,685,1,1),(8,669,2,1),(9,597,5,1),(10,691,4,1),(11,656,5,1),(12,560,3,1),(13,712,1,1),(14,613,4,1),(15,708,1,1),(16,647,2,1),(17,650,1,1),(18,648,1,1),(19,645,5,1),(20,619,2,1),(21,640,4,1),(22,677,2,1),(23,659,5,1),(24,554,2,1),(25,530,3,1),(26,681,2,1),(27,704,2,1),(28,689,2,1),(29,628,1,1),(30,605,5,1),(31,552,4,1),(32,524,1,1),(33,682,3,1),(34,622,5,1),(35,607,5,1),(36,649,5,1),(37,638,4,1),(38,629,2,1),(39,591,5,1),(40,570,4,1),(41,693,5,1),(42,617,1,1),(43,547,5,1),(44,705,3,1),(45,538,2,1),(46,535,1,1),(47,612,2,1),(48,537,3,1),(49,541,2,1),(50,546,2,1),(51,529,3,1),(52,536,5,1),(53,694,2,1),(54,630,3,1),(55,716,3,1),(56,670,3,1),(57,698,4,1),(58,718,3,1),(59,525,1,1),(60,587,3,1),(61,663,2,1),(62,600,4,1),(63,595,5,1),(64,665,1,1),(65,581,5,1),(66,611,5,1),(67,684,2,1),(68,683,2,1),(69,709,1,1),(70,672,3,1),(71,583,3,1),(72,676,5,1),(73,668,1,1),(74,588,3,1),(75,598,3,1),(76,643,2,1),(77,717,2,1),(78,680,5,1),(79,571,4,1),(80,706,1,1),(81,614,5,1),(82,635,4,1),(83,564,2,1),(84,550,2,1),(85,565,5,1),(86,585,1,1),(87,557,1,1),(88,562,4,1),(89,589,3,1),(90,714,3,1),(91,633,1,1),(92,568,3,1),(93,695,3,1),(94,532,5,1),(95,646,3,1),(96,563,5,1),(97,701,1,1),(98,715,4,1),(99,626,1,1),(100,667,1,1),(101,671,3,1),(102,699,5,1),(103,558,1,1),(104,666,4,1),(105,658,1,1),(106,575,4,1),(107,675,3,1),(108,623,5,1),(109,651,2,1),(110,579,1,1),(111,654,1,1),(112,594,4,1),(113,631,4,1),(114,578,2,1),(115,710,4,1),(116,644,3,1),(117,688,2,1),(118,596,1,1),(119,632,2,1),(120,577,2,1),(121,569,5,1),(122,539,3,1),(123,593,5,1),(124,604,3,1),(125,610,1,1),(126,576,2,1),(127,542,4,1),(128,661,5,1),(129,673,1,1),(130,618,4,1),(131,720,3,1),(132,674,2,1),(133,692,1,1),(134,637,3,1),(135,608,4,1),(136,559,3,1),(137,572,3,1),(138,531,4,1),(139,543,5,1),(140,662,3,1),(141,580,5,1),(142,601,2,1),(143,624,5,1),(144,642,2,1),(145,707,4,1),(146,586,3,1),(147,719,3,1),(148,655,3,1),(149,603,2,1),(150,616,2,1),(151,567,4,1),(152,634,4,1),(153,702,5,1),(154,555,5,1),(155,627,4,1),(156,713,5,1),(157,636,2,1),(158,687,4,1),(159,686,2,1),(160,621,5,1),(161,639,3,1),(162,584,2,1),(163,545,3,1),(164,615,1,1),(165,582,1,1),(166,602,3,1),(167,556,4,1),(168,592,4,1),(169,641,5,1),(170,549,5,1),(171,652,2,1),(172,527,5,1),(173,711,1,1),(174,700,2,1),(175,620,1,1),(176,533,1,1),(177,609,2,1),(178,697,4,1),(179,653,1,1),(180,678,2,1),(181,690,4,1),(182,528,5,1),(183,703,3,1),(184,566,2,1),(185,664,3,1),(186,679,4,1),(187,534,3,1),(188,551,5,1),(189,599,1,1),(190,561,4,1),(191,660,1,1),(192,573,2,1),(193,606,1,1),(194,540,1,1),(195,696,1,1),(196,574,3,1),(197,657,3,1),(198,526,3,1),(199,548,1,1),(200,553,4,1),(201,625,3,1),(262,782,4,NULL),(263,783,4,NULL),(264,784,4,NULL),(265,785,4,NULL);
/*!40000 ALTER TABLE `dy_user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_alert_priority`
--

DROP TABLE IF EXISTS `st_pg_alert_priority`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_alert_priority` (
  `id` int NOT NULL AUTO_INCREMENT,
  `priority` varchar(45) DEFAULT NULL,
  `priority_desc` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_alert_priority`
--

LOCK TABLES `st_pg_alert_priority` WRITE;
/*!40000 ALTER TABLE `st_pg_alert_priority` DISABLE KEYS */;
INSERT INTO `st_pg_alert_priority` VALUES (1,'Critical','critical'),(2,'Medium','medium'),(3,'Low','low');
/*!40000 ALTER TABLE `st_pg_alert_priority` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_alrt_cat`
--

DROP TABLE IF EXISTS `st_pg_alrt_cat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_alrt_cat` (
  `id` int NOT NULL AUTO_INCREMENT,
  `alert_category` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_alrt_cat`
--

LOCK TABLES `st_pg_alrt_cat` WRITE;
/*!40000 ALTER TABLE `st_pg_alrt_cat` DISABLE KEYS */;
INSERT INTO `st_pg_alrt_cat` VALUES (1,'billPayment'),(2,'lease'),(3,'agreement'),(4,'announcement'),(5,'maintenance'),(6,'notification'),(7,'miscellenous'),(8,'Maintenance');
/*!40000 ALTER TABLE `st_pg_alrt_cat` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_amns`
--

DROP TABLE IF EXISTS `st_pg_amns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_amns` (
  `id` int NOT NULL AUTO_INCREMENT,
  `amenity_name` varchar(75) DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_amns`
--

LOCK TABLES `st_pg_amns` WRITE;
/*!40000 ALTER TABLE `st_pg_amns` DISABLE KEYS */;
INSERT INTO `st_pg_amns` VALUES (1,'WashingMachine',1),(2,'CommonTV',1),(3,'Electricity',1),(4,'Water',1),(5,'Wifi',1),(6,'Laundry',1),(7,'HotWater',1),(8,'CommonRefrigerator',1),(9,'CommonMicrowave',1),(10,'CCTV Cameras',1),(11,'PowerBackup',1),(12,'ACRooms',1),(13,'Lift',1),(14,'2WheelerParkingSpace',1),(15,'CommonLounge',1),(16,'IndoorGames',1),(17,'Gym',1),(18,'Biometrics',1),(19,'HouseKeeping',1),(20,'RO Water',1),(21,'Beds',1),(22,'Blankets',1),(23,'Pillows',1),(24,'Mattresses',1),(25,'BedSheets',1),(26,'PillowCovers',1),(27,'WardrobesWithLockers',1),(28,'WorkTable',1),(29,'Chairs',1),(30,'CommonSofas',1),(31,'CommonDining',1),(32,'CommonKitchenAccess',1),(33,'Breakfast',1),(34,'Lunch',1),(35,'Dinner',1),(36,'Caretaker',1),(37,'AttachedWashRoom',1),(38,'CommonWashRoom',1),(39,'ShowerFacility',1),(40,'WesternToilets',1),(41,'IndianToilets',1),(42,'4WheelerParkingSpace',1),(43,'CommonLockers',1);
/*!40000 ALTER TABLE `st_pg_amns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_avblty`
--

DROP TABLE IF EXISTS `st_pg_avblty`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_avblty` (
  `id` int NOT NULL AUTO_INCREMENT,
  `availability` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_avblty`
--

LOCK TABLES `st_pg_avblty` WRITE;
/*!40000 ALTER TABLE `st_pg_avblty` DISABLE KEYS */;
INSERT INTO `st_pg_avblty` VALUES (1,'Immediately'),(2,'Within 15 days'),(3,'Within 1 month'),(4,'Beyond a month');
/*!40000 ALTER TABLE `st_pg_avblty` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_baths`
--

DROP TABLE IF EXISTS `st_pg_baths`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_baths` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nbaths` varchar(45) DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_baths`
--

LOCK TABLES `st_pg_baths` WRITE;
/*!40000 ALTER TABLE `st_pg_baths` DISABLE KEYS */;
INSERT INTO `st_pg_baths` VALUES (1,'Attached',1),(2,'Common',1),(11,'Attached',0);
/*!40000 ALTER TABLE `st_pg_baths` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_cat`
--

DROP TABLE IF EXISTS `st_pg_cat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_cat` (
  `id` int NOT NULL AUTO_INCREMENT,
  `category` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_cat`
--

LOCK TABLES `st_pg_cat` WRITE;
/*!40000 ALTER TABLE `st_pg_cat` DISABLE KEYS */;
INSERT INTO `st_pg_cat` VALUES (1,'economy'),(2,'standard'),(3,'premium'),(4,'elite'),(5,'Boys PG'),(6,'Boys PG'),(7,'Boys PG');
/*!40000 ALTER TABLE `st_pg_cat` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_chrgs`
--

DROP TABLE IF EXISTS `st_pg_chrgs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_chrgs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `charge` varchar(45) DEFAULT NULL,
  `chargegroup` varchar(45) DEFAULT NULL,
  `cost` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_chrgs`
--

LOCK TABLES `st_pg_chrgs` WRITE;
/*!40000 ALTER TABLE `st_pg_chrgs` DISABLE KEYS */;
INSERT INTO `st_pg_chrgs` VALUES (1,'bed','rental','7000'),(2,'electricity','common','300'),(3,'wifi','common','500'),(4,'water','common','200'),(5,'parking','common','200'),(6,'dth','common','100'),(7,'AC','common','500'),(8,'laundry','optional','500'),(9,'breakfast','optional','1000'),(10,'lunch','optional','1000'),(11,'Rent','Monthly','5000');
/*!40000 ALTER TABLE `st_pg_chrgs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_components`
--

DROP TABLE IF EXISTS `st_pg_components`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_components` (
  `id` int NOT NULL AUTO_INCREMENT,
  `component` varchar(45) DEFAULT NULL,
  `active` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_components`
--

LOCK TABLES `st_pg_components` WRITE;
/*!40000 ALTER TABLE `st_pg_components` DISABLE KEYS */;
INSERT INTO `st_pg_components` VALUES (1,'pg','1'),(2,'floor','1'),(3,'bed','1'),(4,'room','1'),(5,'amenity','1'),(6,'invoice','1'),(7,'receipt','1'),(8,'payment','1'),(9,'user','1'),(10,'report','1'),(11,'document','1'),(12,'book','1'),(13,'service_request','1'),(14,'events','1'),(15,'alerts','1');
/*!40000 ALTER TABLE `st_pg_components` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_ctys`
--

DROP TABLE IF EXISTS `st_pg_ctys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_ctys` (
  `id` int NOT NULL AUTO_INCREMENT,
  `city` varchar(45) DEFAULT NULL,
  `state_id` int DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=250 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_ctys`
--

LOCK TABLES `st_pg_ctys` WRITE;
/*!40000 ALTER TABLE `st_pg_ctys` DISABLE KEYS */;
INSERT INTO `st_pg_ctys` VALUES (1,'amaravati',1,1),(2,'vijaywada',1,1),(3,'guntur',1,1),(4,'elluru',1,1),(5,'tadipallegudam',1,1),(6,'nellore',1,1),(7,'ongole',1,1),(8,'Tirupati',1,1),(9,'cuddapah',1,1),(10,'vijaynagaram',1,1),(11,'visakhapatnam',1,1),(12,'srikakulam',1,1),(13,'narsapuram',1,1),(14,'narsaraopeta',1,1),(15,'bhivaram',1,1),(16,'tuni',1,1),(17,'anakapalli',1,1),(18,'rajahmundry',1,1),(19,'samalkota',1,1),(20,'kakinada',1,1),(21,'itanagar',2,1),(22,'eastsaing',2,1),(23,'tawang',2,1),(24,'seppo',2,1),(25,'aalo',2,1),(26,'daporijo',2,1),(27,'namsai',2,1),(28,'tezu',2,1),(29,'pasighat',2,1),(30,'naharlagun',2,1),(31,'dispur',3,1),(32,'tezpur',3,1),(33,'guwahati',3,1),(34,'dibrugarh',3,1),(35,'jorhat',3,1),(36,'silchar',3,1),(37,'karimganj',3,1),(38,'dhubri',3,1),(39,'nagaon',3,1),(40,'hojai',3,1),(41,'patna',4,1),(42,'gaya',4,1),(43,'vaishali',4,1),(44,'nalanda',4,1),(45,'madhubani',4,1),(46,'bhagalpur',4,1),(47,'rajgir',4,1),(48,'muzzafarpur',4,1),(49,'bodhgaya',4,1),(50,'chapra',4,1),(51,'raipur',5,1),(52,'bilaspur',5,1),(53,'bhilai',5,1),(54,'korba',5,1),(55,'rajnanndgaon',5,1),(56,'jagadalpur',5,1),(57,'ambikapur',5,1),(58,'dhamtari',5,1),(59,'mahasamund',5,1),(60,'champa',5,1),(61,'panaji',6,1),(62,'mapusa',6,1),(63,'madgoan',6,1),(64,'ponda',6,1),(65,'vascodagama',6,1),(66,'Vadodara',7,1),(67,'Rajkot',7,1),(68,'Ahmedabad',7,1),(69,'surat',7,1),(70,'jamnagar',7,1),(71,'bhavnagar',7,1),(72,'junagadh',7,1),(73,'porbandar',7,1),(74,'Gandhinagar',7,1),(75,'gurgoan',8,1),(76,'faridabad',8,1),(77,'karnal',8,1),(78,'panchkula',8,1),(79,'kaithal',8,1),(80,'bhiwani',8,1),(81,'rewari',8,1),(82,'sonipat',8,1),(83,'shimla',9,1),(84,'mandi',9,1),(85,'kullu',9,1),(86,'manali',9,1),(87,'bilaspur',9,1),(88,'chamba',9,1),(89,'dharamshala',9,1),(90,'solan',9,1),(91,'ranchi',11,1),(92,'dhanbad',11,1),(93,'bokaro city',11,1),(94,'deogarh',11,1),(95,'jamshedpur',11,1),(96,'giridh',11,1),(97,'hazaribagh',11,1),(98,'medininagar',11,1),(99,'ramgarhcantonment',11,1),(100,'chaibasa',11,1),(101,'Bengaluru',11,1),(102,'mangaluru',11,1),(103,'shivamoga',11,1),(104,'mysore',11,1),(105,'kalaburigi',11,1),(106,'udipi',11,1),(107,'ballari',11,1),(108,'davegere',11,1),(109,'tumakuru',11,1),(110,'raichur',11,1),(111,'kochi',12,1),(112,'thiruvananthpuram',12,1),(113,'khozikode',12,1),(114,'kollam',12,1),(115,'thrissur',12,1),(116,'kannur',12,1),(117,'mallapuram',12,1),(118,'allapuzha',12,1),(119,'palakkad',12,1),(120,'kottayam',12,1),(121,'Bhopal',13,1),(122,'Indore',13,1),(123,'Gwalior',13,1),(124,'ujjain',13,1),(125,'ratlam',13,1),(126,'rewa',13,1),(127,'jabalpur',13,1),(128,'sagar',13,1),(129,'satna',13,1),(130,'chindwara',13,1),(131,'Mumbai',14,1),(132,'pune',14,1),(133,'nagpur',14,1),(134,'aurangabad',14,1),(135,'nashik',14,1),(136,'kolhapur',14,1),(137,'amravati',14,1),(138,'solapur',14,1),(139,'thane',14,1),(140,'sangli',14,1),(141,'imphal',15,1),(142,'thoubal',15,1),(143,'shillong',16,1),(144,'tura',16,1),(145,'nongstoin',16,1),(146,'Aizawl',17,1),(147,'lunglei',17,1),(148,'serchipp',17,1),(149,'kohima',18,1),(150,'dimapur',18,1),(151,'tuensang',18,1),(152,'bhubaneswar',19,1),(153,'cuttack',19,1),(154,'brahmapur',19,1),(155,'puri',19,1),(156,'rourkela',19,1),(157,'barripada',19,1),(158,'balasore',19,1),(159,'bhadrak',19,1),(160,'sambalpur',19,1),(161,'jharsguda',19,1),(162,'koraput',19,1),(163,'amritsar',21,1),(164,'patiala',21,1),(165,'ludhaina',21,1),(166,'bhatinda',21,1),(167,'jalandhar',21,1),(168,'moga',21,1),(169,'kapurthala',21,1),(170,'hoshiarpur',21,1),(171,'sahibzada Ajit Singh Nagar',21,1),(172,'gurdaspur',21,1),(173,'barnala',21,1),(174,'jodhpur',21,1),(175,'udaipur',21,1),(176,'pali',21,1),(177,'bikaner',21,1),(178,'jaipur',21,1),(179,'ajmer',21,1),(180,'kota',21,1),(181,'sikar',21,1),(182,'alwar',21,1),(183,'bhilwara',21,1),(184,'sawaimadhopur',21,1),(185,'gangtok',22,1),(186,'namchi',22,1),(187,'rangpo',22,1),(188,'chennai',23,1),(189,'salem',23,1),(190,'madurai',23,1),(191,'coimbatore',23,1),(192,'thiruchapalli',23,1),(193,'kancheepuram',23,1),(194,'vellore',23,1),(195,'tiruppur',23,1),(196,'Thoothukudi',23,1),(197,'Secunderabad',24,1),(198,'Hyderabad',24,1),(199,'warangal',24,1),(200,'khammam',24,1),(201,'nizamabad',24,1),(202,'karimnagar',24,1),(203,'sirpurkagaznagar',24,1),(204,'siddipet',24,1),(205,'mahbubnagar',24,1),(206,'nalgonda',24,1),(207,'adilabad',24,1),(208,'suryapet',24,1),(209,'agartala',25,1),(210,'dharmanagar',25,1),(211,'Kailashahar',25,1),(212,'dehradun',26,1),(213,'rishikesh',26,1),(214,'nainital',26,1),(215,'mussorie',26,1),(216,'haridwar',26,1),(217,'almora',26,1),(218,'haldwani',26,1),(219,'roorkee',26,1),(220,'kashipur',26,1),(221,'lucknow',27,1),(222,'noida',27,1),(223,'agra',27,1),(224,'prayagraj',27,1),(225,'varnasi',27,1),(226,'kanpur',27,1),(227,'jhansi',27,1),(228,'ghaziabad',27,1),(229,'mathura',27,1),(230,'gorakhpur',27,1),(231,'meerut',27,1),(232,'philibit',27,1),(233,'kolkata',28,1),(234,'howrah',28,1),(235,'siliguri',28,1),(236,'asansol',28,1),(237,'malda',28,1),(238,'darjeeling',28,1),(239,'berhampur',28,1),(240,'kharagpur',28,1),(241,'eastmedinipur',28,1),(242,'westmedinipur',28,1),(243,'purabbardhaman',28,1),(244,'south24parganas',28,1),(245,'north24parganas',28,1),(246,'durgapur',28,1),(247,'haldia',28,1),(248,'NewDelhi',37,1),(249,'Bangalore',NULL,0);
/*!40000 ALTER TABLE `st_pg_ctys` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_cur_sts`
--

DROP TABLE IF EXISTS `st_pg_cur_sts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_cur_sts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `status_code` varchar(60) DEFAULT NULL,
  `rstatus` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_cur_sts`
--

LOCK TABLES `st_pg_cur_sts` WRITE;
/*!40000 ALTER TABLE `st_pg_cur_sts` DISABLE KEYS */;
INSERT INTO `st_pg_cur_sts` VALUES (1,'Review',1),(2,'Approved',1),(3,'Vacant',1),(4,'Reserved',1),(5,'Occupied',1),(6,'Joined',1),(7,'Departed',1),(8,'Cancelled',1),(9,'Available',1),(10,'Active',1),(11,'TicketRaised',1),(12,'TicketInProgress',1),(13,'TicketResolved',1),(15,'InvoiceNeeded',1),(16,'InvoiceGenerated',1),(18,'PaymentDue',1),(19,'Paid-Full',1),(21,'KycRequested',1),(22,'KycSubmitted',1),(23,'KycApproved',1),(24,'NoticeGiven',1),(25,'NoticeAccepted',1),(26,'InNoticePeriod',1),(27,'Paid-Partial',1),(28,'allowed',1),(29,'notallowed',1),(30,'in-active',1);
/*!40000 ALTER TABLE `st_pg_cur_sts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_description`
--

DROP TABLE IF EXISTS `st_pg_description`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_description` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pg_desc` varchar(30) DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_description`
--

LOCK TABLES `st_pg_description` WRITE;
/*!40000 ALTER TABLE `st_pg_description` DISABLE KEYS */;
INSERT INTO `st_pg_description` VALUES (1,'Un-Furnished',1),(2,'Semi-Furnished',1),(3,'Full-Furnished',1),(4,'Premium-Furnished',1),(5,'Fully Furnished',0);
/*!40000 ALTER TABLE `st_pg_description` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_experience_score`
--

DROP TABLE IF EXISTS `st_pg_experience_score`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_experience_score` (
  `id` int NOT NULL AUTO_INCREMENT,
  `experience` varchar(20) DEFAULT NULL,
  `score` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_experience_score`
--

LOCK TABLES `st_pg_experience_score` WRITE;
/*!40000 ALTER TABLE `st_pg_experience_score` DISABLE KEYS */;
INSERT INTO `st_pg_experience_score` VALUES (1,'Horrible',1),(2,'Inferior',2),(3,'Decent',3),(4,'Pleasant',4),(5,'Excellent',5);
/*!40000 ALTER TABLE `st_pg_experience_score` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_floors`
--

DROP TABLE IF EXISTS `st_pg_floors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_floors` (
  `id` int NOT NULL AUTO_INCREMENT,
  `floor` int DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_floors`
--

LOCK TABLES `st_pg_floors` WRITE;
/*!40000 ALTER TABLE `st_pg_floors` DISABLE KEYS */;
INSERT INTO `st_pg_floors` VALUES (1,1,1),(2,2,1),(3,3,1),(4,4,1),(5,5,1),(6,6,1),(7,7,1),(8,8,1),(9,9,1),(10,10,1),(11,1,0);
/*!40000 ALTER TABLE `st_pg_floors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_gen`
--

DROP TABLE IF EXISTS `st_pg_gen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_gen` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gender_type` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_gen`
--

LOCK TABLES `st_pg_gen` WRITE;
/*!40000 ALTER TABLE `st_pg_gen` DISABLE KEYS */;
INSERT INTO `st_pg_gen` VALUES (1,'Male'),(2,'Female'),(3,'Not Wish to Disclose');
/*!40000 ALTER TABLE `st_pg_gen` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_gst_typ`
--

DROP TABLE IF EXISTS `st_pg_gst_typ`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_gst_typ` (
  `id` int NOT NULL AUTO_INCREMENT,
  `guest_type` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_gst_typ`
--

LOCK TABLES `st_pg_gst_typ` WRITE;
/*!40000 ALTER TABLE `st_pg_gst_typ` DISABLE KEYS */;
INSERT INTO `st_pg_gst_typ` VALUES (1,'self_employed'),(2,'pvt_employee'),(3,'business_man'),(4,'corp_employee'),(5,'student_male'),(6,'govt_employee'),(7,'senior_citizen'),(8,'expat'),(9,'others'),(10,'student_female');
/*!40000 ALTER TABLE `st_pg_gst_typ` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_kyc_type`
--

DROP TABLE IF EXISTS `st_pg_kyc_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_kyc_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `proof_type` varchar(45) DEFAULT NULL,
  `rstatus` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_kyc_type`
--

LOCK TABLES `st_pg_kyc_type` WRITE;
/*!40000 ALTER TABLE `st_pg_kyc_type` DISABLE KEYS */;
INSERT INTO `st_pg_kyc_type` VALUES (1,'aadhaar',1),(2,'pan',1),(3,'driverlicense',1),(4,'passport',1),(5,'electricitybill',1),(6,'rationcard',1),(7,'policereport',1),(8,'ITRReport',1),(9,'backgroundverification',1),(10,'leasedocument',1),(11,'userdetailsform',1),(12,'bankaccountdetailsform',1),(13,'Aadhaar',1);
/*!40000 ALTER TABLE `st_pg_kyc_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_operations`
--

DROP TABLE IF EXISTS `st_pg_operations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_operations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `operation` varchar(45) DEFAULT NULL,
  `active` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_operations`
--

LOCK TABLES `st_pg_operations` WRITE;
/*!40000 ALTER TABLE `st_pg_operations` DISABLE KEYS */;
INSERT INTO `st_pg_operations` VALUES (1,'create',1),(2,'view',1),(3,'update',1),(4,'delete',1);
/*!40000 ALTER TABLE `st_pg_operations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_pay_mode`
--

DROP TABLE IF EXISTS `st_pg_pay_mode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_pay_mode` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pay_mode` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_pay_mode`
--

LOCK TABLES `st_pg_pay_mode` WRITE;
/*!40000 ALTER TABLE `st_pg_pay_mode` DISABLE KEYS */;
INSERT INTO `st_pg_pay_mode` VALUES (1,'online'),(2,'cash');
/*!40000 ALTER TABLE `st_pg_pay_mode` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_permission`
--

DROP TABLE IF EXISTS `st_pg_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `permission_key` varchar(45) DEFAULT NULL,
  `display_name` varchar(45) DEFAULT NULL,
  `is_active` int DEFAULT NULL,
  `rstatus` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_permission`
--

LOCK TABLES `st_pg_permission` WRITE;
/*!40000 ALTER TABLE `st_pg_permission` DISABLE KEYS */;
INSERT INTO `st_pg_permission` VALUES (1,'CREATE_PG','Create PG',1,1),(2,'VIEW_MY_PG','View My PG',1,1),(3,'EDIT_PG','Edit PG',1,1),(4,'DELETE_PG','Delete PG',1,1),(5,'MANAGE_GUESTS','Manage Guests',1,1),(6,'MANAGE_FEES','Manage Fees',1,1),(7,'MANAGE_MAINTENANCE','Manage Maintenance',1,1);
/*!40000 ALTER TABLE `st_pg_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_perms`
--

DROP TABLE IF EXISTS `st_pg_perms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_perms` (
  `id` int NOT NULL AUTO_INCREMENT,
  `permission` varchar(45) DEFAULT NULL,
  `rstatus` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_perms`
--

LOCK TABLES `st_pg_perms` WRITE;
/*!40000 ALTER TABLE `st_pg_perms` DISABLE KEYS */;
INSERT INTO `st_pg_perms` VALUES (1,'Read',1),(2,'Write',1),(3,'Edit',1),(4,'Delete',1);
/*!40000 ALTER TABLE `st_pg_perms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_prkng_type`
--

DROP TABLE IF EXISTS `st_pg_prkng_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_prkng_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `parking_type` varchar(15) DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_prkng_type`
--

LOCK TABLES `st_pg_prkng_type` WRITE;
/*!40000 ALTER TABLE `st_pg_prkng_type` DISABLE KEYS */;
INSERT INTO `st_pg_prkng_type` VALUES (1,'Car',1),(2,'Bike',1),(3,'Bicycle',1),(4,'Auto',1);
/*!40000 ALTER TABLE `st_pg_prkng_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_role`
--

DROP TABLE IF EXISTS `st_pg_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_role` (
  `id` int NOT NULL AUTO_INCREMENT,
  `role` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_role`
--

LOCK TABLES `st_pg_role` WRITE;
/*!40000 ALTER TABLE `st_pg_role` DISABLE KEYS */;
INSERT INTO `st_pg_role` VALUES (1,'Admin'),(2,'Owner'),(3,'Manager'),(4,'Resident'),(5,'Staff');
/*!40000 ALTER TABLE `st_pg_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_role_permissions`
--

DROP TABLE IF EXISTS `st_pg_role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_role_permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `role_id` int DEFAULT NULL,
  `permission_id` int DEFAULT NULL,
  `is_active` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_role_idx` (`role_id`),
  KEY `fk_permis_idx` (`permission_id`),
  CONSTRAINT `fk_permis` FOREIGN KEY (`permission_id`) REFERENCES `st_pg_permission` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role` FOREIGN KEY (`role_id`) REFERENCES `st_pg_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_role_permissions`
--

LOCK TABLES `st_pg_role_permissions` WRITE;
/*!40000 ALTER TABLE `st_pg_role_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `st_pg_role_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_room_type`
--

DROP TABLE IF EXISTS `st_pg_room_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_room_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nbeds` int DEFAULT NULL,
  `occupancy` varchar(45) DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_room_type`
--

LOCK TABLES `st_pg_room_type` WRITE;
/*!40000 ALTER TABLE `st_pg_room_type` DISABLE KEYS */;
INSERT INTO `st_pg_room_type` VALUES (1,1,'single',1),(2,2,'double',1),(3,3,'triple',1),(4,4,'quadruple',0),(5,5,'pentagonal',0),(6,2,'Double Sharing',0);
/*!40000 ALTER TABLE `st_pg_room_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_srv_cat`
--

DROP TABLE IF EXISTS `st_pg_srv_cat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_srv_cat` (
  `id` int NOT NULL AUTO_INCREMENT,
  `service_category` varchar(45) DEFAULT NULL,
  `resolve_timeline` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_srv_cat`
--

LOCK TABLES `st_pg_srv_cat` WRITE;
/*!40000 ALTER TABLE `st_pg_srv_cat` DISABLE KEYS */;
INSERT INTO `st_pg_srv_cat` VALUES (1,'plumbing',1),(2,'electrical',1),(3,'aircondition',1),(4,'housekeeping',1),(5,'beddebugging',1),(6,'janitor',1),(7,'lockers',2),(8,'miscellenous',4);
/*!40000 ALTER TABLE `st_pg_srv_cat` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_state`
--

DROP TABLE IF EXISTS `st_pg_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_state` (
  `id` int NOT NULL AUTO_INCREMENT,
  `scode` varchar(5) DEFAULT NULL,
  `name` varchar(45) DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_state`
--

LOCK TABLES `st_pg_state` WRITE;
/*!40000 ALTER TABLE `st_pg_state` DISABLE KEYS */;
INSERT INTO `st_pg_state` VALUES (1,'AP','Andhra Pradesh',1),(2,'AR','Arunachal Pradesh',1),(3,'AS','Assam',1),(4,'BR','Bihar',1),(5,'CG','Chhattisgarh',1),(6,'GA','Goa',1),(7,'GJ','Gujarat',1),(8,'HR','Haryana',1),(9,'HP','Himachal Pradesh',11),(10,'JH','Jharkhand',1),(11,'KA','Karnataka',1),(12,'KL','Kerala',1),(13,'MP','Madhya Pradesh',1),(14,'MH','Maharashtra',1),(15,'MN','Manipur',1),(16,'ML','Meghalaya',1),(17,'MZ','Mizoram',1),(18,'NL','Nagaland',1),(19,'OR','Odisha',1),(20,'PB','Punjab',1),(21,'RJ','Rajasthan',1),(22,'SK','Sikkim',1),(23,'TN','Tamil Nadu',1),(24,'TS','Telangana',1),(25,'TR','Tripura',1),(26,'UK','Uttarakhand',1),(27,'UP','Uttar Pradesh',1),(28,'WB','West Bengal',1),(29,'AN','Andaman,Nicobar Islands',1),(30,'CH','Chandigarh',1),(31,'DD','Dadra,NagarHaveli,Daman,Diu',1),(32,'DL','The Government of NCT of Delhi',1),(33,'JK','Jammu & Kashmir',1),(34,'LD','Ladakh',1),(35,'LA','Lakshadweep',1),(36,'PY','Puducherry',1),(37,'DL','Delhi-NCR',1),(38,'KA','Karnataka',0);
/*!40000 ALTER TABLE `st_pg_state` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_survey_items`
--

DROP TABLE IF EXISTS `st_pg_survey_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_survey_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `survey_section_id` int DEFAULT NULL,
  `survey_item` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_survey_items`
--

LOCK TABLES `st_pg_survey_items` WRITE;
/*!40000 ALTER TABLE `st_pg_survey_items` DISABLE KEYS */;
INSERT INTO `st_pg_survey_items` VALUES (1,NULL,'Room Cleanliness'),(3,1,'Room Cleanliness'),(4,1,'Bathroom Hygiene'),(5,1,'Furniture Condition'),(6,2,'Food Quality'),(7,2,'Food Variety'),(8,2,'Food Variety'),(9,3,'WiFi Speed'),(10,3,'Security'),(11,3,'Laundry Service'),(12,3,'Electricity Supply'),(13,3,'Overall Experience');
/*!40000 ALTER TABLE `st_pg_survey_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_survey_section`
--

DROP TABLE IF EXISTS `st_pg_survey_section`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_survey_section` (
  `id` int NOT NULL AUTO_INCREMENT,
  `section` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_survey_section`
--

LOCK TABLES `st_pg_survey_section` WRITE;
/*!40000 ALTER TABLE `st_pg_survey_section` DISABLE KEYS */;
INSERT INTO `st_pg_survey_section` VALUES (1,'Accommodation'),(2,'Food'),(3,'Facilities');
/*!40000 ALTER TABLE `st_pg_survey_section` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `st_pg_type`
--

DROP TABLE IF EXISTS `st_pg_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st_pg_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pg_type` varchar(20) DEFAULT NULL,
  `rstatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `st_pg_type`
--

LOCK TABLES `st_pg_type` WRITE;
/*!40000 ALTER TABLE `st_pg_type` DISABLE KEYS */;
INSERT INTO `st_pg_type` VALUES (1,'Men',1),(2,'Women',1),(3,'Unisex',1),(4,'Student',1),(5,'Corporate',1),(6,'SeniorCitizen',1),(7,'Executive',1),(8,'Employee',1),(9,'Shared',0);
/*!40000 ALTER TABLE `st_pg_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'avyra'
--

--
-- Dumping routines for database 'avyra'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-22 11:33:36
