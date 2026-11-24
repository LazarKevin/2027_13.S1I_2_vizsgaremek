-- ============================================================
--  Fork & Byte – Éttermi rendelési és foglalási rendszer
--  Adatbázis létrehozása (MySQL / MariaDB – XAMPP, phpMyAdmin)
--
--  Készült a "Projektfeladat adatbázis" és az "Algoritmus leírás"
--  dokumentum alapján.
--
--  FIGYELEM: a fájl elején lévő DROP DATABASE sor törli a régi
--  fork_byte adatbázist (ha van), és mindent újra létrehoz.
--  Ha már van benne fontos adatotok, azt a sort töröljétek ki!
-- ============================================================

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS fork_byte;

CREATE DATABASE fork_byte
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_hungarian_ci;

USE fork_byte;


-- ============================================================
--  1. RÉSZ: TÁBLÁK
--  A táblák olyan sorrendben jönnek, hogy egy tábla csak olyan
--  táblára hivatkozzon (idegen kulccsal), ami már létezik.
-- ============================================================


-- ------------------------------------------------------------
-- 2.1. felhasznalok – a személyzet (pincér, konyhás, séf, admin)
-- ------------------------------------------------------------
CREATE TABLE felhasznalok (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nev            VARCHAR(30) NOT NULL,
  felhasznalonev VARCHAR(30) NOT NULL,
  jelszo         VARCHAR(60) NOT NULL,   -- a bcrypt hash mindig 60 karakter
  szerepkor      ENUM('pincer', 'konyhas', 'alapanyagfelelos', 'admin') NOT NULL,
  letrehozva     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  torolve        TIMESTAMP NULL DEFAULT NULL,   -- soft delete
  PRIMARY KEY (id),
  UNIQUE (felhasznalonev)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.2. asztalok
-- ------------------------------------------------------------
CREATE TABLE asztalok (
  id           TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  asztalszam   VARCHAR(10) NOT NULL,
  ferohely     TINYINT UNSIGNED NOT NULL,
  jellemzok    VARCHAR(50) NULL,
  kezi_allapot ENUM('szabad', 'foglalt', 'hasznalatban') NULL DEFAULT NULL,
  pincer_hivas TIMESTAMP NULL DEFAULT NULL,
  letrehozva   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (asztalszam)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.5. etlap_kategoriak
-- ------------------------------------------------------------
CREATE TABLE etlap_kategoriak (
  id         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nev        VARCHAR(50) NOT NULL,
  letrehozva TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.7. alapanyagok
-- ------------------------------------------------------------
CREATE TABLE alapanyagok (
  id         SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nev        VARCHAR(50) NOT NULL,
  elerheto_e BOOLEAN NOT NULL DEFAULT TRUE,
  letrehozva TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (nev)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.8. allergenek
-- ------------------------------------------------------------
CREATE TABLE allergenek (
  id         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nev        VARCHAR(50) NOT NULL,
  letrehozva TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (nev)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.6. etelek
-- ------------------------------------------------------------
CREATE TABLE etelek (
  id              SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  kategoria_id    TINYINT UNSIGNED NOT NULL,
  nev             VARCHAR(50) NOT NULL,
  leiras          TEXT NULL,
  ar              DECIMAL(10,2) NOT NULL,
  kep_url         VARCHAR(255) NULL,
  elkeszitesi_ido TINYINT UNSIGNED NOT NULL,   -- percben
  letrehozva      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  torolve         TIMESTAMP NULL DEFAULT NULL,   -- soft delete
  PRIMARY KEY (id),
  CONSTRAINT fk_etelek_kategoria
    FOREIGN KEY (kategoria_id) REFERENCES etlap_kategoriak (id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.9. etel_alapanyag – kapcsolótábla (étel N:M alapanyag)
-- ------------------------------------------------------------
CREATE TABLE etel_alapanyag (
  etel_id      SMALLINT UNSIGNED NOT NULL,
  alapanyag_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (etel_id, alapanyag_id),
  CONSTRAINT fk_etel_alapanyag_etel
    FOREIGN KEY (etel_id) REFERENCES etelek (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_etel_alapanyag_alapanyag
    FOREIGN KEY (alapanyag_id) REFERENCES alapanyagok (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.10. alapanyag_allergen – kapcsolótábla (alapanyag N:M allergén)
-- ------------------------------------------------------------
CREATE TABLE alapanyag_allergen (
  alapanyag_id SMALLINT UNSIGNED NOT NULL,
  allergen_id  TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (alapanyag_id, allergen_id),
  CONSTRAINT fk_alapanyag_allergen_alapanyag
    FOREIGN KEY (alapanyag_id) REFERENCES alapanyagok (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_alapanyag_allergen_allergen
    FOREIGN KEY (allergen_id) REFERENCES allergenek (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.11. alapanyag_jelzesek – a konyha jelzései a séfnek
-- ------------------------------------------------------------
CREATE TABLE alapanyag_jelzesek (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  alapanyag_id SMALLINT UNSIGNED NOT NULL,
  jelezte_id   INT UNSIGNED NOT NULL,
  megjegyzes   VARCHAR(255) NULL,
  kezelve      TIMESTAMP NULL DEFAULT NULL,   -- ha üres, a jelzés még nyitott
  kezelte_id   INT UNSIGNED NULL,
  letrehozva   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_jelzesek_alapanyag
    FOREIGN KEY (alapanyag_id) REFERENCES alapanyagok (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_jelzesek_jelezte
    FOREIGN KEY (jelezte_id) REFERENCES felhasznalok (id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_jelzesek_kezelte
    FOREIGN KEY (kezelte_id) REFERENCES felhasznalok (id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.3. foglalasok
-- ------------------------------------------------------------
CREATE TABLE foglalasok (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  asztal_id        TINYINT UNSIGNED NOT NULL,
  vendeg_neve      VARCHAR(30) NOT NULL,
  vendeg_email     VARCHAR(50) NULL,
  vendeg_telefon   VARCHAR(20) NULL,
  datum            DATE NOT NULL,
  idopont          TIME NOT NULL,
  idotartam        SMALLINT UNSIGNED NOT NULL DEFAULT 120,   -- percben
  letszam          TINYINT UNSIGNED NOT NULL,
  forras           ENUM('online', 'telefon', 'helyszini') NOT NULL DEFAULT 'online',
  allapot          ENUM('aktiv', 'megerkezett', 'kesik', 'meg_nem_jelent', 'lemondva', 'teljesitve') NOT NULL DEFAULT 'aktiv',
  keses_igazolva   BOOLEAN NOT NULL DEFAULT FALSE,
  turelmi_ido_vege DATETIME NULL,
  belepokod        VARCHAR(10) NULL,
  kod_lejarat      DATETIME NULL,
  kod_felhasznalva DATETIME NULL,   -- ha nem üres, a kód már nem használható
  rogzitette_id    INT UNSIGNED NULL,   -- online foglalásnál üres
  tobb_asztal      BOOLEAN NOT NULL DEFAULT FALSE,
  letrehozva       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (belepokod),
  CONSTRAINT fk_foglalasok_asztal
    FOREIGN KEY (asztal_id) REFERENCES asztalok (id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_foglalasok_rogzitette
    FOREIGN KEY (rogzitette_id) REFERENCES felhasznalok (id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.4. vendeg_menetek – egy vendég(csoport) ottléte az asztalnál
-- ------------------------------------------------------------
CREATE TABLE vendeg_menetek (
  id                     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  asztal_id              TINYINT UNSIGNED NOT NULL,
  foglalas_id            INT UNSIGNED NULL,
  token                  VARCHAR(64) NOT NULL,
  fizetesi_mod           ENUM('kartya', 'keszpenz') NULL,
  vegosszeg              DECIMAL(10,2) NULL,   -- borravaló nélkül
  borravalo_tipus        ENUM('nincs', 'szazalek', 'osszeg') NOT NULL DEFAULT 'nincs',
  borravalo_ertek        DECIMAL(8,2) NULL,
  fizetve                TIMESTAMP NULL DEFAULT NULL,
  fizetest_rogzitette_id INT UNSIGNED NULL,
  lezarva                TIMESTAMP NULL DEFAULT NULL,   -- ha üres, a menet nyitott
  letrehozva             TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (token),
  CONSTRAINT fk_menetek_asztal
    FOREIGN KEY (asztal_id) REFERENCES asztalok (id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_menetek_foglalas
    FOREIGN KEY (foglalas_id) REFERENCES foglalasok (id)
    ON DELETE SET NULL,
  CONSTRAINT fk_menetek_fizetest_rogzitette
    FOREIGN KEY (fizetest_rogzitette_id) REFERENCES felhasznalok (id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.12. rendelesek
-- ------------------------------------------------------------
CREATE TABLE rendelesek (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  menet_id       INT UNSIGNED NOT NULL,
  felszolgalo_id INT UNSIGNED NULL,   -- ha a pincér vette fel
  letrehozva     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_rendelesek_menet
    FOREIGN KEY (menet_id) REFERENCES vendeg_menetek (id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_rendelesek_felszolgalo
    FOREIGN KEY (felszolgalo_id) REFERENCES felhasznalok (id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.13. rendeles_reszletek – a rendelés tételei
-- ------------------------------------------------------------
CREATE TABLE rendeles_reszletek (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  rendeles_id  INT UNSIGNED NOT NULL,
  etel_id      SMALLINT UNSIGNED NOT NULL,
  mennyiseg    TINYINT UNSIGNED NOT NULL DEFAULT 1,
  egysegar     DECIMAL(10,2) NOT NULL,   -- az étel ára a rendelés pillanatában
  egyedi_keres VARCHAR(200) NULL,
  allapot      ENUM('leadva', 'keszul', 'elkeszult', 'kiszolgalva') NOT NULL DEFAULT 'leadva',
  letrehozva   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  frissitve    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_reszletek_rendeles
    FOREIGN KEY (rendeles_id) REFERENCES rendelesek (id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_reszletek_etel
    FOREIGN KEY (etel_id) REFERENCES etelek (id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 2.14. aktiv_vendeg_allergiak – csak az étkezés idejére
-- ------------------------------------------------------------
CREATE TABLE aktiv_vendeg_allergiak (
  menet_id    INT UNSIGNED NOT NULL,
  allergen_id TINYINT UNSIGNED NOT NULL,
  letrehozva  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (menet_id, allergen_id),
  CONSTRAINT fk_vendeg_allergiak_menet
    FOREIGN KEY (menet_id) REFERENCES vendeg_menetek (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_vendeg_allergiak_allergen
    FOREIGN KEY (allergen_id) REFERENCES allergenek (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;



-- ============================================================
--  2. RÉSZ: TESZTADATOK
--  Csak kipróbáláshoz. Az árak, nevek és ételek kitaláltak.
--  Ha nem kellenek, innentől a fájl végéig törölhető.
-- ============================================================


-- Személyzet. A jelszó mindenkinél: Teszt1234
INSERT INTO felhasznalok (id, nev, felhasznalonev, jelszo, szerepkor) VALUES
(1, 'Admin Anna',   'admin',   '$2y$10$WWmO0sVX5Dmw1Ec6GF..OuCfKaYlQ2qp.qsEqqRcSN.yPg1DPjlTS', 'admin'),
(2, 'Kovács Bence', 'pincer1', '$2y$10$Mjd.1h7Buh69qz9Mda.FyuCXHRN9v/P3qQZT.VLK53GLgdLY/DD3q', 'pincer'),
(3, 'Varga Lili',   'konyha1', '$2y$10$jcs0TrB0Wp62KHerlpesCeI09JkijTpt0amKJOyzSu/gtdc/tCHqu', 'konyhas'),
(4, 'Fekete Zsolt', 'sef1',    '$2y$10$HDAQD4ZdniRNdXyYvZtaT.8faqex273RNJxcefNuhH7FxY7H5iswm', 'alapanyagfelelos');


-- 12 asztal
INSERT INTO asztalok (id, asztalszam, ferohely, jellemzok) VALUES
(1,  '1',  2, 'ablak mellett'),
(2,  '2',  4, NULL),
(3,  '3',  4, NULL),
(4,  '4',  6, NULL),
(5,  '5',  2, 'ablak mellett'),
(6,  '6',  4, NULL),
(7,  '7',  4, NULL),
(8,  '8',  8, 'nagy asztal'),
(9,  '9',  2, 'terasz'),
(10, '10', 6, 'terasz'),
(11, '11', 4, 'terasz'),
(12, '12', 4, NULL);


-- Étlap kategóriák
INSERT INTO etlap_kategoriak (id, nev) VALUES
(1, 'Előételek'),
(2, 'Levesek'),
(3, 'Főételek'),
(4, 'Desszertek'),
(5, 'Italok');


-- A 14 fő élelmiszer-allergén (EU-s lista)
INSERT INTO allergenek (id, nev) VALUES
(1,  'Glutén'),
(2,  'Rákfélék'),
(3,  'Tojás'),
(4,  'Hal'),
(5,  'Földimogyoró'),
(6,  'Szója'),
(7,  'Laktóz'),
(8,  'Diófélék'),
(9,  'Zeller'),
(10, 'Mustár'),
(11, 'Szezám'),
(12, 'Kén-dioxid'),
(13, 'Csillagfürt'),
(14, 'Puhatestűek');


-- Alapanyagok (a csicseriborsó most "elfogyott", hogy legyen mit tesztelni)
INSERT INTO alapanyagok (id, nev, elerheto_e) VALUES
(1,  'Búzaliszt',     TRUE),
(2,  'Tojás',         TRUE),
(3,  'Tejföl',        TRUE),
(4,  'Tejszín',       TRUE),
(5,  'Vaj',           TRUE),
(6,  'Trappista sajt', TRUE),
(7,  'Csirkecomb',    TRUE),
(8,  'Marhalábszár',  TRUE),
(9,  'Lazacfilé',     TRUE),
(10, 'Burgonya',      TRUE),
(11, 'Rizs',          TRUE),
(12, 'Paprika',       TRUE),
(13, 'Vöröshagyma',   TRUE),
(14, 'Citrom',        TRUE),
(15, 'Csicseriborsó', FALSE),
(16, 'Kókusztej',     TRUE),
(17, 'Szezámmag',     TRUE);


-- Melyik alapanyagban milyen allergén van
INSERT INTO alapanyag_allergen (alapanyag_id, allergen_id) VALUES
(1,  1),   -- Búzaliszt      -> Glutén
(2,  3),   -- Tojás          -> Tojás
(3,  7),   -- Tejföl         -> Laktóz
(4,  7),   -- Tejszín        -> Laktóz
(5,  7),   -- Vaj            -> Laktóz
(6,  7),   -- Trappista sajt -> Laktóz
(9,  4),   -- Lazacfilé      -> Hal
(17, 11);  -- Szezámmag      -> Szezám


-- Ételek
INSERT INTO etelek (id, kategoria_id, nev, leiras, ar, kep_url, elkeszitesi_ido) VALUES
(1, 2, 'Gulyásleves',                   'Marhahúsos gulyás burgonyával',              2490.00, NULL, 25),
(2, 3, 'Paprikás csirke galuskával',     'Tejfölös paprikás mártás, házi galuska',     3790.00, NULL, 20),
(3, 3, 'Marhapörkölt főtt burgonyával',  'Lassan főzött marhalábszár',                 4190.00, NULL, 25),
(4, 3, 'Grillezett lazac',              'Citromos vajmártással',                      4690.00, NULL, 18),
(5, 3, 'Rántott sajt rizzsel',          'Rántott trappista sajt, párolt rizs',         3290.00, NULL, 12),
(6, 3, 'Zöldséges curry jázminrizzsel', 'Kókusztejes curry, sült csicseriborsó',       3490.00, NULL, 15),
(7, 4, 'Somlói galuska',                'Házi piskóta, csokoládéöntet, tejszínhab',    1690.00, NULL, 5),
(8, 5, 'Házi limonádé',                 'Friss citromból',                             890.00, NULL, 3);


-- Melyik ételben milyen alapanyag van
INSERT INTO etel_alapanyag (etel_id, alapanyag_id) VALUES
(1, 8), (1, 10), (1, 12), (1, 13),                   -- Gulyásleves
(2, 7), (2, 12), (2, 3), (2, 1), (2, 2), (2, 13),    -- Paprikás csirke
(3, 8), (3, 10), (3, 12), (3, 13),                   -- Marhapörkölt
(4, 9), (4, 5), (4, 14),                             -- Grillezett lazac
(5, 6), (5, 1), (5, 2), (5, 11),                     -- Rántott sajt
(6, 15), (6, 16), (6, 11), (6, 17),                  -- Zöldséges curry
(7, 1), (7, 2), (7, 4),                              -- Somlói galuska
(8, 14);                                             -- Házi limonádé


-- Foglalások
--  1. Mai online foglalás, a belépőkód: K7F2Q9 (ezzel lehet tesztelni a Belépés oldalt)
--  2. Telefonos foglalás 14 nap múlvára, a pincér rögzítette
INSERT INTO foglalasok
  (id, asztal_id, vendeg_neve, vendeg_email, vendeg_telefon, datum, idopont, idotartam, letszam, forras, allapot, belepokod, kod_lejarat, rogzitette_id)
VALUES
(1, 3, 'Kiss Anna',    'kiss.anna@example.com', NULL,           CURDATE(),                          '18:00:00', 120, 4, 'online',  'aktiv', 'K7F2Q9', CONCAT(CURDATE(), ' 23:59:59'),                          NULL),
(2, 6, 'Szabó Eszter', NULL,                    '+36301234567', DATE_ADD(CURDATE(), INTERVAL 14 DAY), '18:30:00', 120, 4, 'telefon', 'aktiv', 'P4M8X2', CONCAT(DATE_ADD(CURDATE(), INTERVAL 14 DAY), ' 23:59:59'), 2);


-- Egy nyitott vendégmenet a 7-es asztalnál (foglalás nélkül érkezett vendég)
INSERT INTO vendeg_menetek (id, asztal_id, foglalas_id, token) VALUES
(1, 7, NULL, 'tesztmenet-7-es-asztal');


-- A vendég allergiája: glutén
INSERT INTO aktiv_vendeg_allergiak (menet_id, allergen_id) VALUES
(1, 1);


-- Egy rendelés a 7-es asztaltól, két tétellel
INSERT INTO rendelesek (id, menet_id, felszolgalo_id) VALUES
(1, 1, NULL);

INSERT INTO rendeles_reszletek (id, rendeles_id, etel_id, mennyiseg, egysegar, egyedi_keres, allapot) VALUES
(1, 1, 3, 2, 4190.00, NULL,          'elkeszult'),
(2, 1, 4, 1, 4690.00, 'vaj nélkül',  'keszul');


-- Egy nyitott alapanyag-jelzés a konyhától
INSERT INTO alapanyag_jelzesek (id, alapanyag_id, jelezte_id, megjegyzes) VALUES
(1, 3, 3, 'holnap lejár');
