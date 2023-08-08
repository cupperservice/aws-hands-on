CREATE DATABASE `wordpress-db`;

use `wordpress-db`;

CREATE TABLE student (
  id          INTEGER AUTO_INCREMENT,
  first_name  VARCHAR(100) NOT NULL,
  last_name   VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE class (
  id          INTEGER AUTO_INCREMENT,
  class_name  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE score (
  id          INTEGER AUTO_INCREMENT,
  student_id  INTEGER,
  class_id    INTEGER,
  score       INTEGER,
  PRIMARY KEY (id)
);

INSERT INTO student (id, first_name, last_name) VALUES
(1, 'Taro', 'Suzuki'),
(2, 'Hanako', 'Mochizuki'),
(3, 'Yuko', 'Tanaka'),
(4, 'Tomoko', 'Hayashi'),
(5, 'Jiro', 'Nakata');

INSERT INTO class (id, class_name) VALUES
(1, 'Mathematics'),
(2, 'English'),
(3, 'Chemistry');

INSERT INTO score (id, student_id, class_id, score) VALUES
(1, 1, 1, 90),
(2, 1, 2, 53),
(3, 1, 3, 76),
(4, 2, 1, 67),
(5, 2, 3, 43),
(6, 3, 1, 55),
(7, 3, 2, 77),
(8, 3, 3, 66),
(9, 4, 1, 100),
(10, 4, 2, 79),
(11, 4, 3, 97),
(12, 5, 1, 23),
(13, 5, 2, 45),
(14, 5, 3, 77);

SELECT a.first_name, a.last_name, b.class_name, c.score
FROM student a, class b, score c
WHERE a.id = c.student_id
  AND b.id = c.class_id
ORDER BY a.id, b.id;
