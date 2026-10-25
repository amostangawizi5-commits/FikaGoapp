-- Store the rider's driving licence number alongside their vehicle details.
ALTER TABLE rider_profiles
  ADD COLUMN IF NOT EXISTS license_number TEXT,
  ADD COLUMN IF NOT EXISTS license_plate TEXT,
  ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'pending';

UPDATE rider_profiles
SET approval_status = CASE WHEN is_approved THEN 'approved' ELSE 'pending' END
WHERE approval_status = 'pending';
