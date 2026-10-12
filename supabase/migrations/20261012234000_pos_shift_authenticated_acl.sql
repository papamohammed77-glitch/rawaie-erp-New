-- Keep shift control RPCs on the authenticated user boundary only.
REVOKE ALL ON FUNCTION public.pos_open_shift(uuid,text,numeric,uuid,uuid,text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pos_get_shift_summary(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pos_close_shift(uuid,numeric,jsonb,uuid,text) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.pos_open_shift(uuid,text,numeric,uuid,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pos_get_shift_summary(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pos_close_shift(uuid,numeric,jsonb,uuid,text) TO authenticated;
