CREATE TABLE IF NOT EXISTS `fishing_progress` (
  `citizenid` varchar(50) NOT NULL,
  `xp` int NOT NULL DEFAULT 0,
  `level` int NOT NULL DEFAULT 1,
  `skill_points` int NOT NULL DEFAULT 0,
  `total_caught` int NOT NULL DEFAULT 0,
  `perfect_catches` int NOT NULL DEFAULT 0,
  `best_weight` decimal(8,2) NOT NULL DEFAULT 0.00,
  `total_earned` int NOT NULL DEFAULT 0,
  `skill_data` longtext DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
