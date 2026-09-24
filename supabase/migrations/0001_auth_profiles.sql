-- =============================================================================
-- CAF Movimiento · Perfiles y roles de usuario
-- Ejecutar en Supabase: Dashboard → SQL Editor → pegar y "Run".
-- =============================================================================

-- Roles de la propuesta técnica (sección 3).
create type public.user_role as enum ('admin', 'instructor', 'estudiante');

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text not null unique,
  full_name   text not null default '',
  role        public.user_role not null default 'estudiante',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.profiles is 'Perfil y rol de cada usuario autenticado del CAF.';

-- -----------------------------------------------------------------------------
-- Rol del usuario actual. SECURITY DEFINER evita recursión en las políticas
-- RLS que consultan la misma tabla profiles.
-- -----------------------------------------------------------------------------
create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- -----------------------------------------------------------------------------
-- Al registrarse: solo correos institucionales y siempre como estudiante.
-- El rol NO se toma de los metadatos que envía el cliente.
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Mantener sincronizado con Env.allowedEmailDomains (lib/config/env.dart).
  if lower(split_part(new.email, '@', 2)) not in ('duocuc.cl', 'duoc.cl', 'profesor.duoc.cl') then
    raise exception 'Dominio de correo no permitido: %', new.email;
  end if;

  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    lower(new.email),
    coalesce(trim(new.raw_user_meta_data ->> 'full_name'), '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- Protege los cambios: solo un administrador puede cambiar roles y nadie
-- cambia el correo desde aquí. Desde el SQL Editor (sin usuario de la app,
-- auth.uid() es null) sí se permite, para poder crear el primer admin.
-- -----------------------------------------------------------------------------
create or replace function public.protect_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    if new.role is distinct from old.role
       and public.current_user_role() is distinct from 'admin' then
      raise exception 'Solo un administrador puede cambiar roles';
    end if;
    new.email := old.email;
  end if;
  new.id := old.id;
  new.created_at := old.created_at;
  new.updated_at := now();
  return new;
end;
$$;

create trigger on_profile_update
  before update on public.profiles
  for each row execute function public.protect_profile_update();

-- -----------------------------------------------------------------------------
-- Row Level Security
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;

create policy "Cada usuario ve su perfil"
  on public.profiles for select to authenticated
  using (id = auth.uid());

create policy "Instructores y admins ven todos los perfiles"
  on public.profiles for select to authenticated
  using (public.current_user_role() in ('admin', 'instructor'));

create policy "Cada usuario edita su perfil"
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Admins editan cualquier perfil"
  on public.profiles for update to authenticated
  using (public.current_user_role() = 'admin')
  with check (public.current_user_role() = 'admin');

-- No hay políticas de insert/delete: los perfiles solo se crean con el
-- trigger de registro y se borran en cascada al eliminar el usuario.

-- =============================================================================
-- Primer administrador (ejecutar DESPUÉS de registrarte en la app):
--
--   update public.profiles set role = 'admin' where email = 'tu.correo@duocuc.cl';
-- =============================================================================
