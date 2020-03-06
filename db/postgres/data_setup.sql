insert into STATUS_MAPS(category, event_type)
select category, event_type
from (select 'submitted' category, 'submitted' event_type  union all
      select 'validating', 'val task ' || level from (select generate_series(1,4) as level) s1 union all
      select 'reviewing', 'rev task ' || level from (select generate_series(1,3) as level) s2 union all
      select 'completed', (array['approved', 'withdrawn', 'denied'])[level]
      from (select generate_series(1,3) as level) s3
    ) ms;

insert into EVENT_STATUS_LOGS (client_id, customer_uuid, application_id, event_type, status, event_ts, disposition)
select 'TestApp', customer_uuid, application_id, event_type, status, event_ts, disposition
from (select 'Cust0001' customer_uuid, 1 application_id, 'submitted' event_type, 'submitted' status,
            localtimestamp - make_interval(days => 4, hours => 22) event_ts, '10000' disposition union all
      select 'Cust0001', 1, 'val task 1', 'complete', localtimestamp - make_interval(days => 4, hours => 20), 'ok' union all
      select 'Cust0001', 1, 'val task 2', 'complete', localtimestamp - make_interval(days => 4, hours => 18), 'ok' union all
      select 'Cust0001', 1, 'val task 3', 'complete', localtimestamp - make_interval(days => 4, hours => 16), 'ok' union all
      select 'Cust0001', 1, 'val task 4', 'complete', localtimestamp - make_interval(days => 4, hours => 14), 'ok' union all
      select 'Cust0001', 1, 'rev task 1', 'complete', localtimestamp - make_interval(days => 4, hours => 12), 'ok' union all
      select 'Cust0001', 1, 'rev task 2', 'complete', localtimestamp - make_interval(days => 4, hours => 10), 'ok' union all
      select 'Cust0001', 1, 'rev task 3', 'complete', localtimestamp - make_interval(days => 4, hours => 8), 'ok' union all
      select 'Cust0001', 1, 'approved', 'approved', localtimestamp - make_interval(days => 4, hours => 6), '10000' union all
      select 'Cust0002', 2, 'submitted', 'submitted', localtimestamp - make_interval(days => 3, hours => 21), '5000' union all
      select 'Cust0002', 2, 'val task 1', 'complete', localtimestamp - make_interval(days => 3, hours => 19), 'ok' union all
      select 'Cust0002', 2, 'val task 2', 'complete', localtimestamp - make_interval(days => 3, hours => 17), 'ok' union all
      select 'Cust0002', 2, 'val task 3', 'complete', localtimestamp - make_interval(days => 3, hours => 15), 'ok' union all
      select 'Cust0002', 2, 'val task 4', 'complete', localtimestamp - make_interval(days => 3, hours => 13), 'ok' union all
      select 'Cust0002', 2, 'rev task 1', 'complete', localtimestamp - make_interval(days => 3, hours => 11), 'ok' union all
      select 'Cust0002', 2, 'withdrawn', 'withdrawn', localtimestamp - make_interval(days => 3, hours => 9), '0' union all
      select 'Cust0003', 3, 'submitted', 'submitted', localtimestamp - make_interval(days => 3, hours => 16), '7000' union all
      select 'Cust0003', 3, 'val task 1', 'complete', localtimestamp - make_interval(days => 3, hours => 14), 'ok' union all
      select 'Cust0003', 3, 'val task 2', 'complete', localtimestamp - make_interval(days => 3, hours => 12), 'ok' union all
      select 'Cust0003', 3, 'val task 3', 'complete', localtimestamp - make_interval(days => 3, hours => 10), 'failed' union all
      select 'Cust0003', 3, 'denied', 'denied', localtimestamp - make_interval(days => 3, hours => 8), '0' union all
      select 'Cust0004', 4, 'submitted', 'submitted', localtimestamp - make_interval(days => 2, hours => 22), '12000' union all
      select 'Cust0004', 4, 'val task 1', 'complete', localtimestamp - make_interval(days => 2, hours => 20), 'ok' union all
      select 'Cust0004', 4, 'val task 2', 'complete', localtimestamp - make_interval(days => 2, hours => 18), 'ok' union all
      select 'Cust0004', 4, 'val task 3', 'complete', localtimestamp - make_interval(days => 2, hours => 16), 'failed' union all
      select 'Cust0004', 4, 'rev task 1', 'complete', localtimestamp - make_interval(days => 2, hours => 14), 'ok' union all
      select 'Cust0004', 4, 'rev task 2', 'complete', localtimestamp - make_interval(days => 2, hours => 12), 'ok' union all
      select 'Cust0005', 5, 'submitted', 'submitted', localtimestamp - make_interval(days => 1, hours => 19), '6000' union all
      select 'Cust0005', 5, 'val task 1', 'complete', localtimestamp - make_interval(days => 1, hours => 17), 'ok' union all
      select 'Cust0005', 5, 'val task 2', 'complete', localtimestamp - make_interval(days => 1, hours => 15), 'ok' union all
      select 'Cust0005', 5, 'val task 3', 'complete', localtimestamp - make_interval(days => 1, hours => 13), 'failed' union all
      select 'Cust0006', 6, 'submitted', 'submitted', localtimestamp - make_interval(days => 1, hours => 11), '2000' union all
      select 'Cust0006', 6, 'val task 1', 'complete', localtimestamp - make_interval(days => 1, hours => 9), 'ok' union all
      select 'Cust0002', 7, 'submitted', 'submitted', localtimestamp - make_interval(days => 0, hours => 20), '15000') sl;

update EVENT_STATUS_LOGS e0
set elapsed_time = (select min(event_ts) from EVENT_STATUS_LOGS e1 where e1.application_id = e0.application_id and e1.event_ts > e0.event_ts) - event_ts
where exists (select 1 from EVENT_STATUS_LOGS e1 where e1.application_id = e0.application_id and e1.event_ts > e0.event_ts);

update EVENT_STATUS_LOGS e0
set elapsed_time = interval '0 sec'
where elapsed_time is null
and event_type in (select event_type from status_maps where category = 'completed');
