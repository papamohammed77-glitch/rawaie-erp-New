BEGIN;
INSERT INTO public.audit_log(action,table_name,record_id,new_data,user_agent,created_at)
VALUES
('update','inventory_governance','manual-voucher-create',jsonb_build_object('migration','20260819014000_close_manual_voucher_create_tenant_and_item_identity','status','closed'),'automation:medhat-inventory-governance',now()),
('update','inventory_governance','receive-purchase',jsonb_build_object('migration','20260819024000_harden_receive_purchase_payload_identity','status','closed'),'automation:medhat-inventory-governance',now()),
('update','inventory_governance','inventory-adjustment',jsonb_build_object('migration','20260819030000_fix_inventory_adjustment_global_item_identity','status','closed'),'automation:medhat-inventory-governance',now()),
('update','inventory_governance','manual-voucher-send-receive',jsonb_build_object('migration','20260819031000_close_legacy_receive_v2_writer','legacy_revoked','receive_manual_stock_voucher_v2','status','closed'),'automation:medhat-inventory-governance',now()),
('update','inventory_governance','sales-return-delivery',jsonb_build_object('status','blocked-by-evidence','reason','missing canonical complete return/delivery RPC implementation and unsafe sales idempotency cannot be invented safely'),'automation:medhat-inventory-governance',now());
COMMIT;
