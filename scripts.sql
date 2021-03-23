-- Create tables based on proposed schema

-- TRAINER
create table trainer
(employee_number integer not null,
fname varchar(25),
mname varchar(25),
lname varchar(25),
street1 varchar(30),
street2 varchar(25),
city varchar(25),
state varchar(10),
zip varchar(10),
phone_number varchar(15),
email varchar(25),
hire_date date,
termination_date date,
constraint pk_trainer primary key (employee_number));


-- SOFTWARE PROGRAM
create table software_program
(product_id varchar(25) not null,
name varchar(50),
publisher varchar(20),
number_of_license integer,
required_operating_system varchar(15),
constraint pk_software_program primary key (product_id));


-- BOOK
create table book
(isbn integer not null,
title varchar(50),
publisher varchar(30),
list_price number(5,2),
constraint pk_book primary key (isbn));


-- COURSE
create table course
(course_id varchar(20) not null,
course_name varchar(50),
hardware_requirement varchar(30),
standard_fee number(5,2),
length integer,
isbn integer,
constraint pk_course primary key (course_id),
constraint fk_usebook foreign key (isbn) references book (isbn));


-- PREREQUISITE
create table prerequisite
(course_id varchar(20) not null,
prerequisite_id varchar(20) not null,
constraint pk_prerequisite primary key (course_id, prerequisite_id),
constraint fk_maincourse foreign key (course_id) references course (course_id),
constraint fk_preqcourse foreign key (prerequisite_id) references course (course_id));


-- COURSE SOFTWARE
create table course_software
(course_id varchar(20) not null,
product_id varchar(25) not null,
constraint pk_course_software primary key (course_id, product_id),
constraint fk_usedin foreign key (course_id) references course (course_id),
constraint fk_software foreign key (product_id) references software_program (product_id));


-- QUALIFICATION
create table qualification
(employee_number integer not null,
course_id varchar(20) not null,
complete_date date,
constraint pk_qualification primary key (employee_number, course_id),
constraint fk_trainer foreign key (employee_number) references trainer (employee_number),
constraint fk_qualifyfor foreign key (course_id) references course (course_id));


-- AUTHOR
create table author
(isbn integer not null,
author_id varchar(20) not null,
fname varchar(25),
mname varchar(25),
lname varchar(25),
constraint pk_author primary key (isbn, author_id),
constraint fk_writesbook foreign key (isbn) references book (isbn));


-- VENDOR
create table vendor
(name varchar(30) not null,
vendor_id INTEGER not null,
phone_number varchar(20),
street1 varchar(30),
street2 varchar(25),
city varchar(25),
state varchar(10),
zip varchar(10),
constraint pk_vendor primary key (name));


-- VENDOR CATALOG
create table vendor_catalog
(isbn INTEGER not null,
name varchar(30) not null,
constraint pk_vendor_catalog primary key (isbn, name),
constraint fk_sells foreign key (isbn) references book (isbn),
constraint fk_from foreign key (name) references vendor (name));


-- CLIENT
create table client
(client_number INTEGER not null,
fname varchar(25),
mname varchar(25),
lname varchar(25),
phone_number varchar(20),
street1 varchar(30),
street2 varchar(25),
city varchar(25),
state varchar(10),
zip varchar(10),
initial_date date,
constraint pk_client primary key (client_number));


-- CLASSROOM
create table room
(room_number varchar(5) not null,
capacity INTEGER,
operating_system varchar(10),
constraint pk_room primary key (room_number));


-- MEMBERSHIP
create table membership
(membership_code varchar(15) not null,
price number(5,2),
duration varchar(10),
discount number(5,2),
constraint pk_membership primary key (membership_code));


-- ORDER
create table "ORDER"
(order_number INTEGER not null,
date_placed date,
status varchar(20),
name varchar(30) not null,
constraint pk_order primary key (order_number),
constraint fk_soldby foreign key (name) references vendor (name));


-- ORDERLINE
create table orderline
(order_number INTEGER not null,
isbn INTEGER not null,
quantity INTEGER,
unit_price number(5,2),
constraint pk_orderline primary key (isbn, order_number),
constraint fk_contains foreign key (isbn) references book (isbn),
constraint fk_linkto foreign key (order_number) references "ORDER" (order_number));


-- SHIPMENT
create table shipment
(shipment_id INTEGER not null,
order_number INTEGER not null,
delivery_date date,
constraint pk_shipment primary key (shipment_id),
constraint fk_shipfrom foreign key (order_number) references "ORDER" (order_number));


-- INVENTORY
create table inventory
(shipment_id INTEGER not null,
isbn INTEGER not null,
quantity_received INTEGER,
constraint pk_inventory primary key (shipment_id, isbn),
constraint fk_includes foreign key (isbn) references book (isbn),
constraint fk_receivefrom foreign key (shipment_id) references shipment (shipment_id));


-- CLASS
create table class
(reference_number integer not null,
start_date date,
end_date date,
start_time varchar(20),
capacity integer,
employee_number integer not null,
course_id varchar(20) not null,
room_number varchar(5) not null,
constraint pk_class primary key (reference_number),
constraint fk_taughtby foreign key (employee_number) references trainer (employee_number),
constraint fk_has foreign key (course_id) references course (course_id),
constraint fk_locatein foreign key (room_number) references room (room_number));


-- ENROLLMENT REQUEST
create table enrollment_request
(reference_number integer not null,
client_number integer not null,
requested_time varchar(10),
requested_date date,
status varchar(20),
payment number(10,2),
constraint pk_enrollment_request primary key (reference_number, client_number),
constraint fk_inclass foreign key (reference_number) references class (reference_number),
constraint fk_student foreign key (client_number) references client (client_number));


-- PAYMENT
create table payment
(client_number integer not null,
membership_code varchar(15) not null,
date_selected date,
payment_amount number(10),
constraint pk_payment primary key (client_number, membership_code, date_selected),
constraint fk_belongsto foreign key (client_number) references client (client_number),
constraint fk_obtains foreign key (membership_code) references membership (membership_code));


-- Data was then loaded into database using Excel Import function on Oracle


-- Views created to determine who should get free training sessions

/*
TRAINER QUALIFICATION LIST

Retrieve number of qualified trainers for each course to find courses that have no or only one qualified trainer. These courses would need more trainers to teach so that the school can meet client's demand.
This view is also used to find how many qualifications each trainer has.
*/ 
create view trainer_qualification_list as
select course.course_id, course.course_name, trainer.employee_number, trainer.fname as trainer_name
from (
(select employee_number, fname from trainer) trainer
full outer join
(select employee_number, course_id from qualification) qualification
on trainer.employee_number = qualification.employee_number
full outer join
(select course_id, course_name from course) course
on course.course_id = qualification.course_id)
order by course_name;


/*
COURSE DEMAND, COURSE CAPACITY, COURSE MEET DEMAND

These 3 views help find out which courses have more demand than supply, meaning the school needs to have more trainers to offer additional class sessions to clients.
*/
create view course_demand as
select course.course_id, course.course_name, client_number
from (
(select course_id, course_name from course) course
full outer join
(select course_id, reference_number from class) class
on course.course_id = class.course_id
full outer join
(select reference_number, client_number from enrollment_request) enrollment
on class.reference_number = enrollment.reference_number);

create view course_capacity as
select course.course_id, course_name, sum(capacity)as capacity
from course, class
where course.course_id = class.course_id (+)
group by course.course_id, course_name
order by course_name;

create view course_meetdemand as
select course_demand.course_id, course_demand.course_name, count(client_number) as number_of_enrollmentrequest, capacity
from course_capacity full outer join course_demand
on course_demand.course_id = course_capacity.course_id
group by course_demand.course_name, capacity, course_demand.course_id
order by course_demand.course_id;


/*
YEAR OF SERVICE

Combined with the number of qualifications each trainer has to look at the qualification progress and find out who has stayed at the school for many years but do not have as many qualifications. 
*/
create view Year_of_Service
as
select fname,((sysdate-hire_date)/365) as "Year of Service"
from trainer
Where termination_date is null
group by fname,(sysdate-hire_date)/365
order by "Year of Service" desc;