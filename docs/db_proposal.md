# Database Structure Proposal

## Issues With Current Schema

### 1. Fragmented User Model
`users` is anemic (only `id`, `role`, `phone_number`, `is_super_admin`), while names and avatars live in separate `driver_profiles` and `passenger_profiles` tables with duplicated columns (`first_name`, `last_name`, `profile_image_url`). A user who is both a driver and a passenger has their data split across two places.

### 2. Inconsistent Foreign Key Naming
Some tables use `user_id`, others use `driver_id`, `passenger_id`, `reviewer_id`, `reviewee_id`, or `driver_id` — making joins and code-generation tedious and error-prone.

### 3. Location on Profile vs Telemetry
`driver_profiles.current_location` duplicates the concept of `driver_telemetry.location`. The profile should only hold a "last known location" snapshot if needed; telemetry is the authoritative source.

### 4. No Soft Deletes
No table has a `deleted_at` column. Once a row is gone, it's gone — no audit trail, no recovery.

### 5. `ride_batch_queue` Redundancy
Stores `ride_id`, `passenger_id`, `pickup_lat`, `pickup_lng` — all of which already exist in `rides`. This should be a view or a lightweight status flag on `rides`.

### 6. `notifications` Mixes Concerns
`status` column mixes delivery state (`pending`, `sent`, `failed`) with the same table that stores the notification content. Read/unread should be separate from delivery status.

---

## Proposed Schema

### Core Principle
One `profiles` table for all users. Role-specific data gets its own extension table. All foreign keys follow the pattern `{table_name}_id` (singular, underscored).

### Tables

#### `profiles`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | references `auth.users` ON DELETE CASCADE |
| `first_name` | `text` NOT NULL | |
| `last_name` | `text` NOT NULL | |
| `email` | `text` NOT NULL UNIQUE | mirrors `auth.users.email` for offline-friendly access |
| `phone_number` | `text` UNIQUE | |
| `avatar_url` | `text` | was `profile_image_url` on two tables |
| `role` | `user_role` NOT NULL | enum: `passenger`, `driver`, `admin` |
| `is_super_admin` | `boolean` DEFAULT false | |
| `last_seen_at` | `timestamptz` | when they last used the app |
| `created_at` | `timestamptz` DEFAULT now() | |
| `updated_at` | `timestamptz` DEFAULT now() | |
| `deleted_at` | `timestamptz` | soft delete |

**Why:** Eliminates the split between `users` + `driver_profiles` + `passenger_profiles`. Every user has one row. Role-specific extensions (below) hold the rest.

#### `driver_details`
| Column | Type | Notes |
|--------|------|-------|
| `profile_id` | `uuid` PK | references `profiles.id` ON DELETE CASCADE |
| `status` | `profile_status` DEFAULT `pending` | approved/suspended/pending |
| `is_online` | `boolean` DEFAULT false | |
| `rating` | `numeric(3,2)` DEFAULT 0.00 | |
| `rating_count` | `integer` DEFAULT 0 | denormalized counter to avoid COUNT(*) every time |
| `last_location` | `geography(point)` | snapshot; telemetry is source of truth |
| `created_at` | `timestamptz` DEFAULT now() | |
| `updated_at` | `timestamptz` DEFAULT now() | |

**Why:** Only drivers get this table. Clean 1:1 extension.

#### `rides`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `passenger_id` | `uuid` NOT NULL | references `profiles.id` |
| `driver_id` | `uuid` | references `profiles.id` |
| `pickup_location` | `geography(point)` NOT NULL | |
| `pickup_address` | `text` NOT NULL | |
| `dropoff_location` | `geography(point)` NOT NULL | |
| `dropoff_address` | `text` NOT NULL | |
| `status` | `ride_status` NOT NULL | enum |
| `booking_type` | `booking_type` DEFAULT `instant` | |
| `scheduled_at` | `timestamptz` | was `scheduled_time` |
| `fare_amount` | `numeric(10,2)` NOT NULL | |
| `passenger_note` | `text` | |
| `cancelled_by` | `uuid` | references `profiles.id` — who cancelled |
| `cancelled_reason` | `text` | |
| `batch_status` | `text` | replaces `ride_batch_queue.status` |
| `created_at` | `timestamptz` DEFAULT now() | |
| `updated_at` | `timestamptz` DEFAULT now() | |
| `deleted_at` | `timestamptz` | |

**Why:** `batch_status` column replaces the entire `ride_batch_queue` table. `cancelled_by` and `cancelled_reason` add auditability missing in current schema.

#### `transactions`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `ride_id` | `uuid` | references `rides.id` ON DELETE SET NULL |
| `payer_id` | `uuid` NOT NULL | references `profiles.id` — who paid |
| `payee_id` | `uuid` | references `profiles.id` — who was paid (driver) |
| `amount` | `numeric(10,2)` NOT NULL | |
| `type` | `transaction_type` NOT NULL | enum |
| `status` | `transaction_status` DEFAULT `pending` | |
| `stripe_payment_intent_id` | `text` | explicit Stripe reference |
| `created_at` | `timestamptz` DEFAULT now() | |
| `deleted_at` | `timestamptz` | |

**Why:** `payer_id`/`payee_id` is clearer than `user_id`. Added explicit `stripe_payment_intent_id` for reconciliation.

#### `payment_methods`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `profile_id` | `uuid` NOT NULL | references `profiles.id` |
| `stripe_pm_id` | `text` NOT NULL | Stripe PaymentMethod ID |
| `type` | `payment_type` NOT NULL | card/bank_account |
| `last4` | `text` | |
| `is_default` | `boolean` DEFAULT false | |
| `created_at` | `timestamptz` DEFAULT now() | |
| `deleted_at` | `timestamptz` | |

**Why:** `provider_token` → `stripe_pm_id`. Added `is_default` flag and soft delete.

#### `driver_documents`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `driver_id` | `uuid` NOT NULL | references `profiles.id` |
| `type` | `document_type` NOT NULL | |
| `file_url` | `text` NOT NULL | |
| `status` | `document_status` DEFAULT `pending` | |
| `rejection_reason` | `text` | |
| `issued_at` | `timestamptz` | |
| `expires_at` | `timestamptz` | |
| `created_at` | `timestamptz` DEFAULT now() | |
| `updated_at` | `timestamptz` DEFAULT now() | |
| `deleted_at` | `timestamptz` | |
| UNIQUE | `(driver_id, type)` | |

**Why:** Only soft deletes added. Renamed `driver_id` for consistency.

#### `vehicles`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `driver_id` | `uuid` NOT NULL | references `profiles.id` |
| `make` | `text` NOT NULL | |
| `model` | `text` NOT NULL | |
| `year` | `integer` NOT NULL | |
| `color` | `text` NOT NULL | |
| `license_plate` | `text` NOT NULL | |
| `is_active` | `boolean` DEFAULT true | |
| `created_at` | `timestamptz` DEFAULT now() | |
| `updated_at` | `timestamptz` DEFAULT now() | |
| `deleted_at` | `timestamptz` | |

**Why:** Added soft delete. Otherwise stable.

#### `reviews`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `ride_id` | `uuid` NOT NULL | references `rides.id` |
| `reviewer_id` | `uuid` NOT NULL | references `profiles.id` |
| `reviewee_id` | `uuid` NOT NULL | references `profiles.id` |
| `rating` | `integer` NOT NULL | CHECK (1–5) |
| `comment` | `text` | |
| `created_at` | `timestamptz` DEFAULT now() | |
| UNIQUE | `(ride_id, reviewer_id)` | |

**Why:** This table is already well-designed. Kept as-is.

#### `support_tickets`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `profile_id` | `uuid` NOT NULL | references `profiles.id` |
| `ride_id` | `uuid` | references `rides.id` ON DELETE SET NULL |
| `category` | `ticket_category` NOT NULL | |
| `subject` | `text` NOT NULL | |
| `description` | `text` NOT NULL | |
| `status` | `ticket_status` DEFAULT `open` | |
| `assigned_to` | `uuid` | references `profiles.id` — admin assignment |
| `created_at` | `timestamptz` DEFAULT now() | |
| `updated_at` | `timestamptz` DEFAULT now() | |
| `deleted_at` | `timestamptz` | |

**Why:** `user_id` → `profile_id`. Added `assigned_to` so admins can claim tickets.

#### `notifications`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | |
| `profile_id` | `uuid` NOT NULL | references `profiles.id` |
| `type` | `notification_type` NOT NULL | |
| `title` | `text` NOT NULL | |
| `body` | `text` | |
| `data` | `jsonb` | |
| `is_read` | `boolean` DEFAULT false | read/unread tracking |
| `delivery_status` | `text` DEFAULT `pending` | pending/sent/failed — delivery concern |
| `created_at` | `timestamptz` DEFAULT now() | |

**Why:** Split `status` into `is_read` (user-facing) and `delivery_status` (system-facing). `user_id` → `profile_id`.

#### `ledger_accounts` / `ledger_entries` / `driver_telemetry` / `surge_zones` / `device_biometrics` / `user_devices`
These tables are well-structured and only need `user_id` → `profile_id` renames and soft delete columns. No structural changes.

---

## Migration Strategy (Zero Downtime)

### Phase 1 — Create New Tables (side by side)
```sql
CREATE TABLE public.profiles ( ... );
CREATE TABLE public.driver_details ( ... );
-- Add new columns to existing tables (profile_id, deleted_at, etc.)
```
Old and new tables coexist. App writes to both.

### Phase 2 — Backfill
```sql
INSERT INTO public.profiles (id, first_name, last_name, phone_number, avatar_url, role, is_super_admin, created_at)
SELECT
  u.id,
  COALESCE(dp.first_name, pp.first_name) AS first_name,
  COALESCE(dp.last_name, pp.last_name) AS last_name,
  u.phone_number,
  COALESCE(dp.profile_image_url, pp.profile_image_url) AS avatar_url,
  u.role,
  u.is_super_admin,
  u.created_at
FROM public.users u
LEFT JOIN public.driver_profiles dp ON dp.user_id = u.id
LEFT JOIN public.passenger_profiles pp ON pp.user_id = u.id;
```

### Phase 3 — Update Application Code
- Update all queries to use `profiles` instead of `users`/`driver_profiles`/`passenger_profiles`
- Update all foreign key references from `user_id` → `profile_id`
- Add RLS policies mirroring old behavior

### Phase 4 — Drop Old Tables
```sql
DROP TABLE IF EXISTS public.passenger_profiles;
DROP TABLE IF EXISTS public.driver_profiles;
DROP TABLE IF EXISTS public.users;
-- Drop renamed columns after verifying no code references them
```

---

## Key Improvements Summary

| Concern | Before | After |
|---------|--------|-------|
| User data | 3 tables (`users` + `driver_profiles` + `passenger_profiles`) | 1 table (`profiles`) + 1 extension (`driver_details`) |
| FK naming | `user_id`, `driver_id`, `passenger_id`, `reviewer_id` mixed | Always `profile_id` or explicit `{role}_id` |
| Soft deletes | None | `deleted_at` on all major tables |
| Audit trail | No `cancelled_by` or `assigned_to` | Added `cancelled_by`, `cancelled_reason`, `assigned_to` |
| Notifications | Single `status` column | `is_read` + `delivery_status` separated |
| Payments | `user_id` ambiguous | `payer_id` / `payee_id` explicit |
| Payment methods | Vague `provider_token` | `stripe_pm_id` + `is_default` flag |
| Batch queue | Separate table duplicating `rides` | `rides.batch_status` column |
| Rating | No count, only average | `rating_count` added |
