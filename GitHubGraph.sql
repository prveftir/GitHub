-- ============================================================
-- GitHub Graph Database
-- Вариант: GitHub-граф
-- Узлы: Developer, Repository, Organization
-- Рёбра: Contributes, Owns, BelongsTo
-- ============================================================

USE master;

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GitHubGraph')
    DROP DATABASE GitHubGraph;

CREATE DATABASE GitHubGraph;

USE GitHubGraph;

-- ============================================================
-- 1. ТАБЛИЦЫ УЗЛОВ (NODE TABLES)
-- ============================================================

-- Узел: Разработчик
CREATE TABLE Developer (
    dev_id       INT            NOT NULL,
    login        NVARCHAR(100)  NOT NULL,
    full_name    NVARCHAR(200),
    country      NVARCHAR(100),
    followers    INT            DEFAULT 0,
    joined_year  INT,
    is_pro       BIT            DEFAULT 0
) AS NODE;

-- Узел: Репозиторий
CREATE TABLE Repository (
    repo_id      INT            NOT NULL,
    repo_name    NVARCHAR(200)  NOT NULL,
    language     NVARCHAR(50),
    stars        INT            DEFAULT 0,
    forks        INT            DEFAULT 0,
    is_private   BIT            DEFAULT 0,
    created_year INT
) AS NODE;

-- Узел: Организация
CREATE TABLE Organization (
    org_id        INT            NOT NULL,
    org_name      NVARCHAR(200)  NOT NULL,
    industry      NVARCHAR(100),
    country       NVARCHAR(100),
    founded_year  INT,
    members_count INT            DEFAULT 0
) AS NODE;

-- ============================================================
-- 2. ТАБЛИЦЫ РЁБЕР (EDGE TABLES) с CONNECTION CONSTRAINT
-- ============================================================

-- Ребро: Contributes (Developer -> Repository)
CREATE TABLE Contributes (
    contribution_date DATE,
    commits_count     INT          DEFAULT 0,
    lines_added       INT          DEFAULT 0,
    lines_deleted     INT          DEFAULT 0,
    role              NVARCHAR(50)
) AS EDGE;

ALTER TABLE Contributes
    ADD CONSTRAINT EC_Contributes
    CONNECTION (Developer TO Repository);

-- Ребро: Owns (Developer -> Repository или Organization -> Repository)
CREATE TABLE Owns (
    owned_since  DATE,
    access_level NVARCHAR(50)
) AS EDGE;

ALTER TABLE Owns
    ADD CONSTRAINT EC_Owns
    CONNECTION (Developer TO Repository, Organization TO Repository);

-- Ребро: BelongsTo (Developer -> Organization)
CREATE TABLE BelongsTo (
    join_date DATE,
    role      NVARCHAR(100),
    is_public BIT DEFAULT 1
) AS EDGE;

ALTER TABLE BelongsTo
    ADD CONSTRAINT EC_BelongsTo
    CONNECTION (Developer TO Organization);

-- ============================================================
-- 3. НАПОЛНЕНИЕ УЗЛОВ
-- ============================================================

-- Разработчики (12 строк)
INSERT INTO Developer (dev_id, login, full_name, country, followers, joined_year, is_pro)
VALUES
(1,  'torvalds',     'Linus Torvalds',      'Finland',       220000, 2011, 1),
(2,  'gvanrossum',   'Guido van Rossum',    'USA',             8900, 2012, 1),
(3,  'dhh',          'David H. Hansson',    'Denmark',        20000, 2008, 1),
(4,  'mojombo',      'Tom Preston-Werner',  'USA',            12000, 2007, 1),
(5,  'defunkt',      'Chris Wanstrath',     'USA',            18000, 2007, 1),
(6,  'pjhyett',      'PJ Hyett',            'USA',             4500, 2007, 0),
(7,  'antirez',      'Salvatore Sanfilippo','Italy',          16000, 2009, 1),
(8,  'fabpot',       'Fabien Potencier',    'France',          9000, 2010, 1),
(9,  'taylorotwell', 'Taylor Otwell',       'USA',            30000, 2011, 1),
(10, 'nicowillis',   'Nico Willis',         'Germany',         1200, 2015, 0),
(11, 'evanlucas',    'Evan Lucas',          'USA',             2300, 2013, 0),
(12, 'sindresorhus', 'Sindre Sorhus',       'Norway',         70000, 2012, 1);

-- Репозитории (12 строк)
INSERT INTO Repository (repo_id, repo_name, language, stars, forks, is_private, created_year)
VALUES
(1,  'linux',             'C',           190000, 55000, 0, 2005),
(2,  'cpython',           'Python',       63000, 30000, 0, 2008),
(3,  'rails',             'Ruby',         56000, 21000, 0, 2008),
(4,  'redis',             'C',            67000, 24000, 0, 2009),
(5,  'symfony',           'PHP',          29000, 10000, 0, 2010),
(6,  'laravel',           'PHP',          78000, 24000, 0, 2011),
(7,  'github-site',       'HTML',           500,   120, 1, 2012),
(8,  'awesome',           'Markdown',    320000, 28000, 0, 2014),
(9,  'node',              'JavaScript',  108000, 29000, 0, 2010),
(10, 'vscode',            'TypeScript',  165000, 29000, 0, 2015),
(11, 'homebrew',          'Ruby',         40000,  9000, 0, 2009),
(12, 'sindresorhus-misc', 'JavaScript',    2000,   200, 0, 2016);

-- Организации (10 строк)
INSERT INTO Organization (org_id, org_name, industry, country, founded_year, members_count)
VALUES
(1,  'microsoft',    'Technology',   'USA',             1975, 90000),
(2,  'google',       'Technology',   'USA',             1998,180000),
(3,  'facebook',     'Social Media', 'USA',             2004, 86000),
(4,  'github',       'DevTools',     'USA',             2008,  3000),
(5,  'symfony',      'Open Source',  'France',          2005,   200),
(6,  'laravel',      'Open Source',  'USA',             2011,    50),
(7,  'nodejs',       'Open Source',  'USA',             2009,   400),
(8,  'linux-kernel', 'Open Source',  'International',   1991,  4000),
(9,  'vercel',       'Cloud',        'USA',             2015,   700),
(10, 'jetbrains',    'DevTools',     'Czech Republic',  2000,  1500);

-- ============================================================
-- 4. НАПОЛНЕНИЕ РЁБЕР
-- ============================================================

-- Contributes: Developer -> Repository
INSERT INTO Contributes ($from_id, $to_id, contribution_date, commits_count, lines_added, role)
SELECT d.$node_id, r.$node_id,
       t.contribution_date, t.commits_count, t.lines_added, t.role
FROM (VALUES
    (1,  1,  '2023-01-15', 850, 42000, 'maintainer'),
    (2,  2,  '2023-03-10', 620, 18000, 'author'),
    (3,  3,  '2023-02-20', 310,  8500, 'maintainer'),
    (7,  4,  '2023-04-05', 990, 55000, 'author'),
    (8,  5,  '2023-01-28', 540, 21000, 'maintainer'),
    (9,  6,  '2023-05-12', 760, 33000, 'author'),
    (12, 8,  '2023-06-01', 120,  3200, 'author'),
    (11, 9,  '2022-11-30', 230,  7800, 'reviewer'),
    (10, 10, '2023-07-22',  95,  2100, 'reviewer'),
    (4,  4,  '2023-02-14', 180,  6500, 'reviewer'),
    (5,  3,  '2022-09-08', 270, 11000, 'reviewer'),
    (6,  9,  '2023-03-19', 145,  4300, 'maintainer'),
    (1,  9,  '2021-08-01',  30,   800, 'reviewer'),
    (2,  9,  '2022-05-15',  15,   500, 'reviewer')
) AS t(dev_id, repo_id, contribution_date, commits_count, lines_added, role)
JOIN Developer   d ON d.dev_id  = t.dev_id
JOIN Repository  r ON r.repo_id = t.repo_id;

-- Owns: Developer -> Repository
INSERT INTO Owns ($from_id, $to_id, owned_since, access_level)
SELECT d.$node_id, r.$node_id, t.owned_since, t.access_level
FROM (VALUES
    (1,  1,  '2005-04-07', 'owner'),
    (2,  2,  '2008-01-05', 'owner'),
    (3,  3,  '2008-07-11', 'owner'),
    (7,  4,  '2009-03-22', 'owner'),
    (8,  5,  '2010-06-01', 'owner'),
    (9,  6,  '2011-09-28', 'owner'),
    (12, 8,  '2014-07-11', 'owner'),
    (11, 9,  '2010-05-27', 'admin'),
    (5,  7,  '2012-01-01', 'admin'),
    (4,  11, '2009-05-01', 'admin'),
    (10, 12, '2016-03-10', 'owner'),
    (12, 12, '2016-03-10', 'admin')
) AS t(dev_id, repo_id, owned_since, access_level)
JOIN Developer  d ON d.dev_id  = t.dev_id
JOIN Repository r ON r.repo_id = t.repo_id;

-- Owns: Organization -> Repository
INSERT INTO Owns ($from_id, $to_id, owned_since, access_level)
SELECT o.$node_id, r.$node_id, t.owned_since, t.access_level
FROM (VALUES
    (1, 10, '2015-04-29', 'owner'),
    (7,  9, '2015-01-01', 'owner'),
    (8,  1, '2011-01-01', 'owner'),
    (5,  5, '2010-06-01', 'owner'),
    (6,  6, '2011-09-28', 'owner'),
    (4,  7, '2012-01-01', 'owner')
) AS t(org_id, repo_id, owned_since, access_level)
JOIN Organization o ON o.org_id  = t.org_id
JOIN Repository   r ON r.repo_id = t.repo_id;

-- BelongsTo: Developer -> Organization
INSERT INTO BelongsTo ($from_id, $to_id, join_date, role, is_public)
SELECT d.$node_id, o.$node_id, t.join_date, t.role, t.is_public
FROM (VALUES
    (1,  8, '2011-01-01', 'member', 1),
    (2,  2, '2015-06-01', 'member', 1),
    (3,  6, '2011-09-28', 'owner',  1),
    (4,  4, '2007-10-19', 'owner',  1),
    (5,  4, '2007-10-19', 'owner',  1),
    (6,  4, '2007-10-19', 'admin',  1),
    (7,  8, '2009-03-22', 'member', 1),
    (8,  5, '2010-06-01', 'owner',  1),
    (9,  6, '2011-09-28', 'owner',  1),
    (10, 1, '2018-01-01', 'member', 0),
    (11, 7, '2013-05-01', 'member', 1),
    (12, 9, '2020-03-01', 'member', 1)
) AS t(dev_id, org_id, join_date, role, is_public)
JOIN Developer    d ON d.dev_id = t.dev_id
JOIN Organization o ON o.org_id = t.org_id;

-- ============================================================
-- 5. ЗАПРОСЫ С MATCH (5 запросов)
-- ============================================================

-- Запрос 1: Разработчики, которые одновременно владеют репозиторием
-- и вносят в него вклад (являются author/maintainer)
PRINT '=== Запрос 1: Разработчики — владелец И контрибьютор одного репо ===';
SELECT
    d.login          AS developer,
    r.repo_name      AS repository,
    c.commits_count  AS commits,
    c.role           AS contrib_role,
    o.access_level   AS ownership
FROM Developer d, Contributes c, Repository r, Owns o
WHERE MATCH(d-(c)->r AND d-(o)->r)
ORDER BY c.commits_count DESC;

-- Запрос 2: Цепочка Org -> Dev -> Repo:
-- Найти репозитории, в которые контрибьютят члены организации
-- со звёздочками > 50 000
PRINT '=== Запрос 2: Org <- Dev -> Repo (50k+ stars) ===';
SELECT
    o.org_name       AS organization,
    d.login          AS developer,
    r.repo_name      AS repository,
    r.stars          AS stars,
    c.commits_count  AS commits
FROM Organization o, BelongsTo bt, Developer d, Contributes c, Repository r
WHERE MATCH(o<-(bt)-d-(c)->r)
  AND r.stars > 50000
ORDER BY r.stars DESC;

-- Запрос 3: Цепочка Dev -> Org -> Repo:
-- Разработчик входит в организацию, которая владеет репозиторием
PRINT '=== Запрос 3: Dev -> Org -> Repo (через владение организации) ===';
SELECT
    d.login         AS developer,
    bt.role         AS member_role,
    o.org_name      AS organization,
    r.repo_name     AS owned_repository,
    r.language      AS language,
    r.stars         AS stars
FROM Developer d, BelongsTo bt, Organization o, Owns ow, Repository r
WHERE MATCH(d-(bt)->o-(ow)->r)
ORDER BY o.org_name, r.stars DESC;

-- Запрос 4: Внешние контрибьюторы —
-- разработчики, вносящие вклад в репозитории организаций,
-- к которым сами НЕ принадлежат
PRINT '=== Запрос 4: Внешние контрибьюторы (Dev -> Repo <- Org, Dev NOT IN Org) ===';
SELECT DISTINCT
    d.login         AS external_dev,
    d.country       AS country,
    r.repo_name     AS repository,
    o.org_name      AS repo_owner_org,
    c.commits_count AS commits
FROM Developer d, Contributes c, Repository r, Owns ow, Organization o
WHERE MATCH(d-(c)->r AND o-(ow)->r)
  AND NOT EXISTS (
      SELECT 1
      FROM BelongsTo bt2
      WHERE bt2.$from_id = d.$node_id
        AND bt2.$to_id   = o.$node_id
  )
ORDER BY o.org_name, c.commits_count DESC;

-- Запрос 5: Статистика по странам разработчиков —
-- суммарные коммиты и звёзды по языкам программирования
PRINT '=== Запрос 5: Страна разработчика -> языки репозиториев (агрегация) ===';
SELECT
    d.country                  AS developer_country,
    r.language                 AS repo_language,
    COUNT(*)                   AS repo_count,
    SUM(c.commits_count)       AS total_commits,
    SUM(c.lines_added)         AS total_lines_added,
    SUM(r.stars)               AS total_stars
FROM Developer d, Contributes c, Repository r
WHERE MATCH(d-(c)->r)
GROUP BY d.country, r.language
ORDER BY total_commits DESC;

-- ============================================================
-- 6. ДОПОЛНИТЕЛЬНЫЕ ЗАПРОСЫ
-- ============================================================

-- Запрос 6: Разработчики, связанные через общие репозитории
PRINT '=== Запрос 6: Разработчики через общие репозитории ===';
SELECT DISTINCT
    d1.login           AS developer_1,
    d2.login           AS developer_2,
    r.repo_name        AS common_repository,
    c1.commits_count   AS commits_by_dev1,
    c2.commits_count   AS commits_by_dev2
FROM Developer d1, Contributes c1, Repository r, Contributes c2, Developer d2
WHERE MATCH(d1-(c1)->r AND d2-(c2)->r)
  AND d1.dev_id = 1
  AND d2.dev_id != d1.dev_id
ORDER BY r.repo_name, d2.login;

-- Запрос 7: Полный граф связей
PRINT '=== Запрос 7: Полный граф (разработчики, организации, репозитории) ===';
SELECT 
    d.login AS developer,
    CONCAT('Developer ', d.dev_id) AS [Developer image],
    o.org_name AS organization,
    CONCAT('Organization ', o.org_id) AS [Organization image],
    r.repo_name AS repository,
    CONCAT('Repository ', r.repo_id) AS [Repository image],
    b.role AS member_role,
    ow.access_level AS org_ownership_level
FROM Developer d, BelongsTo b, Organization o, Owns ow, Repository r
WHERE MATCH(d-(b)->o-(ow)->r)
ORDER BY o.org_name, d.login, r.repo_name;

-- Разработчики и их вклад в репозитории
SELECT 
    d.dev_id AS IdDeveloper,
    d.login AS Developer,
    CONCAT('Developer ', d.dev_id) AS [Developer image name],
    r.repo_id AS IdRepository,
    r.repo_name AS Repository,
    CONCAT('Repository ', r.repo_id) AS [Repository image name],
    c.commits_count AS Commits,
    c.lines_added AS [Lines Added],
    c.role AS Role,
    c.contribution_date AS [Contribution Date],
    IIF(c.role = 'maintainer', 'Maintainer', 'Contributor') AS [Contributor Type]
FROM Developer d, Contributes c, Repository r
WHERE MATCH(d-(c)->r)
ORDER BY c.commits_count DESC;

-- Владельцы репозиториев (разработчики)
SELECT 
    d.dev_id AS IdOwner,
    d.login AS OwnerName,
    CONCAT('Developer ', d.dev_id) AS [Owner image name],
    r.repo_id AS IdRepository,
    r.repo_name AS Repository,
    CONCAT('Repository ', r.repo_id) AS [Repository image name],
    o.owned_since AS [Owned Since],
    o.access_level AS [Access Level],
    'Developer' AS [Owner Type]
FROM Developer d, Owns o, Repository r
WHERE MATCH(d-(o)->r)
UNION ALL
SELECT 
    org.org_id AS IdOwner,
    org.org_name AS OwnerName,
    CONCAT('Organization ', org.org_id) AS [Owner image name],
    r.repo_id AS IdRepository,
    r.repo_name AS Repository,
    CONCAT('Repository ', r.repo_id) AS [Repository image name],
    o.owned_since AS [Owned Since],
    o.access_level AS [Access Level],
    'Organization' AS [Owner Type]
FROM Organization org, Owns o, Repository r
WHERE MATCH(org-(o)->r)

ORDER BY [Owner Type], OwnerName;

-- Членство разработчиков в организациях
SELECT 
    d.dev_id AS IdDeveloper,
    d.login AS Developer,
    CONCAT('Developer ', d.dev_id) AS [Developer image name],
    o.org_id AS IdOrganization,
    o.org_name AS Organization,
    CONCAT('Organization ', o.org_id) AS [Organization image name],
    b.join_date AS [Join Date],
    b.role AS [Member Role],
    b.is_public AS [Is Public],
    IIF(b.is_public = 1, 'Public membership', 'Private membership') AS [Membership Type]
FROM Developer d, BelongsTo b, Organization o
WHERE MATCH(d-(b)->o)
ORDER BY o.org_name, b.join_date;

SELECT @@SERVERNAME
