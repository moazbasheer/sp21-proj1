-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), count(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), count(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, p.playerID, yearid
  FROM people as p, halloffame as h
  WHERE p.playerID = h.playerID AND h.inducted = 'Y'
  order by yearid desc, p.playerID asc;
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, p.playerid, s.schoolid, h.yearid
  FROM people as p, halloffame as h, collegeplaying as cp, schools as s
  WHERE p.playerid = h.playerid AND h.inducted = 'Y' AND p.playerid = cp.playerid
  AND cp.schoolID = s.schoolID AND s.schoolState = 'CA'
  order by h.yearid desc, s.schoolid asc, p.playerid asc
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, namefirst, namelast, cp.schoolid
  FROM (people as p LEFT OUTER JOIN collegeplaying as cp
	ON cp.playerid = p.playerid)
  INNER JOIN halloffame as h ON p.playerid = h.playerid
  WHERE h.inducted = 'Y'
  order by p.playerid desc, cp.schoolid asc

;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, namefirst, namelast, yearid, 
	ROUND(((H - H2B - H3B - HR) + (2 * H2B + 3 * H3B + 4 * HR) * 1.0) / AB, 4) as slg
  FROM batting as b, people as p
  WHERE b.playerid = p.playerid AND AB > 50
  order by slg desc, yearid asc, p.playerid asc
  limit 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, 
	ROUND(((SUM(H) - SUM(H2B) - SUM(H3B) - SUM(HR)) + 
	(2 * SUM(H2B) + 3 * SUM(H3B) + 4 * 	SUM(HR)) * 1.0) / SUM(AB), 4) as lslg
  FROM batting as b, people as p
  WHERE b.playerid = p.playerid
  group by b.playerid
  having SUM(b.AB) > 50
  order by lslg desc, p.playerid asc
  limit 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast, 
  ROUND(((SUM(H) - SUM(H2B) - SUM(H3B) - SUM(HR)) + (2 * SUM(H2B) + 3 * SUM(H3B) + 4 * SUM(HR)) * 1.0) / SUM(AB), 4) as lslg
  FROM batting as b, people as p
  WHERE b.playerid = p.playerid
  GROUP BY b.playerid
  having SUM(b.AB) > 50 AND lslg > (
      SELECT ROUND(((SUM(H) - SUM(H2B) - SUM(H3B) - SUM(HR)) + (2 * SUM(H2B) + 3 * SUM(H3B) + 4 * SUM(HR)) * 1.0) / SUM(AB), 4) 
      FROM batting as b
      WHERE b.playerid = 'mayswi01'
      GROUP BY b.playerid
  )
  ORDER BY p.namefirst, p.namelast
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearID, min(salary), max(salary), ROUND(AVG(salary), 4)
  FROM salaries
  group by yearID
  order by yearid asc
;


-- Helper table for 4ii
DROP TABLE IF EXISTS binids;
CREATE TABLE binids(binid);
INSERT INTO binids VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  with a as (select min(salary) as mn from salaries where yearID = 2016),
     b as (select max(salary) as mx from salaries where yearID = 2016),
     c as (select count(*) as cnt from binids)
	select * from (
	SELECT binid, mn + (mx - mn) * binid / cnt, 
	       mn + (mx - mn) * (binid + 1) / cnt, 
	       (
		   select count(salary) 
		   from salaries
		   where yearID = 2016 AND salary >= mn + (mx - mn) * binid / cnt 
		   AND salary < mn + (mx - mn) * (binid + 1) / cnt
	       )
	FROM binids, a, b, c
	WHERE binid < 9
	union
	SELECT 9, mn + (mx - mn) * 9 / cnt, mx, 
	       (
		   select count(salary) 
		   from salaries
		   where yearID = 2016 AND salary >= mn + (mx - mn) * 9 / cnt 
		   AND salary <= mx
	       )
	FROM a, b, c)
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  with a as (select yearid, min(salary) mn, max(salary) mx, avg(salary) ag 
	     from salaries
	     group by yearid)
  SELECT a1.yearid, a1.mn - a2.mn, a1.mx - a2.mx, ROUND(a1.ag - a2.ag, 4)
  FROM a as a1, a as a2
  WHERE a1.yearid = a2.yearid + 1
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, namefirst, namelast, salary, yearid
  FROM people as p natural join salaries as s
  WHERE p.playerid = s.playerid 
	AND salary = (select max(salary) from salaries where yearid = s.yearid)
	AND yearid IN (2000, 2001)
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT asf.teamID, max(s.salary) - min(s.salary)
  FROM allstarfull as asf, salaries as s
  WHERE asf.playerid = s.playerid AND asf.yearID = 2016 AND asf.yearID = s.yearID 
  group by asf.teamID
;

