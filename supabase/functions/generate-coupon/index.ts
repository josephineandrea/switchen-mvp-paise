// Supabase Edge Function: generate-coupon
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts";
import { encode as base64Encode } from "https://deno.land/std@0.168.0/encoding/base64url.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function generateQrToken(orderId: string): Promise<string> {
  const secret = Deno.env.get("QR_SECRET") ?? "switchen_qr_secret_2024";
  const nonce = crypto.randomUUID();
  const payload = `${orderId}:${nonce}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(payload)
  );
  const sigHex = Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .substring(0, 16);

  return base64Encode(`${payload}:${sigHex}`);
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

    const { order_id } = await req.json();

    // Cek apakah coupon sudah ada
    const { data: existing } = await supabase
      .from("coupons")
      .select("id, qr_token")
      .eq("order_id", order_id)
      .single();

    if (existing) {
      return new Response(JSON.stringify(existing), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Generate token
    const qrToken = await generateQrToken(order_id);

    // Insert coupon
    const { data: coupon, error } = await supabase
      .from("coupons")
      .insert({ order_id, qr_token: qrToken })
      .select()
      .single();

    if (error) throw error;

    // Kirim notifikasi ke consumer
    const { data: order } = await supabase
      .from("orders")
      .select("consumer_id, partner_id, partners(name)")
      .eq("id", order_id)
      .single();

    if (order) {
      await supabase.functions.invoke("send-notification", {
        body: {
          user_id: order.consumer_id,
          title: "Pembayaran Berhasil! 🎉",
          body: `Kupon QR kamu untuk ${order.partners?.name} sudah siap. Tunjukkan ke kasir!`,
        },
      });
    }

    return new Response(JSON.stringify(coupon), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});
