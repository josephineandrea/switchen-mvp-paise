-- ============================================================
-- SWITCHEN MVP - SUPABASE DATABASE SCHEMA
-- Jalankan file ini di Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. PROFILES
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   TEXT NOT NULL,
  phone       TEXT,
  role        TEXT NOT NULL DEFAULT 'consumer'
                CHECK (role IN ('consumer', 'partner', 'admin')),
  fcm_token   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on user register
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Pengguna Baru'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'consumer')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- 2. PARTNERS
-- ============================================================
CREATE TABLE IF NOT EXISTS partners (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  name             TEXT NOT NULL,
  address          TEXT NOT NULL,
  lat              FLOAT8 NOT NULL,
  lng              FLOAT8 NOT NULL,
  category         TEXT NOT NULL
                     CHECK (category IN ('restaurant', 'cafe', 'bakery')),
  status           TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'active', 'suspended')),
  rotation_weight  INT2 NOT NULL DEFAULT 100 CHECK (rotation_weight >= 0),
  logo_url         TEXT,
  description      TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for geo queries
CREATE INDEX IF NOT EXISTS idx_partners_location ON partners (lat, lng);
CREATE INDEX IF NOT EXISTS idx_partners_status ON partners (status);

-- ============================================================
-- 3. PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id      UUID NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  image_url       TEXT,
  original_price  NUMERIC(10,2) NOT NULL CHECK (original_price > 0),
  surplus_price   NUMERIC(10,2) NOT NULL CHECK (surplus_price > 0),
  stock_qty       INT4 NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
  expired_at      TIMESTAMPTZ,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT surplus_less_than_original CHECK (surplus_price < original_price)
);

CREATE INDEX IF NOT EXISTS idx_products_partner ON products (partner_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products (is_active, stock_qty);

-- ============================================================
-- 4. STORE VIEWS (untuk rotation algorithm)
-- ============================================================
CREATE TABLE IF NOT EXISTS store_views (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consumer_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  partner_id   UUID NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  viewed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  purchased    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_store_views_consumer ON store_views (consumer_id, viewed_at DESC);

-- ============================================================
-- 5. ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consumer_id  UUID NOT NULL REFERENCES profiles(id),
  product_id   UUID NOT NULL REFERENCES products(id),
  partner_id   UUID NOT NULL REFERENCES partners(id),
  qty          INT4 NOT NULL DEFAULT 1 CHECK (qty > 0),
  total_price  NUMERIC(10,2) NOT NULL CHECK (total_price > 0),
  status       TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'paid', 'completed', 'cancelled')),
  reserved_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at   TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '15 minutes'
);

CREATE INDEX IF NOT EXISTS idx_orders_consumer ON orders (consumer_id, reserved_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_partner ON orders (partner_id, reserved_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);

-- Auto-reduce stock on order
CREATE OR REPLACE FUNCTION reduce_stock_on_order()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE products
  SET stock_qty = stock_qty - NEW.qty,
      updated_at = NOW()
  WHERE id = NEW.product_id
    AND stock_qty >= NEW.qty;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Stok tidak mencukupi';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS after_order_insert ON orders;
CREATE TRIGGER after_order_insert
  AFTER INSERT ON orders
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION reduce_stock_on_order();

-- Restore stock on order cancel
CREATE OR REPLACE FUNCTION restore_stock_on_cancel()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status != 'cancelled' AND NEW.status = 'cancelled' THEN
    UPDATE products
    SET stock_qty = stock_qty + OLD.qty,
        updated_at = NOW()
    WHERE id = OLD.product_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS after_order_cancel ON orders;
CREATE TRIGGER after_order_cancel
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION restore_stock_on_cancel();

-- ============================================================
-- 6. COUPONS
-- ============================================================
CREATE TABLE IF NOT EXISTS coupons (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id  UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
  qr_token  TEXT NOT NULL UNIQUE,
  status    TEXT NOT NULL DEFAULT 'active'
              CHECK (status IN ('active', 'used', 'expired')),
  used_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_coupons_qr ON coupons (qr_token);

-- ============================================================
-- 7. PAYMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id         UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  midtrans_trx_id  TEXT,
  midtrans_url     TEXT,
  status           TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'success', 'failed', 'expired')),
  amount           NUMERIC(10,2) NOT NULL,
  paid_at          TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_order ON payments (order_id);

-- ============================================================
-- 8. NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title    TEXT NOT NULL,
  body     TEXT NOT NULL,
  is_read  BOOLEAN NOT NULL DEFAULT FALSE,
  sent_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id, sent_at DESC);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Function to safely check if user is admin without causing infinite recursion
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$;

-- profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admin can view all profiles" ON profiles
  FOR ALL USING (is_admin());

-- partners (public read for active)
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active partners" ON partners
  FOR SELECT USING (status = 'active');
CREATE POLICY "Partner can manage own store" ON partners
  FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Admin full access to partners" ON partners
  FOR ALL USING (is_admin());

-- products (public read for active)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active products" ON products
  FOR SELECT USING (is_active = TRUE AND stock_qty > 0);
CREATE POLICY "Partner can manage own products" ON products
  FOR ALL USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY "Admin full access to products" ON products
  FOR ALL USING (is_admin());

-- orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Consumer can view own orders" ON orders
  FOR SELECT USING (consumer_id = auth.uid());
CREATE POLICY "Consumer can create orders" ON orders
  FOR INSERT WITH CHECK (consumer_id = auth.uid());
CREATE POLICY "Partner can view their orders" ON orders
  FOR SELECT USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY "Admin full access to orders" ON orders
  FOR ALL USING (is_admin());

-- coupons
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Consumer can view own coupons" ON coupons
  FOR SELECT USING (
    order_id IN (SELECT id FROM orders WHERE consumer_id = auth.uid())
  );
CREATE POLICY "Partner can validate coupons" ON coupons
  FOR UPDATE USING (
    order_id IN (
      SELECT o.id FROM orders o
      JOIN partners p ON o.partner_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

-- payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Consumer can view own payments" ON payments
  FOR SELECT USING (
    order_id IN (SELECT id FROM orders WHERE consumer_id = auth.uid())
  );

-- store_views
ALTER TABLE store_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Consumer can insert own views" ON store_views
  FOR INSERT WITH CHECK (consumer_id = auth.uid());
CREATE POLICY "Consumer can view own history" ON store_views
  FOR SELECT USING (consumer_id = auth.uid());

-- notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can mark own as read" ON notifications
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Admin can insert notifications" ON notifications
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- REALTIME
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================================
-- SEED DATA (Dummy Data Komplit Semua Tabel)
-- ============================================================

-- 1. Create Dummy Auth Users (Password: password123)
INSERT INTO auth.users (id, aud, role, email, encrypted_password, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
VALUES 
  ('a1111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'admin@switchen.com', crypt('password123', gen_salt('bf')), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{"full_name": "Admin Switchen", "role": "admin"}'),
  ('b2222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'partner@switchen.com', crypt('password123', gen_salt('bf')), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{"full_name": "Toko Roti Braga", "role": "partner"}'),
  ('c3333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'consumer@switchen.com', crypt('password123', gen_salt('bf')), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{"full_name": "Jane Doe", "role": "consumer"}')
ON CONFLICT (id) DO NOTHING;

-- 2. Profiles (Mungkin sudah terisi karena trigger, ini untuk fallback)
INSERT INTO profiles (id, full_name, phone, role)
VALUES 
  ('a1111111-1111-1111-1111-111111111111', 'Admin Switchen', '08111111111', 'admin'),
  ('b2222222-2222-2222-2222-222222222222', 'Toko Roti Braga', '08222222222', 'partner'),
  ('c3333333-3333-3333-3333-333333333333', 'Jane Doe', '08333333333', 'consumer')
ON CONFLICT (id) DO NOTHING;

-- 3. Partners
INSERT INTO partners (id, user_id, name, address, lat, lng, category, status, logo_url, description)
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'b2222222-2222-2222-2222-222222222222', 'Toko Roti Braga', 'Jl. Braga No. 99, Bandung', -6.917464, 107.609673, 'bakery', 'active', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&q=80', 'Roti hangat setiap hari'),
  ('22222222-2222-2222-2222-222222222222', NULL, 'Warung Sari Rasa', 'Jl. Dipatiukur No. 12', -6.890632, 107.616335, 'restaurant', 'active', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200&q=80', 'Masakan rumahan'),
  ('33333333-3333-3333-3333-333333333333', NULL, 'Green Bowl Café', 'Jl. Riau No. 55', -6.906935, 107.620025, 'cafe', 'active', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200&q=80', 'Healthy food and salad')
ON CONFLICT (id) DO NOTHING;

-- 4. Products
INSERT INTO products (id, partner_id, name, image_url, original_price, surplus_price, stock_qty, is_active)
VALUES
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Butter Croissant', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&q=80', 25000, 10000, 5, true),
  ('a2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Roti Coklat Lumer', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80', 18000, 8000, 3, true),
  ('a3333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'Nasi Kotak Ayam Penyet', 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&q=80', 30000, 15000, 10, true),
  ('a4444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'Salad Sayur Organik', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80', 45000, 20000, 2, true)
ON CONFLICT (id) DO NOTHING;

-- 5. Orders
INSERT INTO orders (id, consumer_id, product_id, partner_id, qty, total_price, status)
VALUES
  ('b1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 2, 20000, 'paid'),
  ('b2222222-2222-2222-2222-222222222222', 'c3333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 1, 15000, 'pending')
ON CONFLICT (id) DO NOTHING;

-- 6. Coupons
INSERT INTO coupons (id, order_id, qr_token, status)
VALUES
  ('c1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'QR-o1111111', 'active')
ON CONFLICT (id) DO NOTHING;

-- 7. Payments
INSERT INTO payments (id, order_id, midtrans_trx_id, status, amount)
VALUES
  ('d1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'TRX-12345', 'success', 20000)
ON CONFLICT (id) DO NOTHING;

-- 8. Notifications
INSERT INTO notifications (id, user_id, title, body, is_read)
VALUES
  ('e1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 'Pesanan Dikonfirmasi', 'Pesanan Butter Croissant Anda berhasil dibayar.', false),
  ('e2222222-2222-2222-2222-222222222222', 'b2222222-2222-2222-2222-222222222222', 'Pesanan Baru', 'Ada pesanan baru masuk dari Jane Doe.', false)
ON CONFLICT (id) DO NOTHING;

-- 9. Store Views
INSERT INTO store_views (id, consumer_id, partner_id, purchased)
VALUES
  ('f1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', true)
ON CONFLICT (id) DO NOTHING;
