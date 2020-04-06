/*
1. Выбрать с помощью иерархического запроса сотрудников 3-его уровня иерархии (т.е.
таких, у которых непосредственный начальник напрямую подчиняется руководителю
организации). Упорядочить по коду сотрудника
*/

select  e.*
  from  employees e
  where level = 3
  start with  e.manager_id is null
  connect by  e.manager_id = prior(e.employee_id)
  order by e.employee_id
;

/* 
2. Для каждого сотрудника выбрать всех его начальников по иерархии. Вывести поля: код
сотрудника, имя сотрудника (фамилия + имя через пробел), код начальника, имя
начальника (фамилия + имя через пробел), кол-во промежуточных начальников между
сотрудником и начальником из данной строки выборки. Если у какого-то сотрудника
есть несколько начальников, то для данного сотрудника в выборке должно быть
несколько строк с разными начальниками. Упорядочить по коду сотрудника, затем по
уровню начальника (первый – непосредственный начальник, последний – руководитель
организации).
*/

select  connect_by_root(e.employee_id) as employee_id,
        connect_by_root(e.first_name || ' ' || e.last_name) as emp_name,
        e.employee_id as manager_id,
        e.first_name || ' ' || e.last_name as man_name,
        level - 2 as manager_count
  from  employees e
  where level > 1
  connect by  e.employee_id = prior(e.manager_id)
  order siblings by e.employee_id
;

/*
3. Для каждого сотрудника посчитать количество его подчиненных, как непосредственных,
так и по иерархии. Вывести поля: код сотрудника, имя сотрудника (фамилия + имя через
пробел), общее кол-во подчиненных.
*/

select  e.employee_id,
        e.first_name || ' ' || e.last_name,
        count(e.employee_id) as emp_count
  from  employees e
  where level > 1
  connect by  e.employee_id = prior(e.manager_id)
  group by  e.employee_id, 
            e.first_name,
            e.last_name
  order by  emp_count desc
;

/*
4. Для каждого заказчика выбрать в виде строки через запятую даты его заказов. Для
конкатенации дат заказов использовать sys_connect_by_path (иерархический запрос). Для
отбора «последних» строк использовать connect_by_isleaf
*/

select  o.customer_id,
        substr(sys_connect_by_path(to_char(o.order_date2, 'DD.MM.YYYY'), ', '), 3) as order_dates
  from  (
          select  o.customer_id,
                  lead(o.order_date) over (
                    partition by o.customer_id
                    order by o.order_date
                  ) as order_date1,
                  o.order_date as order_date2
            from  orders o
            group by  o.customer_id,
                      o.order_date
          ) o
  where connect_by_isleaf = 1
  start with  o.order_date1 is null
  connect by  o.customer_id = prior(o.customer_id) and
              o.order_date1 = prior(o.order_date2)
;
/*
5. Выполнить задание № 4 c помощью обычного запроса с группировкой и функцией
listagg.
*/

select  o.customer_id,
        listagg(to_char(o.order_date, 'DD.MM.YYYY'), ', ')
          within group (order by o.order_date) as order_dates
  from  orders o
  group by  o.customer_id
;

/*
6. Выполнить задание № 2 с помощью рекурсивного запроса.
2. Для каждого сотрудника выбрать всех его начальников по иерархии. Вывести поля: код
сотрудника, имя сотрудника (фамилия + имя через пробел), код начальника, имя
начальника (фамилия + имя через пробел), кол-во промежуточных начальников между
сотрудником и начальником из данной строки выборки. Если у какого-то сотрудника
есть несколько начальников, то для данного сотрудника в выборке должно быть
несколько строк с разными начальниками. Упорядочить по коду сотрудника, затем по
уровню начальника (первый – непосредственный начальник, последний – руководитель
организации).
*/

with t_req(employee_id, emp_name, manager_id, manager_name, prev_manager_id, manager_level) as (
  select  e.employee_id,
          e.first_name || ' ' || e.last_name,
          e.employee_id,
          e.first_name || ' ' || e.last_name,
          e.manager_id,
          0
    from  employees e
  union all
  select  prev.employee_id,
          prev.emp_name,
          curr.employee_id,
          curr.first_name || ' ' || curr.last_name,
          curr.manager_id,
          manager_level + 1
    from  t_req prev
          join employees curr on
            curr.employee_id = prev.prev_manager_id
)
select  r.employee_id,
        r.emp_name, 
        r.manager_id, 
        r.manager_name, 
        r.manager_level - 1 as manager_level
  from  t_req r
  where manager_level > 0
  order by  r.employee_id,
            r.manager_level
;

/*
7. Выполнить задание № 3 с помощью рекурсивного запроса.
3. Для каждого сотрудника посчитать количество его подчиненных, как непосредственных,
так и по иерархии. Вывести поля: код сотрудника, имя сотрудника (фамилия + имя через
пробел), общее кол-во подчиненных.
*/

with t_req(manager_id, man_name, employee_id) as (
  select  e.employee_id,
          e.last_name || ' ' || e.first_name,
          e.employee_id
    from  employees e
  union all
  select  prev.manager_id,
          prev.man_name,
          curr.employee_id
    from  t_req prev
          join  employees curr
            on  curr.manager_id=prev.employee_id
)
select  r.manager_id,
        r.man_name,
        count(*)-1 as emp_count
  from  t_req r
  group by  r.manager_id,
            r.man_name
  order by  emp_count desc
;

/*
8. Каждому менеджеру по продажам сопоставить последний его заказ. Менеджером по
продажам считаем сотрудников, код должности которых: «SA_MAN» и «SA_REP». Для
выборки последних заказов по менеджерам использовать подзапрос с применением
аналитических функций (например в подзапросе выбирать дату следующего заказа
менеджера, а во внешнем запросе «оставить» только те строки, у которых следующего
заказа нет). Вывести поля: код менеджера, имя менеджера (фамилия + имя через
пробел), код клиента, имя клиента (фамилия + имя через пробел), дата заказа, сумма
заказа, количество различных позиций в заказе. Упорядочить данные по дате заказа в
обратном порядке, затем по сумме заказа в обратном порядке, затем по коду сотрудника.
Тех менеджеров, у которых нет заказов, вывести в конце.
*/

select  e.employee_id,
        e.first_name || ' ' || e.last_name as emp_name,
        c.customer_id,
        c.cust_first_name || ' ' || c.cust_last_name as cust_name,
        o.order_date,
        o.order_total,
        (
          select  count(oi.product_id)
            from  order_items oi
            where oi.order_id = o.order_id
        ) as items_count
  from  employees e
        left join (
          select  o.*,
                  lead(o.order_date) over(
                    partition by o.sales_rep_id
                    order by o.order_date
                  ) as next_order
            from  orders o
        ) o on
          o.sales_rep_id = e.employee_id and
          o.next_order is null
        left join customers c on
          c.customer_id = o.customer_id          
  where e.job_id in ('SA_MAN', 'SA_REP')
  order by  o.order_date desc nulls last,
            o.order_total desc nulls last,
            e.employee_id
;

/*9. Для каждого месяца текущего года найти первые и последние рабочие и выходные дни с
учетом праздников и переносов выходных дней (на 2016 год эту информацию можно
посмотреть, например, на странице http://www.interfax.ru/russia/469373). Для
формирования списка всех дней текущего года использовать иерархический запрос,
оформленный в виде подзапроса в секции with. Праздничные дни и переносы выходных
также задать в виде подзапроса в секции with (с помощью union all перечислить все
даты, в которых рабочие/выходные дни не совпадают с обычной логикой определения
выходного дня как субботы и воскресения). Запрос должен корректно работать, если
добавить изменить какие угодно выходные/рабочие дни в данном подзапросе. Вывести
поля: месяц в виде первого числа месяца, первый выходной день месяца, последний
выходной день, первый праздничный день, последний праздничный день.
*/

with 
days as
(
  select  trunc(sysdate, 'yyyy') + level - 1 as dt
    from  dual
    connect by  trunc(sysdate, 'yyyy') + level - 1 <
                  add_months(trunc(sysdate, 'yyyy'), 12)
),
holidays as 
(
  select date'2018-01-01' as dt, 1 as comments from dual union all
  select date'2018-01-02', 1 from dual union all
  select date'2018-01-03', 1 from dual union all
  select date'2018-01-04', 1 from dual union all
  select date'2018-01-05', 1 from dual union all
  select date'2018-01-08', 1 from dual union all
  select date'2018-02-23', 1 from dual union all
  select date'2018-03-08', 1 from dual union all
  select date'2018-03-09', 1 from dual union all
  select date'2018-04-28', 0 from dual union all
  select date'2018-04-30', 1 from dual union all
  select date'2018-05-01', 1 from dual union all
  select date'2018-05-02', 1 from dual union all
  select date'2018-05-09', 1 from dual union all
  select date'2018-06-09', 0 from dual union all
  select date'2018-06-11', 1 from dual union all
  select date'2018-06-12', 1 from dual union all
  select date'2018-11-05', 1 from dual union all
  select date'2018-12-29', 0 from dual union all
  select date'2018-12-31', 1 from dual
)
select  trunc(d.dt, 'MM') as dt,
        min(
          case when d.comments = 1 then d.dt
          end
        ) as first_weekend,
        max(
          case when d.comments = 1 then d.dt
          end
        ) as last_weekend,
        min(
          case when d.comments = 0 then d.dt
          end
        ) as first_working,
        max(
          case when d.comments = 0 then d.dt
          end
        ) as last_working
  from  (
          select  d.dt,
                  nvl(
                    h.comments, 
                    case 
                      when to_char(d.dt, 'Dy', 'nls_date_language=english') in ('Sat', 'Sun') then 1
                      else 0
                    end
                  ) as comments
            from  days d
                  left join holidays h on
                    h.dt = d.dt
        ) d
  group by  trunc(d.dt, 'MM')
  order by  dt
;

/*
10. 3-м самых эффективным по сумме заказов за 1999 год менеджерам по продажам
увеличить зарплату еще на 20%.*/


update  employees e
  set   e.salary = e.salary*1.2
  where e.employee_id in (
          select  emp.employee_id
            from  (
                    select  e.employee_id,
                            sum_orders
                      from  employees e
                            join (
                              select  o.sales_rep_id,
                                      sum(o.order_total) as sum_orders
                                from  orders o
                                where date'1999-01-01' <= o.order_date and o.order_date < date'2000-01-01'
                                group by  o.sales_rep_id
                            ) o on
                              o.sales_rep_id = e.employee_id
                      where e.job_id in('SA_MAN', 'SA_REP')
                      order by  sum_orders desc
                  ) emp
            where rownum <= 3
        )
;

select  e.employee_id,
        sum_orders,
        e.salary
  from  employees e
        join (
          select  o.sales_rep_id,
                  sum(o.order_total) as sum_orders
            from  orders o
            where date'1999-01-01' <= o.order_date and o.order_date < date'2000-01-01'
            group by  o.sales_rep_id
        ) o on
          o.sales_rep_id = e.employee_id
  order by  sum_orders desc
;



/*
11. Завести нового клиента ‘Старый клиент’ с менеджером, который является
руководителем организации. Остальные поля клиента – по умолчанию.
*/

insert into customers (cust_last_name, cust_first_name, account_mgr_id)
select  'Cтарый',
        'клиент',
        e.employee_id
  from  employees e
  where e.manager_id is null
;
select  c.*
  from  customers c
  where c.cust_last_name = 'Cтарый'
;


/*12. Для клиента, созданного в предыдущем запросе, (найти можно по максимальному id
клиента), продублировать заказы всех клиентов за 1990 год. (Здесь будет 2 запроса, для
дублирования заказов и для дублирования позиций заказа).
*/
insert into orders (order_date, order_mode, customer_id, order_status, order_total, sales_rep_id, promotion_id)
select  o.order_date,
        o.order_mode,
        (
          select  max(c.customer_id) as customer_id
            from  customers c
        ) as customer_id,
        o.order_status,
        o.order_total,
        o.sales_rep_id,
        o.promotion_id
  from  orders o
  where date'1990-01-01' <= o.order_date and o.order_date < date'1991-01-01'
;

insert  into order_items (order_id, line_item_id, product_id, unit_price, quantity)
select  new_order.order_id,
        oi.line_item_id,
        oi.product_id,
        oi.unit_price,
        oi.quantity
  from  order_items oi
        join orders o on
          o.order_id = oi.order_id
        join orders new_order on
          new_order.order_date = o.order_date and
          new_order.customer_id = (
            select  max(c.customer_id) as customer_id
              from  customers c
          )
  where date'1990-01-01' <= o.order_date and o.order_date < date'1991-01-01'
;
/*
13. Для каждого клиента удалить самый первый заказ. Должно быть 2 запроса: первый – для
удаления позиций в заказах, второй – на удаление собственно заказов).
*/

delete  from order_items oi
  where oi.order_id in (
          select  o.order_id
            from  orders o
                  join (
                    select  o.customer_id,
                            min(o.order_date) as first_order
                      from  orders o
                      group by  o.customer_id
                  ) f_ord on
                    f_ord.customer_id = o.customer_id and
                    f_ord.first_order = o.order_date
        )
;

delete from orders o
  where o.order_id in (
                        select  o.order_id
                          from  orders o
                                join (
                                  select  o.customer_id,
                                          min(o.order_date) as first_order
                                    from  orders o
                                    group by  o.customer_id
                                ) f_ord on
                                  f_ord.customer_id = o.customer_id and
                                  f_ord.first_order = o.order_date
                        )
;

/*
14. Для товаров, по которым не было ни одного заказа, уменьшить цену в 2 раза (округлив
до целых) и изменить название, приписав префикс ‘Супер Цена! ’.
*/

update  product_information pi
  set   pi.product_name = 'Супер Цена! ' || pi.product_name,
        pi.list_price = round(pi.list_price / 2),
        pi.min_price = round(pi.min_price/2)
  where not exists (
          select  *
            from  order_items oi
            where oi.product_id = pi.product_id
        )
  ;
  /*
15. Импортировать в базу данных из прайс-листа фирмы «Рет» (http://www.voronezh.ret.ru/?
&pn=down) информацию о всех реализуемых планшетах. Подсказка: воспользоваться
excel для конструирования insert-запросов (или select-запросов, что даже удобнее).
*/

insert  into product_information (product_description, list_price, min_price, warranty_period)
select  trim(product_description) as product_description,
        list_price,
        min_price, 
        warranty_period
  from  (
          select 'Планшет  7" Archos 70c Xenon, 1024*600, ARM 1.3ГГц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 2/0.3Мпикс,  Android 5.1, 190*110*10мм 242г, серебристый' as product_description,  3665 as list_price,  3665 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Galapad 7, 1024*600, NVIDIA 1.3ГГц, 8GB, GPS, BT, WiFi, SD-micro, microHDMI, камера 2Мпикс, Android 4.1, 122*196*10мм 320г, черный' as product_description,  2490 as list_price,  2490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Huawei MediaPad T3 7.0 53010adp, 1024*600, Spreadtrum 1.3ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/2Мпикс, Android 7, 187.6*103.7*8.6мм 275г, серый' as product_description,  6990 as list_price,  6990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Iconbit NetTAB Sky 3G Duo, 1024*600, ARM 1.2ГГц, 4GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, MiniHDMI, 2 камеры 5/0.3Мпикс, Android 4.0, 195*124*11мм 315г, черный' as product_description,  2700 as list_price,  2700 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Iconbit NetTAB Sky II mk2, 800*480, ARM 1.2ГГц, 4GB, WiFi, SD-micro, камера 0.3Мпикс, Android 4.1, 191*114*11мм 310г, белый' as product_description,  2100 as list_price,  2100 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Irbis TZ71, 1024*600, ARM 1ГГц, 8GB, 4G/3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 0.3/2Мпикс, Android 5.1, 119.2*191.8*10.7мм 280г, черный' as product_description,  3500 as list_price,  3500 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Lenovo Tab 3 TB3-710I Essential ZA0S0023RU, 1024*600, MTK 1.3ГГц, 8GB, BT, WiFi, 3G, GPS, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 113*190*10мм 300г, черный' as product_description,  5590 as list_price,  5590 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Lenovo Tab 3 TB3-730X ZA130004RU, 1024*600,  MTK 1ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 6, 101*191*98мм 260г, белый' as product_description,  7690 as list_price,  7690 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Lenovo Tab 4 TB-7304i Essential ZA310031RU, 1024*600, MTK 1.3ГГц, 16GB, BT, WiFi, 3G, GPS, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 102*194.8*8.8мм 254г, черный' as product_description,  6990 as list_price,  6990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad  Wize 3787, 1280*800, intel 1.1ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 190*115*9.5мм 270г, серый' as product_description,  4300 as list_price,  4300 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad  Wize 3787, 1280*800, intel 1.1ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 190*115*9.5мм 270г, черный' as product_description,  4300 as list_price,  4300 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad Color Wize 3797, 1280*800, intel 1.2ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 190*115*9.5мм 270г, серый' as product_description,  4290 as list_price,  4290 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad Grace PMT3157, 1280*720, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 186*115*9.5мм 280г черный' as product_description,  5590 as list_price,  5590 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad Grace PMT3157, 1280*720, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 186*115*9.5мм 280г черный' as product_description,  3990 as list_price,  3990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad PMT3677, 800*480, ARM 1ГГц, 4GB, WiFi, SD-micro, камера 0.3Мпикс, Android 4.2, 192*116*11мм 300г, черный' as product_description,  2100 as list_price,  2100 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad WIZE 3757, 1280*800, intel 1.2ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 186*115*9.5мм 280г черный' as product_description,  5250 as list_price,  5250 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad Wize 3407, 1024*600, intel 1.3ГГц, 8GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 188*108*10.5мм 310г, черный' as product_description,  5390 as list_price,  5390 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Prestigio MultiPad Wize PMT3427, 1024*600, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 186*115*9.5мм 280г серый' as product_description,  4190 as list_price,  4190 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Samsung Galaxy Tab 4 SM-T231NYKASER, 1280*800, Samsung 1.2ГГц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 3/1.3Мпикс, Android 4.2, 107*186*9мм 281г, 10ч, черный' as product_description,  8800 as list_price,  8800 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Samsung Galaxy Tab 4 SM-T231NZWASER, 1280*800, Samsung 1.2ГГц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 3/1.3Мпикс, Android 4.2, 107*186*9мм 281г, 10ч, белый' as product_description,  8800 as list_price,  8800 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Samsung Galaxy Tab A SM-T285NZKASER, 1280*800, Samsung 1.3ГГц, 8GB, 4G/3G, GPS, BT, WiFi, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 109*187*8.7мм 285г, 10ч, черный' as product_description,  9990 as list_price,  9990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Tesla Element 7.0, 1024*600, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, камера 0.3Мпикс, Android 4.4, 188*108*10.5мм 311г, черный' as product_description,  3190 as list_price,  3190 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7" Topstar TS-AD75 TE, 1024*600, ARM 1ГГц, 8GB, 3G, GSM, BT, WiFi, SD-micro, SDHC-micro, miniHDMI, камера 0.3 Мпикс, Android 4.0, 193*123*10мм 350г, черный' as product_description,  2700 as list_price,  2700 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7.9" Apple iPad mini 3 Demo 3A136RU, 2048*1536, A7 1.3ГГц, 16GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 134.7*200*7.5мм 331г, 10ч, золотистый' as product_description,  17990 as list_price,  17990 as min_price,  interval '1' month as warranty_period from dual union all
          select 'Планшет  7.9" Apple iPad mini 3 MGGQ2RU/A, 2048*1536, A7 1.3ГГц, 64GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 135*200*8мм 331г, 10ч, серый' as product_description,  25990 as list_price,  25990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7.9" Apple iPad mini 3 MGGT2RU/A, 2048*1536, A7 1.3ГГц, 64GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 135*200*8мм 331г, 10ч, серебристый' as product_description,  25990 as list_price,  25990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7.9" Apple iPad mini 3 MGJ32RU/A, 2048*1536, A7 1.3ГГц, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 134.7*200*7.5мм 341г, 10ч, серебристый' as product_description,  32469 as list_price,  32469 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7.9" Apple iPad mini 3 MGP32RU/A, 2048*1536, A7 1.3ГГц, 128GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 134.7*200*7.5мм 331г, 10ч, серый' as product_description,  28990 as list_price,  28990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  7.9" Apple iPad mini 3 MGYU2RU/A, 2048*1536, A7 1.3ГГц, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 134.7*200*7.5мм 341г, 10ч, золотистый' as product_description,  29990 as list_price,  29990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" ASUS VivoTab Note 8 M80TA, 1280*800, Intel 1.86ГГц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/1.26Мпикс, W8.1, 134*221*11мм 380г, черный' as product_description,  9490 as list_price,  9490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Acer Iconia Tab 8 A1-840FHD-17RT, 1920*1080, Intel 1.8ГГц, 16GB, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2Мпикс, Android 4.4, серебристый' as product_description,  10200 as list_price,  10200 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Archos 80 G9, 1024*768, ARM 1ГГц, 8GB, GPS, BT, WiFi, SD-micro, miniHDMI, камера, Android 3.2, 226*155*12мм 465г, 10ч, темно-серый' as product_description,  2290 as list_price,  2290 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Huawei MediaPad T3 8.0 53018493, 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 211*124.65*7.95мм, 350гр, серый' as product_description,  10990 as list_price,  10990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Lenovo Tab 4 TB-8504X ZA2D0036RU, 1280*800, Qualcomm 1.4ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 7, 211*124.2мм 310г, черный' as product_description,  11990 as list_price,  11990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Lenovo Tab 4 TB-8504X ZA2D0059RU, 1280*800, Qualcomm 1.4ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 7, 211*124.2мм 310г, белый' as product_description,  11990 as list_price,  11990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Grace PMT3118, 1280*800, MTK 1.1ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 206*123*10мм, 343гр, черный' as product_description,  4590 as list_price,  4590 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Grace PMT5588, 1920*1200, MTK 1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 8.1, 213*125*8мм, 357гр, черный' as product_description,  9990 as list_price,  9990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Muze PMT3708, 1280*800, MTK 1.3ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 206*122.8*10мм, 360гр, черный' as product_description,  5990 as list_price,  5990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Muze PMT3708, 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 206*122.8*10мм, 360гр, черный' as product_description,  5490 as list_price,  5490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Muze PMT3718, 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 206*122.8*10мм, 360гр, черный' as product_description,  5490 as list_price,  5490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Wize PMT3108 + CNE-CSPB26W, 1280*800, intel 1.2ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 207*123*8.8мм, 356гр, черный' as product_description,  5890 as list_price,  5890 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Wize PMT3208, 1280*800, intel 1.1ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 208.2*126.2*10мм, 613гр, черный' as product_description,  5390 as list_price,  5390 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Wize PMT3418, 1280*800, MTK 1.1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 6, 206*122.8*10мм, 360гр, черный' as product_description,  6490 as list_price,  6490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Wize PMT3508, 1280*800, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 206*122.8*10мм, 360гр, серый' as product_description,  6200 as list_price,  6200 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Wize PMT3508, 1280*800, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 206*122.8*10мм, 360гр, черный' as product_description,  6200 as list_price,  6200 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Wize PMT3518, 1280*800, MTK 1.1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 6, 206*122.8*10мм, 360гр, черный' as product_description,  6710 as list_price,  6710 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Prestigio MultiPad Wize PMT3618, 1280*800, MTK 1.1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 8.1, 206*122.8*9.9мм, 363гр, черный' as product_description,  6490 as list_price,  6490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" RoverPad Magic HD8G, 1280*800, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 6, 208*123.5*11мм 420г, черный' as product_description,  4990 as list_price,  4990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Tesla Element 8.0 3G, 1280*800, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 4.4, 207*123.5*9.8мм 420г, черный' as product_description,  3490 as list_price,  3490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  8" Tesla Impulse 8.0 3G, 1280*800, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 4.4, 208*123.5*11мм 420г, черный' as product_description,  3700 as list_price,  3700 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.6" Huawei MediaPad T3 10 53018522, 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 229.8*159.8*7.95мм, 460гр, серый' as product_description,  11990 as list_price,  11990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.6" Huawei MediaPad T3 10 53018545, 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 229.8*159.8*7.95мм, 460гр, золотистый' as product_description,  11990 as list_price,  11990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.6" Prestigio MultiPad Wize 3096, 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 8, 261*155*9.8мм, 554гр, черный' as product_description,  6490 as list_price,  6490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.6" Samsung Galaxy Tab E SM-T561NZKASER, 1280*800, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2Мпикс, Android 4.4, 242*149.5*8.5мм 495г, черный' as product_description,  11890 as list_price,  11890 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.7" Apple iPad Air 2 Demo 3A141RU, 2048*1536, A8X 1.5ГГц, 16GB, BT, WiFi, 2 камеры 8/1.2Мпикс, золотистый' as product_description,  22500 as list_price,  22500 as min_price,  interval '1' month as warranty_period from dual union all
          select 'Планшет  9.7" Apple iPad Air MD791, 2048*1536, A7 1.4ГГц, 16GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 480г, 10ч, серый' as product_description,  33990 as list_price,  33990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.7" Apple iPad Air ME898, 2048*1536, A7 1.4ГГц, 128GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 469г, 10ч, серый' as product_description,  32000 as list_price,  32000 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.7" Apple iPad Air ME906, 2048*1536, A7 1.4ГГц, 128GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 469г, 10ч, серебристый' as product_description,  32000 as list_price,  32000 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.7" Apple iPad Air ME987, 2048*1536, A7 1.4ГГц, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 478г, 10ч, серый' as product_description,  34990 as list_price,  34990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.7" Apple iPad Air ME988, 2048*1536, A7 1.4ГГц, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 480г, 10ч, серебристый' as product_description,  34990 as list_price,  34990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет  9.7" Apple iPad Pro MM172RU/A, 2048*1536, A9X 2.26ГГц, 32GB, BT, WiFi, 2 камеры 12/5Мпикс, 169.5*240*6.1мм437г, 10ч, розовое золото' as product_description,  43490 as list_price,  43490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" ASUS Eee Pad Transformer Prime TF201, 1280*800, ARM 1.4ГГц, 32GB, GPS, BT, WiFi, Android 4.0, док-станция, клавиатура, 263*181*8мм 586г, 12ч, золотистый' as product_description,  7990 as list_price,  7990 as min_price,  interval '1' month as warranty_period from dual union all
          select 'Планшет 10.1" ASUS Transformer Book T100HA-FU002T, 1280*800, Intel 1.44ГГц, 32GB,  BT, WiFi, SDHC-micro, microHDMI, 2 камеры 5/2Мпикс, W10, док-станция, клавиатура, 263*171*11мм 550гр, серый' as product_description,  17500 as list_price,  17500 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" ASUS Transformer Pad TF103CG-1A056A, 1280*800, intel 1.6ГГц, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3Мпикс, Android 4.4, 257.3*178.4*9.9мм 550г черный' as product_description,  7400 as list_price,  7400 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" ASUS Transformer Pad TF103CG-1A059A, 1280*800, intel 1.33ГГц, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3Мпикс, клавиатура, Android 4.4, 257.3*178.4*9.9мм 550г черный' as product_description,  13590 as list_price,  13590 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" ASUS ZenPad 10 Z300M-6A056A, 1280*800, MTK 1.3ГГц, 8GB, BT,  WiFi, SD/SD-micro, 2/5Мпикс, Android 6, 251.6*172*7.9мм 490г, черный' as product_description,  9990 as list_price,  9990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Acer Iconia Tab A200, 1280*800, ARM 1ГГц, 32GB, GPS, BT, WiFi, SD-micro, камера 2Мпикс, Android 4.0, 260*175*70мм 720г, красный' as product_description,  5590 as list_price,  5590 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Archos 101b Copper, 1024*600, ARM 1.3ГГц, 8GB, 3G, BT, WiFi, SD-micro, 2 камеры 2/0.3Мпикс,  Android 4.4, 262*166*10мм 577г, серый' as product_description,  6300 as list_price,  6300 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Archos 101c Copper, 1024*600, ARM 1.3ГГц, 16GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 2/0.3Мпикс,  Android 5.1, 259*150*9.8мм 450г, синий' as product_description,  6250 as list_price,  6250 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Dell XPS 10 Tablet 6225-8264, 1366*768, Qualcomm 1.5ГГц, 64GB, BT, WiFi, SD-micro, miniHDMI, 2 камеры 5/2 Мпикс, W8RT, док-станция, клавиатура, 275*177*9мм 635г, 10.5ч, черный' as product_description,  8200 as list_price,  8200 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Huawei MediaPad T5 10 LTE 53010DLM, 1920*1200, Kirin 2.36ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 8, 243*164*7.8мм, 460гр, черный' as product_description,  15990 as list_price,  15990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Irbis TW21, 1280*800, Intel 1.8ГГц, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, microHDMI, 2 камеры 2/2Мпикс, W8.1, клавиатура, черный' as product_description,  6990 as list_price,  6990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Irbis TW31, 1280*800, Intel 1.8ГГц, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2Мпикс,  W10, клавиатура, 170*278*10мм 600г, черный' as product_description,  10400 as list_price,  10400 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Lenovo Tab 4 TB-X304L ZA2K0056RU, 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 247*170*8.4мм 505г, черный' as product_description,  13100 as list_price,  13100 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Lenovo Tab 4 TB-X304L ZA2K0082RU, 1280*800, Qualcomm 1.4ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 7, 247*170*8.4мм 505г, белый' as product_description,  12990 as list_price,  12990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Pegatron Chagall 90NL-083S100, 1280*800, ARM 1.5ГГц, 16GB, BT, WiFi, SD-micro,  2 камеры 8/2 Мпикс, Android 4.0, 260*7*180мм 540г, 8ч, черный' as product_description,  4100 as list_price,  4100 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Prestigio MultiPad Grace PMT3101, 1280*800, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 243*171*10мм, 545гр, черный' as product_description,  7990 as list_price,  7990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Prestigio MultiPad Wize PMT3131, 1280*800, MTK 1.13ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 261*155*9.8мм, 554гр, черный' as product_description,  6490 as list_price,  6490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Prestigio MultiPad Wize PMT3131, 1280*800, MTK 1.13ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 261*155*9.8мм, 554гр, черный' as product_description,  5490 as list_price,  5490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Prestigio MultiPad Wize PMT3151, 1280*800, MTK 1.13ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 261*155*9.8мм, 554гр, черный' as product_description,  6490 as list_price,  6490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Prestigio MultiPad Wize PMT3161, 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 243*171*10мм, 545гр, черный' as product_description,  6490 as list_price,  6490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Prestigio Visconte 4U XIPMP1011TDBK, 1280*800, Intel 1.8ГГц, 16GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2Мпикс, W10, клавиатура, 256*173.6*10.5мм 580г, черный' as product_description,  7490 as list_price,  7490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Prestigio Visconte A WCPMP1014TEDG, 1280*800, Intel 1.83ГГц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2Мпикс, W10, клавиатура, 259.3*173.5*10.1мм 575г, серый' as product_description,  8490 as list_price,  8490 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" RoverPad Magic HD10G, 1280*800, ARM 1.2ГГц, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 7, 242.3*171.2*9.5мм 560г, черный' as product_description,  5990 as list_price,  5990 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 10.1" Tesla Impulse 10.1 3G, 1280*800, ARM 1.2ГГц, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 242.3*171.2*9.5мм 560г, черный' as product_description,  5590 as list_price,  5590 as min_price,  interval '12' month as warranty_period from dual union all
          select 'Планшет 11.6" Prestigio Visconte S UEPMP1020CESR, 1920*1080, Intel 1.84ГГц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2Мпикс, W10, клавиатура, 260*186*9.75мм 684г, серый' as product_description,  12490 as list_price,  12490 as min_price,  interval '12' month as warranty_period from dual
        )
;
