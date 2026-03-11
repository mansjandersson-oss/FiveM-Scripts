CREATE TABLE IF NOT EXISTS `hunter_progress` (
  `citizenid` varchar(60) NOT NULL,
  `xp` int NOT NULL DEFAULT 0,
  `level` int NOT NULL DEFAULT 1,
  `has_license` tinyint(1) NOT NULL DEFAULT 0,
  `kills` int NOT NULL DEFAULT 0,
  `cuts` int NOT NULL DEFAULT 0,
  `sold` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
