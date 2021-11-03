-- CREATE OR REPLACE PROCEDURE <procedure name>
-- 	(<param> <type>,
-- 	<param> <type>)
-- AS $$
-- BEGIN
-- 	<code>
-- END;
-- $$
-- LANGUAGE plpgsql;

/*
* Basic functionalities
*/

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
CREATE OR REPLACE PROCEDURE remove_department
	(r_did integer,
	n_did integer)
AS $$
BEGIN
	UPDATE employees
	SET did = n_did
	WHERE did = r_did;

	UPDATE meetingRooms
	SET did = n_did
	WHERE did = r_did;

	DELETE FROM departments
	WHERE did = r_did;

END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_room
	(floor integer,
	room integer,
	rname VARCHAR(255),
	cap integer,
	did integer,
	udate DATE,
	eid integer)
RETURN 
AS $$
BEGIN
	IF EXISTS(SELECT 1 FROM manager m, departments d WHERE m.eid = eid AND d.did = did)
		THEN
			INSERT INTO meetingRooms VALUES (room, floor, did, rname);
			INSERT INTO mr_update VALUES (eid, udate, cap, room, floor);
	END IF;
END;
$$
LANGUAGE plpgsql;

SELECT add_room(100,100,'Heaven', 50, 2, '2021-11-01', 2);

CREATE OR REPLACE PROCEDURE add_employee
	(eid integer,
	ename VARCHAR(255),
	email VARCHAR(255),
	did integer,
	kind integer,
	contact integer)
AS $$
BEGIN
	-- IF kind >= 0 AND kind <= 3
	-- 	THEN
			INSERT INTO employees VALUES (eid, ename, email, NULL, did, kind);
			INSERT INTO eContacts VALUES (eid, contact);
			-- IF kind = 0 
			-- THEN	
			-- 	INSERT INTO junior VALUES (eid);
			-- ELSEIF kind = 1 
			-- THEN	
			-- 	INSERT INTO booker VALUES (eid);
			-- 	INSERT INTO senior VALUES (eid);
			-- ELSEIF kind = 2
			-- THEN	
			-- 	INSERT INTO booker VALUES (eid);
			-- 	INSERT INTO manager VALUES (eid);
			-- END IF;
	-- END IF;
END;
$$
LANGUAGE plpgsql;

-- date YYYY-MM-DD
CREATE OR REPLACE PROCEDURE remove_employee
	(id integer,
	r_date DATE)
AS $$
BEGIN
	UPDATE employees
	SET resigned_date = r_date
	WHERE eid = id;

	-- DELETE FROM sessions
	-- WHERE book_id = id AND sdate >= r_date;
	
	-- DELETE FROM session_part
	-- WHERE book_id = id AND sdate >= r_date;
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
DROP FUNCTION search_room;

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
				AND stime > start_hr
				AND stime < end_hr
				ORDER BY floor,room 
			)
			SELECT ctc.floor, ctc.room, mr.did, mru.new_cap
			FROM capacity_time_check ctc 
			INNER JOIN meetingRooms mr ON ctc.floor = mr.floor AND ctc.room = mr.room
			INNER JOIN mr_update mru ON mru.floor = mr.floor AND mru.room = mr.room;

	END
	$$ LANGUAGE plpgsql;

SELECT search_room(30,'2021-11-01','09:00:00', '10:00:00');




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
	AND ddate > CURRENT_DATE - integer '6'
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


CALL book_room(1,2,'2021-10-03','08:00:00','13:00:00' , 1);

SELECT * from sessions;

SELECT * from session_part;

DELETE FROM sessions 
WHERE sdate = '2021-10-03';


SELECT * from health_declaration;
DELETE from health_declaration
WHERE eid = 1
AND temp = 38.1;

SELECT fever FROM health_declaration c
WHERE c.eid = 1 

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

CALL unbook_room(1,2,'2021-10-03','08:00:00','13:00:00' , 1);
SELECT * from sessions;