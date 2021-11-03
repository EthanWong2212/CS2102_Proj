DROP TABLE IF EXISTS departments, meetingRooms, employees, eContacts, health_declaration, sessions, session_part, mr_update CASCADE;


CREATE TABLE departments (
   did integer PRIMARY KEY,
   dname VARCHAR(255) UNIQUE
);

CREATE TABLE meetingRooms (
	room integer,
	floor integer,
   -- If did, null meeting room does not exist
   did integer,
	rname VARCHAR(255),
	PRIMARY KEY (room,floor),
   -- located in department
   FOREIGN KEY (did) REFERENCES departments (did) ON UPDATE CASCADE
);

CREATE TABLE employees (
   eid serial PRIMARY KEY,
   ename VARCHAR(255),
   email VARCHAR(255) UNIQUE,
   resigned_date DATE DEFAULT NULL,
   -- participation constraint
   did integer,
   kind integer check((kind >= 0 AND kind <= 2) OR kind IS NULL),
   qe_date DATE DEFAULT NULL,
   -- works in department
   FOREIGN KEY (did) REFERENCES departments (did) ON UPDATE CASCADE
);
-- multivalue attribute of employees 
CREATE TABLE eContacts (
   eid integer,
   contact integer NOT NULL,
   PRIMARY KEY (eid, contact),
   FOREIGN KEY (eid) REFERENCES employees (eid) ON DELETE CASCADE
);

CREATE TABLE health_declaration (
   eid integer,
   ddate DATE NOT NULL DEFAULT CURRENT_DATE check (ddate >= CURRENT_DATE),
   temp float8 NOT NULL check (temp >= 34 AND temp <= 43),
   fever boolean NOT NULL,
   PRIMARY KEY(eid, ddate),
   -- Weak entity
   FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
);


-- CREATE TABLE quarantine (
--    eid integer PRIMARY KEY,
--    edate DATE NOT NULL
--    FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
-- )

-- -- ISA employee
-- CREATE TABLE junior (
--    eid integer PRIMARY KEY,
--    FOREIGN KEY (eid) REFERENCES employees (eid) ON DELETE CASCADE
-- );
-- -- ISA employee
-- CREATE TABLE booker (
--    eid integer PRIMARY KEY,
--    FOREIGN KEY (eid) REFERENCES employees(eid) ON DELETE CASCADE
-- );
-- -- ISA booker
-- CREATE TABLE senior (
--    eid integer PRIMARY KEY,
--    FOREIGN KEY (eid) REFERENCES booker(eid) ON DELETE CASCADE
-- );
-- -- ISA booker
-- CREATE TABLE manager (
--    eid integer PRIMARY KEY,
--    FOREIGN KEY (eid) REFERENCES booker(eid) ON DELETE CASCADE
-- );

CREATE TABLE sessions (
   -- participation constraint
   book_id integer NOT NULL,
   stime TIME,
   sdate DATE,
   room integer,
   floor integer,
   curr_cap integer,
   approve_id integer,

   PRIMARY KEY (stime, sdate, room, floor),
   FOREIGN KEY (room, floor) REFERENCES meetingRooms (room, floor) ON UPDATE CASCADE,
   -- deletes meeting session when booker no longer authorized
   FOREIGN KEY (book_id) REFERENCES employees (eid) ON UPDATE CASCADE,
   -- manager approves sessions
   FOREIGN KEY (approve_id) REFERENCES employees (eid) ON UPDATE CASCADE

);

-- join relation between employees and sessions
CREATE TABLE session_part (
   stime TIME,
   sdate DATE,
   room integer,
   floor integer,
   -- join participation constraint
   eid integer NOT NULL,

   PRIMARY KEY (stime, sdate, room, floor, eid),
   FOREIGN KEY (stime, sdate, room, floor) REFERENCES sessions (stime, sdate, room, floor) ON DELETE CASCADE,
   FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
);

CREATE TABLE mr_update (
   eid integer NOT NULL,
   udate DATE,
   new_cap integer,
   room integer,
   floor integer,
   PRIMARY KEY (udate, room, floor),
   FOREIGN KEY (room, floor) REFERENCES meetingRooms (room, floor) ON DELETE CASCADE,
   FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
);

-- CREATE TABLE deleted_past_part (
--    eid integer NOT NULL PRIMARY KEY,
--    stime integer NOT NULL,
--    room integer NOT NULL,
--    floor integer NOT NULL,
--    PRIMARY KEY (eid, stime, room, floor),
--    FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
-- );