insert into STATUS_MAPS(id, category, event_type)
select seq_status_maps_id.nextval, category, event_type
from (select 'submitted' category, 'submitted' event_type from dual union all
      select 'validating', 'val task ' || level from dual connect by level <= 4 union all
      select 'reviewing', 'rev task ' || level from dual connect by level <= 3 union all
      select 'completed', decode(level, 1, 'approved', 2, 'withdrawn', 3, 'denied') from dual connect by level <= 3);

insert into EVENT_STATUS_LOGS (id, client_id, customer_uuid, application_id, event_type, status, event_ts, disposition)
select seq_event_status_logs_id.nextval, 'TestApp', customer_uuid, application_id, event_type, status, event_ts, disposition
from (select 'Cust0001' customer_uuid, 1 application_id, 'submitted' event_type, 'submitted' status, sysdate - 4.9 event_ts, '10000' disposition from dual union all
      select 'Cust0001', 1, 'val task 1', 'complete', sysdate - 4.81, 'ok' from dual union all
      select 'Cust0001', 1, 'val task 2', 'complete', sysdate - 4.72, 'ok' from dual union all
      select 'Cust0001', 1, 'val task 3', 'complete', sysdate - 4.62, 'ok' from dual union all
      select 'Cust0001', 1, 'val task 4', 'complete', sysdate - 4.55, 'ok' from dual union all
      select 'Cust0001', 1, 'rev task 1', 'complete', sysdate - 4.41, 'ok' from dual union all
      select 'Cust0001', 1, 'rev task 2', 'complete', sysdate - 4.32, 'ok' from dual union all
      select 'Cust0001', 1, 'rev task 3', 'complete', sysdate - 4.23, 'ok' from dual union all
      select 'Cust0001', 1, 'approved', 'approved', sysdate - 4.14, '10000' from dual union all
      select 'Cust0002', 2, 'submitted', 'submitted', sysdate - 3.91, '5000' from dual union all
      select 'Cust0002', 2, 'val task 1', 'complete', sysdate - 3.82, 'ok' from dual union all
      select 'Cust0002', 2, 'val task 2', 'complete', sysdate - 3.73, 'ok' from dual union all
      select 'Cust0002', 2, 'val task 3', 'complete', sysdate - 3.64, 'ok' from dual union all
      select 'Cust0002', 2, 'val task 4', 'complete', sysdate - 3.55, 'ok' from dual union all
      select 'Cust0002', 2, 'rev task 1', 'complete', sysdate - 3.46, 'ok' from dual union all
      select 'Cust0002', 2, 'withdrawn', 'withdrawn', sysdate - 3.37, '0' from dual union all
      select 'Cust0003', 3, 'submitted', 'submitted', sysdate - 3.68, '7000' from dual union all
      select 'Cust0003', 3, 'val task 1', 'complete', sysdate - 3.59, 'ok' from dual union all
      select 'Cust0003', 3, 'val task 2', 'complete', sysdate - 3.40, 'ok' from dual union all
      select 'Cust0003', 3, 'val task 3', 'complete', sysdate - 3.31, 'failed' from dual union all
      select 'Cust0003', 3, 'denied', 'denied', sysdate - 3.20, '0' from dual union all
      select 'Cust0004', 4, 'submitted', 'submitted', sysdate - 2.90, '12000' from dual union all
      select 'Cust0004', 4, 'val task 1', 'complete', sysdate - 2.81, 'ok' from dual union all
      select 'Cust0004', 4, 'val task 2', 'complete', sysdate - 2.72, 'ok' from dual union all
      select 'Cust0004', 4, 'val task 3', 'complete', sysdate - 2.63, 'failed' from dual union all
      select 'Cust0004', 4, 'rev task 1', 'complete', sysdate - 2.44, 'ok' from dual union all
      select 'Cust0004', 4, 'rev task 2', 'complete', sysdate - 2.35, 'ok' from dual union all
      select 'Cust0005', 5, 'submitted', 'submitted', sysdate - 1.96, '6000' from dual union all
      select 'Cust0005', 5, 'val task 1', 'complete', sysdate - 1.87, 'ok' from dual union all
      select 'Cust0005', 5, 'val task 2', 'complete', sysdate - 1.78, 'ok' from dual union all
      select 'Cust0005', 5, 'val task 3', 'complete', sysdate - 1.69, 'failed' from dual union all
      select 'Cust0006', 6, 'submitted', 'submitted', sysdate - 1.40, '2000' from dual union all
      select 'Cust0006', 6, 'val task 1', 'complete', sysdate - 1.31, 'ok' from dual union all
      select 'Cust0002', 7, 'submitted', 'submitted', sysdate - 0.72, '15000' from dual);

update EVENT_STATUS_LOGS e0
set elapsed_time = event_ts - (select min(event_ts) from EVENT_STATUS_LOGS e1 where e1.application_id = e0.application_id and e1.id > e0.id)
where exists (select 1 from EVENT_STATUS_LOGS e1 where e1.application_id = e0.application_id and e1.id > e0.id);

update EVENT_STATUS_LOGS e0
set elapsed_time = 0
where elapsed_time is null
and event_type in (select event_type from status_maps where category = 'completed');

commit;

