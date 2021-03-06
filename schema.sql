DROP TABLE IF EXISTS departments, meetingRooms, employees, eContacts, health_declaration, sessions, session_part, mr_update CASCADE;


CREATE TABLE departments (
   did integer PRIMARY KEY,
   dname VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE meetingRooms (
	room integer NOT NULL,
	floor integer NOT NULL,
   -- If did, null meeting room does not exist
    did integer,
	rname VARCHAR(255) NOT NULL,
	PRIMARY KEY (room,floor),
   -- located in department
   FOREIGN KEY (did) REFERENCES departments (did) ON UPDATE CASCADE
);

CREATE TABLE employees (
   eid integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
   ename VARCHAR(255) NOT NULL,
   email VARCHAR(255) UNIQUE GENERATED ALWAYS AS (REPLACE(ename, ' ', '_')|| CAST(eid AS VARCHAR(255)) || '@gmail.com') STORED,
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
   eid integer NOT NULL,
   contact integer NOT NULL UNIQUE,
   PRIMARY KEY (eid, contact),
   FOREIGN KEY (eid) REFERENCES employees (eid) ON DELETE CASCADE
);

CREATE TABLE health_declaration (
   eid integer,
   ddate DATE,
   temp float8 NOT NULL check (temp >= 34 AND temp <= 43),
   fever boolean GENERATED ALWAYS AS (temp > 37.5) STORED,
   PRIMARY KEY(eid, ddate),
   -- Weak entity
   FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
);

CREATE TABLE sessions (
   -- participation constraint
   book_id integer NOT NULL,
   stime TIME,
   sdate DATE,
   room integer,
   floor integer,
   curr_cap integer NOT NULL,
   approve_id integer,
   bdate DATE NOT NULL check(bdate <= sdate),
   CONSTRAINT session_book UNIQUE (stime, sdate, book_id), 
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
   CONSTRAINT session_part_limit UNIQUE (stime, sdate, eid), 
   PRIMARY KEY (stime, sdate, room, floor, eid),
   FOREIGN KEY (stime, sdate, room, floor) REFERENCES sessions (stime, sdate, room, floor) ON DELETE CASCADE,
   FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
);

CREATE TABLE mr_update (
   eid integer NOT NULL,
   udate DATE,
   new_cap integer NOT NULL,
   room integer,
   floor integer,
   PRIMARY KEY (udate, room, floor),
   FOREIGN KEY (room, floor) REFERENCES meetingRooms (room, floor) ON DELETE CASCADE,
   FOREIGN KEY (eid) REFERENCES employees (eid) ON UPDATE CASCADE
);
