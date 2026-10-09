-- =============================================================================
-- CAF Movimiento · Siempre debe quedar al menos un administrador
-- Los roles se cambian desde la sección "Usuarios" de la app (solo admins,
-- ver protect_profile_update en 0001). Esta regla evita que el centro se
-- quede sin nadie que pueda asignar roles.
-- =============================================================================

create or replace function public.keep_one_admin()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.role = 'admin'
     and new.role is distinct from 'admin'
     and not exists (
       select 1 from public.profiles p where p.role = 'admin' and p.id <> old.id
     ) then
    raise exception 'Debe quedar al menos un administrador';
  end if;
  return new;
end;
$$;

create trigger on_profile_keep_one_admin
  before update of role on public.profiles
  for each row execute function public.keep_one_admin();
