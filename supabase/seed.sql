-- =============================================================================
-- CAF Movimiento · Datos de ejemplo (opcional, para demostraciones)
-- Ejecutar DESPUÉS de las migraciones, en el SQL Editor de Supabase.
-- Son los mismos estudiantes del modo demo de la app.
-- =============================================================================

insert into public.students (full_name, email, created_at) values
  ('Javiera Muñoz',    'javiera.munoz@duocuc.cl',    now() - interval '52 days'),
  ('Benjamín Torres',  'benjamin.torres@duocuc.cl',  now() - interval '52 days'),
  ('Antonia Vera',     'antonia.vera@duocuc.cl',     now() - interval '52 days'),
  ('Matías Contreras', 'matias.contreras@duocuc.cl', now() - interval '52 days')
on conflict (email) do nothing;

-- Dos evaluaciones de Javiera (inicial y seguimiento), con el plan que
-- genera la app para esos puntajes.
do $$
declare
  v_student uuid := (select id from public.students where email = 'javiera.munoz@duocuc.cl');
  v_eval    public.evaluations;
begin
  if exists (select 1 from public.evaluations where student_id = v_student) then
    return;
  end if;

  v_eval := public.create_evaluation(
    v_student,
    'Evaluación inicial de ingreso al CAF.',
    '[{"exercise_id":"press-banca","score":2},{"exercise_id":"dominadas","score":1},
      {"exercise_id":"peso-muerto","score":2},{"exercise_id":"sentadilla","score":3},
      {"exercise_id":"plancha-lateral","score":1},{"exercise_id":"plancha-frontal","score":2},
      {"exercise_id":"estocada","score":2},{"exercise_id":"remo","score":3},
      {"exercise_id":"jalon-pecho","score":2},{"exercise_id":"biceps","score":3}]',
    '[{"exercise_id":"dominadas","score":1},{"exercise_id":"plancha-lateral","score":1}]'
  );
  update public.evaluations set evaluated_at = now() - interval '42 days' where id = v_eval.id;

  v_eval := public.create_evaluation(
    v_student,
    'Control de seguimiento.',
    '[{"exercise_id":"press-banca","score":3},{"exercise_id":"dominadas","score":2},
      {"exercise_id":"peso-muerto","score":3},{"exercise_id":"sentadilla","score":3},
      {"exercise_id":"plancha-lateral","score":2},{"exercise_id":"plancha-frontal","score":3},
      {"exercise_id":"estocada","score":3},{"exercise_id":"remo","score":3},
      {"exercise_id":"jalon-pecho","score":3},{"exercise_id":"biceps","score":3}]',
    '[{"exercise_id":"dominadas","score":2},{"exercise_id":"plancha-lateral","score":2}]'
  );
  update public.evaluations set evaluated_at = now() - interval '3 days' where id = v_eval.id;
end;
$$;
