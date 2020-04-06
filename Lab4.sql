/*1. В анонимном PL/SQL блоке распечатать все пифагоровы числа, меньшие 25 
(для печати использовать пакет dbms_output, процедуру put_line).*/

declare
  c_max_num int := 25;
begin
  for i in 1..c_max_num loop
    for j in i..c_max_num loop
      for k in j..c_max_num loop
        if i*i + j*j = k*k then
          dbms_output.put_line(i || ' ' || j || ' ' || k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/

/*2. Переделать предыдущий пример, чтобы для определения, что 3 числа пифагоровы использовалась функция.*/

declare
  c_max_num int := 25;
begin
  for i in 1..c_max_num loop
    for j in i..c_max_num loop
      for k in j..c_max_num loop
        if first_package.fn_check_pifagor(i, j, k) then
          dbms_output.put_line(i || ' ' || j || ' ' || k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/
/*3. Написать хранимую процедуру, которой передается ID сотрудника и которая увеличивает ему зарплату на 10%,
если в 2000 году у сотрудника были продажи. Использовать выборку количества заказов за 2000 год в переменную.
А затем, если переменная больше 0, выполнить update данных.*/

declare
  v_order_count int;
  v_salary employees.salary%type;
  v_emp_id employees.employee_id%type := 158;
  
begin
  select  e.salary
    into  v_salary
    from  employees e
    where e.employee_id = v_emp_id;
  dbms_output.put_line(v_salary);
  first_package.pr_increase_salary(v_emp_id);
  select  e.salary
    into  v_salary
    from  employees e
    where e.employee_id = v_emp_id;
  dbms_output.put_line(v_salary);
end;
/

/*4. Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY 
по позициям каждого заказа. Для этого создать хранимую процедуру, в которой будет в цикле for проход по всем заказам,
далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа 
и сравниваться с ORDER_TOTAL. Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.
*/

declare
begin
  first_package.pr_check_order_total();
end;
/

/*5. Переписать предыдущее задание с использованием явного курсора.*/

declare
begin
  first_package.pr_check_order_total_cursor();
end;
/

/*6. Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ
на текущую дату из одной позиции каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров.
Функция возвращает ID созданного клиента.*/

declare
begin
  dbms_output.put_line(first_package.fn_make_test_client('test', 'client', 1));
end;
/
/*7. Добавить в предыдущую функцию проверку на существование склада с переданным ID. 
Для этого выбрать склад в переменную типа «запись о складе» и перехватить исключение no_data_found, 
если оно возникнет. В обработчике исключения выйти из функции, вернув null.
*/

declare
begin
  dbms_output.put_line(first_package.fn_make_test_client_ex('test', 'client', 1));
end;
/
/*8. Написанные процедуры и функции объединить в пакет FIRST_PACKAGE.*/
create or replace package first_package as  
  function fn_check_nums(
    p_a int,
    p_b int,
    p_c int
  ) return boolean;
  
  procedure pr_increase_salary(p_id employees.employee_id%type);
  
  procedure pr_check_order_total;
  
  procedure pr_check_order_total_cursor;
 
  function fn_make_test_order(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
  
  function fn_make_test_order_ex(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
end first_package;
/
create or replace package body first_package
as 
  /*2.*/
  function fn_check_pifagor(
    p_a int,
    p_b int,
    p_c int
  ) return boolean
  is
  begin
    return p_a*p_a + p_b*p_b = p_c*p_c;
  end;
  
  /*3.*/
  procedure pr_increase_salary(p_id employees.employee_id%type)
  is
    v_order_count int;
  begin
    select  count(o.order_id)
      into  v_order_count
      from  orders o
      where o.sales_rep_id = p_id and
            date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01';
    if v_order_count > 0 then
      update  employees e
        set   e.salary = e.salary * 1.1
        where e.employee_id = p_id;
    end if;
  end;
  
  /*4.*/
  procedure pr_check_order_total
  is
    v_order_total orders.order_total%type;
    v_real_price number;
  begin
    for i_order in (
      select *
        from orders
    ) loop
      v_order_total := i_order.order_total;
      select  sum(oi.unit_price * oi.quantity)
        into v_real_price
        from  order_items oi
        where oi.order_id = i_order.order_id;
      if v_real_price <> v_order_total then
        dbms_output.put_line(i_order.order_id || ' ' || i_order.order_date || ' ' || i_order.customer_id);
      end if;
    end loop;        
  end;
  
  /*5.*/
  procedure pr_check_order_total_cursor
  is
    cursor cur_check is
      select  o.order_id,
              oi.real_price,
              o.order_total,
              o.customer_id,
              o.order_date
        from  orders o
              join (select  sum(oi.unit_price * oi.quantity) as real_price,
                            oi.order_id
                      from  order_items oi
                      group by oi.order_id
              ) oi on
                oi.order_id = o.order_id;
                
    v_order cur_check%rowtype;
  begin
    open cur_check;
    loop
      fetch cur_check into v_order;
      exit when cur_check%notfound;
      if v_order.order_total <> v_order.real_price then
        dbms_output.put_line(v_order.order_id || ' ' || v_order.order_date || ' ' || v_order.customer_id);
      end if;
    end loop;        
  end;
  
  /*6.*/
  function fn_make_test_client(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    
    for i_product in (
      select pi.*
        from  inventories inv
              join product_information pi on 
                pi.product_id = inv.product_id
        where inv.warehouse_id = p_warehouse_id and
              inv.quantity_on_hand > 0
    ) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + i_product.list_price;
    end loop;
    update  orders 
       set  order_total = v_order_total
      where order_id = v_order_id;
    return v_customer_id;
  end;
  
  /*7.*/
  function fn_make_test_client_ex(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_warehouse warehouses%rowtype;
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
    begin
      select  *
        into  v_warehouse
        from  warehouses w
        where w.warehouse_id = p_warehouse_id;
    exception
    when no_data_found then
      return null;
    end;
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    for i_product in (select pi.*
                          from  inventories inv
                                join product_information pi on 
                                  pi.product_id = inv.product_id
                          where inv.warehouse_id = p_warehouse_id and
                                inv.quantity_on_hand > 0) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + i_product.list_price;
    end loop;
    update  orders 
         set  order_total = v_order_total
        where order_id = v_order_id;
      return v_customer_id;
    return v_customer_id;
  end;
end first_package;
/

/*
9. Написать функцию, которая возвратит таблицу (table of record), содержащую информацию 
о частоте встречаемости отдельных символов во всех названиях (и описаниях) товара на заданном языке 
(передается код языка, а также параметр, указывающий, учитывать ли описания товаров). 
Возвращаемая таблица состоит из 2-х полей: символ, частота встречаемости в виде частного от кол-ва данного символа 
к количеству всех символов в названиях (и описаниях) товара.
*/

create type tp_char_frequency as 
object(
  ch nchar(1), 
  freq number
);

create type tp_char_frequency_table as
table of tp_char_frequency;

create or replace function fn_char_freq(
  p_lang_id in product_descriptions.language_id%type,
  p_description in int
) return tp_char_frequency_table
is 
  type tp_char_indexed_table is 
    table of tp_char_frequency index by binary_integer;
  v_result_table tp_char_frequency_table;
  v_indexed_table tp_char_indexed_table;
  v_ch nchar(1);
  v_code binary_integer;
begin 
  v_result_table := tp_char_frequency_table();
  for i_pd in (select  *
                 from  product_descriptions pd
                 where pd.language_id = p_lang_id
  ) loop
    for i_l in 1..length(i_pd.translated_name) loop
      v_ch := substr(i_pd.translated_name, i_l, 1);
      v_code := ascii(v_ch);
      if not v_indexed_table.exists(v_code) then
        v_indexed_table(v_code) := tp_char_frequency(v_ch, 0);
      end if;
      v_indexed_table(v_code).freq := v_indexed_table(v_code).freq + 1;
    end loop;
  end loop;
  
  if p_description>0 then 
    for i_pd in (select  *
                   from  product_descriptions pd
                   where pd.language_id = p_lang_id
    ) loop
      for i_l in 1..length(i_pd.translated_description) loop
        v_ch := substr(i_pd.translated_description, i_l, 1);
        v_code := ascii(v_ch);
        if not v_indexed_table.exists(v_code) then
          v_indexed_table(v_code) := tp_char_frequency(v_ch, 0);
        end if;
        v_indexed_table(v_code).freq := v_indexed_table(v_code).freq + 1;
      end loop;
    end loop;
  end if;
  
  v_code := v_indexed_table.first;
  while v_code is not null
    loop
      v_result_table.extend(1);
      v_result_table(v_result_table.last) := v_indexed_table(v_code);
      v_code := v_indexed_table.next(v_code);
    end loop;
  return v_result_table;
end;

declare
  v_result tp_char_frequency_table;
begin
  v_result := fn_char_freq('RU', 1);
  for i in 1..v_result.count
    loop
      dbms_output.put_line(v_result(i).ch || ' ' || v_result(i).freq);
    end loop;
end;

select  *
  from  table(cast(fn_char_freq('RU', 1) as tp_char_result_table))
;
/*
10. Написать функцию, которой передается sys_refcursor и которая по данному курсору формирует HTML-таблицу,
содержащую информацию из курсора. Тип возвращаемого значения – clob.
*/

declare
  v_cur sys_refcursor;
  v_result clob;
  
  
  function get_html_table(p_cur in out sys_refcursor)
    return clob
  is
    v_cur sys_refcursor := p_cur;
    v_cn integer;
    v_cols_desc dbms_sql.desc_tab2;
    v_cols_count integer;
    v_temp integer;
    v_result clob;
    v_str varchar2(1000);
  begin
    dbms_lob.createtemporary(v_result, true);
  
    v_cn := dbms_sql.to_cursor_number(v_cur);
    dbms_sql.describe_columns2(v_cn, v_cols_count, v_cols_desc);
     
    for i_index in 1 .. v_cols_count loop
      dbms_sql.define_column(v_cn, i_index, v_str, 1000);
    end loop;
      
    dbms_lob.append(v_result, '<table><tr>');
    for i_index in 1..v_cols_count loop
      dbms_lob.append(v_result, '<th>' || v_cols_desc(i_index).col_name || '</th>');
    end loop;
    dbms_lob.append(v_result, '</tr>');
    
    loop
      v_temp:=dbms_sql.fetch_rows(v_cn);
      exit when v_temp = 0;
      
      dbms_lob.append(v_result, '<tr>');
      for i_index in 1 .. v_cols_count
        loop
          dbms_sql.column_value(v_cn, i_index, v_str);
          dbms_lob.append(v_result, '<td>' || v_str || '</td>');
        end loop;
      dbms_lob.append(v_result, '</tr>');
    end loop;
    
    dbms_lob.append(v_result, '</table>');
    return v_result;
  end;
  
begin
  open v_cur for
    select c.* 
      from countries c;
  v_result := get_html_table(v_cur);
  dbms_output.put_line(v_result);
end;
