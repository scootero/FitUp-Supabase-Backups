


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

  -- Balanced steps: snapshot rolling averages onto participants (fixed FROM).
  UPDATE match_participants mp
  SET baseline_steps = src.baseline
  FROM (
    SELECT
      mp2.id,
      COALESCE(uhb.rolling_avg_30d_steps, uhb.rolling_avg_7d_steps) AS baseline
    FROM match_participants mp2
    INNER JOIN matches m ON m.id = mp2.match_id AND m.id = p_match_id
    LEFT JOIN user_health_baselines uhb ON uhb.user_id = mp2.user_id
    WHERE mp2.match_id = p_match_id
      AND m.scoring_mode = 'balanced'
      AND m.metric_type = 'steps'
  ) src
  WHERE mp.id = src.id;

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


CREATE OR REPLACE FUNCTION "public"."append_user_intraday_step_tick"("p_calendar_date" "date", "p_timezone_identifier" "text", "p_cumulative_steps" integer, "p_recorded_at" timestamp with time zone DEFAULT "now"()) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_profile_id uuid;
  v_new_id uuid;
BEGIN
  SELECT p.id
  INTO v_profile_id
  FROM public.profiles p
  WHERE p.auth_user_id = auth.uid()
  LIMIT 1;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated or profile missing';
  END IF;

  IF length(trim(coalesce(p_timezone_identifier, ''))) = 0 THEN
    RAISE EXCEPTION 'timezone_identifier required';
  END IF;

  IF p_cumulative_steps < 0 THEN
    RAISE EXCEPTION 'cumulative_steps must be non-negative';
  END IF;

  INSERT INTO public.user_intraday_step_ticks (
    user_id,
    calendar_date,
    timezone_identifier,
    cumulative_steps,
    recorded_at
  )
  VALUES (
    v_profile_id,
    p_calendar_date,
    trim(p_timezone_identifier),
    p_cumulative_steps,
    p_recorded_at
  )
  RETURNING id INTO v_new_id;

  WHILE (
    SELECT count(*)::int
    FROM public.user_intraday_step_ticks
    WHERE user_id = v_profile_id
      AND calendar_date = p_calendar_date
  ) > 30
  LOOP
    PERFORM public.intraday_step_ticks_prune_one_victim(v_profile_id, p_calendar_date);
  END LOOP;

  RETURN v_new_id;
END;
$$;


ALTER FUNCTION "public"."append_user_intraday_step_tick"("p_calendar_date" "date", "p_timezone_identifier" "text", "p_cumulative_steps" integer, "p_recorded_at" timestamp with time zone) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."append_user_intraday_step_tick"("p_calendar_date" "date", "p_timezone_identifier" "text", "p_cumulative_steps" integer, "p_recorded_at" timestamp with time zone) IS 'Inserts one tick for the signed-in profile and prunes that calendar_date to at most 30 rows.';



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



CREATE OR REPLACE FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone, "p_scoring_mode" "text" DEFAULT NULL::"text", "p_difficulty" "text" DEFAULT NULL::"text") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_challenger uuid;
  v_match_id uuid;
  v_challenge_id uuid;
  v_now timestamptz := now();
  v_tz text;
  v_score text;
  v_diff text;
  v_bt text;
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

  IF p_metric_type = 'steps' THEN
    v_score := COALESCE(NULLIF(trim(p_scoring_mode), ''), 'balanced');
    IF v_score NOT IN ('balanced', 'raw') THEN
      RAISE EXCEPTION 'invalid scoring_mode';
    END IF;
    IF v_score = 'balanced' THEN
      v_diff := NULL;
    ELSE
      v_diff := COALESCE(NULLIF(trim(p_difficulty), ''), 'fair');
      IF v_diff NOT IN ('easy', 'fair', 'hard') THEN
        RAISE EXCEPTION 'invalid difficulty';
      END IF;
    END IF;
    v_bt := CASE WHEN v_score = 'balanced' THEN '30d' ELSE NULL END;
  ELSE
    v_score := NULL;
    v_diff := NULL;
    v_bt := NULL;
  END IF;

  INSERT INTO public.matches (
    match_type,
    metric_type,
    duration_days,
    start_mode,
    state,
    match_timezone,
    starts_at,
    scoring_mode,
    baseline_timeframe,
    difficulty
  )
  VALUES (
    'direct_challenge',
    p_metric_type,
    p_duration_days,
    p_start_mode,
    'pending',
    v_tz,
    p_starts_at,
    v_score,
    v_bt,
    v_diff
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


ALTER FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone, "p_scoring_mode" "text", "p_difficulty" "text") OWNER TO "postgres";


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



CREATE OR REPLACE FUNCTION "public"."fetch_latest_opponent_intraday_ticks_for_active_matches"("p_calendar_date" "date") RETURNS TABLE("opponent_profile_id" "uuid", "cumulative_steps" integer, "recorded_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_me uuid;
BEGIN
  SELECT p.id
  INTO v_me
  FROM public.profiles p
  WHERE p.auth_user_id = auth.uid()
  LIMIT 1;

  IF v_me IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT DISTINCT ON (t.user_id)
    t.user_id AS opponent_profile_id,
    t.cumulative_steps,
    t.recorded_at
  FROM public.user_intraday_step_ticks t
  WHERE t.calendar_date = p_calendar_date
    AND t.user_id IN (
      SELECT mp_opp.user_id
      FROM public.match_participants mp_self
      JOIN public.matches m
        ON m.id = mp_self.match_id
       AND m.state = 'active'
      JOIN public.match_participants mp_opp
        ON mp_opp.match_id = m.id
       AND mp_opp.user_id <> v_me
      WHERE mp_self.user_id = v_me
        AND mp_self.accepted_at IS NOT NULL
        AND mp_opp.accepted_at IS NOT NULL
    )
  ORDER BY t.user_id, t.recorded_at DESC, t.id DESC;
END;
$$;


ALTER FUNCTION "public"."fetch_latest_opponent_intraday_ticks_for_active_matches"("p_calendar_date" "date") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."fetch_latest_opponent_intraday_ticks_for_active_matches"("p_calendar_date" "date") IS 'Latest intraday step tick per active-match opponent for one calendar_date (viewer passes local date).';



CREATE OR REPLACE FUNCTION "public"."fetch_opponent_intraday_step_ticks"("p_opponent_profile_id" "uuid", "p_calendar_date" "date", "p_since" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE("tick_id" "uuid", "cumulative_steps" integer, "recorded_at" timestamp with time zone, "timezone_identifier" "text", "calendar_date" "date", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_me uuid;
BEGIN
  SELECT p.id
  INTO v_me
  FROM public.profiles p
  WHERE p.auth_user_id = auth.uid()
  LIMIT 1;

  IF v_me IS NULL THEN
    RETURN;
  END IF;

  IF p_opponent_profile_id IS NULL OR p_opponent_profile_id = v_me THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.matches m
    JOIN public.match_participants mp_self
      ON mp_self.match_id = m.id
     AND mp_self.user_id = v_me
    JOIN public.match_participants mp_opp
      ON mp_opp.match_id = m.id
     AND mp_opp.user_id = p_opponent_profile_id
    WHERE m.state = 'active'
      AND mp_self.accepted_at IS NOT NULL
      AND mp_opp.accepted_at IS NOT NULL
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    t.id AS tick_id,
    t.cumulative_steps,
    t.recorded_at,
    t.timezone_identifier,
    t.calendar_date,
    t.created_at
  FROM public.user_intraday_step_ticks t
  WHERE t.user_id = p_opponent_profile_id
    AND t.calendar_date = p_calendar_date
    AND (p_since IS NULL OR t.recorded_at > p_since)
  ORDER BY t.recorded_at ASC, t.id ASC;
END;
$$;


ALTER FUNCTION "public"."fetch_opponent_intraday_step_ticks"("p_opponent_profile_id" "uuid", "p_calendar_date" "date", "p_since" timestamp with time zone) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."fetch_opponent_intraday_step_ticks"("p_opponent_profile_id" "uuid", "p_calendar_date" "date", "p_since" timestamp with time zone) IS 'Returns opponent ticks for a calendar_date if viewer shares an active accepted match with that profile.';



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


CREATE OR REPLACE FUNCTION "public"."fn_messages_touch_thread_last"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
BEGIN
  UPDATE public.message_threads
  SET last_message_at = NEW.created_at
  WHERE id = NEW.thread_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_messages_touch_thread_last"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."fn_messages_touch_thread_last"() IS 'Sets message_threads.last_message_at when a message is inserted (MVP).';



CREATE OR REPLACE FUNCTION "public"."get_my_rival_stats"("p_limit" integer DEFAULT 3) RETURNS TABLE("opponent_profile_id" "uuid", "opponent_display_name" "text", "opponent_initials" "text", "opponent_avatar_url" "text", "finalized_days_competed" integer, "match_wins" integer, "match_losses" integer, "match_ties" integer, "win_percentage" integer, "avg_finalized_daily_margin" numeric, "last_played_on" "date", "days_won_by_viewer" integer, "days_won_by_opponent" integer, "avg_margin_on_viewer_win_days" numeric, "avg_margin_on_opponent_win_days" numeric, "recent_series_results" "text"[], "active_match_id" "uuid", "computed_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
declare
  v_viewer_profile_id uuid;
  v_limit int;
begin
  v_limit := greatest(1, least(coalesce(p_limit, 3), 50));

  select p.id
  into v_viewer_profile_id
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_viewer_profile_id is null then
    return;
  end if;

  return query
  with opponent_matches as (
    select
      m.id as match_id,
      m.state,
      m.created_at,
      m.completed_at,
      mp_o.user_id as opponent_id
    from public.matches m
    join public.match_participants mp_v
      on mp_v.match_id = m.id
     and mp_v.user_id = v_viewer_profile_id
    join public.match_participants mp_o
      on mp_o.match_id = m.id
     and mp_o.user_id <> v_viewer_profile_id
    where m.state in ('active', 'completed')
  ),
  finalized_days as (
    select
      om.opponent_id,
      md.match_id,
      md.calendar_date,
      coalesce(mdp_v.finalized_value, mdp_v.metric_total)::numeric as viewer_day_total,
      coalesce(mdp_o.finalized_value, mdp_o.metric_total)::numeric as opponent_day_total,
      case when md.winner_user_id = v_viewer_profile_id then 1 else 0 end as viewer_day_win,
      case when md.winner_user_id = om.opponent_id then 1 else 0 end as opponent_day_win
    from opponent_matches om
    join public.match_days md
      on md.match_id = om.match_id
     and md.status = 'finalized'
     and md.is_void = false
    join public.match_day_participants mdp_v
      on mdp_v.match_day_id = md.id
     and mdp_v.user_id = v_viewer_profile_id
    join public.match_day_participants mdp_o
      on mdp_o.match_day_id = md.id
     and mdp_o.user_id = om.opponent_id
    where coalesce(mdp_v.finalized_value, mdp_v.metric_total) is not null
      and coalesce(mdp_o.finalized_value, mdp_o.metric_total) is not null
  ),
  day_rollup as (
    select
      fd.opponent_id,
      count(*)::int as finalized_days_competed,
      avg(fd.viewer_day_total - fd.opponent_day_total) as avg_finalized_daily_margin,
      max(fd.calendar_date) as last_played_on,
      sum(fd.viewer_day_win)::int as days_won_by_viewer,
      sum(fd.opponent_day_win)::int as days_won_by_opponent,
      avg(case when fd.viewer_day_win = 1 then (fd.viewer_day_total - fd.opponent_day_total) end) as avg_margin_on_viewer_win_days,
      avg(case when fd.opponent_day_win = 1 then (fd.viewer_day_total - fd.opponent_day_total) end) as avg_margin_on_opponent_win_days
    from finalized_days fd
    group by fd.opponent_id
  ),
  completed_series as (
    select
      om.opponent_id,
      om.match_id,
      om.completed_at,
      coalesce(sum(fd.viewer_day_win), 0)::int as viewer_day_wins,
      coalesce(sum(fd.opponent_day_win), 0)::int as opponent_day_wins
    from opponent_matches om
    left join finalized_days fd
      on fd.match_id = om.match_id
     and fd.opponent_id = om.opponent_id
    where om.state = 'completed'
    group by om.opponent_id, om.match_id, om.completed_at
  ),
  series_rollup as (
    select
      cs.opponent_id,
      sum(case when cs.viewer_day_wins > cs.opponent_day_wins then 1 else 0 end)::int as match_wins,
      sum(case when cs.opponent_day_wins > cs.viewer_day_wins then 1 else 0 end)::int as match_losses,
      sum(case when cs.viewer_day_wins = cs.opponent_day_wins then 1 else 0 end)::int as match_ties
    from completed_series cs
    group by cs.opponent_id
  ),
  recent_series as (
    select
      ranked.opponent_id,
      array_agg(ranked.result order by ranked.completed_at desc nulls last, ranked.match_id desc) as recent_series_results
    from (
      select
        cs.opponent_id,
        cs.match_id,
        cs.completed_at,
        case
          when cs.viewer_day_wins > cs.opponent_day_wins then 'W'
          when cs.opponent_day_wins > cs.viewer_day_wins then 'L'
          else 'T'
        end as result,
        row_number() over (
          partition by cs.opponent_id
          order by cs.completed_at desc nulls last, cs.match_id desc
        ) as rn
      from completed_series cs
    ) ranked
    where ranked.rn <= 5
    group by ranked.opponent_id
  ),
  active_match as (
    select distinct on (om.opponent_id)
      om.opponent_id,
      om.match_id as active_match_id
    from opponent_matches om
    where om.state = 'active'
    order by om.opponent_id, om.created_at desc, om.match_id
  ),
  rivals as (
    select
      dr.opponent_id,
      dr.finalized_days_competed,
      coalesce(sr.match_wins, 0) as match_wins,
      coalesce(sr.match_losses, 0) as match_losses,
      coalesce(sr.match_ties, 0) as match_ties,
      case
        when (coalesce(sr.match_wins, 0) + coalesce(sr.match_losses, 0)) > 0 then
          round(
            (coalesce(sr.match_wins, 0)::numeric
            / (coalesce(sr.match_wins, 0) + coalesce(sr.match_losses, 0))::numeric) * 100
          )::int
        else 0
      end as win_percentage,
      dr.avg_finalized_daily_margin,
      dr.last_played_on,
      dr.days_won_by_viewer,
      dr.days_won_by_opponent,
      dr.avg_margin_on_viewer_win_days,
      dr.avg_margin_on_opponent_win_days,
      rs.recent_series_results
    from day_rollup dr
    left join series_rollup sr
      on sr.opponent_id = dr.opponent_id
    left join recent_series rs
      on rs.opponent_id = dr.opponent_id
  )
  select
    r.opponent_id as opponent_profile_id,
    coalesce(nullif(trim(p.display_name), ''), 'Opponent') as opponent_display_name,
    coalesce(nullif(upper(trim(p.initials)), ''), 'OP') as opponent_initials,
    p.avatar_url as opponent_avatar_url,
    r.finalized_days_competed,
    r.match_wins,
    r.match_losses,
    r.match_ties,
    r.win_percentage,
    round(r.avg_finalized_daily_margin, 2) as avg_finalized_daily_margin,
    r.last_played_on,
    r.days_won_by_viewer,
    r.days_won_by_opponent,
    round(r.avg_margin_on_viewer_win_days, 2) as avg_margin_on_viewer_win_days,
    round(r.avg_margin_on_opponent_win_days, 2) as avg_margin_on_opponent_win_days,
    r.recent_series_results,
    am.active_match_id,
    now() as computed_at
  from rivals r
  join public.profiles p
    on p.id = r.opponent_id
  left join active_match am
    on am.opponent_id = r.opponent_id
  order by
    r.finalized_days_competed desc,
    r.last_played_on desc nulls last,
    r.opponent_id
  limit v_limit;
end;
$$;


ALTER FUNCTION "public"."get_my_rival_stats"("p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_profile_stats_snapshot"("p_range_key" "text", "p_metric_type" "text" DEFAULT 'steps'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
declare
  v_effective_range_key text;
  v_day_count int;
  v_range_support text;
  v_margins jsonb := '[]'::jsonb;
  v_previous_margins jsonb := '[]'::jsonb;
  v_battle jsonb := '{}'::jsonb;
  v_net_margin bigint := 0;
  v_previous_net_margin bigint := 0;
  v_previous_period_percent int := 0;
begin
  if coalesce(p_metric_type, '') not in ('steps', 'active_calories') then
    return jsonb_build_object(
      'range_key', coalesce(p_range_key, '30D'),
      'effective_range_key', '30D',
      'scope_flags', jsonb_build_object(
        'battle_stats_scope', 'lifetime',
        'range_support', 'fallback'
      ),
      'summary', jsonb_build_object(
        'net_margin', 0,
        'wins', 0,
        'losses', 0,
        'ties', 0,
        'win_rate_percent', 0,
        'current_streak_type', 'none',
        'current_streak_count', 0
      ),
      'chart', jsonb_build_object('points', '[]'::jsonb)
    );
  end if;

  if p_range_key = '1D' then
    v_effective_range_key := '1D';
    v_day_count := 1;
    v_range_support := 'native';
  elsif p_range_key = '7D' then
    v_effective_range_key := '7D';
    v_day_count := 7;
    v_range_support := 'native';
  elsif p_range_key = '30D' then
    v_effective_range_key := '30D';
    v_day_count := 30;
    v_range_support := 'native';
  else
    -- Current margin RPC supports up to 31 days. Until expanded backend support lands,
    -- keep this explicit and return 30D data for unsupported ranges.
    v_effective_range_key := '30D';
    v_day_count := 30;
    v_range_support := 'fallback';
  end if;

  v_margins := coalesce(
    public.home_daily_battle_margins(current_date, v_day_count, p_metric_type),
    '[]'::jsonb
  );
  v_previous_margins := coalesce(
    public.home_daily_battle_margins((current_date - v_day_count), v_day_count, p_metric_type),
    '[]'::jsonb
  );
  v_battle := coalesce(public.health_battle_stats(), '{}'::jsonb);

  select coalesce(sum((e ->> 'margin')::bigint), 0)
  into v_net_margin
  from jsonb_array_elements(v_margins) as e;
  select coalesce(sum((e ->> 'margin')::bigint), 0)
  into v_previous_net_margin
  from jsonb_array_elements(v_previous_margins) as e;

  if v_previous_net_margin = 0 then
    if v_net_margin > 0 then
      v_previous_period_percent := 100;
    elsif v_net_margin < 0 then
      v_previous_period_percent := -100;
    else
      v_previous_period_percent := 0;
    end if;
  else
    v_previous_period_percent := round(
      ((v_net_margin - v_previous_net_margin)::numeric / abs(v_previous_net_margin)::numeric) * 100
    )::int;
  end if;

  return jsonb_build_object(
    'range_key', coalesce(p_range_key, '30D'),
    'effective_range_key', v_effective_range_key,
    'saved_at', now(),
    'scope_flags', jsonb_build_object(
      'battle_stats_scope', 'lifetime',
      'range_support', v_range_support
    ),
    'summary', jsonb_build_object(
      'net_margin', v_net_margin,
      'previous_period_percent', v_previous_period_percent,
      'wins', coalesce((v_battle ->> 'wins')::int, 0),
      'losses', coalesce((v_battle ->> 'losses')::int, 0),
      'ties', coalesce((v_battle ->> 'ties')::int, 0),
      'win_rate_percent', coalesce((v_battle ->> 'win_rate')::int, 0),
      'current_streak_type', coalesce(v_battle ->> 'current_streak_type', 'none'),
      'current_streak_count', coalesce((v_battle ->> 'current_streak_count')::int, 0)
    ),
    'chart', jsonb_build_object(
      'unit', p_metric_type,
      'points', v_margins
    ),
    'personal_bests', jsonb_build_object(
      'battle_win_streak_days', coalesce((v_battle ->> 'current_streak_count')::int, 0),
      'biggest_comeback_day_deficit_recovered', null,
      'biggest_comeback_series_net_swing', null
    )
  );
end;
$$;


ALTER FUNCTION "public"."get_profile_stats_snapshot"("p_range_key" "text", "p_metric_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_stats_opponent_steps_rollups"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
declare
  v_viewer_profile_id uuid;
  v_tz text;
  v_today date;
  v_month_start date;
  v_lifetime bigint := 0;
  v_rolling_365d bigint := 0;
  v_current_month bigint := 0;
begin
  select
    p.id,
    coalesce(nullif(trim(p.timezone), ''), 'UTC')
  into v_viewer_profile_id, v_tz
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_viewer_profile_id is null then
    return jsonb_build_object(
      'lifetime_steps', 0,
      'rolling_365d_steps', 0,
      'current_month_steps', 0,
      'computed_at', now()
    );
  end if;

  v_today := (now() at time zone v_tz)::date;
  v_month_start := date_trunc('month', v_today::timestamp)::date;

  with viewer_step_matches as (
    select m.id as match_id
    from public.matches m
    join public.match_participants mp_v
      on mp_v.match_id = m.id
     and mp_v.user_id = v_viewer_profile_id
    where m.metric_type = 'steps'
      and m.state in ('active', 'completed')
  ),
  battle_day_rows as (
    select
      md.calendar_date,
      greatest(
        0,
        coalesce(mdp_o.finalized_value, mdp_o.metric_total)::bigint
      ) as opponent_steps
    from viewer_step_matches vsm
    join public.match_days md
      on md.match_id = vsm.match_id
     and md.status = 'finalized'
     and md.is_void = false
    join public.match_participants mp_o
      on mp_o.match_id = vsm.match_id
     and mp_o.user_id <> v_viewer_profile_id
    join public.match_day_participants mdp_v
      on mdp_v.match_day_id = md.id
     and mdp_v.user_id = v_viewer_profile_id
    join public.match_day_participants mdp_o
      on mdp_o.match_day_id = md.id
     and mdp_o.user_id = mp_o.user_id
    where coalesce(mdp_v.finalized_value, mdp_v.metric_total) is not null
      and coalesce(mdp_o.finalized_value, mdp_o.metric_total) is not null
  )
  select
    coalesce(sum(bdr.opponent_steps), 0)::bigint,
    coalesce(
      sum(bdr.opponent_steps) filter (
        where bdr.calendar_date >= v_today - 364
      ),
      0
    )::bigint,
    coalesce(
      sum(bdr.opponent_steps) filter (
        where bdr.calendar_date >= v_month_start
          and bdr.calendar_date <= v_today
      ),
      0
    )::bigint
  into v_lifetime, v_rolling_365d, v_current_month
  from battle_day_rows bdr;

  return jsonb_build_object(
    'lifetime_steps', v_lifetime,
    'rolling_365d_steps', v_rolling_365d,
    'current_month_steps', v_current_month,
    'computed_at', now()
  );
end;
$$;


ALTER FUNCTION "public"."get_stats_opponent_steps_rollups"() OWNER TO "postgres";


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
    pair_rows as (
      select
        md.calendar_date as cal_date,
        max(coalesce(mdp_v.finalized_value, mdp_v.metric_total))::bigint as viewer_total,
        max(coalesce(mdp_o.finalized_value, mdp_o.metric_total))::bigint as opponent_total
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
      where md.calendar_date between v_start and p_end_date
        and md.is_void = false
        and m.state in ('active', 'completed')
        and m.metric_type = p_metric_type
      group by md.calendar_date, md.id, mp_o.user_id
    ),
    day_my as (
      select
        cal_date,
        max(viewer_total) as my_total
      from pair_rows
      group by cal_date
    ),
    day_ref as (
      select
        pr.cal_date,
        dm.my_total,
        min(pr.opponent_total) filter (
          where pr.opponent_total is not null
            and pr.opponent_total > dm.my_total
        ) as nearest_ahead,
        max(pr.opponent_total) filter (
          where pr.opponent_total is not null
            and pr.opponent_total <= dm.my_total
        ) as nearest_behind,
        max(pr.opponent_total) filter (where pr.opponent_total is not null) as max_opponent_total
      from pair_rows pr
      inner join day_my dm on dm.cal_date = pr.cal_date
      group by pr.cal_date, dm.my_total
    ),
    daily as (
      select
        d.cal_date,
        coalesce(
          case
            when dr.cal_date is null then 0::bigint
            when dr.nearest_ahead is not null then dr.my_total - dr.nearest_ahead
            when dr.nearest_behind is not null then dr.my_total - dr.nearest_behind
            when dr.max_opponent_total is not null then dr.my_total - dr.max_opponent_total
            else 0::bigint
          end,
          0::bigint
        ) as margin
      from days d
      left join day_ref dr on dr.cal_date = d.cal_date
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


CREATE OR REPLACE FUNCTION "public"."intraday_step_ticks_prune_one_victim"("p_user_id" "uuid", "p_calendar_date" "date") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_cnt int;
  v_victim uuid;
BEGIN
  SELECT count(*)::int
  INTO v_cnt
  FROM public.user_intraday_step_ticks
  WHERE user_id = p_user_id
    AND calendar_date = p_calendar_date;

  IF v_cnt <= 30 THEN
    RETURN NULL;
  END IF;

  WITH day_rows AS (
    SELECT *
    FROM public.user_intraday_step_ticks
    WHERE user_id = p_user_id
      AND calendar_date = p_calendar_date
  ),
  bounds AS (
    SELECT
      (SELECT min(recorded_at) FROM day_rows) AS ra_min,
      (SELECT max(recorded_at) FROM day_rows) AS ra_max,
      (SELECT min(cumulative_steps)::double precision FROM day_rows) AS s_min,
      (SELECT max(cumulative_steps)::double precision FROM day_rows) AS s_max
  ),
  seq AS (
    SELECT
      d.id,
      d.recorded_at,
      d.cumulative_steps,
      lag(d.recorded_at) OVER w AS prev_t,
      lag(d.cumulative_steps) OVER w AS prev_s,
      lead(d.recorded_at) OVER w AS next_t,
      lead(d.cumulative_steps) OVER w AS next_s
    FROM day_rows d
    WINDOW w AS (ORDER BY d.recorded_at, d.id)
  ),
  norm AS (
    SELECT
      s.id,
      s.recorded_at,
      extract(epoch FROM (s.prev_t - b.ra_min))
        / greatest(extract(epoch FROM (b.ra_max - b.ra_min)), 1e-9) AS x_prev,
      extract(epoch FROM (s.recorded_at - b.ra_min))
        / greatest(extract(epoch FROM (b.ra_max - b.ra_min)), 1e-9) AS x_curr,
      extract(epoch FROM (s.next_t - b.ra_min))
        / greatest(extract(epoch FROM (b.ra_max - b.ra_min)), 1e-9) AS x_next,
      (s.prev_s - b.s_min) / greatest(b.s_max - b.s_min, 1.0::double precision) AS y_prev,
      (s.cumulative_steps - b.s_min) / greatest(b.s_max - b.s_min, 1.0::double precision) AS y_curr,
      (s.next_s - b.s_min) / greatest(b.s_max - b.s_min, 1.0::double precision) AS y_next
    FROM seq s
    CROSS JOIN bounds b
    WHERE s.prev_t IS NOT NULL
      AND s.next_t IS NOT NULL
  ),
  scored AS (
    SELECT
      id,
      recorded_at,
      abs(
        x_prev * (y_curr - y_next)
        + x_curr * (y_next - y_prev)
        + x_next * (y_prev - y_curr)
      ) / 2.0 AS tri_area
    FROM norm
  )
  SELECT id
  INTO v_victim
  FROM scored
  ORDER BY tri_area ASC NULLS LAST, recorded_at ASC, id ASC
  LIMIT 1;

  IF v_victim IS NULL THEN
    RAISE EXCEPTION 'intraday_step_ticks_prune_one_victim: count=% but no interior victim', v_cnt;
  END IF;

  DELETE FROM public.user_intraday_step_ticks
  WHERE id = v_victim;

  RETURN v_victim;
END;
$$;


ALTER FUNCTION "public"."intraday_step_ticks_prune_one_victim"("p_user_id" "uuid", "p_calendar_date" "date") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."intraday_step_ticks_prune_one_victim"("p_user_id" "uuid", "p_calendar_date" "date") IS 'Internal (no client EXECUTE): one Visvalingam-style prune step for user_intraday_step_ticks.';



CREATE OR REPLACE FUNCTION "public"."invoke_edge_function_async"("p_function_name" "text", "p_payload" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'private', 'extensions'
    AS $$
BEGIN
  PERFORM private.invoke_edge_function(p_function_name, p_payload);
END;
$$;


ALTER FUNCTION "public"."invoke_edge_function_async"("p_function_name" "text", "p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."list_opponent_candidates"("p_query" "text" DEFAULT ''::"text", "p_metric_type" "text" DEFAULT 'steps'::"text", "p_viewer_local_date" "date" DEFAULT CURRENT_DATE, "p_limit" integer DEFAULT 15) RETURNS TABLE("id" "uuid", "display_name" "text", "initials" "text", "wins" integer, "losses" integer, "today_steps" integer, "rolling_avg_7d_steps" numeric, "rolling_avg_7d_calories" numeric)
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
declare
  v_viewer_id uuid;
  v_my_baseline numeric;
  v_limit int;
  v_query text;
begin
  v_limit := greatest(1, least(coalesce(p_limit, 15), 50));
  v_query := lower(trim(coalesce(p_query, '')));

  select p.id
  into v_viewer_id
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_viewer_id is null then
    return;
  end if;

  select
    case
      when coalesce(p_metric_type, 'steps') = 'active_calories'
        then uhb.rolling_avg_7d_calories
      else uhb.rolling_avg_7d_steps
    end
  into v_my_baseline
  from public.user_health_baselines uhb
  where uhb.user_id = v_viewer_id
  limit 1;

  return query
  with latest_lb as (
    select distinct on (le.user_id)
      le.user_id,
      le.wins,
      le.losses
    from public.leaderboard_entries le
    order by le.user_id, le.week_start desc
  ),
  today_snap as (
    select distinct on (ms.user_id)
      ms.user_id,
      ms.value::int as today_steps
    from public.metric_snapshots ms
    where ms.metric_type = 'steps'
      and ms.source_date = p_viewer_local_date
    order by ms.user_id, ms.synced_at desc
  ),
  ranked as (
    select
      p.id,
      p.display_name,
      p.initials,
      lb.wins,
      lb.losses,
      ts.today_steps,
      uhb.rolling_avg_7d_steps,
      uhb.rolling_avg_7d_calories,
      case
        when coalesce(p_metric_type, 'steps') = 'active_calories' then uhb.rolling_avg_7d_calories
        else uhb.rolling_avg_7d_steps
      end as candidate_baseline,
      case
        when v_my_baseline is not null
          and (
            case
              when coalesce(p_metric_type, 'steps') = 'active_calories'
                then uhb.rolling_avg_7d_calories
              else uhb.rolling_avg_7d_steps
            end
          ) is not null
          then abs(
            (
              case
                when coalesce(p_metric_type, 'steps') = 'active_calories'
                  then uhb.rolling_avg_7d_calories
                else uhb.rolling_avg_7d_steps
              end
            ) - v_my_baseline
          )
        when (
          case
            when coalesce(p_metric_type, 'steps') = 'active_calories'
              then uhb.rolling_avg_7d_calories
            else uhb.rolling_avg_7d_steps
          end
        ) is not null then 10000000::numeric
        when v_my_baseline is not null then 10000001::numeric
        else 10000002::numeric
      end as baseline_distance
    from public.profiles p
    left join public.user_health_baselines uhb on uhb.user_id = p.id
    left join latest_lb lb on lb.user_id = p.id
    left join today_snap ts on ts.user_id = p.id
    where p.id <> v_viewer_id
      and (
        v_query = ''
        or lower(coalesce(p.display_name, '')) like '%' || v_query || '%'
      )
  )
  select
    r.id,
    r.display_name,
    r.initials,
    r.wins,
    r.losses,
    r.today_steps,
    r.rolling_avg_7d_steps,
    r.rolling_avg_7d_calories
  from ranked r
  order by r.baseline_distance asc, r.display_name asc
  limit v_limit;
end;
$$;


ALTER FUNCTION "public"."list_opponent_candidates"("p_query" "text", "p_metric_type" "text", "p_viewer_local_date" "date", "p_limit" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."list_opponent_candidates"("p_query" "text", "p_metric_type" "text", "p_viewer_local_date" "date", "p_limit" integer) IS 'Challenge opponent picker: skill-sorted candidates with optional name filter. Caller passes viewer local calendar date for today steps.';



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
  v_now timestamptz := now();
  v_my_avg numeric;
  v_attempt int;
  v_eff_mode text;
  v_eff_diff text;
  v_found boolean := false;
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

  v_my_avg := COALESCE(v_incoming.creator_avg_30d_steps, v_incoming.creator_baseline);
  v_eff_mode := COALESCE(v_incoming.scoring_mode, 'raw');
  v_eff_diff := COALESCE(v_incoming.difficulty, 'fair');

  FOR v_attempt IN 1..3 LOOP
    SELECT msr.*
    INTO v_partner
    FROM match_search_requests msr
    WHERE msr.status = 'searching'
      AND msr.id <> v_incoming.id
      AND msr.creator_id <> v_incoming.creator_id
      AND msr.metric_type = v_incoming.metric_type
      AND msr.duration_days = v_incoming.duration_days
      AND msr.start_mode = v_incoming.start_mode
      AND msr.scoring_mode IS NOT DISTINCT FROM v_incoming.scoring_mode
      AND msr.difficulty IS NOT DISTINCT FROM v_incoming.difficulty
      AND (
        v_incoming.metric_type <> 'steps'
        OR v_attempt >= 3
        OR v_my_avg IS NULL
        OR v_my_avg <= 0
        OR (
          v_attempt = 2
          AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) >= v_my_avg * 0.01
          AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) <= v_my_avg * 100
        )
        OR (
          v_attempt = 1
          AND (
            (v_eff_mode = 'raw' AND v_eff_diff = 'easy'
              AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) BETWEEN v_my_avg * 0.70 AND v_my_avg * 1.00)
            OR (v_eff_mode = 'raw' AND v_eff_diff = 'fair'
              AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) BETWEEN v_my_avg * 0.85 AND v_my_avg * 1.15)
            OR (v_eff_mode = 'raw' AND v_eff_diff = 'hard'
              AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) BETWEEN v_my_avg * 1.05 AND v_my_avg * 1.40)
            OR (v_eff_mode = 'balanced' AND v_eff_diff = 'easy'
              AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) BETWEEN v_my_avg * 0.60 AND v_my_avg * 1.10)
            OR (v_eff_mode = 'balanced' AND v_eff_diff = 'fair'
              AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) BETWEEN v_my_avg * 0.50 AND v_my_avg * 1.50)
            OR (v_eff_mode = 'balanced' AND v_eff_diff = 'hard'
              AND COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) BETWEEN v_my_avg * 0.90 AND v_my_avg * 2.50)
          )
        )
      )
    ORDER BY
      CASE
        WHEN v_incoming.metric_type = 'steps' THEN abs(COALESCE(msr.creator_avg_30d_steps, msr.creator_baseline) - v_my_avg)
        ELSE abs(msr.creator_baseline - v_incoming.creator_baseline)
      END ASC NULLS LAST,
      msr.created_at ASC,
      msr.id ASC
    FOR UPDATE SKIP LOCKED
    LIMIT 1;

    IF FOUND THEN
      v_found := true;
      EXIT;
    END IF;
  END LOOP;

  IF NOT v_found THEN
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
    starts_at,
    scoring_mode,
    baseline_timeframe,
    difficulty
  )
  VALUES (
    'public_matchmaking',
    v_incoming.metric_type,
    v_incoming.duration_days,
    v_incoming.start_mode,
    'pending',
    v_tz,
    NULL,
    v_incoming.scoring_mode,
    CASE
      WHEN v_incoming.scoring_mode = 'balanced' AND v_incoming.metric_type = 'steps' THEN '30d'
      ELSE NULL
    END,
    v_incoming.difficulty
  )
  RETURNING id INTO v_match_id;

  -- Both players treated as having accepted public matchmaking; no invite / opponent-wait UI.
  INSERT INTO match_participants (match_id, user_id, role, joined_via, accepted_at)
  VALUES
    (v_match_id, v_challenger, 'challenger', 'matchmaking', v_now),
    (v_match_id, v_opponent, 'opponent', 'matchmaking', v_now);

  IF NOT public.activate_match_with_days(v_match_id) THEN
    RAISE EXCEPTION 'matchmaking_pair_atomic: activate_match_with_days failed for match %', v_match_id;
  END IF;

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
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_match_id uuid;
  v_match_state text;
  v_metric_type text;
  v_scoring_mode text;
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

  SELECT m.id, m.state, m.metric_type, m.scoring_mode
  INTO v_match_id, v_match_state, v_metric_type, v_scoring_mode
  FROM match_days md
  JOIN matches m ON m.id = md.match_id
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
      'scoring_mode', COALESCE(v_scoring_mode, ''),
      'opponent_display_name', v_leader_name,
      'lead_delta', v_lead_delta,
      'deep_link_target', 'match_details'
    )
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_lead_changed"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_message_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_thread public.message_threads%rowtype;
  v_recipient uuid;
  v_sender_name text;
  v_preview text;
begin
  select * into v_thread from public.message_threads where id = new.thread_id;
  if not found then
    return new;
  end if;

  if new.sender_id = v_thread.user_low then
    v_recipient := v_thread.user_high;
  else
    v_recipient := v_thread.user_low;
  end if;

  if v_recipient = new.sender_id then
    return new;
  end if;

  select coalesce(display_name, 'Player')
  into v_sender_name
  from public.profiles
  where id = new.sender_id
  limit 1;

  v_preview := left(trim(both from new.body), 120);

  perform private.invoke_dispatch_notification(
    array[v_recipient],
    'message_received',
    jsonb_build_object(
      'thread_id', new.thread_id::text,
      'peer_profile_id', new.sender_id::text,
      'sender_display_name', v_sender_name,
      'opponent_display_name', v_sender_name,
      'message_preview', v_preview,
      'deep_link_target', 'messages'
    )
  );

  return new;
end;
$$;


ALTER FUNCTION "public"."notify_message_insert"() OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."prune_user_intraday_step_tick_day"("p_calendar_date" "date") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_profile_id uuid;
  v_deleted int := 0;
BEGIN
  SELECT p.id
  INTO v_profile_id
  FROM public.profiles p
  WHERE p.auth_user_id = auth.uid()
  LIMIT 1;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated or profile missing';
  END IF;

  WHILE (
    SELECT count(*)::int
    FROM public.user_intraday_step_ticks
    WHERE user_id = v_profile_id
      AND calendar_date = p_calendar_date
  ) > 30
  LOOP
    PERFORM public.intraday_step_ticks_prune_one_victim(v_profile_id, p_calendar_date);
    v_deleted := v_deleted + 1;
  END LOOP;

  RETURN v_deleted;
END;
$$;


ALTER FUNCTION "public"."prune_user_intraday_step_tick_day"("p_calendar_date" "date") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."prune_user_intraday_step_tick_day"("p_calendar_date" "date") IS 'Deletes excess ticks for the caller for one calendar_date using the same prune heuristic. Returns number of rows removed.';



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



CREATE OR REPLACE FUNCTION "public"."record_metric_snapshot"("p_match_id" "uuid", "p_metric_type" "text", "p_value" numeric, "p_source_date" "date", "p_flagged" boolean DEFAULT false, "p_metadata" "jsonb" DEFAULT NULL::"jsonb", "p_synced_at" timestamp with time zone DEFAULT "now"()) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_profile_id uuid;
  v_latest_id uuid;
  v_latest_value numeric;
  v_new_id uuid;
  v_was_updated boolean := false;
BEGIN
  SELECT p.id
  INTO v_profile_id
  FROM public.profiles p
  WHERE p.auth_user_id = auth.uid()
  LIMIT 1;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated or profile missing';
  END IF;

  IF p_metric_type NOT IN ('steps', 'active_calories') THEN
    RAISE EXCEPTION 'invalid metric_type: %', p_metric_type;
  END IF;

  IF p_value IS NULL OR p_value < 0 THEN
    RAISE EXCEPTION 'value must be non-negative';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.match_participants mp
    WHERE mp.match_id = p_match_id
      AND mp.user_id = v_profile_id
  ) THEN
    RAISE EXCEPTION 'not a participant in match';
  END IF;

  SELECT ms.id, ms.value
  INTO v_latest_id, v_latest_value
  FROM public.metric_snapshots ms
  WHERE ms.user_id = v_profile_id
    AND ms.match_id = p_match_id
    AND ms.metric_type = p_metric_type
    AND ms.source_date = p_source_date
  ORDER BY ms.synced_at DESC, ms.id DESC
  LIMIT 1;

  IF v_latest_id IS NOT NULL AND v_latest_value = p_value THEN
    UPDATE public.metric_snapshots
    SET
      synced_at = COALESCE(p_synced_at, now()),
      metadata = COALESCE(p_metadata, metadata),
      flagged = p_flagged
    WHERE id = v_latest_id;

    v_new_id := v_latest_id;
    v_was_updated := true;
  ELSE
    INSERT INTO public.metric_snapshots (
      match_id,
      user_id,
      metric_type,
      value,
      source_date,
      synced_at,
      flagged,
      metadata
    )
    VALUES (
      p_match_id,
      v_profile_id,
      p_metric_type,
      p_value,
      p_source_date,
      COALESCE(p_synced_at, now()),
      COALESCE(p_flagged, false),
      p_metadata
    )
    RETURNING id INTO v_new_id;
  END IF;

  RETURN jsonb_build_object(
    'snapshot_id', v_new_id,
    'was_updated', v_was_updated
  );
END;
$$;


ALTER FUNCTION "public"."record_metric_snapshot"("p_match_id" "uuid", "p_metric_type" "text", "p_value" numeric, "p_source_date" "date", "p_flagged" boolean, "p_metadata" "jsonb", "p_synced_at" timestamp with time zone) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."record_metric_snapshot"("p_match_id" "uuid", "p_metric_type" "text", "p_value" numeric, "p_source_date" "date", "p_flagged" boolean, "p_metadata" "jsonb", "p_synced_at" timestamp with time zone) IS 'Records a metric snapshot for the signed-in user: inserts when value changed, updates synced_at when value unchanged for that match/day.';



CREATE OR REPLACE FUNCTION "public"."set_my_match_participant_baseline"("p_match_id" "uuid", "p_baseline_steps" numeric) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_pid uuid;
  v_metric text;
  v_mode text;
  v_updated int;
BEGIN
  IF p_baseline_steps IS NULL OR p_baseline_steps < 3000 THEN
    RAISE EXCEPTION 'baseline_steps must be >= 3000';
  END IF;

  SELECT id INTO v_pid FROM public.profiles WHERE auth_user_id = auth.uid() LIMIT 1;
  IF v_pid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT m.metric_type, m.scoring_mode
  INTO v_metric, v_mode
  FROM public.matches m
  WHERE m.id = p_match_id
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'match not found';
  END IF;

  IF v_metric <> 'steps' OR COALESCE(v_mode, 'raw') <> 'balanced' THEN
    RAISE EXCEPTION 'baseline snapshot only for balanced steps matches';
  END IF;

  UPDATE public.match_participants mp
  SET baseline_steps = p_baseline_steps
  WHERE mp.match_id = p_match_id
    AND mp.user_id = v_pid
    AND mp.baseline_steps IS NULL;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'not a participant';
  END IF;
END;
$$;


ALTER FUNCTION "public"."set_my_match_participant_baseline"("p_match_id" "uuid", "p_baseline_steps" numeric) OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."weekly_steps_leaderboard"("p_week_start" "date", "p_limit" integer DEFAULT 100, "p_scope" "text" DEFAULT 'global'::"text") RETURNS TABLE("user_id" "uuid", "display_name" "text", "initials" "text", "week_start" "date", "week_end" "date", "total_steps" bigint, "rank" integer)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_viewer uuid;
  v_week_start date;
  v_limit int;
  v_scope text;
begin
  select p.id
  into v_viewer
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_viewer is null then
    return;
  end if;

  if p_week_start is null then
    return;
  end if;

  v_week_start := p_week_start;
  v_limit := least(500, greatest(1, coalesce(p_limit, 100)));
  v_scope := case
    when lower(coalesce(p_scope, 'global')) = 'friends' then 'friends'
    else 'global'
  end;

  return query
  with scoped_users as (
    select p.id
    from public.profiles p
    where v_scope = 'global'

    union

    select v_viewer
    where v_scope = 'friends'

    union

    select case
      when f.a_id = v_viewer then f.b_id
      else f.a_id
    end as id
    from public.friendships f
    where v_scope = 'friends'
      and f.status = 'accepted'
      and (f.a_id = v_viewer or f.b_id = v_viewer)
  ),
  latest_daily_snapshots as (
    select
      ms.user_id,
      ms.source_date,
      ms.value::bigint as step_value,
      row_number() over (
        partition by ms.user_id, ms.source_date
        order by ms.synced_at desc, ms.id desc
      ) as rn
    from public.metric_snapshots ms
    inner join scoped_users su
      on su.id = ms.user_id
    where ms.metric_type = 'steps'
      and ms.flagged = false
      and ms.source_date >= v_week_start
      and ms.source_date < (v_week_start + interval '7 days')::date
  ),
  weekly as (
    select
      l.user_id,
      sum(greatest(l.step_value, 0))::bigint as total_steps
    from latest_daily_snapshots l
    where l.rn = 1
    group by l.user_id
    having sum(greatest(l.step_value, 0)) > 0
  ),
  ranked as (
    select
      w.user_id,
      w.total_steps,
      row_number() over (
        order by w.total_steps desc, w.user_id asc
      )::int as rank
    from weekly w
  )
  select
    r.user_id,
    coalesce(nullif(trim(p.display_name), ''), 'Player') as display_name,
    coalesce(nullif(upper(trim(p.initials)), ''), 'PL') as initials,
    v_week_start as week_start,
    (v_week_start + interval '6 days')::date as week_end,
    r.total_steps,
    r.rank
  from ranked r
  inner join public.profiles p
    on p.id = r.user_id
  order by r.rank
  limit v_limit;
end;
$$;


ALTER FUNCTION "public"."weekly_steps_leaderboard"("p_week_start" "date", "p_limit" integer, "p_scope" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."weekly_steps_leaderboard_from_daily_totals"("p_week_start" "date", "p_limit" integer DEFAULT 100, "p_scope" "text" DEFAULT 'global'::"text") RETURNS TABLE("user_id" "uuid", "display_name" "text", "initials" "text", "week_start" "date", "week_end" "date", "total_steps" bigint, "rank" integer)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_viewer uuid;
  v_week_start date;
  v_limit int;
  v_scope text;
begin
  select p.id
  into v_viewer
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;

  if v_viewer is null then
    return;
  end if;

  if p_week_start is null then
    return;
  end if;

  v_week_start := p_week_start;
  v_limit := least(500, greatest(1, coalesce(p_limit, 100)));
  v_scope := case
    when lower(coalesce(p_scope, 'global')) = 'friends' then 'friends'
    else 'global'
  end;

  return query
  with scoped_users as (
    select p.id
    from public.profiles p
    where v_scope = 'global'

    union

    select v_viewer
    where v_scope = 'friends'

    union

    select case
      when f.a_id = v_viewer then f.b_id
      else f.a_id
    end as id
    from public.friendships f
    where v_scope = 'friends'
      and f.status = 'accepted'
      and (f.a_id = v_viewer or f.b_id = v_viewer)
  ),
  weekly as (
    select
      d.user_id,
      sum(greatest(d.steps, 0))::bigint as total_steps
    from public.user_daily_step_totals d
    inner join scoped_users su
      on su.id = d.user_id
    where d.calendar_date >= v_week_start
      and d.calendar_date < (v_week_start + interval '7 days')::date
    group by d.user_id
    having sum(greatest(d.steps, 0)) > 0
  ),
  ranked as (
    select
      w.user_id,
      w.total_steps,
      row_number() over (
        order by w.total_steps desc, w.user_id asc
      )::int as rank
    from weekly w
  )
  select
    r.user_id,
    coalesce(nullif(trim(p.display_name), ''), 'Player') as display_name,
    coalesce(nullif(upper(trim(p.initials)), ''), 'PL') as initials,
    v_week_start as week_start,
    (v_week_start + interval '6 days')::date as week_end,
    r.total_steps,
    r.rank
  from ranked r
  inner join public.profiles p
    on p.id = r.user_id
  order by r.rank
  limit v_limit;
end;
$$;


ALTER FUNCTION "public"."weekly_steps_leaderboard_from_daily_totals"("p_week_start" "date", "p_limit" integer, "p_scope" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."weekly_steps_leaderboard_from_daily_totals"("p_week_start" "date", "p_limit" integer, "p_scope" "text") IS 'Ranks users by sum of user_daily_step_totals.steps for UTC week [p_week_start, p_week_start+7).';


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
    "balanced_ratio" numeric,
    "balanced_percent" numeric,
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
    "baseline_steps" numeric,
    CONSTRAINT "match_participants_joined_via_check" CHECK (("joined_via" = ANY (ARRAY['matchmaking'::"text", 'direct_challenge'::"text"]))),
    CONSTRAINT "match_participants_role_check" CHECK (("role" = ANY (ARRAY['challenger'::"text", 'opponent'::"text"])))
);


ALTER TABLE "public"."match_participants" OWNER TO "postgres";


COMMENT ON COLUMN "public"."match_participants"."baseline_steps" IS 'Snapshotted steps baseline for balanced scoring; immutable once set ideally';



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
    "scoring_mode" "text",
    "difficulty" "text",
    "creator_avg_30d_steps" numeric,
    CONSTRAINT "match_search_requests_duration_days_check" CHECK (("duration_days" = ANY (ARRAY[1, 3, 5, 7]))),
    CONSTRAINT "match_search_requests_metric_type_check" CHECK (("metric_type" = ANY (ARRAY['steps'::"text", 'active_calories'::"text"]))),
    CONSTRAINT "match_search_requests_start_mode_check" CHECK (("start_mode" = ANY (ARRAY['today'::"text", 'tomorrow'::"text"]))),
    CONSTRAINT "match_search_requests_status_check" CHECK (("status" = ANY (ARRAY['searching'::"text", 'matched'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "msq_difficulty_check" CHECK ((("difficulty" IS NULL) OR ("difficulty" = ANY (ARRAY['easy'::"text", 'fair'::"text", 'hard'::"text"])))),
    CONSTRAINT "msq_scoring_mode_check" CHECK ((("scoring_mode" IS NULL) OR ("scoring_mode" = ANY (ARRAY['balanced'::"text", 'raw'::"text"]))))
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
    "scoring_mode" "text",
    "baseline_timeframe" "text",
    "difficulty" "text",
    "matchmaking_resolution" "text",
    "matchmaking_attempt" integer,
    CONSTRAINT "matches_baseline_timeframe_check" CHECK ((("baseline_timeframe" IS NULL) OR ("baseline_timeframe" = '30d'::"text"))),
    CONSTRAINT "matches_difficulty_check" CHECK ((("difficulty" IS NULL) OR ("difficulty" = ANY (ARRAY['easy'::"text", 'fair'::"text", 'hard'::"text"])))),
    CONSTRAINT "matches_duration_days_check" CHECK (("duration_days" = ANY (ARRAY[1, 3, 5, 7]))),
    CONSTRAINT "matches_match_type_check" CHECK (("match_type" = ANY (ARRAY['public_matchmaking'::"text", 'direct_challenge'::"text"]))),
    CONSTRAINT "matches_matchmaking_resolution_check" CHECK ((("matchmaking_resolution" IS NULL) OR ("matchmaking_resolution" = ANY (ARRAY['exact_preference'::"text", 'widened'::"text", 'fallback_fifo'::"text"])))),
    CONSTRAINT "matches_metric_type_check" CHECK (("metric_type" = ANY (ARRAY['steps'::"text", 'active_calories'::"text"]))),
    CONSTRAINT "matches_scoring_mode_check" CHECK ((("scoring_mode" IS NULL) OR ("scoring_mode" = ANY (ARRAY['balanced'::"text", 'raw'::"text"])))),
    CONSTRAINT "matches_start_mode_check" CHECK (("start_mode" = ANY (ARRAY['today'::"text", 'tomorrow'::"text"]))),
    CONSTRAINT "matches_state_check" CHECK (("state" = ANY (ARRAY['searching'::"text", 'pending'::"text", 'active'::"text", 'completed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."matches" OWNER TO "postgres";


COMMENT ON COLUMN "public"."matches"."scoring_mode" IS 'balanced | raw | NULL legacy (raw winner semantics)';



COMMENT ON COLUMN "public"."matches"."matchmaking_resolution" IS 'public_matchmaking only: exact_preference | widened | fallback_fifo (Raw widening phase)';



COMMENT ON COLUMN "public"."matches"."matchmaking_attempt" IS 'public_matchmaking Raw steps: widening phase index 1–3; NULL otherwise';



CREATE TABLE IF NOT EXISTS "public"."message_threads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_low" "uuid" NOT NULL,
    "user_high" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_message_at" timestamp with time zone,
    CONSTRAINT "message_threads_order_check" CHECK (("user_low" < "user_high"))
);


ALTER TABLE "public"."message_threads" OWNER TO "postgres";


COMMENT ON TABLE "public"."message_threads" IS 'One row per 1:1 pair; user_low < user_high matches friendships(a_id,b_id) order.';



CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "thread_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "body" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "messages_body_len_check" CHECK ((("char_length"(TRIM(BOTH FROM "body")) >= 1) AND ("char_length"("body") <= 2000)))
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


COMMENT ON TABLE "public"."messages" IS 'Friend-gated chat messages; RLS enforces sender + friendship.';



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


CREATE TABLE IF NOT EXISTS "public"."user_daily_step_totals" (
    "user_id" "uuid" NOT NULL,
    "calendar_date" "date" NOT NULL,
    "timezone_identifier" "text" NOT NULL,
    "steps" integer NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_daily_step_totals_steps_non_negative" CHECK (("steps" >= 0)),
    CONSTRAINT "user_daily_step_totals_timezone_identifier_nonempty" CHECK (("length"(TRIM(BOTH FROM "timezone_identifier")) > 0))
);


ALTER TABLE "public"."user_daily_step_totals" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_daily_step_totals" IS 'Canonical HealthKit total steps for one writer-local calendar day; upserted from the app for leaderboard and history (not intraday samples).';



COMMENT ON COLUMN "public"."user_daily_step_totals"."user_id" IS 'profiles.id of the person who walked (writer).';



COMMENT ON COLUMN "public"."user_daily_step_totals"."calendar_date" IS 'Calendar day for which `steps` is the full-day total (boundaries computed in timezone_identifier).';



COMMENT ON COLUMN "public"."user_daily_step_totals"."timezone_identifier" IS 'IANA zone used when mapping HealthKit day boundaries to calendar_date (e.g. America/Chicago).';



COMMENT ON COLUMN "public"."user_daily_step_totals"."steps" IS 'Total step count for that calendar_date from HealthKit (may increase intraday; past days may revise when late data syncs).';



COMMENT ON COLUMN "public"."user_daily_step_totals"."updated_at" IS 'Last time this row was written from the client.';



CREATE TABLE IF NOT EXISTS "public"."user_health_baselines" (
    "user_id" "uuid" NOT NULL,
    "rolling_avg_7d_steps" numeric,
    "rolling_avg_7d_calories" numeric,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "rolling_avg_30d_steps" numeric,
    "rolling_avg_90d_steps" numeric
);


ALTER TABLE "public"."user_health_baselines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_intraday_step_ticks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "calendar_date" "date" NOT NULL,
    "timezone_identifier" "text" NOT NULL,
    "cumulative_steps" integer NOT NULL,
    "recorded_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_intraday_step_ticks_cumulative_steps_non_negative" CHECK (("cumulative_steps" >= 0)),
    CONSTRAINT "user_intraday_step_ticks_timezone_identifier_nonempty" CHECK (("length"(TRIM(BOTH FROM "timezone_identifier")) > 0))
);


ALTER TABLE "public"."user_intraday_step_ticks" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_intraday_step_ticks" IS 'Append-only cumulative step samples for a writer-local calendar day (Slice 1). Opponent/chart reads use Slice 2 RPCs.';



COMMENT ON COLUMN "public"."user_intraday_step_ticks"."user_id" IS 'profiles.id of the person who walked (writer).';



COMMENT ON COLUMN "public"."user_intraday_step_ticks"."calendar_date" IS 'Writer-local calendar date for "today" when the sample was taken (IANA TZ in timezone_identifier).';



COMMENT ON COLUMN "public"."user_intraday_step_ticks"."timezone_identifier" IS 'IANA zone used to interpret calendar_date (e.g. America/Chicago).';



COMMENT ON COLUMN "public"."user_intraday_step_ticks"."cumulative_steps" IS 'HealthKit-style cumulative steps for that calendar_date at recorded_at.';



COMMENT ON COLUMN "public"."user_intraday_step_ticks"."recorded_at" IS 'Instant the sample represents (typically client clock at HK read; monotonic with uploads).';



COMMENT ON COLUMN "public"."user_intraday_step_ticks"."created_at" IS 'Server insert time (audit).';



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



ALTER TABLE ONLY "public"."message_threads"
    ADD CONSTRAINT "message_threads_pair_unique" UNIQUE ("user_low", "user_high");



ALTER TABLE ONLY "public"."message_threads"
    ADD CONSTRAINT "message_threads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



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



ALTER TABLE ONLY "public"."user_daily_step_totals"
    ADD CONSTRAINT "user_daily_step_totals_pkey" PRIMARY KEY ("user_id", "calendar_date");



ALTER TABLE ONLY "public"."user_health_baselines"
    ADD CONSTRAINT "user_health_baselines_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_intraday_step_ticks"
    ADD CONSTRAINT "user_intraday_step_ticks_pkey" PRIMARY KEY ("id");



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



CREATE INDEX "idx_user_daily_step_totals_calendar_date" ON "public"."user_daily_step_totals" USING "btree" ("calendar_date");



CREATE INDEX "idx_user_daily_step_totals_user_updated" ON "public"."user_daily_step_totals" USING "btree" ("user_id", "updated_at" DESC);



CREATE INDEX "idx_user_intraday_step_ticks_calendar_date" ON "public"."user_intraday_step_ticks" USING "btree" ("calendar_date");



CREATE INDEX "idx_user_intraday_step_ticks_user_date_recorded" ON "public"."user_intraday_step_ticks" USING "btree" ("user_id", "calendar_date", "recorded_at" DESC);



CREATE INDEX "le_week" ON "public"."leaderboard_entries" USING "btree" ("week_start", "points" DESC);



CREATE INDEX "matches_state" ON "public"."matches" USING "btree" ("state");



CREATE INDEX "md_match" ON "public"."match_days" USING "btree" ("match_id");



CREATE INDEX "md_status" ON "public"."match_days" USING "btree" ("status");



CREATE INDEX "mdp_match_day" ON "public"."match_day_participants" USING "btree" ("match_day_id");



CREATE INDEX "mdp_user" ON "public"."match_day_participants" USING "btree" ("user_id");



CREATE INDEX "message_threads_last_message_at_idx" ON "public"."message_threads" USING "btree" ("last_message_at" DESC NULLS LAST);



CREATE INDEX "message_threads_user_high_idx" ON "public"."message_threads" USING "btree" ("user_high");



CREATE INDEX "message_threads_user_low_idx" ON "public"."message_threads" USING "btree" ("user_low");



CREATE INDEX "messages_sender_created_idx" ON "public"."messages" USING "btree" ("sender_id", "created_at" DESC);



CREATE INDEX "messages_thread_created_idx" ON "public"."messages" USING "btree" ("thread_id", "created_at" DESC);



CREATE INDEX "mp_match" ON "public"."match_participants" USING "btree" ("match_id");



CREATE INDEX "mp_user_match" ON "public"."match_participants" USING "btree" ("user_id", "match_id");



CREATE INDEX "ms_match" ON "public"."metric_snapshots" USING "btree" ("match_id");



CREATE INDEX "ms_user_date" ON "public"."metric_snapshots" USING "btree" ("user_id", "source_date" DESC);



CREATE INDEX "msq_creator_status" ON "public"."match_search_requests" USING "btree" ("creator_id", "status");



CREATE INDEX "msq_pairing_dims" ON "public"."match_search_requests" USING "btree" ("status", "metric_type", "duration_days", "start_mode", "scoring_mode", "difficulty");



CREATE INDEX "msq_status_metric" ON "public"."match_search_requests" USING "btree" ("status", "metric_type", "duration_days", "start_mode");



CREATE INDEX "ne_status" ON "public"."notification_events" USING "btree" ("status");



CREATE INDEX "ne_user_created" ON "public"."notification_events" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "profiles_auth_user" ON "public"."profiles" USING "btree" ("auth_user_id");



CREATE INDEX "tester_feedback_user_created" ON "public"."tester_feedback" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "user_public_daily_activity_active_date_idx" ON "public"."user_public_daily_activity" USING "btree" ("active_date" DESC);



CREATE OR REPLACE TRIGGER "tr_finalize_when_all_confirmed" AFTER INSERT OR UPDATE OF "data_status" ON "public"."match_day_participants" FOR EACH ROW EXECUTE FUNCTION "public"."finalize_when_all_confirmed"();



CREATE OR REPLACE TRIGGER "tr_matchmaking_pairing_after_insert" AFTER INSERT ON "public"."match_search_requests" FOR EACH ROW EXECUTE FUNCTION "public"."tr_matchmaking_pairing_after_insert"();



CREATE OR REPLACE TRIGGER "tr_messages_touch_thread_last" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."fn_messages_touch_thread_last"();



CREATE OR REPLACE TRIGGER "tr_notify_challenge_declined" AFTER UPDATE OF "status" ON "public"."direct_challenges" FOR EACH ROW EXECUTE FUNCTION "public"."notify_challenge_declined"();



CREATE OR REPLACE TRIGGER "tr_notify_challenge_received" AFTER INSERT ON "public"."direct_challenges" FOR EACH ROW EXECUTE FUNCTION "public"."notify_challenge_received"();



CREATE OR REPLACE TRIGGER "tr_notify_lead_changed" AFTER UPDATE OF "metric_total" ON "public"."match_day_participants" FOR EACH ROW EXECUTE FUNCTION "public"."notify_lead_changed"();



CREATE OR REPLACE TRIGGER "tr_notify_message_insert" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."notify_message_insert"();



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



ALTER TABLE ONLY "public"."message_threads"
    ADD CONSTRAINT "message_threads_user_high_fkey" FOREIGN KEY ("user_high") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_threads"
    ADD CONSTRAINT "message_threads_user_low_fkey" FOREIGN KEY ("user_low") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "public"."message_threads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."metric_snapshots"
    ADD CONSTRAINT "metric_snapshots_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."metric_snapshots"
    ADD CONSTRAINT "metric_snapshots_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_events"
    ADD CONSTRAINT "notification_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tester_feedback"
    ADD CONSTRAINT "tester_feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_daily_step_totals"
    ADD CONSTRAINT "user_daily_step_totals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_health_baselines"
    ADD CONSTRAINT "user_health_baselines_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_intraday_step_ticks"
    ADD CONSTRAINT "user_intraday_step_ticks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



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



ALTER TABLE "public"."message_threads" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "message_threads: friend pair insert" ON "public"."message_threads" FOR INSERT WITH CHECK ((("user_low" < "user_high") AND (("user_low" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) OR ("user_high" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1))) AND (EXISTS ( SELECT 1
   FROM "public"."friendships" "f"
  WHERE (("f"."status" = 'accepted'::"text") AND ("f"."a_id" = "message_threads"."user_low") AND ("f"."b_id" = "message_threads"."user_high")))) AND ((( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1) = "user_low") OR (( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1) = "user_high"))));



CREATE POLICY "message_threads: participant select" ON "public"."message_threads" FOR SELECT USING ((("user_low" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) OR ("user_high" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1))));



ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "messages: friend send insert" ON "public"."messages" FOR INSERT WITH CHECK ((("sender_id" = ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_user_id" = "auth"."uid"())
 LIMIT 1)) AND (EXISTS ( SELECT 1
   FROM "public"."message_threads" "t"
  WHERE (("t"."id" = "messages"."thread_id") AND (("t"."user_low" = ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."auth_user_id" = "auth"."uid"())
         LIMIT 1)) OR ("t"."user_high" = ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."auth_user_id" = "auth"."uid"())
         LIMIT 1))) AND (EXISTS ( SELECT 1
           FROM "public"."friendships" "f"
          WHERE (("f"."status" = 'accepted'::"text") AND ("f"."a_id" = "t"."user_low") AND ("f"."b_id" = "t"."user_high")))))))));



CREATE POLICY "messages: participant select" ON "public"."messages" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."message_threads" "t"
  WHERE (("t"."id" = "messages"."thread_id") AND (("t"."user_low" = ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."auth_user_id" = "auth"."uid"())
         LIMIT 1)) OR ("t"."user_high" = ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."auth_user_id" = "auth"."uid"())
         LIMIT 1)))))));



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



ALTER TABLE "public"."user_daily_step_totals" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_daily_step_totals_insert_own" ON "public"."user_daily_step_totals" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "p"."id"
   FROM "public"."profiles" "p"
  WHERE ("p"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



CREATE POLICY "user_daily_step_totals_select_own" ON "public"."user_daily_step_totals" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "p"."id"
   FROM "public"."profiles" "p"
  WHERE ("p"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



CREATE POLICY "user_daily_step_totals_update_own" ON "public"."user_daily_step_totals" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "p"."id"
   FROM "public"."profiles" "p"
  WHERE ("p"."auth_user_id" = "auth"."uid"())
 LIMIT 1))) WITH CHECK (("user_id" = ( SELECT "p"."id"
   FROM "public"."profiles" "p"
  WHERE ("p"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



ALTER TABLE "public"."user_health_baselines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_intraday_step_ticks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_intraday_step_ticks_insert_own" ON "public"."user_intraday_step_ticks" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "p"."id"
   FROM "public"."profiles" "p"
  WHERE ("p"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



CREATE POLICY "user_intraday_step_ticks_select_own" ON "public"."user_intraday_step_ticks" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "p"."id"
   FROM "public"."profiles" "p"
  WHERE ("p"."auth_user_id" = "auth"."uid"())
 LIMIT 1)));



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



GRANT ALL ON FUNCTION "public"."append_user_intraday_step_tick"("p_calendar_date" "date", "p_timezone_identifier" "text", "p_cumulative_steps" integer, "p_recorded_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."append_user_intraday_step_tick"("p_calendar_date" "date", "p_timezone_identifier" "text", "p_cumulative_steps" integer, "p_recorded_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."append_user_intraday_step_tick"("p_calendar_date" "date", "p_timezone_identifier" "text", "p_cumulative_steps" integer, "p_recorded_at" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone, "p_scoring_mode" "text", "p_difficulty" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone, "p_scoring_mode" "text", "p_difficulty" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_direct_challenge"("p_recipient_id" "uuid", "p_metric_type" "text", "p_duration_days" integer, "p_start_mode" "text", "p_match_timezone" "text", "p_starts_at" timestamp with time zone, "p_scoring_mode" "text", "p_difficulty" "text") TO "service_role";



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



GRANT ALL ON FUNCTION "public"."fetch_latest_opponent_intraday_ticks_for_active_matches"("p_calendar_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."fetch_latest_opponent_intraday_ticks_for_active_matches"("p_calendar_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fetch_latest_opponent_intraday_ticks_for_active_matches"("p_calendar_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."fetch_opponent_intraday_step_ticks"("p_opponent_profile_id" "uuid", "p_calendar_date" "date", "p_since" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."fetch_opponent_intraday_step_ticks"("p_opponent_profile_id" "uuid", "p_calendar_date" "date", "p_since" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."fetch_opponent_intraday_step_ticks"("p_opponent_profile_id" "uuid", "p_calendar_date" "date", "p_since" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."finalize_when_all_confirmed"() TO "anon";
GRANT ALL ON FUNCTION "public"."finalize_when_all_confirmed"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."finalize_when_all_confirmed"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_messages_touch_thread_last"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_messages_touch_thread_last"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_messages_touch_thread_last"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_rival_stats"("p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_rival_stats"("p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_rival_stats"("p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_profile_stats_snapshot"("p_range_key" "text", "p_metric_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_profile_stats_snapshot"("p_range_key" "text", "p_metric_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_profile_stats_snapshot"("p_range_key" "text", "p_metric_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_stats_opponent_steps_rollups"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_stats_opponent_steps_rollups"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_stats_opponent_steps_rollups"() TO "service_role";



GRANT ALL ON FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."head_to_head_stats"("p_opponent_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."health_battle_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."health_battle_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."health_battle_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."home_daily_battle_margins"("p_end_date" "date", "p_day_count" integer, "p_metric_type" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."intraday_step_ticks_prune_one_victim"("p_user_id" "uuid", "p_calendar_date" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."intraday_step_ticks_prune_one_victim"("p_user_id" "uuid", "p_calendar_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."intraday_step_ticks_prune_one_victim"("p_user_id" "uuid", "p_calendar_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."intraday_step_ticks_prune_one_victim"("p_user_id" "uuid", "p_calendar_date" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."invoke_edge_function_async"("p_function_name" "text", "p_payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."invoke_edge_function_async"("p_function_name" "text", "p_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."invoke_edge_function_async"("p_function_name" "text", "p_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."invoke_edge_function_async"("p_function_name" "text", "p_payload" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_opponent_candidates"("p_query" "text", "p_metric_type" "text", "p_viewer_local_date" "date", "p_limit" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_opponent_candidates"("p_query" "text", "p_metric_type" "text", "p_viewer_local_date" "date", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."list_opponent_candidates"("p_query" "text", "p_metric_type" "text", "p_viewer_local_date" "date", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."list_opponent_candidates"("p_query" "text", "p_metric_type" "text", "p_viewer_local_date" "date", "p_limit" integer) TO "service_role";



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



GRANT ALL ON FUNCTION "public"."notify_message_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_message_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_message_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_public_matchmaking_declined"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_public_matchmaking_declined"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_public_matchmaking_declined"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prune_user_intraday_step_tick_day"("p_calendar_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."prune_user_intraday_step_tick_day"("p_calendar_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."prune_user_intraday_step_tick_day"("p_calendar_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."push_live_activity_updates"() TO "anon";
GRANT ALL ON FUNCTION "public"."push_live_activity_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."push_live_activity_updates"() TO "service_role";



GRANT ALL ON FUNCTION "public"."reconcile_stuck_match_completions"() TO "anon";
GRANT ALL ON FUNCTION "public"."reconcile_stuck_match_completions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."reconcile_stuck_match_completions"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."record_metric_snapshot"("p_match_id" "uuid", "p_metric_type" "text", "p_value" numeric, "p_source_date" "date", "p_flagged" boolean, "p_metadata" "jsonb", "p_synced_at" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."record_metric_snapshot"("p_match_id" "uuid", "p_metric_type" "text", "p_value" numeric, "p_source_date" "date", "p_flagged" boolean, "p_metadata" "jsonb", "p_synced_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."record_metric_snapshot"("p_match_id" "uuid", "p_metric_type" "text", "p_value" numeric, "p_source_date" "date", "p_flagged" boolean, "p_metadata" "jsonb", "p_synced_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_metric_snapshot"("p_match_id" "uuid", "p_metric_type" "text", "p_value" numeric, "p_source_date" "date", "p_flagged" boolean, "p_metadata" "jsonb", "p_synced_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_my_match_participant_baseline"("p_match_id" "uuid", "p_baseline_steps" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."set_my_match_participant_baseline"("p_match_id" "uuid", "p_baseline_steps" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_my_match_participant_baseline"("p_match_id" "uuid", "p_baseline_steps" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."tr_matchmaking_pairing_after_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."tr_matchmaking_pairing_after_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tr_matchmaking_pairing_after_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."tr_on_all_accepted_after_participant"() TO "anon";
GRANT ALL ON FUNCTION "public"."tr_on_all_accepted_after_participant"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tr_on_all_accepted_after_participant"() TO "service_role";



GRANT ALL ON FUNCTION "public"."weekly_steps_leaderboard"("p_week_start" "date", "p_limit" integer, "p_scope" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."weekly_steps_leaderboard"("p_week_start" "date", "p_limit" integer, "p_scope" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."weekly_steps_leaderboard"("p_week_start" "date", "p_limit" integer, "p_scope" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."weekly_steps_leaderboard_from_daily_totals"("p_week_start" "date", "p_limit" integer, "p_scope" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."weekly_steps_leaderboard_from_daily_totals"("p_week_start" "date", "p_limit" integer, "p_scope" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."weekly_steps_leaderboard_from_daily_totals"("p_week_start" "date", "p_limit" integer, "p_scope" "text") TO "service_role";






























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



GRANT ALL ON TABLE "public"."message_threads" TO "anon";
GRANT ALL ON TABLE "public"."message_threads" TO "authenticated";
GRANT ALL ON TABLE "public"."message_threads" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



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



GRANT ALL ON TABLE "public"."user_daily_step_totals" TO "anon";
GRANT ALL ON TABLE "public"."user_daily_step_totals" TO "authenticated";
GRANT ALL ON TABLE "public"."user_daily_step_totals" TO "service_role";



GRANT ALL ON TABLE "public"."user_health_baselines" TO "anon";
GRANT ALL ON TABLE "public"."user_health_baselines" TO "authenticated";
GRANT ALL ON TABLE "public"."user_health_baselines" TO "service_role";



GRANT ALL ON TABLE "public"."user_intraday_step_ticks" TO "anon";
GRANT ALL ON TABLE "public"."user_intraday_step_ticks" TO "authenticated";
GRANT ALL ON TABLE "public"."user_intraday_step_ticks" TO "service_role";



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































