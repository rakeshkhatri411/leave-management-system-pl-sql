--      Q1
CREATE TABLE new_tbl_department 
(
    department_id NUMBER(4) PRIMARY KEY,
    department_name varchar(100) NOT NULL
)

/

insert into new_tbl_department values(1,'HR');
insert into new_tbl_department values(2,'Oracle Apps Dev');
insert into new_tbl_department values(3,'Python Dev');
insert into new_tbl_department values(4,'Java Dev');
insert into new_tbl_department values(5,'QA Dev');
insert into new_tbl_department values(6,'Functional Team');

/

select * from new_tbl_department;

/

CREATE TABLE new_tbl_country
(
	country_id number(10) PRIMARY KEY, -- 1 india , 2 canada , 3 spaain.
    country_name varchar(30)
)
/
insert into new_tbl_country values(1,'india');
insert into new_tbl_country values(2,'canada');
insert into new_tbl_country values(3,'spain');

/
 select * from new_tbl_country;
/

CREATE TABLE new_tbl_employee 
(
    employee_id number(11) PRIMARY KEY,
    department_id number(4) REFERENCES new_tbl_department(department_id),
    last_name varchar(30),
    first_name varchar(30),
    full_name varchar(30),
    age number(3),
    gender VARCHAR(1), -- 'M=male, F=female',
    email_address varchar(50),
    contact_number number(15),
    salary number (15),
    account_status number(1),--  '0=inactive, 1=active'
    address varchar(100),
    city varchar(100),
    country_id number(4) REFERENCES new_tbl_country(country_id)
)
/
select * from new_tbl_employee;

/
CREATE TABLE new_tbl_leave_days
(   days_ID number (10) PRIMARY KEY,
	leave_type varchar(30) ,
    total_days number(30) ,
    country_id number(10) REFERENCES new_tbl_country(country_id)
	
)
/
insert into new_tbl_leave_days values(1,'leave Earned',24,1);
insert into new_tbl_leave_days values(2,'leave Casual',6,1);
insert into new_tbl_leave_days values(3,'leave Sick',6,1);
insert into new_tbl_leave_days values(4,'leave Other','',1);

insert into new_tbl_leave_days values(5,'leave Earned',30,2);
insert into new_tbl_leave_days values(6,'leave Casual','',2);
insert into new_tbl_leave_days values(7,'leave Sick',15,2);
insert into new_tbl_leave_days values(8,'leave Other','',2);

insert into new_tbl_leave_days values(9,'leave Earned','' ,3);
insert into new_tbl_leave_days values(10,'leave Casual','',3);
insert into new_tbl_leave_days values(11,'leave Sick','',3);
insert into new_tbl_leave_days values(12,'leave Other',50,3);

/
 select * from new_tbl_leave_days;
/

CREATE TABLE new_tbl_leave_application 
(
    application_id number(11) PRIMARY KEY,
    employee_id number(11) REFERENCES new_tbl_employee(employee_id),
    date_of_application date,
    Leave_comment varchar(100),
    from_Leave_date date,
    To_leave_date date,
    leave_type varchar(30)
)
/


/

CREATE TABLE new_tbl_leave_balance 
(
    employee_id number(11) REFERENCES new_tbl_employee(employee_id),
    country_id number(10),
    leave_type varchar(30),
    total_days number(30) 
)
/
select * from new_tbl_leave_balance;
/
--Q2
--We have requirement where we will pass City name and you need to bring all employee who lives in that city and have taken no leave.
--Q2.1
SELECT
    e.employee_id,
    e.department_id,
    e.full_name,
    e.age,
    e.email_address,
    e.city,
    e.contact_number,
    pa.from_Leave_date,
    pa.To_leave_date
FROM
    new_tbl_employee e,
    new_tbl_leave_application pa
where
    e.employee_id = pa.employee_id
    and
    e.city = 'Ahmedabad' 
	and
    SYSDATE NOT BETWEEN pa.from_Leave_date AND pa.To_leave_date;
/
--Q2.2
SELECT distinct
    e.employee_id,
    e.department_id,
    e.full_name,
    e.age,
    e.email_address,
    e.city,
    e.contact_number
FROM
    new_tbl_employee e,
    new_tbl_leave_application pa
where
    e.employee_id != pa.employee_id
    and
    e.city = 'Ahmedabad';

/
--      Q3 Triggar for insert values
CREATE OR REPLACE TRIGGER new_auto_leave_insert
AFTER INSERT ON new_tbl_employee
Referencing OLD As "OLD" NEW As "NEW"
FOR EACH ROW
DECLARE
   cursor c1 is select *
                    from   new_tbl_leave_days
                    where  country_id = :new.COUNTRY_ID;
   date_rec  new_tbl_leave_days%ROWTYPE;
   eid number(10);
   cid number(10);
BEGIN
   open c1;   
    loop
        fetch c1 into date_rec;
        EXIT WHEN C1%NOTFOUND;
            INSERT INTO new_tbl_leave_balance
                (employee_id,COUNTRY_ID,leave_type,total_days)
                values(:NEW.employee_id,:NEW.COUNTRY_ID,date_rec.leave_type,date_rec.total_days);
    end loop;
    close c1;
END new_auto_leave_insert;

/

--Q4  Procedure which tell employee that they have leave or not
set serveroutput on;

CREATE OR REPLACE procedure LeaveOrNOT
   ( eid IN number )
IS
   cursor c2 is SELECT * 
                    FROM new_tbl_leave_balance 
                    where employee_id = eid ;
   days_rec  new_tbl_leave_balance%ROWTYPE;
BEGIN
    open c2;
     loop
            fetch c2 into days_rec;
            EXIT WHEN C2%NOTFOUND;
            IF days_rec.TOTAL_DAYS >= 1 THEN
                dbms_output.put_line('employee Has Leave');
                exit;
            end if; 
            IF days_rec.TOTAL_DAYS <= 0 THEN
                dbms_output.put_line('employee Has No Leave');
                exit;
            end if;
    end loop;
    close c2;
end;
/
EXECUTE LeaveOrNOT(1);
/
--Q5 AND Q6 Trigger
CREATE OR REPLACE TRIGGER auto_leave_update
AFTER INSERT ON new_tbl_leave_application
Referencing Old As "OLD" New As "NEW"
    FOR EACH ROW
DECLARE

    country_id varchar(10);
    total_days new_tbl_leave_balance.total_days%type;
    count_days number(10);
    WeekCount number(10);
    eid tbl_leave_type.employee_id%type;
    TOL VARCHAR(20);
    FRL VARCHAR(20);
     
BEGIN
        TOL := rtrim(TO_CHAR(:new.To_leave_date, 'DAY'));
        dbms_output.put_line(TOL);
		
		FRL := rtrim(TO_CHAR(:new.from_Leave_date, 'DAY'));
        dbms_output.put_line(FRL);
		
		select country_id into country_id from new_tbl_employee where employee_id = :new.employee_id;
        dbms_output.put_line(country_id);
        
        count_days:= TO_DATE(:new.To_leave_date, 'DD-MM-YYYY') - TO_DATE(:new.from_Leave_date, 'DD-MM-YYYY') + 1  ;
        dbms_output.put_line(count_days);
        
        WeekCount :=
            to_number(to_char(:new.To_leave_date , 'WW')) -
            to_number(to_char(:new.from_Leave_date, 'WW')) +
                52 * (to_number(to_char(:new.To_leave_date, 'YYYY')) -
                to_number(to_char(:new.from_Leave_date, 'YYYY')));
        dbms_output.put_line(WeekCount);
             
            IF :new.leave_type = 'leave Earned' then
            dbms_output.put_line(1);
                IF (country_id = 1) then
                  update new_tbl_leave_balance set total_days = total_days - count_days 
                    where employee_id = :new.employee_id
							and leave_type = 'leave Earned';
                    dbms_output.put_line(2);
                ELSE
                    IF (country_id = 2 AND count_days >= 15) then
                        dbms_output.put_line(3);
                    else 
                        update new_tbl_leave_balance set total_days = (total_days - (count_days - (WeekCount * 2 ))) 
                        where employee_id = :new.employee_id
							and leave_type = 'leave Earned';
                        dbms_output.put_line(4);
                    END IF;
                END IF;
            END IF;
            dbms_output.put_line(5);
            IF :new.leave_type = 'leave Casual' then
                update new_tbl_leave_balance set total_days = (total_days -  (count_days - (WeekCount * 2 ))) 
                    where employee_id = :new.employee_id
							and leave_type = 'leave Earned'; 
            END IF;
            
            IF :new.leave_type = 'leave Sick' then
                update new_tbl_leave_balance set total_days = (total_days -  (count_days - (WeekCount * 2 ))) 
                    where employee_id = :new.employee_id
							and leave_type = 'leave Sick';
            END IF;
            
            IF :new.leave_type = 'leave other' then
                update new_tbl_leave_balance set total_days = (total_days - (count_days - (WeekCount * 2 ))) 
                    where employee_id = :new.employee_id
							and leave_type = 'leave other';
            END IF;
end;
/
--Q7 procedure is used for eny employee Leave before applying 2 time to avoid sandwich rule only then it will be work.

set serveroutput on;

CREATE OR REPLACE procedure AddWeeks
   ( eid IN number)
IS
    findweek number(10);
    enumber number (10);
    ltype varchar (50);
    L_country_id number(10);
    min_date date;
    max_date date;

BEGIN
    select  dt.EMPLOYEE_ID,
            dt.leave_type,
            min(dt.FROM_LEAVE_DATE) as start_date,-- min(dt.FROM_LEAVE_DATE)||'-'||
            max(dt.TO_LEAVE_DATE ) as FromTo
            into enumber ,ltype ,min_date,max_date
            from NEW_TBL_LEAVE_APPLICATION dt
            where dt.FROM_LEAVE_DATE >=sysdate and  
            EMPLOYEE_ID = eid
            group by dt.EMPLOYEE_ID ,leave_type;
            dbms_output.put_line('max_date ' || max_date);
            dbms_output.put_line('min_date ' || min_date);
            dbms_output.put_line('ltype ' || ltype);

    select country_id into L_country_id from new_tbl_employee where employee_id = eid;
        dbms_output.put_line(L_country_id);
        
    findweek := 
        to_number(to_char(max_date , 'WW')) -
        to_number(to_char(min_date, 'WW')) +
        52 * (to_number(to_char(max_date, 'YYYY')) -
        to_number(to_char(min_date, 'YYYY')));
    
     dbms_output.put_line('findweek' || findweek);
            IF (ltype = 'leave Earned' and L_country_id = 1 )then
            dbms_output.put_line(1);
                update new_tbl_leave_balance set total_days = total_days - (findweek *2)
                    where employee_id = eid
                        and leave_type = 'leave Earned';
                dbms_output.put_line(2);
            end if;

end;
/
EXECUTE AddWeeks(1);
/
--Q7.1 procedure is used for eny employee Leave after and before applying 2 time to avoid sandwich rule only then it will be work.

set serveroutput on;

CREATE OR REPLACE procedure AddWeeks
   ( eid IN varchar2)
IS
    findweek number(10);
    enumber number (10);
    ltype varchar (50);
    L_country_id number(10);
    min_date date;
    max_date date;

BEGIN
    -- last record quary
    SELECT FROM_LEAVE_DATE,employee_id into min_date,enumber FROM (
       SELECT EMPLOYEE_ID, FROM_LEAVE_DATE, 
       row_number() OVER(ORDER BY FROM_LEAVE_DATE DESC) row_num
       FROM NEW_TBL_LEAVE_APPLICATION)  
       NEW_TBL_LEAVE_APPLICATION
       WHERE row_num = 2  and EMPLOYEE_ID = 1; 
    
    --  Maximum record quary
    SELECT TO_LEAVE_DATE,leave_type into max_date,ltype
    FROM NEW_TBL_LEAVE_APPLICATION
            where TO_LEAVE_DATE = (SELECT MAX (TO_LEAVE_DATE) AS "Max Date" 
                    FROM NEW_TBL_LEAVE_APPLICATION
                    where EMPLOYEE_ID = 1) 
                and EMPLOYEE_ID = 1;
       
    select country_id into L_country_id from new_tbl_employee where employee_id = eid;
        dbms_output.put_line(L_country_id);
            
    findweek := 
        to_number(to_char(max_date , 'WW')) -
        to_number(to_char(min_date, 'WW')) +
        52 * (to_number(to_char(max_date, 'YYYY')) -
        to_number(to_char(min_date, 'YYYY')));
    
     dbms_output.put_line('findweek' || findweek);
            IF (ltype = 'leave Earned' and L_country_id = 1 )then
            dbms_output.put_line(1);
                update new_tbl_leave_balance set total_days = total_days - (findweek *2)
                    where employee_id = eid
                        and leave_type = 'leave Earned';
                dbms_output.put_line(2);
            end if;

end;
/
EXECUTE AddWeeks(1);
/

insert into new_tbl_employee values(1,1,'khatri','Rakesh','khari rakesh',23,'M','rakesh411@gmail.com',7034124764,40000,1,'a13 mahadevnagar','Ahmedabad',1);
insert into new_tbl_employee values(2,3,'soni','muskan','soni muskan',25,'F','muskan@gmail.com',5554124764,47000,1,'a13 swaika','winnipeg',2);
insert into new_tbl_employee values(3,4,'patel','naina','patel naina',39,'F','naina@mail.com',5464124765,2000,1,'123 B','gandhinagar',1);
--insert into new_tbl_employee values(4,2,'shah','raj','shah raj',27,'M','raj@gmail.com',3245124764,40700,1,'12 kubernagar','barcelona',3);
--insert into new_tbl_employee values(5,4,'patel','naina','patel naina',39,'F','naina@mail.com',5464124765,2000,1,'123 B','gandhinagar',1);

/
insert into new_tbl_leave_application values(1,1,'1-sep-2022','NO','12-oct-2022','14-oct-2022','leave Earned'); --1,2
insert into new_tbl_leave_application values(2,1,'1-sep-2022','NO','17-oct-2022','19-oct-2022','leave Earned');
--
insert into new_tbl_leave_application values(3,3,'1-sep-2022','NO','28-sep-2022','30-sep-2022','leave Earned'); --1,2
insert into new_tbl_leave_application values(4,3,'1-sep-2022','NO','03-oct-2022','05-oct-2022','leave Earned');
--insert into new_tbl_leave_application values(3,1,'1-sep-2022','NO','01-sep-2022','05-sep-2022','leave Casual'); --1
--insert into new_tbl_leave_application values(4,1,'1-sep-2022','NO','01-sep-2022','06-sep-2022','leave Sick');   --1,2
--insert into new_tbl_leave_application values(5,1,'1-sep-2022','NO','01-sep-2022','06-sep-2022','leave Other');  -- 
  
/
select * from new_tbl_employee;
/
select * from new_tbl_leave_application;
/
select * from new_tbl_leave_balance;



/
delete from new_tbl_leave_balance where 1=1;
/
delete from new_tbl_employee where 1=1;

/
delete from new_tbl_leave_application where 1=1;

commit;
