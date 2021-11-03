DELETE FROM session_part;
DELETE FROM mr_update;
DELETE FROM sessions;
DELETE FROM health_declaration;
DELETE FROM employees;
DELETE FROM eContacts;
DELETE FROM meetingRooms;
DELETE FROM departments;

--1 insert into departments
insert into departments (did, dname) values (1, 'Sales');
insert into departments (did, dname) values (2, 'IT');
insert into departments (did, dname) values (3, 'Compliance');
insert into departments (did, dname) values (4, 'Research');
insert into departments (did, dname) values (5, 'HR');
insert into departments (did, dname) values (6, 'Supply Chain');
insert into departments (did, dname) values (7, 'Support');
insert into departments (did, dname) values (8, 'Transport');
insert into departments (did, dname) values (9, 'Cleanliness');

SELECT * from departments;

-- 2 insert employees
insert into employees (eid, ename, email, did, kind) values (1, 'Clo Allright', 'callright0@deviantart.com', 2, 3);
insert into employees (eid, ename, email, did, kind) values (2, 'Innis Varvara', 'ivarvara1@arstechnica.com', 3, 2);
insert into employees (eid, ename, email, did, kind) values (3, 'Elspeth Dumbrell', 'edumbrell2@mashable.com', 4, 0);
insert into employees (eid, ename, email, did, kind) values (4, 'Jean Leeman', 'jleeman3@ftc.gov', 5, 1);
insert into employees (eid, ename, email, did, kind) values (5, 'Antonie Reightley', 'areightley4@google.fr', 6, 2);
insert into employees (eid, ename, email, did, kind) values (6, 'Ranna Donoher', 'rdonoher5@tmall.com', 7, 0);
insert into employees (eid, ename, email, did, kind) values (7, 'Hew Huckfield', 'hhuckfield6@plala.or.jp', 8, 1);
insert into employees (eid, ename, email, did, kind) values (8, 'Cecil Concannon', 'cconcannon7@nifty.com', 9, 2);
insert into employees (eid, ename, email, did, kind) values (9, 'Burke Shrimplin', 'bshrimplin8@google.com', 1, 0);
insert into employees (eid, ename, email, did, kind) values (10, 'Melony Woolley', 'mwoolley9@vistaprint.com', 2, 1);
insert into employees (eid, ename, email, did, kind) values (11, 'Alanah Shildrake', 'ashildrakea@unicef.org', 3, 2);
insert into employees (eid, ename, email, did, kind) values (12, 'Terence Langwade', 'tlangwadeb@typepad.com', 4, 0);
insert into employees (eid, ename, email, did, kind) values (13, 'Katleen Sheppard', 'ksheppardc@google.es', 5, 1);
insert into employees (eid, ename, email, did, kind) values (14, 'Archibaldo Waterstone', 'awaterstoned@state.tx.us', 6, 2);
insert into employees (eid, ename, email, did, kind) values (15, 'Sharai Roycroft', 'sroycrofte@issuu.com', 7, 0);
insert into employees (eid, ename, email, did, kind) values (16, 'Consuela Trebilcock', 'ctrebilcockf@msu.edu', 8, 1);
insert into employees (eid, ename, email, did, kind) values (17, 'Bernette Matys', 'bmatysg@craigslist.org', 9, 2);
insert into employees (eid, ename, email, did, kind) values (18, 'Cindelyn Simon', 'csimonh@canalblog.com', 1, 0);
insert into employees (eid, ename, email, did, kind) values (19, 'Konstantine Horsewood', 'khorsewoodi@sitemeter.com', 2, 1);
insert into employees (eid, ename, email, did, kind) values (20, 'Deborah Harragin', 'dharraginj@furl.net', 3, 2);
insert into employees (eid, ename, email, did, kind) values (21, 'Camala Stimpson', 'cstimpsonk@w3.org', 4, 0);
insert into employees (eid, ename, email, did, kind) values (22, 'Sutherland Hacquel', 'shacquell@sogou.com', 5, 1);
insert into employees (eid, ename, email, did, kind) values (23, 'Russell Webborn', 'rwebbornm@opensource.org', 6, 2);
insert into employees (eid, ename, email, did, kind) values (24, 'Andras Gilman', 'agilmann@nasa.gov', 7, 0);
insert into employees (eid, ename, email, did, kind) values (25, 'Korey Bickerdyke', 'kbickerdykeo@tmall.com', 8, 1);
insert into employees (eid, ename, email, did, kind) values (26, 'Ogdon Casarini', 'ocasarinip@bluehost.com', 9, 2);
insert into employees (eid, ename, email, did, kind) values (27, 'Steve Bamblett', 'sbamblettq@newyorker.com', 1, 0);
insert into employees (eid, ename, email, did, kind) values (28, 'Sinclare McLagain', 'smclagainr@shareasale.com', 2, 1);
insert into employees (eid, ename, email, did, kind) values (29, 'Adara Sparkwell', 'asparkwells@gizmodo.com', 3, 2);
insert into employees (eid, ename, email, did, kind) values (30, 'Asia Lauritzen', 'alauritzent@nbcnews.com', 4, 0);

SELECT * FROM employees;

-- 3 insert meeting rooms
insert into meetingRooms (room, floor, did, rname) values (1, 1, 1, 'Meeting Room 1');
insert into meetingRooms (room, floor, did, rname) values (2, 1, 1, 'Meeting Room 2');
insert into meetingRooms (room, floor, did, rname) values (3, 2, 2, 'Meeting Room 3');
insert into meetingRooms (room, floor, did, rname) values (4, 2, 2, 'Meeting Room 4');
insert into meetingRooms (room, floor, did, rname) values (5, 3, 3, 'Meeting Room 5');
insert into meetingRooms (room, floor, did, rname) values (6, 4, 3, 'Meeting Room 6');
insert into meetingRooms (room, floor, did, rname) values (7, 5, 4, 'Meeting Room 7');
insert into meetingRooms (room, floor, did, rname) values (8, 6, 4, 'Meeting Room 8');
insert into meetingRooms (room, floor, did, rname) values (9, 6, 4, 'Meeting Room 9');
insert into meetingRooms (room, floor, did, rname) values (10, 6, 5, 'Meeting Room 10');
insert into meetingRooms (room, floor, did, rname) values (11, 6, 6, 'Meeting Room 11');
insert into meetingRooms (room, floor, did, rname) values (12, 6, 7, 'Meeting Room 12');
insert into meetingRooms (room, floor, did, rname) values (13, 6, 7, 'Meeting Room 13');
insert into meetingRooms (room, floor, did, rname) values (14, 7, 8, 'Meeting Room 14');
insert into meetingRooms (room, floor, did, rname) values (15, 8, 8, 'Meeting Room 15');
insert into meetingRooms (room, floor, did, rname) values (16, 9, 8,'Meeting Room 16');
insert into meetingRooms (room, floor, did, rname) values (17, 10, 9, 'Meeting Room 17');

SELECT * FROM meetingRooms;

--7
--sessions
insert into sessions (book_id , stime, sdate, room, floor, curr_cap, approve_id) values (1,'08:00:00','2021-11-01',1,1,15,1);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap, approve_id) values (1,'09:00:00','2021-11-01',1,1,15,1);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap, approve_id) values (1,'10:00:00','2021-11-01',1,1,15,1);

insert into sessions (book_id , stime, sdate, room, floor,curr_cap, approve_id) values (1,'11:00:00','2021-11-01',2,1,15,1);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (1,'12:00:00','2021-11-01',2,1,15,1);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (1,'13:00:00','2021-11-01',2,1,15,1);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (1,'16:00:00','2021-11-01',2,1,15,1);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (1,'17:00:00','2021-11-01',2,1,15,1);

insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'08:00:00','2021-11-01',3,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'09:00:00','2021-11-01',3,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'10:00:00','2021-11-01',3,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'11:00:00','2021-11-01',3,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'12:00:00','2021-11-01',4,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'13:00:00','2021-11-01',4,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'16:00:00','2021-11-01',4,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'17:00:00','2021-11-01',4,2,15,2);
insert into sessions (book_id , stime, sdate, room, floor, curr_cap,approve_id) values (2,'18:00:00','2021-11-01',4,2,15,NULL);
