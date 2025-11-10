-- Table des comptes bancaires personnels
CREATE TABLE IF NOT EXISTS `bank_accounts_personal` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(50) NOT NULL,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `iban` VARCHAR(34) NOT NULL UNIQUE,
    `balance` DECIMAL(15,2) NOT NULL DEFAULT 5000.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`),
    KEY `iban` (`iban`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des comptes bancaires professionnels
CREATE TABLE IF NOT EXISTS `bank_accounts_business` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `society` VARCHAR(50) NOT NULL,
    `society_label` VARCHAR(100) NOT NULL,
    `iban` VARCHAR(34) NOT NULL UNIQUE,
    `balance` DECIMAL(15,2) NOT NULL DEFAULT 10000.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `society` (`society`),
    KEY `iban` (`iban`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des cartes bancaires
CREATE TABLE IF NOT EXISTS `bank_cards` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(50) NOT NULL,
    `iban` VARCHAR(34) NOT NULL,
    `account_type` ENUM('personal', 'business') NOT NULL DEFAULT 'personal',
    `pin` VARCHAR(4) NOT NULL,
    `card_number` VARCHAR(16) NOT NULL UNIQUE,
    `expiry_date` VARCHAR(5) NOT NULL,
    `cvv` VARCHAR(3) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `is_blocked` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `iban` (`iban`),
    KEY `card_number` (`card_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des transactions
CREATE TABLE IF NOT EXISTS `bank_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `from_iban` VARCHAR(34) NOT NULL,
    `to_iban` VARCHAR(34) NOT NULL,
    `from_name` VARCHAR(100) NOT NULL,
    `to_name` VARCHAR(100) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `type` ENUM('transfer', 'deposit', 'withdraw', 'salary', 'fee') NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `from_iban` (`from_iban`),
    KEY `to_iban` (`to_iban`),
    KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des employés (pour le système de salaires)
CREATE TABLE IF NOT EXISTS `bank_employees` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(50) NOT NULL,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `iban` VARCHAR(34) NOT NULL,
    `society` VARCHAR(50) NOT NULL,
    `job_grade` INT(11) NOT NULL DEFAULT 0,
    `job_grade_label` VARCHAR(50) NOT NULL,
    `salary` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `last_salary_paid` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `society` (`society`),
    KEY `iban` (`iban`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des paiements de salaires
CREATE TABLE IF NOT EXISTS `bank_salary_payments` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `employee_identifier` VARCHAR(50) NOT NULL,
    `employee_name` VARCHAR(100) NOT NULL,
    `society` VARCHAR(50) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `iban` VARCHAR(34) NOT NULL,
    `paid_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `employee_identifier` (`employee_identifier`),
    KEY `society` (`society`),
    KEY `paid_at` (`paid_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
