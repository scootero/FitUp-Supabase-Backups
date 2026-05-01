


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "public";






CREATE SCHEMA IF NOT EXISTS "private";


ALTER SCHEMA "private" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "hypopg" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "index_advisor" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "private"."invoke_dispatch_notification"("p_user_ids" "uuid"[], "p_event_type" "text", "p_payload" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_user_ids text[];
BEGIN
  IF p_user_ids IS NULL OR array_length(p_user_ids, 1) IS NULL THEN
    RETURN;
  END IF;

  SELECT ARRAY_AGG(value::text)
  INTO v_user_ids
  FROM unnest(p_user_ids) AS value;

  PERFORM private.invoke_edge_function(
    'dispatch-notification',
    jsonb_build_object(
      'user_ids', to_jsonb(v_user_ids),
      'event_type', p_event_type,
      'payload', COALESCE(p_payload, '{}'::jsonb)
    )
  );
END;
$$;


ALTER FUNCTION "private"."invoke_dispatch_notification"("p_user_ids" "uuid"[], "p_event_type" "text", "p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."invoke_edge_function"("p_function_name" "text", "p_payload" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_project_url text;
  v_service_role_key text;
BEGIN
  SELECT decrypted_secret
  INTO v_project_url
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_project_url'
  LIMIT 1;

  SELECT decrypted_secret
  INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_service_role_key'
  LIMIT 1;

  IF v_project_url IS NULL OR v_service_role_key IS NULL THEN
    RAISE EXCEPTION 'Missing vault secrets fitup_project_url or fitup_service_role_key.';
  END IF;

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/' || p_function_name,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key,
      'apikey', v_service_role_key
    ),
    body := p_payload
  );
END;
$$;


ALTER FUNCTION "private"."invoke_edge_function"("p_function_name" "text", "p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."invoke_finalize_match_day"("p_match_day_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_project_url text;
  v_service_role_key text;
BEGIN
  SELECT decrypted_secret
  INTO v_project_url
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_project_url'
  LIMIT 1;

  SELECT decrypted_secret
  INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_service_role_key'
  LIMIT 1;

  IF v_project_url IS NULL OR v_service_role_key IS NULL THEN
    RAISE EXCEPTION 'Missing vault secrets fitup_project_url or fitup_service_role_key.';
  END IF;

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/finalize-match-day',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key,
      'apikey', v_service_role_key
    ),
    body := jsonb_build_object('match_day_id', p_match_day_id::text),
    timeout_milliseconds := 60000
  );
END;
$$;


ALTER FUNCTION "private"."invoke_finalize_match_day"("p_match_day_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."invoke_matchmaking_pairing"("p_request_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_project_url text;
  v_service_role_key text;
BEGIN
  SELECT decrypted_secret
  INTO v_project_url
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_project_url'
  LIMIT 1;

  SELECT decrypted_secret
  INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_service_role_key'
  LIMIT 1;

  IF v_project_url IS NULL OR v_service_role_key IS NULL THEN
    RAISE EXCEPTION 'Missing vault secrets fitup_project_url or fitup_service_role_key.';
  END IF;

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/matchmaking-pairing',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key,
      'apikey', v_service_role_key
    ),
    body := jsonb_build_object('match_search_request_id', p_request_id::text)
  );
END;
$$;


ALTER FUNCTION "private"."invoke_matchmaking_pairing"("p_request_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."invoke_on_all_accepted"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_project_url text;
  v_service_role_key text;
BEGIN
  SELECT decrypted_secret
  INTO v_project_url
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_project_url'
  LIMIT 1;

  SELECT decrypted_secret
  INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'fitup_service_role_key'
  LIMIT 1;

  IF v_project_url IS NULL OR v_service_role_key IS NULL THEN
    RAISE EXCEPTION 'Missing vault secrets fitup_project_url or fitup_service_role_key.';
  END IF;

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/on-all-accepted',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key,
      'apikey', v_service_role_key
    ),
    body := jsonb_build_object('match_id', p_match_id::text)
  );
END;
$$;


ALTER FUNCTION "private"."invoke_on_all_accepted"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."notification_sent_today"("p_user_id" "uuid", "p_event_type" "text", "p_match_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM notification_events ne
    WHERE ne.user_id = p_user_id
      AND ne.event_type = p_event_type
      AND COALESCE(ne.payload ->> 'match_id', '') = p_match_id::text
      AND ne.created_at >= date_trunc('day', now())
  );
$$;


ALTER FUNCTION "private"."notification_sent_today"("p_user_id" "uuid", "p_event_type" "text", "p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."resolve_leader_user"("p_my_value" numeric, "p_other_value" numeric, "p_my_user_id" "uuid", "p_other_user_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
  IF COALESCE(p_my_value, 0) = COALESCE(p_other_value, 0) THEN
    RETURN NULL;
  END IF;
  IF COALESCE(p_my_value, 0) > COALESCE(p_other_value, 0) THEN
    RETURN p_my_user_id;
  END IF;
  RETURN p_other_user_id;
END;
$$;


ALTER FUNCTION "private"."resolve_leader_user"("p_my_value" numeric, "p_other_value" numeric, "p_my_user_id" "uuid", "p_other_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."activate_match_with_days"("p_match_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_state text;
  v_duration int;
  v_starts_at timestamptz;
  v_tz text;
  v_total int;
  v_accepted int;
  v_rowcount int;
  v_base_date date;
  v_day int;
  v_match_day_id uuid;
  r_participant record;
BEGIN
  SELECT state, duration_days, starts_at, match_timezone
  INTO v_state, v_duration, v_starts_at, v_tz
  FROM matches
  WHERE id = p_match_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF v_state <> 'pending' THEN
    RETURN false;
  END IF;

  SELECT
    COUNT(*)::int,
    COUNT(*) FILTER (WHERE accepted_at IS NOT NULL)::int
  INTO v_total, v_accepted
  FROM match_participants
  WHERE match_id = p_match_id;

  IF v_total = 0 OR v_total <> v_accepted THEN
    RETURN false;
  END IF;

  -- Match start = 00:00 local on Day 1 in match_timezone (proper timestamptz; server-TZ independent).
  v_tz := COALESCE(NULLIF(trim(v_tz), ''), 'America/New_York');

  UPDATE matches
  SET state = 'active',
      starts_at = (((timezone(v_tz, clock_timestamp()))::date)::timestamp) AT TIME ZONE v_tz
  WHERE id = p_match_id
    AND state = 'pending';

  GET DIAGNOSTICS v_rowcount = ROW_COUNT;
  IF v_rowcount = 0 THEN
    RETURN false;
  END IF;

  SELECT starts_at, match_timezone, duration_days
  INTO v_starts_at, v_tz, v_duration
  FROM matches
  WHERE id = p_match_id;

  IF v_tz IS NULL OR length(trim(v_tz)) = 0 THEN
    v_tz := 'America/New_York';
  END IF;

  v_base_date := (timezone(v_tz, v_starts_at))::date;

  FOR v_day IN 1..v_duration LOOP
    INSERT INTO match_days (match_id, day_number, calendar_date, status)
    VALUES (p_match_id, v_day, v_base_date + (v_day - 1), 'pending')
    ON CONFLICT (match_id, day_number) DO NOTHING;

    SELECT id
    INTO v_match_day_id
    FROM match_days
    WHERE match_id = p_match_id
      AND day_number = v_day
    LIMIT 1;

    IF v_match_day_id IS NULL THEN
      CONTINUE;
    END IF;

    FOR r_participant IN
      SELECT user_id FROM match_participants WHERE match_id = p_match_id
    LOOP
      INSERT INTO match_day_participants (match_day_id, user_id, metric_total, data_status)
      VALUES (v_match_day_id, r_participant.user_id, 0, 'pending')
      ON CONFLICT (match_day_id, user_id) DO NOTHING;
    END LOOP;
  END LOOP;

  RETURN true;
END;
$$;


ALTER FUNCTION "public"."activate_match_with_days"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_challenger uuid;
  v_match_id uuid;
  v_challenge_id uuid;
  v_now timestamptz := now();
  v_tz text;
BEGIN
  v_challenger := (
    SELECT id FROM public.profiles WHERE auth_user_id = auth.uid() LIMIT 1
  );

  IF v_challenger IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  IF p_recipient_id = v_challenger THEN
    RAISE EXCEPTION 'cannot challenge self';
  END IF;

  IF p_metric_type NOT IN ('steps', 'active_calories') THEN
    RAISE EXCEPTION 'invalid metric_type';
  END IF;

  IF p_duration_days NOT IN (1, 3, 5, 7) THEN
    RAISE EXCEPTION 'invalid duration_days';
  END IF;

  IF p_start_mode NOT IN ('today', 'tomorrow') THEN
    RAISE EXCEPTION 'invalid start_mode';
  END IF;

  v_tz := COALESCE(NULLIF(trim(p_match_timezone), ''), 'America/New_York');

  INSERT INTO public.matches (
    match_type,
    metric_type,
    duration_days,
    start_mode,
    state,
    match_timezone,
    starts_at
  )
  VALUES (
    'direct_challenge',
    p_metric_type,
    p_duration_days,
    p_start_mode,
    'pending',
    v_tz,
    p_starts_at
  )
  RETURNING id INTO v_match_id;

  INSERT INTO public.match_participants (match_id, user_id, role, joined_via, accepted_at)
  VALUES
    (v_match_id, v_challenger, 'challenger', 'direct_challenge', v_now),
    (v_match_id, p_recipient_id, 'opponent', 'direct_challenge', NULL);

  INSERT INTO public.direct_challenges (challenger_id, recipient_id, match_id, status)
  VALUES (v_challenger, p_recipient_id, v_match_id, 'pending')
  RETURNING id INTO v_challenge_id;

  RETURN json_build_object(
    'match_id', v_match_id,
    'challenge_id', v_challenge_id
  );
END;
$$;


ALTER FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) IS 'Creates a direct challenge match + participants + direct_challenges row; challenger from JWT only.';



CREATE OR REPLACE FUNCTION "public"."current_user_match_ids"() RETURNS SETOF "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
  SELECT mp.match_id
  FROM match_participants mp
  WHERE mp.user_id = (SELECT id FROM profiles WHERE auth_user_id = auth.uid());
$$;


ALTER FUNCTION "public"."current_user_match_ids"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."current_user_match_ids"() IS 'Returns match_id values for the invoking user; SECURITY DEFINER avoids RLS recursion in policies.';



CREATE OR REPLACE FUNCTION "public"."day_cutoff_check"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_match_day_id uuid;
BEGIN
  -- Phase 1: pending participants past local cutoff → confirmed (existing behavior)
  FOR v_match_day_id IN
    WITH pending_cutoff_rows AS (
      SELECT mdp.id, mdp.match_day_id
      FROM match_day_participants mdp
      JOIN match_days md
        ON md.id = mdp.match_day_id
      JOIN profiles p
        ON p.id = mdp.user_id
      WHERE md.status <> 'finalized'
        AND mdp.data_status = 'pending'
        AND timezone(COALESCE(p.timezone, 'UTC'), now())
          >= ((md.calendar_date + 1)::timestamp + time '10:00')
    ),
    force_confirmed AS (
      UPDATE match_day_participants mdp
      SET data_status = 'confirmed',
          last_updated_at = now()
      FROM pending_cutoff_rows pending
      WHERE mdp.id = pending.id
      RETURNING pending.match_day_id
    )
    SELECT DISTINCT match_day_id
    FROM force_confirmed
  LOOP
    PERFORM private.invoke_finalize_match_day(v_match_day_id);
  END LOOP;

  -- Phase 2: all participants already confirmed, day not finalized, cutoff passed for
  -- every participant — re-invoke finalize (e.g. after pg_net timeout or edge hiccup)
  FOR v_match_day_id IN
    SELECT md.id
    FROM match_days md
    WHERE md.status <> 'finalized'
      AND NOT EXISTS (
        SELECT 1
        FROM match_day_participants mdp
        WHERE mdp.match_day_id = md.id
          AND mdp.data_status <> 'confirmed'
      )
      AND EXISTS (
        SELECT 1
        FROM match_day_participants mdp
        WHERE mdp.match_day_id = md.id
      )
      AND NOT EXISTS (
        SELECT 1
        FROM match_day_participants mdp
        JOIN profiles p ON p.id = mdp.user_id
        WHERE mdp.match_day_id = md.id
          AND timezone(COALESCE(p.timezone, 'UTC'), now())
            < ((md.calendar_date + 1)::timestamp + time '10:00')
      )
  LOOP
    PERFORM private.invoke_finalize_match_day(v_match_day_id);
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."day_cutoff_check"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."decline_pending_match"("p_match_id" "uuid") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_profile_id uuid;
  v_state text;
  v_match_type text;
  v_updated int;
BEGIN
  v_profile_id := (
    SELECT id FROM public.profiles WHERE auth_user_id = auth.uid() LIMIT 1
  );

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT m.state, m.match_type
  INTO v_state, v_match_type
  FROM public.matches m
  WHERE m.id = p_match_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'reason', 'match_not_found');
  END IF;

  IF v_state <> 'pending' THEN
    RETURN json_build_object('ok', true, 'reason', 'already_resolved');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.match_participants mp
    WHERE mp.match_id = p_match_id
      AND mp.user_id = v_profile_id
  ) THEN
    RAISE EXCEPTION 'not a participant';
  END IF;

  IF v_match_type = 'direct_challenge' THEN
    UPDATE public.direct_challenges
    SET status = 'declined'
    WHERE match_id = p_match_id
      AND status = 'pending';
  END IF;

  PERFORM set_config('app.decline_user_id', v_profile_id::text, true);

  UPDATE public.matches
  SET state = 'cancelled'
  WHERE id = p_match_id
    AND state = 'pending';

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    RETURN json_build_object('ok', true, 'reason', 'already_resolved');
  END IF;

  RETURN json_build_object('ok', true, 'reason', 'declined');
END;
$$;


ALTER FUNCTION "public"."decline_pending_match"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."decline_pending_match"("p_match_id" "uuid") IS 'Declines a pending match: updates direct_challenges when present, sets matches.state to cancelled; notifies opponent for public_matchmaking.';



CREATE OR REPLACE FUNCTION "public"."evening_checkin_candidates"() RETURNS TABLE("user_id" "uuid", "local_date" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
  SELECT
    p.id AS user_id,
    to_char(
      ((now() AT TIME ZONE COALESCE(NULLIF(btrim(p.timezone), ''), 'America/New_York')))::date,
      'YYYY-MM-DD'
    ) AS local_date
  FROM public.profiles p
  WHERE
    EXTRACT(
      HOUR
      FROM (now() AT TIME ZONE COALESCE(NULLIF(btrim(p.timezone), ''), 'America/New_York'))
    ) = 19
    AND NOT EXISTS (
      SELECT 1
      FROM public.user_public_daily_activity u
      WHERE u.user_id = p.id
        AND u.active_date = ((now() AT TIME ZONE COALESCE(NULLIF(btrim(p.timezone), ''), 'America/New_York')))::date
    );
$$;


ALTER FUNCTION "public"."evening_checkin_candidates"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."evening_checkin_candidates"() IS 'User ids in local 7–8pm window (hour 19) who have not synced user_public_daily_activity for the local calendar day.';



CREATE OR REPLACE FUNCTION "public"."finalize_when_all_confirmed"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_total_count int;
  v_confirmed_count int;
  v_day_status text;
BEGIN
  IF NEW.data_status <> 'confirmed' THEN
    RETURN NEW;
  END IF;

  SELECT status
  INTO v_day_status
  FROM match_days
  WHERE id = NEW.match_day_id
  LIMIT 1;

  IF v_day_status = 'finalized' THEN
    RETURN NEW;
  END IF;

  SELECT
    COUNT(*)::int,
    COUNT(*) FILTER (WHERE data_status = 'confirmed')::int
  INTO v_total_count, v_confirmed_count
  FROM match_day_participants
  WHERE match_day_id = NEW.match_day_id;

  IF v_total_count > 0 AND v_total_count = v_confirmed_count THEN
    PERFORM private.invoke_finalize_match_day(NEW.match_day_id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."finalize_when_all_confirmed"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_viewer uuid;
  v_total int;
  v_vwins int;
  v_owins int;
  v_ties int;
BEGIN
  SELECT id
  INTO v_viewer
  FROM public.profiles
  WHERE auth_user_id = auth.uid()
  LIMIT 1;

  IF v_viewer IS NULL OR p_opponent_id IS NULL OR v_viewer = p_opponent_id THEN
    RETURN jsonb_build_object(
      'total_completed', 0,
      'viewer_wins', 0,
      'opponent_wins', 0,
      'series_ties', 0
    );
  END IF;

  WITH mutual_matches AS (
    SELECT DISTINCT m.id AS match_id
    FROM public.matches m
    INNER JOIN public.match_participants mp1
      ON mp1.match_id = m.id AND mp1.user_id = v_viewer
    INNER JOIN public.match_participants mp2
      ON mp2.match_id = m.id AND mp2.user_id = p_opponent_id
    WHERE m.state = 'completed'
  ),
  day_wins AS (
    SELECT
      md.match_id,
      md.winner_user_id
    FROM public.match_days md
    INNER JOIN mutual_matches mm ON mm.match_id = md.match_id
    WHERE md.status = 'finalized'
      AND md.is_void = false
      AND md.winner_user_id IS NOT NULL
  ),
  per_match AS (
    SELECT
      mm.match_id,
      COALESCE(
        SUM(CASE WHEN dw.winner_user_id = v_viewer THEN 1 ELSE 0 END),
        0
      )::int AS viewer_day_wins,
      COALESCE(
        SUM(CASE WHEN dw.winner_user_id = p_opponent_id THEN 1 ELSE 0 END),
        0
      )::int AS opponent_day_wins
    FROM mutual_matches mm
    LEFT JOIN day_wins dw ON dw.match_id = mm.match_id
    GROUP BY mm.match_id
  ),
  outcomes AS (
    SELECT
      CASE
        WHEN viewer_day_wins > opponent_day_wins THEN 1
        ELSE 0
      END AS win_viewer,
      CASE
        WHEN opponent_day_wins > viewer_day_wins THEN 1
        ELSE 0
      END AS win_opponent,
      CASE
        WHEN viewer_day_wins = opponent_day_wins THEN 1
        ELSE 0
      END AS tie_series
    FROM per_match
  )
  SELECT
    COALESCE(COUNT(*)::int, 0),
    COALESCE(SUM(win_viewer)::int, 0),
    COALESCE(SUM(win_opponent)::int, 0),
    COALESCE(SUM(tie_series)::int, 0)
  INTO v_total, v_vwins, v_owins, v_ties
  FROM outcomes;

  RETURN jsonb_build_object(
    'total_completed', COALESCE(v_total, 0),
    'viewer_wins', COALESCE(v_vwins, 0),
    'opponent_wins', COALESCE(v_owins, 0),
    'series_ties', COALESCE(v_ties, 0)
  );
END;
$$;


ALTER FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."health_battle_stats"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
declare
  v_viewer uuid;
  v_matches_played int := 0;
  v_wins int := 0;
  v_losses int := 0;
  v_ties int := 0;
  v_win_rate int := 0;
  v_current_streak_type text := 'none';
  v_current_streak_count int := 0;
  v_result text;
begin
  select p.id
  into v_viewer
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_viewer is null then
    return jsonb_build_object(
      'matches_played', 0,
      'wins', 0,
      'losses', 0,
      'ties', 0,
      'win_rate', 0,
      'current_streak_type', 'none',
      'current_streak_count', 0
    );
  end if;

  with viewer_matches as (
    select m.id, m.completed_at, m.ends_at
    from public.matches m
    inner join public.match_participants mp
      on mp.match_id = m.id
     and mp.user_id = v_viewer
    where m.state = 'completed'
  ),
  day_scores as (
    select
      vm.id as match_id,
      vm.completed_at,
      vm.ends_at,
      coalesce(sum(case when md.winner_user_id = v_viewer then 1 else 0 end), 0)::int as viewer_day_wins,
      coalesce(sum(case when md.winner_user_id is not null and md.winner_user_id <> v_viewer then 1 else 0 end), 0)::int as opponent_day_wins
    from viewer_matches vm
    left join public.match_days md
      on md.match_id = vm.id
     and md.status = 'finalized'
     and md.is_void = false
    group by vm.id, vm.completed_at, vm.ends_at
  ),
  outcomes as (
    select
      match_id,
      completed_at,
      ends_at,
      case
        when viewer_day_wins > opponent_day_wins then 'win'
        when opponent_day_wins > viewer_day_wins then 'loss'
        else 'tie'
      end as result
    from day_scores
  ),
  aggregate_counts as (
    select
      count(*)::int as matches_played,
      coalesce(sum(case when result = 'win' then 1 else 0 end), 0)::int as wins,
      coalesce(sum(case when result = 'loss' then 1 else 0 end), 0)::int as losses,
      coalesce(sum(case when result = 'tie' then 1 else 0 end), 0)::int as ties
    from outcomes
  )
  select
    a.matches_played,
    a.wins,
    a.losses,
    a.ties
  into
    v_matches_played,
    v_wins,
    v_losses,
    v_ties
  from aggregate_counts a;

  if (v_wins + v_losses) > 0 then
    v_win_rate := round((v_wins::numeric / (v_wins + v_losses)::numeric) * 100)::int;
  end if;

  for v_result in
    with viewer_matches as (
      select m.id, m.completed_at, m.ends_at
      from public.matches m
      inner join public.match_participants mp
        on mp.match_id = m.id
       and mp.user_id = v_viewer
      where m.state = 'completed'
    ),
    day_scores as (
      select
        vm.id as match_id,
        vm.completed_at,
        vm.ends_at,
        coalesce(sum(case when md.winner_user_id = v_viewer then 1 else 0 end), 0)::int as viewer_day_wins,
        coalesce(sum(case when md.winner_user_id is not null and md.winner_user_id <> v_viewer then 1 else 0 end), 0)::int as opponent_day_wins
      from viewer_matches vm
      left join public.match_days md
        on md.match_id = vm.id
       and md.status = 'finalized'
       and md.is_void = false
      group by vm.id, vm.completed_at, vm.ends_at
    )
    select
      case
        when viewer_day_wins > opponent_day_wins then 'win'
        when opponent_day_wins > viewer_day_wins then 'loss'
        else 'tie'
      end as result
    from day_scores
    order by completed_at desc nulls last, ends_at desc nulls last
  loop
    if v_result = 'tie' then
      exit;
    end if;

    if v_current_streak_type = 'none' then
      v_current_streak_type := v_result;
      v_current_streak_count := 1;
    elsif v_result = v_current_streak_type then
      v_current_streak_count := v_current_streak_count + 1;
    else
      exit;
    end if;
  end loop;

  return jsonb_build_object(
    'matches_played', coalesce(v_matches_played, 0),
    'wins', coalesce(v_wins, 0),
    'losses', coalesce(v_losses, 0),
    'ties', coalesce(v_ties, 0),
    'win_rate', coalesce(v_win_rate, 0),
    'current_streak_type', coalesce(v_current_streak_type, 'none'),
    'current_streak_count', coalesce(v_current_streak_count, 0)
  );
end;
$$;


ALTER FUNCTION "public"."health_battle_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
declare
  v_viewer uuid;
  v_start date;
  v_count int;
begin
  if p_metric_type is null
     or p_metric_type not in ('steps', 'active_calories') then
    return '[]'::jsonb;
  end if;

  if p_end_date is null then
    return '[]'::jsonb;
  end if;

  v_count := least(31, greatest(1, coalesce(p_day_count, 7)));

  select p.id
  into v_viewer
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_viewer is null then
    return '[]'::jsonb;
  end if;

  v_start := p_end_date - (v_count - 1);

  return (
    with days as (
      select gs::date as cal_date
      from generate_series(v_start, p_end_date, interval '1 day') as gs
    ),
    daily as (
      select
        d.cal_date,
        coalesce((
          select sum(
            (
              coalesce(mdp_v.finalized_value, mdp_v.metric_total)
              - coalesce(mdp_o.finalized_value, mdp_o.metric_total)
            )::bigint
          )
          from public.match_days md
          inner join public.matches m on m.id = md.match_id
          inner join public.match_participants mp_v
            on mp_v.match_id = m.id
           and mp_v.user_id = v_viewer
          inner join public.match_participants mp_o
            on mp_o.match_id = m.id
           and mp_o.user_id <> mp_v.user_id
          inner join public.match_day_participants mdp_v
            on mdp_v.match_day_id = md.id
           and mdp_v.user_id = mp_v.user_id
          inner join public.match_day_participants mdp_o
            on mdp_o.match_day_id = md.id
           and mdp_o.user_id = mp_o.user_id
          where md.calendar_date = d.cal_date
            and md.is_void = false
            and m.state in ('active', 'completed')
            and m.metric_type = p_metric_type
        ), 0::bigint) as margin
      from days d
    )
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'date', cal_date,
          'margin', margin
        )
        order by cal_date
      ),
      '[]'::jsonb
    )
    from daily
  );
end;
$$;


ALTER FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."matchmaking_pair_atomic"("p_request_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_incoming match_search_requests%ROWTYPE;
  v_partner match_search_requests%ROWTYPE;
  v_match_id uuid;
  v_tz text;
  v_challenger uuid;
  v_opponent uuid;
  v_rowcount int;
BEGIN
  SELECT *
  INTO v_incoming
  FROM match_search_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF v_incoming.status <> 'searching' OR v_incoming.matched_match_id IS NOT NULL THEN
    RETURN NULL;
  END IF;

  SELECT msr.*
  INTO v_partner
  FROM match_search_requests msr
  WHERE msr.status = 'searching'
    AND msr.id <> v_incoming.id
    AND msr.creator_id <> v_incoming.creator_id
    AND msr.metric_type = v_incoming.metric_type
    AND msr.duration_days = v_incoming.duration_days
    AND msr.start_mode = v_incoming.start_mode
  ORDER BY
    abs(msr.creator_baseline - v_incoming.creator_baseline) ASC NULLS LAST,
    msr.created_at ASC,
    msr.id ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF v_incoming.created_at < v_partner.created_at
    OR (
      v_incoming.created_at = v_partner.created_at
      AND v_incoming.id < v_partner.id
    )
  THEN
    v_challenger := v_incoming.creator_id;
    v_opponent := v_partner.creator_id;
  ELSE
    v_challenger := v_partner.creator_id;
    v_opponent := v_incoming.creator_id;
  END IF;

  SELECT COALESCE(p.timezone, 'America/New_York')
  INTO v_tz
  FROM profiles p
  WHERE p.id = v_challenger
  LIMIT 1;

  IF v_tz IS NULL OR length(trim(v_tz)) = 0 THEN
    v_tz := 'America/New_York';
  END IF;

  INSERT INTO matches (
    match_type,
    metric_type,
    duration_days,
    start_mode,
    state,
    match_timezone,
    starts_at
  )
  VALUES (
    'public_matchmaking',
    v_incoming.metric_type,
    v_incoming.duration_days,
    v_incoming.start_mode,
    'pending',
    v_tz,
    NULL
  )
  RETURNING id INTO v_match_id;

  INSERT INTO match_participants (match_id, user_id, role, joined_via, accepted_at)
  VALUES
    (v_match_id, v_challenger, 'challenger', 'matchmaking', NULL),
    (v_match_id, v_opponent, 'opponent', 'matchmaking', NULL);

  UPDATE match_search_requests
  SET status = 'matched',
      matched_match_id = v_match_id
  WHERE id IN (v_incoming.id, v_partner.id)
    AND status = 'searching';

  GET DIAGNOSTICS v_rowcount = ROW_COUNT;
  IF v_rowcount <> 2 THEN
    RAISE EXCEPTION 'matchmaking_pair_atomic: expected 2 updated search rows, got %', v_rowcount;
  END IF;

  RETURN v_match_id;
END;
$$;


ALTER FUNCTION "public"."matchmaking_pair_atomic"("p_request_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."matchmaking_retry_stale_searches"("p_min_age_seconds" integer DEFAULT 5, "p_max_invocations" integer DEFAULT 30) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  n int := 0;
  r record;
BEGIN
  IF p_min_age_seconds < 0 OR p_max_invocations < 1 THEN
    RAISE EXCEPTION 'matchmaking_retry_stale_searches: invalid parameters';
  END IF;

  FOR r IN
    SELECT id
    FROM match_search_requests
    WHERE status = 'searching'
      AND created_at <= now() - make_interval(secs => p_min_age_seconds)
    ORDER BY created_at ASC
    LIMIT p_max_invocations
  LOOP
    PERFORM private.invoke_matchmaking_pairing(r.id);
    n := n + 1;
  END LOOP;

  RETURN n;
END;
$$;


ALTER FUNCTION "public"."matchmaking_retry_stale_searches"("p_min_age_seconds" integer, "p_max_invocations" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_challenge_declined"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_metric_type text;
  v_decliner_name text;
BEGIN
  IF NEW.status <> 'declined' OR OLD.status = 'declined' THEN
    RETURN NEW;
  END IF;

  SELECT metric_type
  INTO v_metric_type
  FROM matches
  WHERE id = NEW.match_id
  LIMIT 1;

  SELECT COALESCE(display_name, 'Opponent')
  INTO v_decliner_name
  FROM profiles
  WHERE id = NEW.recipient_id
  LIMIT 1;

  PERFORM private.invoke_dispatch_notification(
    ARRAY[NEW.challenger_id],
    'challenge_declined',
    jsonb_build_object(
      'match_id', NEW.match_id::text,
      'metric_type', COALESCE(v_metric_type, 'steps'),
      'opponent_display_name', v_decliner_name,
      'deep_link_target', 'home'
    )
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_challenge_declined"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_challenge_received"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_metric_type text;
  v_challenger_name text;
BEGIN
  SELECT metric_type
  INTO v_metric_type
  FROM matches
  WHERE id = NEW.match_id
  LIMIT 1;

  SELECT COALESCE(display_name, 'Opponent')
  INTO v_challenger_name
  FROM profiles
  WHERE id = NEW.challenger_id
  LIMIT 1;

  IF private.notification_sent_today(NEW.recipient_id, 'challenge_received', NEW.match_id) THEN
    RETURN NEW;
  END IF;

  PERFORM private.invoke_dispatch_notification(
    ARRAY[NEW.recipient_id],
    'challenge_received',
    jsonb_build_object(
      'match_id', NEW.match_id::text,
      'metric_type', COALESCE(v_metric_type, 'steps'),
      'opponent_display_name', v_challenger_name,
      'deep_link_target', 'home'
    )
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_challenge_received"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_lead_changed"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_match_id uuid;
  v_match_state text;
  v_metric_type text;
  v_opponent_user_id uuid;
  v_opponent_total numeric;
  v_prev_leader uuid;
  v_new_leader uuid;
  v_trailing_user_id uuid;
  v_leader_name text;
  v_lead_delta int;
BEGIN
  IF COALESCE(NEW.metric_total, 0) = COALESCE(OLD.metric_total, 0) THEN
    RETURN NEW;
  END IF;

  SELECT m.id, m.state, m.metric_type
  INTO v_match_id, v_match_state, v_metric_type
  FROM match_days md
  JOIN matches m
    ON m.id = md.match_id
  WHERE md.id = NEW.match_day_id
    AND md.status <> 'finalized'
  LIMIT 1;

  IF v_match_id IS NULL OR v_match_state <> 'active' THEN
    RETURN NEW;
  END IF;

  SELECT user_id, metric_total
  INTO v_opponent_user_id, v_opponent_total
  FROM match_day_participants
  WHERE match_day_id = NEW.match_day_id
    AND user_id <> NEW.user_id
  LIMIT 1;

  IF v_opponent_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_prev_leader := private.resolve_leader_user(OLD.metric_total, v_opponent_total, NEW.user_id, v_opponent_user_id);
  v_new_leader := private.resolve_leader_user(NEW.metric_total, v_opponent_total, NEW.user_id, v_opponent_user_id);

  IF v_prev_leader IS NULL OR v_new_leader IS NULL OR v_prev_leader = v_new_leader THEN
    RETURN NEW;
  END IF;

  IF v_new_leader = NEW.user_id THEN
    v_trailing_user_id := v_opponent_user_id;
  ELSE
    v_trailing_user_id := NEW.user_id;
  END IF;

  SELECT COALESCE(display_name, 'Opponent')
  INTO v_leader_name
  FROM profiles
  WHERE id = v_new_leader
  LIMIT 1;

  v_lead_delta := ABS(COALESCE(NEW.metric_total, 0)::int - COALESCE(v_opponent_total, 0)::int);

  PERFORM private.invoke_dispatch_notification(
    ARRAY[v_trailing_user_id],
    'lead_changed',
    jsonb_build_object(
      'match_id', v_match_id::text,
      'metric_type', COALESCE(v_metric_type, 'steps'),
      'opponent_display_name', v_leader_name,
      'lead_delta', v_lead_delta,
      'deep_link_target', 'match_details'
    )
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_lead_changed"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_public_matchmaking_declined"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_decliner_id uuid;
  v_other_id uuid;
  v_metric_type text;
  v_decliner_name text;
  v_setting text;
BEGIN
  -- Trigger WHEN clause already limits to pending→cancelled, public_matchmaking.
  v_setting := current_setting('app.decline_user_id', true);
  IF v_setting IS NULL OR length(trim(v_setting)) = 0 THEN
    RETURN NEW;
  END IF;

  BEGIN
    v_decliner_id := trim(v_setting)::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN NEW;
  END;

  SELECT user_id
  INTO v_other_id
  FROM match_participants
  WHERE match_id = NEW.id
    AND user_id <> v_decliner_id
  LIMIT 1;

  IF v_other_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT metric_type
  INTO v_metric_type
  FROM matches
  WHERE id = NEW.id
  LIMIT 1;

  SELECT COALESCE(display_name, 'Opponent')
  INTO v_decliner_name
  FROM profiles
  WHERE id = v_decliner_id
  LIMIT 1;

  PERFORM private.invoke_dispatch_notification(
    ARRAY[v_other_id],
    'challenge_declined',
    jsonb_build_object(
      'match_id', NEW.id::text,
      'metric_type', COALESCE(v_metric_type, 'steps'),
      'opponent_display_name', v_decliner_name,
      'deep_link_target', 'home'
    )
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_public_matchmaking_declined"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."push_live_activity_updates"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_match_id uuid;
  v_metric_type text;
  v_day_number int;
  v_participant_ids uuid[];
BEGIN
  SELECT m.id, m.metric_type, md.day_number
  INTO v_match_id, v_metric_type, v_day_number
  FROM match_days md
  JOIN matches m
    ON m.id = md.match_id
  WHERE md.id = NEW.match_day_id
    AND m.state = 'active'
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT ARRAY_AGG(user_id)
  INTO v_participant_ids
  FROM match_participants
  WHERE match_id = v_match_id;

  PERFORM private.invoke_dispatch_notification(
    v_participant_ids,
    'live_activity_update',
    jsonb_build_object(
      'match_id', v_match_id::text,
      'match_day_id', NEW.match_day_id::text,
      'metric_type', COALESCE(v_metric_type, 'steps'),
      'day_number', COALESCE(v_day_number, 1),
      'deep_link_target', 'match_details'
    )
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."push_live_activity_updates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reconcile_stuck_match_completions"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_match_id uuid;
BEGIN
  FOR v_match_id IN
    SELECT m.id
    FROM public.matches m
    WHERE m.state = 'active'
      AND EXISTS (SELECT 1 FROM public.match_days md WHERE md.match_id = m.id)
      AND NOT EXISTS (
        SELECT 1
        FROM public.match_days md2
        WHERE md2.match_id = m.id
          AND md2.status IS DISTINCT FROM 'finalized'
      )
  LOOP
    PERFORM private.invoke_edge_function(
      'complete-match',
      jsonb_build_object('match_id', v_match_id::text)
    );
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."reconcile_stuck_match_completions"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."reconcile_stuck_match_completions"() IS 'Invokes complete-match for active matches where all match_days are finalized, healing partial failures from finalize-match-day.';



CREATE OR REPLACE FUNCTION "public"."tr_matchmaking_pairing_after_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.status = 'searching' THEN
    PERFORM private.invoke_matchmaking_pairing(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."tr_matchmaking_pairing_after_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tr_on_all_accepted_after_participant"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.accepted_at IS NOT NULL THEN
    PERFORM private.invoke_on_all_accepted(NEW.match_id);
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."tr_on_all_accepted_after_participant"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."all_time_bests" (
    "user_id" "uuid" NOT NULL,
    "steps_best_day" numeric,
    "steps_best_week" numeric,
    "cals_best_day" numeric,
    "cals_best_week" numeric,
    "best_win_streak_days" integer,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."all_time_bests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."analytics_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "event_name" "text" NOT NULL,
    "screen_name" "text",
    "session_id" "uuid",
    "client_session_id" "text",
    "properties" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "app_version" "text",
    "build_number" "text",
    "platform" "text" DEFAULT 'ios'::"text" NOT NULL,
    "source" "text" DEFAULT 'ios_client'::"text" NOT NULL,
    "event_schema_version" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "analytics_events_event_name_len" CHECK (("char_length"("event_name") <= 128))
);


ALTER TABLE "public"."analytics_events" OWNER TO "postgres";


COMMENT ON TABLE "public"."analytics_events" IS 'Product/user behavior only. Technical diagnostics belong in app_logs.';



CREATE TABLE IF NOT EXISTS "public"."app_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "category" "text" NOT NULL,
    "level" "text" DEFAULT 'info'::"text" NOT NULL,
    "message" "text" NOT NULL,
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "app_logs_level_check" CHECK (("level" = ANY (ARRAY['debug'::"text", 'info'::"text", 'warning'::"text", 'error'::"text"])))
);


ALTER TABLE "public"."app_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."direct_challenges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "challenger_id" "uuid" NOT NULL,
    "recipient_id" "uuid" NOT NULL,
    "match_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "direct_challenges_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'declined'::"text"])))
);


ALTER TABLE "public"."direct_challenges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."friendships" (
    "a_id" "uuid" NOT NULL,
    "b_id" "uuid" NOT NULL,
    "status" "text" NOT NULL,
    "requested_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "accepted_at" timestamp with time zone,
    CONSTRAINT "friendships_order_check" CHECK (("a_id" < "b_id")),
    CONSTRAINT "friendships_requested_by_check" CHECK ((("requested_by" = "a_id") OR ("requested_by" = "b_id"))),
    CONSTRAINT "friendships_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text"])))
);


ALTER TABLE "public"."friendships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leaderboard_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "week_start" "date" NOT NULL,
    "points" integer DEFAULT 0 NOT NULL,
    "wins" integer DEFAULT 0 NOT NULL,
    "losses" integer DEFAULT 0 NOT NULL,
    "streak" integer DEFAULT 0 NOT NULL,
    "rank" integer,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."leaderboard_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."match_day_participants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_day_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "metric_total" numeric DEFAULT 0 NOT NULL,
    "finalized_value" numeric,
    "data_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "last_updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "match_day_participants_data_status_check" CHECK (("data_status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text"])))
);


ALTER TABLE "public"."match_day_participants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."match_days" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "day_number" integer NOT NULL,
    "calendar_date" "date" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "winner_user_id" "uuid",
    "is_void" boolean DEFAULT false NOT NULL,
    "finalized_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "match_days_day_number_check" CHECK (("day_number" >= 1)),
    CONSTRAINT "match_days_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'provisional'::"text", 'finalized'::"text"])))
);


ALTER TABLE "public"."match_days" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."match_participants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "joined_via" "text" NOT NULL,
    "accepted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "match_participants_joined_via_check" CHECK (("joined_via" = ANY (ARRAY['matchmaking'::"text", 'direct_challenge'::"text"]))),
    CONSTRAINT "match_participants_role_check" CHECK (("role" = ANY (ARRAY['challenger'::"text", 'opponent'::"text"])))
);


ALTER TABLE "public"."match_participants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."match_search_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "metric_type" "text" NOT NULL,
    "duration_days" integer NOT NULL,
    "start_mode" "text" DEFAULT 'today'::"text" NOT NULL,
    "status" "text" DEFAULT 'searching'::"text" NOT NULL,
    "creator_baseline" numeric,
    "matched_match_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "match_search_requests_duration_days_check" CHECK (("duration_days" = ANY (ARRAY[1, 3, 5, 7]))),
    CONSTRAINT "match_search_requests_metric_type_check" CHECK (("metric_type" = ANY (ARRAY['steps'::"text", 'active_calories'::"text"]))),
    CONSTRAINT "match_search_requests_start_mode_check" CHECK (("start_mode" = ANY (ARRAY['today'::"text", 'tomorrow'::"text"]))),
    CONSTRAINT "match_search_requests_status_check" CHECK (("status" = ANY (ARRAY['searching'::"text", 'matched'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."match_search_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."matches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_type" "text" NOT NULL,
    "metric_type" "text" NOT NULL,
    "duration_days" integer NOT NULL,
    "start_mode" "text" DEFAULT 'today'::"text" NOT NULL,
    "state" "text" DEFAULT 'pending'::"text" NOT NULL,
    "match_timezone" "text" DEFAULT 'America/Chicago'::"text" NOT NULL,
    "starts_at" timestamp with time zone,
    "ends_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    CONSTRAINT "matches_duration_days_check" CHECK (("duration_days" = ANY (ARRAY[1, 3, 5, 7]))),
    CONSTRAINT "matches_match_type_check" CHECK (("match_type" = ANY (ARRAY['public_matchmaking'::"text", 'direct_challenge'::"text"]))),
    CONSTRAINT "matches_metric_type_check" CHECK (("metric_type" = ANY (ARRAY['steps'::"text", 'active_calories'::"text"]))),
    CONSTRAINT "matches_start_mode_check" CHECK (("start_mode" = ANY (ARRAY['today'::"text", 'tomorrow'::"text"]))),
    CONSTRAINT "matches_state_check" CHECK (("state" = ANY (ARRAY['searching'::"text", 'pending'::"text", 'active'::"text", 'completed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."matches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metric_snapshots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "metric_type" "text" NOT NULL,
    "value" numeric NOT NULL,
    "source_date" "date" NOT NULL,
    "synced_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "flagged" boolean DEFAULT false NOT NULL,
    "metadata" "jsonb",
    CONSTRAINT "metric_snapshots_metric_type_check" CHECK (("metric_type" = ANY (ARRAY['steps'::"text", 'active_calories'::"text"])))
);


ALTER TABLE "public"."metric_snapshots" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "payload" "jsonb",
    "sent_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "notification_events_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'sent'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."notification_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "auth_user_id" "uuid" NOT NULL,
    "display_name" "text" NOT NULL,
    "initials" "text" NOT NULL,
    "avatar_url" "text",
    "subscription_tier" "text" DEFAULT 'free'::"text" NOT NULL,
    "apns_token" "text",
    "timezone" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notifications_enabled" boolean DEFAULT true NOT NULL,
    "live_activity_push_token" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tester_feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "message" "text" NOT NULL,
    "app_version" "text",
    "context" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "category" "text" DEFAULT 'other'::"text" NOT NULL,
    "screen_name" "text",
    "build_number" "text"
);


ALTER TABLE "public"."tester_feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_health_baselines" (
    "user_id" "uuid" NOT NULL,
    "rolling_avg_7d_steps" numeric,
    "rolling_avg_7d_calories" numeric,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_health_baselines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_public_daily_activity" (
    "user_id" "uuid" NOT NULL,
    "active_date" "date" NOT NULL,
    "steps" integer,
    "active_calories" integer,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_public_daily_activity" OWNER TO "postgres";


ALTER TABLE ONLY "public"."all_time_bests"
    ADD CONSTRAINT "all_time_bests_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_logs"
    ADD CONSTRAINT "app_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."direct_challenges"
    ADD CONSTRAINT "direct_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_pkey" PRIMARY KEY ("a_id", "b_id");



ALTER TABLE ONLY "public"."leaderboard_entries"
    ADD CONSTRAINT "leaderboard_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leaderboard_entries"
    ADD CONSTRAINT "leaderboard_entries_user_id_week_start_key" UNIQUE ("user_id", "week_start");



ALTER TABLE ONLY "public"."match_day_participants"
    ADD CONSTRAINT "match_day_participants_match_day_id_user_id_key" UNIQUE ("match_day_id", "user_id");



ALTER TABLE ONLY "public"."match_day_participants"
    ADD CONSTRAINT "match_day_participants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."match_days"
    ADD CONSTRAINT "match_days_match_id_day_number_key" UNIQUE ("match_id", "day_number");



ALTER TABLE ONLY "public"."match_days"
    ADD CONSTRAINT "match_days_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."match_participants"
    ADD CONSTRAINT "match_participants_match_id_user_id_key" UNIQUE ("match_id", "user_id");



ALTER TABLE ONLY "public"."match_participants"
    ADD CONSTRAINT "match_participants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."match_search_requests"
    ADD CONSTRAINT "match_search_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metric_snapshots"
    ADD CONSTRAINT "metric_snapshots_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_events"
    ADD CONSTRAINT "notification_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_auth_user_id_key" UNIQUE ("auth_user_id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tester_feedback"
    ADD CONSTRAINT "tester_feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_health_baselines"
    ADD CONSTRAINT "user_health_baselines_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_public_daily_activity"
    ADD CONSTRAINT "user_public_daily_activity_pkey" PRIMARY KEY ("user_id");



CREATE INDEX "al_level" ON "public"."app_logs" USING "btree" ("level");



CREATE INDEX "al_user_created" ON "public"."app_logs" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "analytics_events_created_at_desc" ON "public"."analytics_events" USING "btree" ("created_at" DESC);



CREATE INDEX "analytics_events_name_created" ON "public"."analytics_events" USING "btree" ("event_name", "created_at" DESC);



CREATE INDEX "analytics_events_session_created" ON "public"."analytics_events" USING "btree" ("session_id", "created_at" DESC);



CREATE INDEX "analytics_events_user_created" ON "public"."analytics_events" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "analytics_events_user_session_created" ON "public"."analytics_events" USING "btree" ("user_id", "session_id", "created_at" DESC);



CREATE INDEX "dc_challenger" ON "public"."direct_challenges" USING "btree" ("challenger_id");



CREATE INDEX "dc_recipient" ON "public"."direct_challenges" USING "btree" ("recipient_id", "status");



CREATE INDEX "friendships_requested_by_idx" ON "public"."friendships" USING "btree" ("requested_by");



CREATE INDEX "friendships_status_idx" ON "public"."friendships" USING "btree" ("status");



CREATE INDEX "le_week" ON "public"."leaderboard_entries" USING "btree" ("week_start", "points" DESC);



CREATE INDEX "matches_state" ON "public"."matches" USING "btree" ("state");



CREATE INDEX "md_match" ON "public"."match_days" USING "btree" ("match_id");



CREATE INDEX "md_status" ON "public"."match_days" USING "btree" ("status");



CREATE INDEX "mdp_match_day" ON "public"."match_day_participants" USING "btree" ("match_day_id");



CREATE INDEX "mdp_user" ON "public"."match_day_participants" USING "btree" ("user_id");



CREATE INDEX "mp_match" ON "public"."match_participants" USING "btree" ("match_id");



CREATE INDEX "mp_user_match" ON "public"."match_participants" USING "btree" ("user_id", "match_id");



CREATE INDEX "ms_match" ON "public"."metric_snapshots" USING "btree" ("match_id");



CREATE INDEX "ms_user_date" ON "public"."metric_snapshots" USING "btree" ("user_id", "source_date" DESC);



CREATE INDEX "msq_creator_status" ON "public"."match_search_requests" USING "btree" ("creator_id", "status");



CREATE INDEX "msq_status_metric" ON "public"."match_search_requests" USING "btree" ("status", "metric_type", "duration_days", "start_mode");



CREATE INDEX "ne_status" ON "public"."notification_events" USING "btree" ("status");



CREATE INDEX "ne_user_created" ON "public"."notification_events" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "profiles_auth_user" ON "public"."profiles" USING "btree" ("auth_user_id");



CREATE INDEX "tester_feedback_user_created" ON "public"."tester_feedback" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "user_public_daily_activity_active_date_idx" ON "public"."user_public_daily_activity" USING "btree" ("active_date" DESC);



CREATE OR REPLACE TRIGGER "tr_finalize_when_all_confirmed" AFTER INSERT OR UPDATE OF "data_status" ON "public"."match_day_participants" FOR EACH ROW EXECUTE FUNCTION "public"."finalize_when_all_confirmed"();



CREATE OR REPLACE TRIGGER "tr_matchmaking_pairing_after_insert" AFTER INSERT ON "public"."match_search_requests" FOR EACH ROW EXECUTE FUNCTION "public"."tr_matchmaking_pairing_after_insert"();



CREATE OR REPLACE TRIGGER "tr_notify_challenge_declined" AFTER UPDATE OF "status" ON "public"."direct_challenges" FOR EACH ROW EXECUTE FUNCTION "public"."notify_challenge_declined"();



CREATE OR REPLACE TRIGGER "tr_notify_challenge_received" AFTER INSERT ON "public"."direct_challenges" FOR EACH ROW EXECUTE FUNCTION "public"."notify_challenge_received"();



CREATE OR REPLACE TRIGGER "tr_notify_lead_changed" AFTER UPDATE OF "metric_total" ON "public"."match_day_participants" FOR EACH ROW EXECUTE FUNCTION "public"."notify_lead_changed"();



CREATE OR REPLACE TRIGGER "tr_notify_public_matchmaking_declined" AFTER UPDATE OF "state" ON "public"."matches" FOR EACH ROW WHEN ((("old"."state" = 'pending'::"text") AND ("new"."state" = 'cancelled'::"text") AND ("new"."match_type" = 'public_matchmaking'::"text"))) EXECUTE FUNCTION "public"."notify_public_matchmaking_declined"();



CREATE OR REPLACE TRIGGER "tr_on_all_accepted_after_participant" AFTER INSERT OR UPDATE OF "accepted_at" ON "public"."match_participants" FOR EACH ROW EXECUTE FUNCTION "public"."tr_on_all_accepted_after_participant"();



CREATE OR REPLACE TRIGGER "tr_push_live_activity_updates" AFTER INSERT OR UPDATE OF "metric_total" ON "public"."match_day_participants" FOR EACH ROW EXECUTE FUNCTION "public"."push_live_activity_updates"();



ALTER TABLE ONLY "public"."all_time_bests"
    ADD CONSTRAINT "all_time_bests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."app_logs"
    ADD CONSTRAINT "app_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."direct_challenges"
    ADD CONSTRAINT "direct_challenges_challenger_id_fkey" FOREIGN KEY ("challenger_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."direct_challenges"
    ADD CONSTRAINT "direct_challenges_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."direct_challenges"
    ADD CONSTRAINT "direct_challenges_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_search_requests"
    ADD CONSTRAINT "fk_msq_matched_match" FOREIGN KEY ("matched_match_id") REFERENCES "public"."matches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_a_id_fkey" FOREIGN KEY ("a_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_b_id_fkey" FOREIGN KEY ("b_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_requested_by_fkey" FOREIGN KEY ("requested_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leaderboard_entries"
    ADD CONSTRAINT "leaderboard_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_day_participants"
    ADD CONSTRAINT "match_day_participants_match_day_id_fkey" FOREIGN KEY ("match_day_id") REFERENCES "public"."match_days"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_day_participants"
    ADD CONSTRAINT "match_day_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_days"
    ADD CONSTRAINT "match_days_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_days"
    ADD CONSTRAINT "match_days_winner_user_id_fkey" FOREIGN KEY ("winner_user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."match_participants"
    ADD CONSTRAINT "match_participants_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_participants"
    ADD CONSTRAINT "match_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_search_requests"
    ADD CONSTRAINT "match_search_requests_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."metric_snapshots"
    ADD CONSTRAINT "metric_snapshots_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."metric_snapshots"
    ADD CONSTRAINT "metric_snapshots_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_events"
    ADD CONSTRAINT "notification_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tester_feedback"
    ADD CONSTRAINT "tester_feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_health_baselines"
    ADD CONSTRAINT "user_health_baselines_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_public_daily_activity"
    ADD CONSTRAINT "user_public_daily_activity_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE "public"."all_time_bests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."analytics_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "analytics_events: insert" ON "public"."analytics_events" FOR INSERT WITH CHECK (((("user_id" IS NULL) AND ("auth"."uid"() IS NULL) AND ("event_name" = ANY (ARRAY['app_cold_start'::"text", 'auth_screen_view'::"text"]))) OR (("user_id" IS NOT NULL) AND ("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) AND (( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1) IS NOT NULL))));



ALTER TABLE "public"."app_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_logs: own insert" ON "public"."app_logs" FOR INSERT WITH CHECK ((("user_id" IS NULL) OR ("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())))));



CREATE POLICY "app_logs: own read" ON "public"."app_logs" FOR SELECT USING (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "atb: public read" ON "public"."all_time_bests" FOR SELECT USING (true);



CREATE POLICY "dc: own insert" ON "public"."direct_challenges" FOR INSERT WITH CHECK (("challenger_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "dc: party read" ON "public"."direct_challenges" FOR SELECT USING ((("challenger_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))) OR ("recipient_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())))));



CREATE POLICY "dc: recipient update" ON "public"."direct_challenges" FOR UPDATE USING (("recipient_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



ALTER TABLE "public"."direct_challenges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."friendships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "friendships: accept pending" ON "public"."friendships" FOR UPDATE USING ((("status" = 'pending'::"text") AND ("requested_by" <> ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) AND (("a_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) OR ("b_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1))))) WITH CHECK ((("status" = 'accepted'::"text") AND ("accepted_at" IS NOT NULL)));



CREATE POLICY "friendships: party delete" ON "public"."friendships" FOR DELETE USING ((("a_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) OR ("b_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1))));



CREATE POLICY "friendships: party select" ON "public"."friendships" FOR SELECT USING ((("a_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) OR ("b_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1))));



CREATE POLICY "friendships: requester insert pending" ON "public"."friendships" FOR INSERT WITH CHECK ((("status" = 'pending'::"text") AND ("accepted_at" IS NULL) AND ("requested_by" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) AND (("a_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) OR ("b_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)))));



CREATE POLICY "le: public read" ON "public"."leaderboard_entries" FOR SELECT USING (true);



ALTER TABLE "public"."leaderboard_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."match_day_participants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."match_days" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."match_participants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."match_search_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."matches" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "matches: insert direct challenge" ON "public"."matches" FOR INSERT WITH CHECK ((("match_type" = 'direct_challenge'::"text") AND ("state" = 'pending'::"text") AND ("auth"."uid"() IS NOT NULL)));



CREATE POLICY "matches: participant read" ON "public"."matches" FOR SELECT USING (("id" IN ( SELECT "public"."current_user_match_ids"() AS "current_user_match_ids")));



CREATE POLICY "md: participant read" ON "public"."match_days" FOR SELECT USING (("match_id" IN ( SELECT "public"."current_user_match_ids"() AS "current_user_match_ids")));



CREATE POLICY "mdp: own update" ON "public"."match_day_participants" FOR UPDATE USING (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "mdp: participant read" ON "public"."match_day_participants" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."match_days" "md"
  WHERE (("md"."id" = "match_day_participants"."match_day_id") AND ("md"."match_id" IN ( SELECT "public"."current_user_match_ids"() AS "current_user_match_ids"))))));



ALTER TABLE "public"."metric_snapshots" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "mp: insert challenger direct challenge" ON "public"."match_participants" FOR INSERT WITH CHECK ((("role" = 'challenger'::"text") AND ("joined_via" = 'direct_challenge'::"text") AND ("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))) AND (EXISTS ( SELECT 1
   FROM "public"."matches" "m"
  WHERE (("m"."id" = "match_participants"."match_id") AND ("m"."match_type" = 'direct_challenge'::"text") AND ("m"."state" = 'pending'::"text"))))));



CREATE POLICY "mp: insert opponent direct challenge" ON "public"."match_participants" FOR INSERT WITH CHECK ((("role" = 'opponent'::"text") AND ("joined_via" = 'direct_challenge'::"text") AND ("accepted_at" IS NULL) AND (EXISTS ( SELECT 1
   FROM "public"."matches" "m"
  WHERE (("m"."id" = "match_participants"."match_id") AND ("m"."match_type" = 'direct_challenge'::"text") AND ("m"."state" = 'pending'::"text")))) AND (EXISTS ( SELECT 1
   FROM "public"."match_participants" "mp"
  WHERE (("mp"."match_id" = "match_participants"."match_id") AND ("mp"."user_id" = ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."auth_user_id" = "auth"."uid"()))) AND ("mp"."role" = 'challenger'::"text") AND ("mp"."joined_via" = 'direct_challenge'::"text"))))));



CREATE POLICY "mp: own update" ON "public"."match_participants" FOR UPDATE USING (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "mp: participant read" ON "public"."match_participants" FOR SELECT USING (("match_id" IN ( SELECT "public"."current_user_match_ids"() AS "current_user_match_ids")));



CREATE POLICY "ms: own insert" ON "public"."metric_snapshots" FOR INSERT WITH CHECK (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "ms: participant read" ON "public"."metric_snapshots" FOR SELECT USING (("match_id" IN ( SELECT "public"."current_user_match_ids"() AS "current_user_match_ids")));



CREATE POLICY "msr: own insert" ON "public"."match_search_requests" FOR INSERT WITH CHECK (("creator_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "msr: own read" ON "public"."match_search_requests" FOR SELECT USING (("creator_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "msr: own update" ON "public"."match_search_requests" FOR UPDATE USING (("creator_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



ALTER TABLE "public"."notification_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles: own insert" ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "auth_user_id"));



CREATE POLICY "profiles: own read" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "auth_user_id"));



CREATE POLICY "profiles: own update" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "auth_user_id"));



CREATE POLICY "profiles: read others" ON "public"."profiles" FOR SELECT USING (true);



ALTER TABLE "public"."tester_feedback" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tester_feedback: own insert" ON "public"."tester_feedback" FOR INSERT WITH CHECK (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



CREATE POLICY "uhb: own read" ON "public"."user_health_baselines" FOR SELECT USING (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "uhb: own update" ON "public"."user_health_baselines" FOR UPDATE USING (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "uhb: own upsert" ON "public"."user_health_baselines" FOR INSERT WITH CHECK (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"()))));



CREATE POLICY "upda: own insert" ON "public"."user_public_daily_activity" FOR INSERT WITH CHECK (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



CREATE POLICY "upda: own update" ON "public"."user_public_daily_activity" FOR UPDATE USING (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1))) WITH CHECK (("user_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



CREATE POLICY "upda: public read" ON "public"."user_public_daily_activity" FOR SELECT USING (true);



ALTER TABLE "public"."user_health_baselines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_public_daily_activity" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."match_day_participants";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."match_participants";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."match_search_requests";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."matches";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";


















































































































































































































REVOKE ALL ON FUNCTION "public"."activate_match_with_days"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."activate_match_with_days"("p_match_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."activate_match_with_days"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."activate_match_with_days"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."current_user_match_ids"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."current_user_match_ids"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_user_match_ids"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_user_match_ids"() TO "service_role";



GRANT ALL ON FUNCTION "public"."day_cutoff_check"() TO "anon";
GRANT ALL ON FUNCTION "public"."day_cutoff_check"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."day_cutoff_check"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."decline_pending_match"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."decline_pending_match"("p_match_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."decline_pending_match"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."decline_pending_match"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."evening_checkin_candidates"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evening_checkin_candidates"() TO "anon";
GRANT ALL ON FUNCTION "public"."evening_checkin_candidates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."evening_checkin_candidates"() TO "service_role";



GRANT ALL ON FUNCTION "public"."finalize_when_all_confirmed"() TO "anon";
GRANT ALL ON FUNCTION "public"."finalize_when_all_confirmed"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."finalize_when_all_confirmed"() TO "service_role";



GRANT ALL ON FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."health_battle_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."health_battle_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."health_battle_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."matchmaking_pair_atomic"("p_request_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."matchmaking_pair_atomic"("p_request_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."matchmaking_pair_atomic"("p_request_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."matchmaking_pair_atomic"("p_request_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."matchmaking_retry_stale_searches"("p_min_age_seconds" integer, "p_max_invocations" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."matchmaking_retry_stale_searches"("p_min_age_seconds" integer, "p_max_invocations" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."matchmaking_retry_stale_searches"("p_min_age_seconds" integer, "p_max_invocations" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."matchmaking_retry_stale_searches"("p_min_age_seconds" integer, "p_max_invocations" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_challenge_declined"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_challenge_declined"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_challenge_declined"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_challenge_received"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_challenge_received"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_challenge_received"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_lead_changed"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_lead_changed"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_lead_changed"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_public_matchmaking_declined"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_public_matchmaking_declined"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_public_matchmaking_declined"() TO "service_role";



GRANT ALL ON FUNCTION "public"."push_live_activity_updates"() TO "anon";
GRANT ALL ON FUNCTION "public"."push_live_activity_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."push_live_activity_updates"() TO "service_role";



GRANT ALL ON FUNCTION "public"."reconcile_stuck_match_completions"() TO "anon";
GRANT ALL ON FUNCTION "public"."reconcile_stuck_match_completions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."reconcile_stuck_match_completions"() TO "service_role";



GRANT ALL ON FUNCTION "public"."tr_matchmaking_pairing_after_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."tr_matchmaking_pairing_after_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tr_matchmaking_pairing_after_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."tr_on_all_accepted_after_participant"() TO "anon";
GRANT ALL ON FUNCTION "public"."tr_on_all_accepted_after_participant"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tr_on_all_accepted_after_participant"() TO "service_role";






























GRANT ALL ON TABLE "public"."all_time_bests" TO "anon";
GRANT ALL ON TABLE "public"."all_time_bests" TO "authenticated";
GRANT ALL ON TABLE "public"."all_time_bests" TO "service_role";



GRANT ALL ON TABLE "public"."analytics_events" TO "anon";
GRANT ALL ON TABLE "public"."analytics_events" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_events" TO "service_role";



GRANT ALL ON TABLE "public"."app_logs" TO "anon";
GRANT ALL ON TABLE "public"."app_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."app_logs" TO "service_role";



GRANT ALL ON TABLE "public"."direct_challenges" TO "anon";
GRANT ALL ON TABLE "public"."direct_challenges" TO "authenticated";
GRANT ALL ON TABLE "public"."direct_challenges" TO "service_role";



GRANT ALL ON TABLE "public"."friendships" TO "anon";
GRANT ALL ON TABLE "public"."friendships" TO "authenticated";
GRANT ALL ON TABLE "public"."friendships" TO "service_role";



GRANT ALL ON TABLE "public"."leaderboard_entries" TO "anon";
GRANT ALL ON TABLE "public"."leaderboard_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."leaderboard_entries" TO "service_role";



GRANT ALL ON TABLE "public"."match_day_participants" TO "anon";
GRANT ALL ON TABLE "public"."match_day_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."match_day_participants" TO "service_role";



GRANT ALL ON TABLE "public"."match_days" TO "anon";
GRANT ALL ON TABLE "public"."match_days" TO "authenticated";
GRANT ALL ON TABLE "public"."match_days" TO "service_role";



GRANT ALL ON TABLE "public"."match_participants" TO "anon";
GRANT ALL ON TABLE "public"."match_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."match_participants" TO "service_role";



GRANT ALL ON TABLE "public"."match_search_requests" TO "anon";
GRANT ALL ON TABLE "public"."match_search_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."match_search_requests" TO "service_role";



GRANT ALL ON TABLE "public"."matches" TO "anon";
GRANT ALL ON TABLE "public"."matches" TO "authenticated";
GRANT ALL ON TABLE "public"."matches" TO "service_role";



GRANT ALL ON TABLE "public"."metric_snapshots" TO "anon";
GRANT ALL ON TABLE "public"."metric_snapshots" TO "authenticated";
GRANT ALL ON TABLE "public"."metric_snapshots" TO "service_role";



GRANT ALL ON TABLE "public"."notification_events" TO "anon";
GRANT ALL ON TABLE "public"."notification_events" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_events" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."tester_feedback" TO "anon";
GRANT ALL ON TABLE "public"."tester_feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."tester_feedback" TO "service_role";



GRANT ALL ON TABLE "public"."user_health_baselines" TO "anon";
GRANT ALL ON TABLE "public"."user_health_baselines" TO "authenticated";
GRANT ALL ON TABLE "public"."user_health_baselines" TO "service_role";



GRANT ALL ON TABLE "public"."user_public_daily_activity" TO "anon";
GRANT ALL ON TABLE "public"."user_public_daily_activity" TO "authenticated";
GRANT ALL ON TABLE "public"."user_public_daily_activity" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































