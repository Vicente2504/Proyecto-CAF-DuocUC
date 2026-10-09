-- =============================================================================
-- CAF Movimiento · Ficha automática para cada estudiante registrado
-- Requiere 0002_students_evaluations.sql. Ejecutar en Supabase: Dashboard →
-- SQL Editor → pegar y "Run".
--
-- Cuando alguien se registra (perfil con rol 'estudiante') se le crea su
-- ficha en public.students, para que el instructor lo vea en su lista sin
-- tener que agregarlo a mano. Si el instructor ya había creado una ficha
-- con ese correo, se usa esa (no se duplica).
-- =============================================================================

create or replace function public.ensure_student_record()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role = 'estudiante' then
    insert into public.students (full_name, email, created_by)
    values (
      coalesce(nullif(trim(new.full_name), ''), split_part(new.email, '@', 1)),
      new.email,
      null
    )
    on conflict (email) do nothing;
  elsif tg_op = 'UPDATE' and old.role = 'estudiante' then
    -- Si un admin lo asciende a instructor o admin, se quita su ficha
    -- solo si nunca fue evaluado (así no se pierde historial).
    delete from public.students s
    where s.email = new.email
      and not exists (select 1 from public.evaluations e where e.student_id = s.id);
  end if;
  return new;
end;
$$;

create trigger on_profile_student_record
  after insert or update of role on public.profiles
  for each row execute function public.ensure_student_record();

-- Fichas para los estudiantes que se registraron antes de esta migración.
insert into public.students (full_name, email, created_by)
select coalesce(nullif(trim(p.full_name), ''), split_part(p.email, '@', 1)), p.email, null
from public.profiles p
where p.role = 'estudiante'
on conflict (email) do nothing;
