CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');
;

-- Таблица пиров.
CREATE TABLE IF NOT EXISTS peers (
    nickname varchar PRIMARY KEY,
    birthday date
)
;

-- Таблица заданий.
CREATE TABLE IF NOT EXISTS tasks (
    title varchar PRIMARY KEY,
    parent_task varchar NULL REFERENCES tasks(title),  -- ссылаемся на другую запись из этой же таблицы
    max_xp integer
)
;

-- Таблица проверок.
CREATE TABLE IF NOT EXISTS checks (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    peer varchar REFERENCES peers(nickname),
    task varchar REFERENCES tasks(title),
    "date" date
)
;

-- Таблица полученных XP (за успешно выполненные задания).
CREATE TABLE IF NOT EXISTS xp (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    "check" bigint NOT NULL REFERENCES checks(id),
    xp_amount integer
)
;

-- Таблица автоматических проверок (verter).
CREATE TABLE IF NOT EXISTS verter (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    "check" bigint NOT NULL REFERENCES checks(id),
    state check_status,
    "time" time
)
;

-- Таблица peer-to-peer проверок.
CREATE TABLE IF NOT EXISTS p2p (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    "check" bigint NOT NULL REFERENCES checks(id),
    checking_peer varchar REFERENCES peers(nickname),
    state check_status,
    "time" time
)
;

-- Таблица движения пир-поинтов.
CREATE TABLE IF NOT EXISTS transferred_points (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    checking_peer varchar REFERENCES peers(nickname),
    checked_peer varchar REFERENCES peers(nickname),
    points_amount integer
)
;

-- Таблица друзей.
CREATE TABLE IF NOT EXISTS friends (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    peer1 varchar REFERENCES peers(nickname),
    peer2 varchar REFERENCES peers(nickname)
)
;

-- Таблица рекомендаций.
CREATE TABLE IF NOT EXISTS recommendations (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    peer varchar REFERENCES peers(nickname),
    recommended_peer varchar REFERENCES peers(nickname)
)
;

-- Таблица учета времени.
CREATE TABLE IF NOT EXISTS time_tracking (
    id bigint PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    peer varchar REFERENCES peers(nickname),
    "date" date,
    "time" time,
    state smallint CHECK ( state BETWEEN 1 AND 2 )
)
;

--
-- Процедуры импорта/экспорта данных.
--

CREATE OR REPLACE PROCEDURE from_csv(path text, separator char = ',')
    LANGUAGE plpgsql
AS
$$
BEGIN
EXECUTE ('COPY peers FROM '''
    || path
    || '/peers.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY tasks FROM '''
    || path
    || '/tasks.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY checks (peer, task, "date") FROM '''
    || path
    || '/checks.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY xp ("check", xp_amount) FROM '''
    || path
    || '/xp.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY verter ("check", state, "time") FROM '''
    || path
    || '/verter.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY p2p ("check", checking_peer, state, "time") FROM '''
    || path
    || '/p2p.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY transferred_points (checking_peer, checked_peer, points_amount) FROM '''
    || path
    || '/transferred_points.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY friends (peer1, peer2) FROM '''
    || path
    || '/friends.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY recommendations (peer, recommended_peer) FROM '''
    || path
    || '/recommendations.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY time_tracking (peer, "date", "time", state) FROM '''
    || path
    || '/time_tracking.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
END
$$
;

CREATE OR REPLACE PROCEDURE to_csv(path text, separator char = ',')
    LANGUAGE plpgsql
AS
$$
BEGIN
EXECUTE ('COPY peers TO '''
    || path
    || '/peers.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY tasks TO '''
    || path
    || '/tasks.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY checks (peer, task, "date") TO '''
    || path
    || '/checks.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY xp ("check", xp_amount) TO '''
    || path
    || '/xp.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY verter ("check", state, "time") TO '''
    || path
    || '/verter.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY p2p ("check", checking_peer, state, "time") TO '''
    || path
    || '/p2p.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY transferred_points (checking_peer, checked_peer, points_amount) TO '''
    || path
    || '/transferred_points.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY friends (peer1, peer2) TO '''
    || path
    || '/friends.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY recommendations (peer, recommended_peer) TO '''
    || path
    || '/recommendations.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
EXECUTE ('COPY time_tracking (peer, "date", "time", state) TO '''
    || path
    || '/time_tracking.csv'' WITH (FORMAT CSV, DELIMITER '''
    || separator
    || ''')');
END
$$
;

-- Необходимо указать абсолютный путь до папки /csv.
CALL from_csv('SQL_info/src/csv')
;

-- Дополнительные данные для таблицы учета времени
INSERT INTO time_tracking(peer, "date", "time", state)
VALUES ('conor', CURRENT_DATE - 1, '10:15', 1),
       ('papuas', CURRENT_DATE - 1, '11:10', 1),
       ('papuas', CURRENT_DATE - 1, '13:48', 2),
       ('papuas', CURRENT_DATE - 1, '15:03', 1),
       ('conor', CURRENT_DATE - 1, '18:15', 2),
       ('papuas', CURRENT_DATE - 1, '20:10', 2),
       ('conor', CURRENT_DATE, '08:15', 1),
       ('conor', CURRENT_DATE, '11:30', 2),
       ('bellatri', CURRENT_DATE, '11:50', 1),
       ('conor', CURRENT_DATE, '12:18', 1),
       ('gerasim', CURRENT_DATE, '12:26', 1),
       ('bellatri', CURRENT_DATE, '13:50', 2),
       ('bellatri', CURRENT_DATE, '14:30', 1),
       ('conor', CURRENT_DATE, '16:30', 2),
       ('conor', CURRENT_DATE, '16:44', 1),
       ('gerasim', CURRENT_DATE, '18:37', 2),
       ('bellatri', CURRENT_DATE, '19:00', 2),
       ('conor', CURRENT_DATE, '21:02', 2)
;