alter table public.teacher_requests
  add column if not exists disciplines text[] not null default '{}';

alter table public.teachers
  add column if not exists disciplines text[] not null default '{}';

alter table public.schedules
  add column if not exists shift text not null default 'morning';

update public.teacher_requests
set disciplines = array[discipline]
where cardinality(disciplines) = 0 and discipline is not null;

update public.teachers
set disciplines = array[discipline]
where cardinality(disciplines) = 0 and discipline is not null;

update public.schedules
set shift = case
  when start_time >= time '18:30' then 'night'
  when start_time >= time '13:00' then 'afternoon'
  else 'morning'
end
where shift is null or shift = '';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'schedules_shift_check'
  ) then
    alter table public.schedules
      add constraint schedules_shift_check
      check (shift in ('morning', 'afternoon', 'night'));
  end if;
end $$;

create index if not exists schedules_shift_weekday_idx
  on public.schedules (shift, weekday, start_time);
