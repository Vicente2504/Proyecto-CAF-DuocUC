-- =============================================================================
-- CAF Movimiento · Estudiantes, evaluaciones y plan de ejercicios
-- Requiere 0001_auth_profiles.sql. Ejecutar en Supabase: Dashboard →
-- SQL Editor → pegar y "Run".
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Catálogo de los 10 ejercicios evaluados. Los ids deben coincidir con
-- kExercises (lib/models/exercise.dart); los textos de criterio y
-- prescripción siguen viviendo en la app.
-- -----------------------------------------------------------------------------
create table public.exercises (
  id        text primary key,
  name      text not null,
  position  smallint not null unique
);

comment on table public.exercises is 'Catálogo de ejercicios de la ficha de movimiento funcional.';

insert into public.exercises (id, name, position) values
  ('press-banca',     'Press banca',      1),
  ('dominadas',       'Dominadas',        2),
  ('peso-muerto',     'Peso muerto',      3),
  ('sentadilla',      'Sentadilla',       4),
  ('plancha-lateral', 'Plancha lateral',  5),
  ('plancha-frontal', 'Plancha frontal',  6),
  ('estocada',        'Estocada',         7),
  ('remo',            'Remo',             8),
  ('jalon-pecho',     'Jalón al pecho',   9),
  ('biceps',          'Curl de bíceps',  10);

-- -----------------------------------------------------------------------------
-- Estudiantes (fichas). Los crea un instructor; el estudiante ve la suya
-- cuando inicia sesión con el mismo correo.
-- -----------------------------------------------------------------------------
create table public.students (
  id          uuid primary key default gen_random_uuid(),
  full_name   text not null check (length(trim(full_name)) > 0),
  email       text unique check (email = lower(trim(email)) and email <> ''),
  created_by  uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now()
);

comment on table public.students is 'Ficha de cada estudiante del CAF. Se vincula con su cuenta por correo.';

-- -----------------------------------------------------------------------------
-- Evaluaciones: una por sesión de evaluación, con sus 10 puntajes y el
-- plan de ejercicios que generó la app en ese momento.
-- -----------------------------------------------------------------------------
create table public.evaluations (
  id             uuid primary key default gen_random_uuid(),
  student_id     uuid not null references public.students (id) on delete cascade,
  instructor_id  uuid default auth.uid() references public.profiles (id) on delete set null,
  evaluated_at   timestamptz not null default now(),
  notes          text
);

create index evaluations_student_date_idx on public.evaluations (student_id, evaluated_at);

create table public.evaluation_scores (
  evaluation_id  uuid not null references public.evaluations (id) on delete cascade,
  exercise_id    text not null references public.exercises (id),
  score          smallint not null check (score between 0 and 3),
  pain           boolean not null default false,
  primary key (evaluation_id, exercise_id)
);

create table public.evaluation_plan_items (
  evaluation_id  uuid not null references public.evaluations (id) on delete cascade,
  exercise_id    text not null references public.exercises (id),
  score          smallint not null check (score between 0 and 3),
  primary key (evaluation_id, exercise_id)
);

comment on table public.evaluation_plan_items is
  'Ejercicios del plan generado por la app (lib/services/recommendation.dart) para esa evaluación.';

-- -----------------------------------------------------------------------------
-- Correo del usuario actual, para vincular al estudiante con su ficha.
-- -----------------------------------------------------------------------------
create or replace function public.current_user_email()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select email from public.profiles where id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.current_user_role() in ('admin', 'instructor'), false);
$$;

-- -----------------------------------------------------------------------------
-- Guarda una evaluación completa (cabecera, puntajes y plan) en una sola
-- transacción. SECURITY INVOKER: las políticas RLS de abajo se aplican.
--
--   p_scores: [{"exercise_id": "remo", "score": 2, "pain": false}, ...]
--   p_plan:   [{"exercise_id": "remo", "score": 1}, ...]
-- -----------------------------------------------------------------------------
create or replace function public.create_evaluation(
  p_student_id uuid,
  p_notes      text,
  p_scores     jsonb,
  p_plan       jsonb
)
returns public.evaluations
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_eval public.evaluations;
begin
  if jsonb_array_length(p_scores) <> (select count(*) from public.exercises) then
    raise exception 'La evaluación debe incluir el puntaje de los % ejercicios',
      (select count(*) from public.exercises);
  end if;

  insert into public.evaluations (student_id, notes)
  values (p_student_id, nullif(trim(p_notes), ''))
  returning * into v_eval;

  insert into public.evaluation_scores (evaluation_id, exercise_id, score, pain)
  select v_eval.id, s.exercise_id, s.score, coalesce(s.pain, false)
  from jsonb_to_recordset(p_scores) as s(exercise_id text, score smallint, pain boolean);

  insert into public.evaluation_plan_items (evaluation_id, exercise_id, score)
  select v_eval.id, p.exercise_id, p.score
  from jsonb_to_recordset(coalesce(p_plan, '[]'::jsonb)) as p(exercise_id text, score smallint);

  return v_eval;
end;
$$;

-- -----------------------------------------------------------------------------
-- Row Level Security
--   · Instructores y admins: ven y crean fichas y evaluaciones de todos.
--   · Estudiantes: solo leen su propia ficha (por correo) y sus evaluaciones.
--   · Solo los admins eliminan.
-- -----------------------------------------------------------------------------
alter table public.exercises             enable row level security;
alter table public.students              enable row level security;
alter table public.evaluations           enable row level security;
alter table public.evaluation_scores     enable row level security;
alter table public.evaluation_plan_items enable row level security;

create policy "Usuarios autenticados ven el catálogo"
  on public.exercises for select to authenticated
  using (true);

-- students
create policy "Personal ve todas las fichas"
  on public.students for select to authenticated
  using (public.is_staff());

create policy "Estudiante ve su ficha"
  on public.students for select to authenticated
  using (email = public.current_user_email());

create policy "Personal crea fichas"
  on public.students for insert to authenticated
  with check (public.is_staff());

create policy "Personal edita fichas"
  on public.students for update to authenticated
  using (public.is_staff())
  with check (public.is_staff());

create policy "Admins eliminan fichas"
  on public.students for delete to authenticated
  using (public.current_user_role() = 'admin');

-- evaluations (la subconsulta a students respeta su propia RLS)
create policy "Ven evaluaciones de fichas visibles"
  on public.evaluations for select to authenticated
  using (exists (select 1 from public.students s where s.id = student_id));

create policy "Personal crea evaluaciones"
  on public.evaluations for insert to authenticated
  with check (public.is_staff());

create policy "Admins eliminan evaluaciones"
  on public.evaluations for delete to authenticated
  using (public.current_user_role() = 'admin');

-- evaluation_scores / evaluation_plan_items heredan la visibilidad de la
-- evaluación. Se borran en cascada junto con ella.
create policy "Ven puntajes de evaluaciones visibles"
  on public.evaluation_scores for select to authenticated
  using (exists (select 1 from public.evaluations e where e.id = evaluation_id));

create policy "Personal registra puntajes"
  on public.evaluation_scores for insert to authenticated
  with check (public.is_staff());

create policy "Ven el plan de evaluaciones visibles"
  on public.evaluation_plan_items for select to authenticated
  using (exists (select 1 from public.evaluations e where e.id = evaluation_id));

create policy "Personal registra el plan"
  on public.evaluation_plan_items for insert to authenticated
  with check (public.is_staff());
