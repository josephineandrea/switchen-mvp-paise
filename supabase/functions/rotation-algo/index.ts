// Supabase Edge Function: rotation-algo
// Deploy: supabase functions deploy rotation-algo
// Path: supabase/functions/rotation-algo/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RotationRequest {
  consumer_id: string;
  lat: number;
  lng: number;
  radius_km?: number;
}

// Haversine formula untuk hitung jarak
function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const body: RotationRequest = await req.json();
    const { consumer_id, lat, lng, radius_km = 5.0 } = body;

    // 1. Ambil semua partner aktif yang punya produk tersedia
    const { data: partners } = await supabase
      .from("partners")
      .select(`
        id, name, address, lat, lng, category, logo_url, rotation_weight,
        products(count)
      `)
      .eq("status", "active");

    if (!partners || partners.length === 0) {
      return new Response(JSON.stringify([]), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Filter by radius
    const nearbyPartners = partners
      .map((p) => ({
        ...p,
        distance_km: haversineKm(lat, lng, p.lat, p.lng),
        available_products: p.products?.[0]?.count ?? 0,
      }))
      .filter((p) => p.distance_km <= radius_km && p.available_products > 0);

    // 3. Ambil histori view consumer (30 hari terakhir)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const { data: viewHistory } = await supabase
      .from("store_views")
      .select("partner_id, purchased")
      .eq("consumer_id", consumer_id)
      .gte("viewed_at", thirtyDaysAgo);

    const viewCounts = new Map<string, number>();
    const purchasedSet = new Set<string>();

    (viewHistory ?? []).forEach((v) => {
      viewCounts.set(v.partner_id, (viewCounts.get(v.partner_id) ?? 0) + 1);
      if (v.purchased) purchasedSet.add(v.partner_id);
    });

    // 4. Scoring algorithm
    // score = (rotation_weight * 0.4) + (distance_score * 0.3) + (freshness_score * 0.3)
    const maxDistance = Math.max(...nearbyPartners.map((p) => p.distance_km), 1);

    const scored = nearbyPartners.map((p) => {
      const distanceScore = (1 - p.distance_km / maxDistance) * 100;
      const viewCount = viewCounts.get(p.id) ?? 0;
      const freshnessScore = Math.max(0, 100 - viewCount * 15);
      const rotationScore = p.rotation_weight;

      const totalScore =
        rotationScore * 0.4 + distanceScore * 0.3 + freshnessScore * 0.3;

      return { ...p, score: totalScore };
    });

    // 5. Sort by score DESC
    const result = scored
      .sort((a, b) => b.score - a.score)
      .slice(0, 10)
      .map(({ score, products, ...p }) => p);

    // 6. Log view untuk tracking
    if (result.length > 0) {
      await supabase.from("store_views").insert(
        result.map((p) => ({
          consumer_id,
          partner_id: p.id,
          purchased: false,
        }))
      );
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
