create table specialties (
  specialty_id number(10),
  specialty_name varchar2(255) not null,
  constraint specialty_pk 
    primary key (specialty_id),
  constraint specialty_name_un 
    unique (specialty_name)
);

create table subjects ( 
  subject_id number(10),
  subject_name varchar2(255) not null unique,
  constraint subject_pk 
    primary key (subject_id)
);

create table students ( 
  student_id number(10),
  student_name varchar2(255) not null,
  specialty_id number(10) not null,
  year_enrollment number(5) not null,
  constraint student_pk 
    primary key (student_id),
  constraint fk_specialties_students
    foreign key (specialty_id)
    references specialties(specialty_id)
);

create table curriculums ( 
  curriculum_id number(10),
  specialty_id number(10) not null,
  semester number(10) not null,
  subject_id number(10) not null,
  report_type varchar2(255) not null,
  constraint curriculums_pk 
    primary key (curriculum_id),
  constraint fk_specialties_curriculums
    foreign key (specialty_id)
    references specialties(specialty_id),
  constraint fk_subjects_curriculums
    foreign key (subject_id)
    references subjects(subject_id),
  constraint check_curriculums_report_type
    check (report_type in ('ZACHET', 'EXAM', 'ZACHET_WITH_MARK'))
);

create table marks ( 
  student_id number(10),
  curriculum_id number(10),
  exam_date date,
  mark number(3),
  constraint marks_pk 
    primary key (student_id, curriculum_id, exam_date),
  constraint fk_students_marks
    foreign key (student_id)
    references students(student_id),
  constraint fk_subjects_marks
    foreign key (curriculum_id)
    references curriculums(curriculum_id)
);


create sequence specialty_seq
  minvalue 1
  maxvalue 9999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger specialties_tr_set_id
  before insert on specialties
  for each row
begin
  if :new.specialty_id is null then
    select specialty_seq.nextval
      into :new.specialty_id 
      from dual;
  end if;
end;

alter trigger specialties_tr_set_id enable;

create sequence curriculums_seq
  minvalue 1
  maxvalue 9999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger curriculums_tr_set_id
  before insert on curriculums
  for each row
begin
  if :new.curriculum_id is null then
    select curriculums_seq.nextval
      into :new.curriculum_id
      from dual;
  end if;
end;

alter trigger curriculums_tr_set_id enable;

create sequence students_seq
  minvalue 1
  maxvalue 9999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger students_tr_set_id
  before insert on students
  for each row
begin
  if :new.student_id is null then
    select students_seq.nextval
      into :new.student_id
      from dual;
  end if;
end;

alter trigger students_tr_set_id enable;

create sequence subjects_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger subjects_tr_set_id
  before insert on subjects
  for each row
begin
  if :new.subject_id is null then
    select subjects_seq.nextval
      into :new.subject_id
      from dual;
  end if;
end;

alter trigger subjects_tr_set_id enable;


insert all
  into specialties (specialty_name) values ('mkn')
  into specialties (specialty_name) values ('isit')
select * from dual
;

insert all
  into students (student_name, year_enrollment, specialty_id) values ('Elizaveta', 2017, 1)
  into students (student_name, year_enrollment, specialty_id) values ('Darya', 2017, 1)
  into students (student_name, year_enrollment, specialty_id) values ('Anya', 2017, 2)
  into students (student_name, year_enrollment, specialty_id) values ('Mariya', 2017, 2)
select * from dual;

insert all
  into subjects (subject_name) values ('math')    --1
  into subjects (subject_name) values ('english') --2
  into subjects (subject_name) values ('history') --3
  into subjects (subject_name) values ('algebra') --4
  into subjects (subject_name) values ('java')  --5
  into subjects (subject_name) values ('mmkz') --6 
  into subjects (subject_name) values ('data')     --7
  into subjects (subject_name) values ('funcan') --8
select * from dual;

insert all
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 1, 1, 'EXAM')   --1
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 2, 1, 'EXAM')   --2
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 3, 1, 'EXAM')   --3
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 1, 2, 'ZACHET') --4
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 2, 2, 'ZACHET') --5
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 3, 2, 'EXAM')   --6
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 1, 3, 'EXAM')   --7
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 4, 4, 'EXAM')   --8
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 5, 5, 'ZACHET') --9
  into curriculums (specialty_id, semester, subject_id, report_type) values (1, 6, 6, 'ZACHET') --10
  into curriculums (specialty_id, semester, subject_id, report_type) values(1, 6, 8, 'EXAM') --11
  
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 1, 1, 'EXAM')   --12
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 2, 1, 'EXAM')   --13
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 3, 1, 'EXAM')   --14
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 1, 2, 'ZACHET') --15
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 2, 2, 'ZACHET') --16
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 3, 2, 'EXAM')   --17
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 1, 3, 'EXAM')   --18
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 4, 4, 'EXAM')   --19
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 5, 7, 'ZACHET') --20
  into curriculums (specialty_id, semester, subject_id, report_type) values (2, 6, 7, 'ZACHET') --21
select * from dual;

insert all
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 1, date'2018-01-13', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 2, date'2018-06-26', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 3, date'2018-01-16', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 4, date'2018-01-20', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 5, date'2019-06-02', 3)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 6, date'2019-01-10', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 7, date'2020-01-02', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 8, date'2020-01-05', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 1, date'2018-01-02', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 3, date'2019-01-04', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 4, date'2018-01-02', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 5, date'2018-06-02', 3)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 6, date'2019-01-02', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 7, date'2020-01-02', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 8, date'2020-01-02', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 11, date'2018-01-02', 3)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 12, date'2018-06-03', 3)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 13, date'2019-01-04', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 14, date'2018-01-02', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 15, date'2019-06-02', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 16, date'2019-01-02', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 17, date'2018-01-02', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 18, date'2020-01-02', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 19, date'2020-01-02', 2) 
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 11, date'2018-01-02', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 12, date'2018-06-03', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 13, date'2019-01-04', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 14, date'2018-01-02', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 15, date'2018-06-02', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 16, date'2019-01-02', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 17, date'2018-01-02', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 18, date'2020-01-02', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 19, date'2020-01-02', 5)
select * from dual;

create or replace function fn_count_semester (
  p_student_id in students.student_id%type
) return number
is
  v_year_enrollment students.year_enrollment%type;
  v_years number;
  v_month number;
  v_semestrs number;
begin
  select s.year_enrollment
    into v_year_enrollment
    from students s
    where s.student_id = p_student_id;
  v_years := extract(year from sysdate) - v_year_enrollment;
  v_month := extract(month from sysdate);
  v_semestrs := v_years * 2;
  if (v_month < 2) then
    v_semestrs := v_semestrs - 1;
  end if;
  if (v_month >= 9) then 
    v_semestrs := v_semestrs + 1;
  end if;
  return v_semestrs;
end;

create or replace view student_tails_view as
select  s.student_id,
        s.student_name,
        round(fn_count_semester(s.student_id)/2) as course,
        sub.subject_id,
        sub.subject_name,
        cur.semester as semester,
        m.mark 
  from  students s
        join specialties sp on
          sp.specialty_id = s.specialty_id
        join curriculums cur on
          cur.specialty_id = sp.specialty_id and
          cur.semester < fn_count_semester(s.student_id)
        join subjects sub on
          sub.subject_id = cur.subject_id
        left join marks m on
          m.student_id = s.student_id and
          m.curriculum_id = cur.curriculum_id
  where nvl(m.mark, 2) = 2
;

select * from student_tails_view;
select  stv.student_id,
        stv.student_name, 
        count(stv.student_id) as tails_count
  from  student_tails_view stv
  group by  stv.student_id,
            stv.student_name
  having count(stv.student_id) > 3
;
