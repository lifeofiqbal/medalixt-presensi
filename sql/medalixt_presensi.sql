-- ============================================================
--  medalixt_presensi | database migration
--  Run this manually OR let the resource auto-create via oxmysql
-- ============================================================

CREATE TABLE IF NOT EXISTS `medalixt_presensi` (
    `id`              INT           NOT NULL AUTO_INCREMENT,
    `citizenid`       VARCHAR(50)   NOT NULL             COMMENT 'QBX citizenid',
    `name`            VARCHAR(100)  NOT NULL DEFAULT ''  COMMENT 'Character full name',
    `login_time`      DATETIME      NOT NULL             COMMENT 'Session start',
    `logout_time`     DATETIME      DEFAULT NULL         COMMENT 'Session end (NULL = still online)',
    `session_minutes` INT           DEFAULT NULL         COMMENT 'Duration in minutes, filled on logout',
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid`  (`citizenid`),
    INDEX `idx_login_time` (`login_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  Useful queries for admins
-- ============================================================

-- Total playtime per character:
-- SELECT citizenid, name, SUM(session_minutes) AS total_minutes
-- FROM medalixt_presensi WHERE logout_time IS NOT NULL
-- GROUP BY citizenid ORDER BY total_minutes DESC;

-- Sessions still open (player currently online):
-- SELECT * FROM medalixt_presensi WHERE logout_time IS NULL;

-- Playtime for a specific citizenid:
-- SELECT SUM(session_minutes) FROM medalixt_presensi WHERE citizenid = 'ABC123';
