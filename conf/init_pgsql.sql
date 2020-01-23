CREATE DATABASE vmail ENCODING 'UTF8';
CREATE USER vmail_user WITH PASSWORD 'not_a_password';
\c vmail
CREATE EXTENSION pgcrypto;

CREATE TABLE domains (
    id SERIAL PRIMARY KEY,
    domain varchar(255) UNIQUE NOT NULL
);

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    email varchar(255) NOT NULL UNIQUE,
    password varchar(255) NOT NULL,
    quota integer default 0,
    enabled boolean DEFAULT false,
    sendonly boolean DEFAULT false
);

CREATE TABLE aliases (
    id SERIAL PRIMARY KEY,
    source varchar(255) NOT NULL,
    destination varchar(255) NOT NULL,
    enabled boolean DEFAULT false,
    unique (source, destination)
);

CREATE TYPE tlspolicies_policy AS ENUM ('none', 'may', 'encrypt', 'dane', 'dane-only', 'fingerprint', 'verify', 'secure');

CREATE TABLE tlspolicies (
    id SERIAL PRIMARY KEY,
    domain varchar(255) NOT NULL UNIQUE,
    policy tlspolicies_policy,
    params varchar(255)
);

GRANT SELECT ON ALL TABLES IN SCHEMA public TO vmail_user;

insert into domains (domain) values ('waswiegentiere.de');

insert into accounts (email, password, quota, enabled, sendonly) values ('chris@waswiegentiere.de', crypt('not_a_password',gen_salt('bf', 10)), 2048, true, false);

insert into aliases (source, destination, enabled) values ('alias@waswiegentiere.de', 'chris@waswiegentiere.de', true);
