# Unused Database Architecture

An audit of the SQL migration files against the Flutter application codebase (`app/lib`) and the React admin dashboard (`website/src`) reveals a major disconnect between the database architecture and the actual implementation.

Specifically, the migration file `20260417000000_nextgen_features.sql` sets up advanced tables that are **never referenced or queried** by any client applications.

## Unused Tables

### 1. High-Frequency Telemetry Data Lake
- **Table:** `driver_telemetry`
- **Issue:** The database expects drivers to constantly ping their location, speed, and heading to this table for advanced tracking. However, the Flutter app does not implement background location tracking or telemetry uploading for this purpose.

### 2. Immutable Double-Entry Ledger (Wallet)
- **Tables:** `ledger_accounts`, `ledger_entries`
- **Issue:** The database contains schema for a highly advanced internal wallet system utilizing double-entry accounting. The app, however, relies entirely on the basic `payment_methods` and `transactions` tables. There is no UI or backend logic integrated to view wallet balances or process ledger entries.

### 3. Intelligent Batch Dispatching
- **Table:** `ride_batch_queue`
- **Issue:** The database supports queuing rides for batched, algorithmic driver assignments. The app, conversely, utilizes a basic instant dispatching flow and never inserts into or queries this batch queue.

### 4. Real-Time Dynamic Surge Engine
- **Table:** `surge_zones`
- **Issue:** The database possesses tables and RPCs designed to calculate and store surge pricing based on supply/demand geofences (hex grids). The app does not query these surge zones, nor does it display them on the driver map.

## Recommendations
The database is structured for a "Next-Gen" enterprise architecture, but the app is only wired up to utilize the core "Phase 1" features. 
- If the goal is to keep the application lightweight and stable, it is highly recommended to **delete or roll back** the `20260417000000_nextgen_features.sql` migration to prevent database bloat and confusion.
- If the features are intended for a future roadmap, they will require massive new systems to be built within the Flutter app to utilize them properly.
