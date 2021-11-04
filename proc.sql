-- CREATE OR REPLACE PROCEDURE <procedure name>
-- 	(<param> <type>,
-- 	<param> <type>)
-- AS $$
-- BEGIN
-- 	<code>
-- END;
-- $$
-- LANGUAGE plpgsql;


-- LEAVES FUTURE COMMITMENTS
CREATE OR REPLACE FUNCTION handle_leave_future()
RETURNS TRIGGER
AS $$
BEGIN
	-- DELETE ALL SESSIONS BOOKED 
	DELETE FROM sessions s WHERE s.book_id = NEW.eid AND s.sdate >= NEW.resigned_date;
	-- DELETE ALL SESSION PART AFTER R_DATE
	-- UPDATE sessions
	-- SET curr_cap = curr_cap - 1
	-- FROM sessions s, session_part sp 
	-- WHERE sp.eid = NEW.eid
	-- AND s.stime = sp.stime
	-- AND s.sdate = sp.sdate
	-- AND s.room = sp.room
	-- AND s.floor = sp.floor
	-- AND s.sdate >= NEW.resigned_date;
	
	DELETE FROM session_part sp WHERE sp.eid = NEW.eid AND sp.sdate >= NEW.resigned_date; 
	RETURN NEW;
END;
$$
LANGUAGE plpgsql;

/*
* Basic functionalities
*/
-- TRIGGER FOR EMPLOYEE RESIGNING
DROP TRIGGER IF EXISTS resigning_employee ON employees;
CREATE TRIGGER resigning_employee
BEFORE UPDATE ON employees
-- RESIGNED DATE IS NOT NULL IMPLIES RESIGNATION
FOR EACH ROW WHEN (NEW.resigned_date IS NOT NULL)
EXECUTE FUNCTION handle_leave_future();

-- SETS meetingRooms did to null to indicate deleted
CREATE OR REPLACE FUNCTION del_dep()
RETURNS TRIGGER
AS $$
BEGIN
	UPDATE meetingRooms
	SET did = NULL
	WHERE did = OLD.did;

	-- Resign employee
	UPDATE employees 
	SET resigned_date = CURRENT_DATE, 
		did = NULL
	WHERE did = OLD.did;


	RETURN OLD;
END;
$$
LANGUAGE plpgsql;


-- TRIGGER FOR DELETING DEPARTMENT
DROP TRIGGER IF EXISTS del_dep_trig ON departments;
CREATE TRIGGER del_dep_trig
BEFORE DELETE ON departments
FOR EACH ROW
EXECUTE FUNCTION del_dep();

CREATE OR REPLACE FUNCTION check_fever()
RETURNS TRIGGER 
AS $$
BEGIN
	IF NEW.temp > 37.5
	THEN 
		NEW.fever := TRUE;
		DELETE FROM sessions s WHERE s.book_id = NEW.eid AND s.sdate >= NEW.ddate;
		DELETE FROM session_part sp WHERE sp.eid = NEW.eid AND sp.sdate >= NEW.ddate;
		EXECUTE contact_tracing(NEW.eid); 
	ELSE
		NEW.fever := FALSE;
	END IF;

	RETURN NEW;
END;
$$
LANGUAGE plpgsql;


-- TRIGGER FOR TEMPERATURE DECLARATION
DROP TRIGGER IF EXISTS temp_declared ON health_declaration;
CREATE TRIGGER temp_declared
BEFORE INSERT ON health_declaration
FOR EACH ROW EXECUTE FUNCTION check_fever();



CREATE OR REPLACE PROCEDURE add_department 
	(did integer,
	dname VARCHAR(255))
AS $$
BEGIN
	INSERT INTO departments VALUES (did, dname);
END;
$$
LANGUAGE plpgsql;

-- requires existing department to replace
--DROP PROCEDURE remove_department(integer);
CREATE OR REPLACE PROCEDURE remove_department
	(id integer)
AS $$
BEGIN
	DELETE FROM departments d WHERE d.did = id;
END;
$$
LANGUAGE plpgsql;


--DROP PROCEDURE add_room;
CREATE OR REPLACE PROCEDURE add_room
	(floor integer,
	room integer,
	rname VARCHAR(255),
	cap integer,
	d_id integer,
	udate DATE,
	e_id integer)
AS $$
BEGIN
	IF EXISTS(SELECT 1 FROM employees e 
		WHERE e.eid = e_id AND e.kind = 2 AND e.did = d_id)
		THEN
			INSERT INTO meetingRooms VALUES (room, floor, d_id, rname);
			INSERT INTO mr_update VALUES (e_id, udate, cap, room, floor);
	ELSE
		RAISE NOTICE 'Unauthorized to add room';
	END IF;
END;
$$
LANGUAGE plpgsql;

-- SELECT * from meetingRooms;

-- SELECT add_room(100,100,'Heaven', 50, 2, '2021-11-01', 2);

-- kind 0,1,2

CREATE OR REPLACE PROCEDURE add_employee
	(ename VARCHAR(255),
	email VARCHAR(255),
	did integer,
	kind integer,
	contact integer)
AS $$
DECLARE
	id integer := 0; 
BEGIN
	INSERT INTO employees (ename, email, did, kind) VALUES (ename, email, did, kind);
	SELECT LASTVAL() INTO id;
	INSERT INTO eContacts VALUES (id, contact);
END;
$$
LANGUAGE plpgsql;
	

-- date YYYY-MM-DD
CREATE OR REPLACE PROCEDURE remove_employee
	(id integer,
	r_date DATE)
AS $$
BEGIN
	-- Set resign_date triggers resigning_employee;
	UPDATE employees
	SET resigned_date = r_date
	WHERE eid = id;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE declare_health
	(id integer,
	d_date DATE,
	temp float8)
AS $$
BEGIN
	INSERT INTO health_declaration VALUES (id, d_date, temp);
END;
$$
LANGUAGE plpgsql;


-- CREATE OR REPLACE PROCEDURE leave_next_7
-- 	(id integer,
-- 	s_date DATE)
-- AS $$
-- BEGIN
-- 	DELETE FROM sessions s WHERE (s.book_id = id AND s.sdate >= s_date AND s.sdate <= s_date + 7);

-- 	UPDATE sessions
-- 	SET cap = OLD.cap - 1
-- 	FROM sessions s, session_part sp 
-- 	WHERE sp.eid = id
-- 	AND s.stime = sp.stime
-- 	AND s.sdate = sp.sdate
-- 	AND s.room = sp.room
-- 	AND s.floor = sp.floor
-- 	AND s.sdate >= s_date
-- 	AND s.sdate <= s_date + 7;
	
-- 	DELETE FROM session_part sp WHERE (sp.eid = id AND sp.sdate >= s_date AND sp.sdate <= s_date + 7); 
-- END;
-- $$ 
-- LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION contact_tracing 
	(id integer)
RETURNS TABLE (Eid integer)
AS $$
BEGIN
	WITH closeContact AS
		(SELECT DISTINCT sp2.eid AS eid
		FROM session_part sp, session_part sp2
		WHERE sp.eid = id
		AND sp2.eid <> id
		AND sp2.stime = sp.stime
		AND sp2.sdate = sp.sdate
		AND sp2.room = sp.room
		AND sp2.floor = sp.floor
		AND sp.sdate > CURRENT_DATE -3)

	-- Delete meetings which were booked
	DELETE FROM sessions s WHERE (s.book_id IN (SELECT * FROM closeContact) AND s.sdate >= CURRENT_DATE AND s.sdate <= CURRENT_DATE + 7);

	-- Remove meetings participating
	/*UPDATE sessions
	SET curr_cap = curr_cap - 1
	FROM sessions s, session_part sp, closeContact cc
	WHERE sp.eid = cc.eid
	AND s.stime = sp.stime
	AND s.sdate = sp.sdate
	AND s.room = sp.room
	AND s.floor = sp.floor
	AND s.sdate >= CURRENT_DATE
	AND s.sdate <= CURRENT_DATE + 7;*/
	
	DELETE FROM session_part sp WHERE (sp.eid = id AND sp.sdate >= CURRENT_DATE AND sp.sdate <= CURRENT_DATE + 7); 
	
	-- add to quarantine
	UPDATE employees SET qe_date = CURRENT_DATE + 7 FROM closeContact cc, employees e WHERE cc.eid = e.eid;
	UPDATE employees SET qe_date = CURRENT_DATE + 7 FROM employees e WHERE id = e.eid;



	RETURN QUERY SELECT cc.eid FROM closeContact;
	
END;
$$
LANGUAGE plpgsql;

/**
 * Core Functionalities
 */

/*
* Search room function seeks out all avail room
* Assumption that updated table where one meeting room has one entry in mr update
*/
--DROP FUNCTION search_room;

CREATE OR REPLACE FUNCTION search_room  
    (IN capacity INTEGER, IN intended_date DATE, IN start_hr TIME, IN end_hr TIME) 
    RETURNS TABLE(res_floor INTEGER, res_room INTEGER, res_did INTEGER, res_cap INTEGER) AS $$
    BEGIN 
		IF (start_hr > end_hr) THEN
			RAISE NOTICE 'Exception caught: Start hour cannot be more than end hour, No change made!'; 
			RETURN;
		END IF;
		
		RETURN QUERY
			WITH capacity_time_check AS(
				SELECT u.floor,u.room
				FROM mr_update u INNER JOIN meetingRooms mr
					ON u.floor = mr.floor
					AND u.room = mr.room
				WHERE new_cap > capacity
				EXCEPT
				SELECT s.floor, s.room  
				FROM sessions s
				WHERE sdate = intended_date
				AND stime >= start_hr
				AND stime < end_hr
				ORDER BY floor,room 
			)
			SELECT ctc.floor, ctc.room, mr.did, mru.new_cap
			FROM capacity_time_check ctc 
			INNER JOIN meetingRooms mr ON ctc.floor = mr.floor AND ctc.room = mr.room
			INNER JOIN mr_update mru ON mru.floor = mr.floor AND mru.room = mr.room;

	END
	$$ LANGUAGE plpgsql;

-- SELECT search_room(30,'2021-11-01','09:00:00', '10:00:00');




/*
* book room function books a room for the given 1hr time slot
* Condition to check: Emp is a booker
* Emp is a booker : Manager or senior
* Room is available
* employee not having fever
*/
CREATE OR REPLACE PROCEDURE book_room
	(floor_num INTEGER,
	room_num INTEGER,
	booking_date DATE,
	start_hr TIME,
	end_hr TIME,
	booker_eid INTEGER)
AS $$
DECLARE
hasFever BOOLEAN; -- has fever for the past 7 days
tempTime TIME; -- increments by 1
endTime TIME;
BEGIN

	SELECT EXISTS(
	SELECT fever from health_declaration hd
	WHERE eid = booker_eid
	AND ddate >= CURRENT_DATE - integer '6'
	AND ddate <= CURRENT_DATE
	AND fever = TRUE)
	INTO hasFever;

	-- SELECT fever from health_declaration hd
	-- INTO hasFever
	-- WHERE eid = booker_eid
	-- AND ddate = CURRENT_DATE;

	tempTime := start_hr;
	endTime := end_hr;
	
	IF (start_hr > end_hr) THEN
		RAISE NOTICE 'Exception caught: Start hour cannot be more than end hour, No change made!'; 
		RETURN;
	END IF;

	IF NOT EXISTS(SELECT 1 FROM employees e WHERE e.eid = booker_eid AND (e.kind = 1 OR e.kind = 2)) THEN
		RAISE NOTICE 'Exception caught: Employee is not a booker (Senior/ Manager), No change made!';
		RETURN;
	END IF;

	IF NOT EXISTS (SELECT 1 from health_declaration c WHERE c.eid = booker_eid AND c.ddate = CURRENT_DATE) THEN
		RAISE NOTICE 'Exception caught: Employee has not made his declaration and no booking can be made! No change made!'; 
		RETURN;
	END IF;

	IF hasFever THEN
		RAISE NOTICE 'Exception caught: Employee has a fever and no booking can be made! No change made!'; 
		RETURN;
	END IF;

	WHILE (tempTime < endTime) LOOP
		INSERT INTO sessions (book_id , stime, sdate, room, floor, curr_cap, approve_id) values (booker_eid,tempTime,booking_date,room_num,floor_num,1,NULL);  
		INSERT INTO session_part (stime, sdate, room, floor, eid) VALUES (tempTime, booking_date, room_num, floor_num, booker_eid);
		tempTime := tempTime + interval '1' hour;
	END LOOP;		

END;
$$
LANGUAGE plpgsql;


-- CALL book_room(1,2,'2021-10-03','08:00:00','13:00:00' , 1);

-- SELECT * from sessions;

-- SELECT * from session_part;

-- DELETE FROM sessions 
-- WHERE sdate = '2021-10-03';


-- SELECT * from health_declaration;
-- DELETE from health_declaration
-- WHERE eid = 1
-- AND temp = 38.1;

-- SELECT fever FROM health_declaration c
-- WHERE c.eid = 1 

/*
* unbook room function unbooks a room for all timeslots within a range
* Condition to check: unbooker_eid is the one that made the booking
* Emp is a booker : Manager or senior
* Room is available
* employee not having fever
*/
CREATE OR REPLACE PROCEDURE unbook_room
	(floor_num INTEGER,
	room_num INTEGER,
	booking_date DATE,
	start_hr TIME,
	end_hr TIME,
	booker_eid INTEGER)
AS $$
DECLARE
	check_booker INTEGER;
BEGIN		
	SELECT book_id FROM sessions s
	INTO check_booker
	WHERE s.stime = start_hr
	AND s.sdate = booking_date
	AND s.room = room_num
	AND s.floor = floor_num;

	IF (booker_eid <> check_booker) THEN
		RAISE NOTICE 'You are not the person that made this booking'; 
		RETURN;
	END IF;

	DELETE FROM sessions s
	WHERE s.book_id = booker_eid 
	AND s.floor = floor_num
	AND s.room = room_num
	AND s.sdate = booking_date
	AND s.stime >= start_hr
	AND s.stime < end_hr;

END;
$$
LANGUAGE plpgsql;

-- CALL unbook_room(1,2,'2021-10-03','08:00:00','13:00:00' , 1);
-- SELECT * from sessions;

-- Join meeting 
CREATE OR REPLACE PROCEDURE join_meeting
	(j_floor integer,
	j_room integer,
	j_sdate DATE,
	j_stime time,
	j_etime time,
	j_eid integer
	)
AS $$
DECLARE
hasFever BOOLEAN;
BEGIN
	SELECT EXISTS(
		SELECT fever from health_declaration hd
		WHERE eid = j_eid
		AND ddate > CURRENT_DATE - integer '6'
		AND ddate <= CURRENT_DATE
		AND fever = TRUE)
		INTO hasFever;

		IF (j_etime <= j_stime) THEN
			RAISE NOTICE 'Exception caught: Start hour cannot be more than or equal to end hour, No change made!'; 
			RETURN;
		END IF;
		
		IF hasFever THEN
			RAISE NOTICE 'Exception caught: Employee has a fever and cannot join the meeting! No change made!'; 
			RETURN;
		END IF;
		
		IF NOT EXISTS (SELECT * from employees e INNER JOIN meetingRooms m ON e.did = m.did
			WHERE e.eid = j_eid AND m.floor = j_floor AND m.room = j_room AND m.did = e.did) THEN
			RAISE NOTICE 'Exception caught: Employee is not from this department and cannot join the meeting! No change made!';
			RETURN;
		END IF;

		IF NOT EXISTS (SELECT 1 from health_declaration c WHERE c.eid = j_eid AND c.ddate = CURRENT_DATE) THEN
			RAISE NOTICE 'Exception caught: Employee has not made his declaration and cannot join the meeting! No change made!'; 
			RETURN;
		END IF;

	WHILE j_stime < j_etime LOOP
		IF 	EXISTS (SELECT 1 FROM sessions s
			WHERE s.floor = j_floor 
			AND s.room = j_room 
			AND s.sdate = j_sdate
			AND s.stime = j_stime 
			AND s.approve_id IS NULL
			AND s.curr_cap < (SELECT new_cap FROM mr_update m WHERE m.floor = j_floor AND m.room = j_room))
		THEN
			INSERT INTO session_part VALUES (j_stime, j_sdate, j_room, j_floor, j_eid);
			/*UPDATE sessions s SET curr_cap = curr_cap + 1
				WHERE s.floor = j_floor AND s.room = j_room AND s.sdate = j_sdate
					AND s.stime = j_stime AND s.approve_id IS NULL;*/
			j_stime := j_stime + interval '1 hour';
		ELSE
			j_stime := j_stime + interval '1 hour';
		END IF;
	END LOOP;
END
$$
LANGUAGE plpgsql;
-- CALL join_meeting(1,1,'2021-11-01','08:00:00','09:00:00',1);

--Leave meeting
CREATE OR REPLACE PROCEDURE leave_meeting
	(l_floor integer,
	l_room integer,
	l_sdate DATE,
	l_stime time,
	l_etime time,
	l_eid integer
	)
AS $$
BEGIN
	IF (l_etime <= l_stime) THEN
		RAISE NOTICE 'Exception caught: Start hour cannot be more than or equal to end hour, No change made!'; 
		RETURN;
	END IF;

	IF EXISTS(SELECT * FROM session_part sp INNER JOIN sessions s 
		ON sp.floor = s.floor 
		AND sp.room = s.room 
		AND sp.sdate = s.sdate 
		AND sp.stime = s.stime
			WHERE s.floor = l_floor 
			AND s.room = l_room 
			AND s.sdate = l_sdate
			AND (s.stime >= l_stime AND s.stime < l_etime) 
			AND sp.eid = l_eid
			AND s.approve_id IS NULL)
		THEN
			DELETE FROM session_part sp 
				WHERE sp.floor = l_floor 
				AND sp.room = l_room 
				AND sp.sdate = l_sdate
				AND (sp.stime >= l_stime AND sp.stime < l_etime) 
				AND sp.eid = l_eid;
				/*UPDATE sessions s SET curr_cap = curr_cap - 1
					WHERE s.floor = l_floor AND s.room = l_room AND s.sdate = l_sdate
						AND (s.stime >= l_stime AND s.stime < l_etime);*/
						ELSE
			RAISE NOTICE 'No meetings found.'; 
	END IF;
END
$$
LANGUAGE plpgsql;

--Approve meeting
CREATE OR REPLACE PROCEDURE approve_meeting
	(a_floor integer,
	a_room integer,
	a_sdate DATE,
	a_stime time,
	a_etime time,
	a_eid integer
	)
AS $$
BEGIN
	IF (a_etime <= a_stime) THEN
		RAISE NOTICE 'Exception caught: Start hour cannot be more than or equal to end hour, No change made!'; 
		RETURN;
	END IF;
	
	IF NOT EXISTS (SELECT * from employees e INNER JOIN meetingRooms m ON e.did = m.did
		WHERE e.eid = a_eid AND m.floor = a_floor AND m.room = a_room AND m.did = e.did) THEN
		RAISE NOTICE 'Exception caught: Employee is not from this department and cannot approve the meeting! No change made!';
		RETURN;
	END IF;

	IF EXISTS(SELECT 1 FROM employees e WHERE e.eid = a_eid AND (e.kind = 1 OR e.kind = 0)) THEN
		RAISE NOTICE 'Exception caught: Employee is not a Manager and cannot approve the meeting!, No change made!';
		RETURN;
	END IF;

	IF EXISTS (SELECT 1 FROM sessions s
		WHERE s.floor = a_floor 
		AND s.room = a_room 
		AND s.sdate = a_sdate
		AND (s.stime >= a_stime AND s.stime < a_etime) 
		AND s.approve_id IS NULL)
		THEN
			UPDATE sessions s SET approve_id = a_eid
				WHERE s.floor = a_floor 
				AND s.room = a_room 
				AND s.sdate = a_sdate
				AND (s.stime >= a_stime AND s.stime < a_etime) 
				AND s.approve_id IS NULL;
				ELSE
			RAISE NOTICE 'No meetings to be approved within the given time.'; 
	END IF;
END
$$
LANGUAGE plpgsql;

-- CALL approve_meeting(1,1,'2021-11-01','08:00:00','09:00:00',1);



-- View Future Meeting
CREATE OR REPLACE FUNCTION view_future_meeting (f_sdate date, f_eid integer)
	RETURNS TABLE(Floor_Number INT,Room_Number INT, Date DATE, Start_hour time) AS $$
	SELECT s.floor , s.room, s.sdate, s.stime
	FROM session_part sp INNER JOIN sessions s 
	ON sp.stime = s.stime
	AND sp.sdate = s.sdate
	AND sp.room = s.room
	AND sp.floor = s.floor
	WHERE sp.eid = f_eid
	AND sp.sdate >= f_sdate
	AND s.approve_id IS NOT NULL
	ORDER BY sp.sdate, sp.stime ASC;
$$ LANGUAGE sql;

-- View Booking report 
CREATE OR REPLACE FUNCTION view_booking_report (b_sdate date, b_eid integer)
RETURNS TABLE(Floor_Number INT,Room_Number INT, Date DATE, Start_hour time, isApproved VARCHAR(5)) AS $$
	SELECT floor ,room, sdate, stime,
	CASE COALESCE(approve_id, -1) 
		WHEN -1 THEN 'False'
		ELSE 'True'
	END
	FROM sessions s
	WHERE s.book_id = b_eid
	AND s.sdate >= b_sdate;
$$ LANGUAGE sql;

-- select * from view_booking_report('2020-10-10',1);

-- Trigger to update capacity of sessions 
DROP TRIGGER IF EXISTS curr_capacity_changed ON session_part;
CREATE OR REPLACE FUNCTION update_capacity()
RETURNS TRIGGER
AS $$
BEGIN
	IF (TG_OP = 'INSERT') THEN 
		UPDATE sessions 
		SET curr_cap = curr_cap + 1
		WHERE stime = NEW.stime 
		AND sdate = NEW.sdate
		AND room = NEW.room
		AND floor = NEW.floor;
		RETURN NULL;
	ELSIF (TG_OP = 'DELETE') THEN 
		UPDATE sessions 
		SET curr_cap = curr_cap - 1
		WHERE stime = OLD.stime 
		AND sdate = OLD.sdate
		AND room = OLD.room
		AND floor = OLD.floor;
		RETURN NULL;
	END IF;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER curr_capacity_changed
AFTER INSERT OR DELETE ON session_part
FOR EACH ROW EXECUTE function update_capacity();


CREATE OR REPLACE PROCEDURE change_capacity
	(c_floor integer,
	c_room integer,
	c_capacity integer,
	c_date DATE,
	c_eid integer
	)
AS $$
BEGIN	
	IF EXISTS (SELECT * from employees e INNER JOIN meetingRooms m ON e.did = m.did
		WHERE e.eid = c_eid AND e.kind = 2 AND m.floor = c_floor AND m.room = c_room AND m.did = e.did) THEN
		UPDATE mr_update
		SET udate = c_date, new_cap = c_capacity
		WHERE floor = c_floor 
		AND room = c_room ;
		RETURN;
	END IF;
END
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS max_capacity_changed ON mr_update;
CREATE OR REPLACE FUNCTION update_sessions()
RETURNS TRIGGER
AS $$
BEGIN
	DELETE FROM sessions 
	WHERE sdate >= NEW.udate
	AND curr_cap > NEW.new_cap;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER max_capacity_changed
AFTER UPDATE ON mr_update
FOR EACH ROW EXECUTE function update_sessions();


-- non-compliance
CREATE OR REPLACE FUNCTION non_compliance 
    (s_date DATE, e_date DATE) 
RETURNS TABLE (eid integer, number_of_days integer) AS $$ 
BEGIN 
    SELECT e.eid, ((e_date - s_date + 1) - count(h.ddate)) AS number_of_days 
    FROM employees e, health_declaration h 
    WHERE e.eid = h.eid AND h.ddate >= s_date AND h.ddate <= e_date 
    GROUP BY e.eid 
    HAVING count(h.ddate) < (e_date - s_date +1) 
    ORDER BY number_of_days DESC;
END; 
$$ LANGUAGE plpgsql; 

-- view manager report
CREATE OR REPLACE FUNCTION view_manager_report 
    (s_date DATE, id integer) 
RETURNS TABLE (floor_number integer, room_number integer, date DATE, start_hour TIME, eid integer) AS $$ 
BEGIN 
    SELECT s.floor, s.room, s.sdate, s.stime, s.approve_id 
    FROM employees e, sessions s 
    WHERE id = e.eid AND e.kind = 0 AND s.sdate >= s_date AND s.approve_id IS NULL;
END;
$$ LANGUAGE plpgsql;