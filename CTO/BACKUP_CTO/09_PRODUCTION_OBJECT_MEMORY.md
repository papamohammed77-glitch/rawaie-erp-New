# BACKUP CTO 09 — PRODUCTION OBJECT MEMORY

## Rule
Never invent a Production object. Query its existence/schema/definition before changing it.

## Core Production objects already established
### Company / Settings
`public.app_settings`
Known active company:
`da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
Known MAIN branch:
`151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`

### Branches
`public.branches`

Main branch code:
`BR-01`

Mobile VAN branch created for the official test vehicle:
`VAN-VEH-92yrzb`
ID:
`dbdef0b7-0909-4f71-a367-30c61d021286`

### Vehicles
`public.vehicles` exists in Production.
Relevant columns proven include:
- id
- company_id
- vehicle_code
- model
- license_plate
- driver_id
- max_weight_kg
- max_volume_m3
- min_trip_value
- status
- notes
- created_at
- updated_at

Vehicle code is unique per company.

Official experimental vehicle:
`VEH-92yrzb`
`70e5d809-0505-4e60-b317-feff6e799127`

### Users / Representatives
`public.users`
Known experimental direct-sales representatives:
- `van-sales@rawaea.com`
- `vansales@rawaea.com`

Official test representative reused:
`van-sales@rawaea.com`
ID:
`a86726d9-d687-4113-a9e2-5f90f4bdb4fa`

Role:
`مندوب بيع مباشر`
Status:
`Active`

The user schema does NOT contain an `is_active` column in the captured query. Use `status` instead.

### Vehicle tracking
`public.vehicle_tracking` exists.
Proven fields include:
- id
- vehicle_id
- driver_id
- runsheet_code
- meter_reading
- meter_photo_url
- tracking_date
- created_at
- company_id

### Items
`public.items`
Do not assume item identifiers or item codes. Query Production.

### Stock
`public.stock_branches`
Proven columns:
- id
- branch_id
- item_id
- qty
- allocated_qty
- available_qty
- updated_at

`available_qty` is a GENERATED column. Never include it in INSERT/UPDATE assignments.

Unique constraint:
`stock_branches_branch_id_item_id_key`

### Manual Voucher
`public.stock_vouchers`
Proven fields include:
- id
- company_id
- voucher_code
- voucher_date
- type
- status
- from_branch_id
- to_branch_id
- from_type
- from_id
- to_type
- to_id
- reference
- notes
- created_by
- sent_date
- received_date
- completed_at
- created_at
- updated_at
- source
- completed_by was NOT present in the captured Production schema at the earlier rescue checkpoint.

`public.stock_voucher_details`
Proven fields include:
- id
- voucher_id
- item_id
- item_code
- item_name
- unit
- qty
- unit_price
- received_qty
- notes
- created_at

### Inventory history
`public.inventory_log`
Captured fields include:
- id
- company_id
- log_code
- movement_date
- voucher_id
- item_id
- item_code
- item_name
- movement_type
- qty
- reference
- user_email
- created_at

Do not assume `branch_id` exists; earlier captured Production evidence did not contain it.

## Central RPCs established during rescue
- `public.post_stock_movement(...)`
- `public.setup_van_stock(uuid)`
- `public.create_manual_stock_voucher_atomic(...)`
- `public.send_manual_stock_voucher_v2(...)`
- `public.receive_manual_stock_voucher_v2(...)`
- `public.complete_manual_stock_voucher_atomic(...)`
- `public.cancel_manual_stock_voucher_atomic(...)`
- `public.post_manual_stock_voucher_atomic(...)`

## Important distinction
The repository also contains older atomic SEND infrastructure such as `send_stock_voucher_atomic`. Do not assume it has been replaced by the later manual-voucher path without Production consumer evidence.

## Security
Reviewed RPCs used `SECURITY DEFINER` in the relevant rescue path. Never disable RLS or weaken security as a workaround.
