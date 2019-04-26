# https://thomas-leister.de/en/mailserver-debian-stretch/

create database vmail
    CHARACTER SET 'utf8';

grant select on vmail.* to 'vmail'@'%' identified by 'vmaildbpass';

use vmail;

CREATE TABLE `domains` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `domain` varchar(255) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`domain`)
);

CREATE TABLE `accounts` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `email` varchar(255) NOT NULL,
    `password` varchar(255) NOT NULL,
    `quota` int unsigned DEFAULT '0',
    `enabled` boolean DEFAULT '0',
    `sendonly` boolean DEFAULT '0',
    PRIMARY KEY (id),
    UNIQUE KEY (`email`)
);

CREATE TABLE `aliases` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `source` varchar(255) NOT NULL,
    `destination` varchar(255) NOT NULL,
    `enabled` boolean DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY (`source`, `destination`)
);

CREATE TABLE `tlspolicies` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `domain` varchar(255) NOT NULL,
    `policy` enum('none', 'may', 'encrypt', 'dane', 'dane-only', 'fingerprint', 'verify', 'secure') NOT NULL,
    `params` varchar(255),
    PRIMARY KEY (`id`),
    UNIQUE KEY (`domain`)
);

insert into domains (domain) values ('waswiegentiere.de');

insert into accounts (email, password, quota, enabled, sendonly) values ('chris@waswiegentiere.de', encrypt('password', CONCAT('$5$', MD5(RAND()))), 2048, true, false);

insert into aliases (source, destination, enabled) values ('alias@waswiegentiere.de', 'chris@waswiegentiere.de', true);
