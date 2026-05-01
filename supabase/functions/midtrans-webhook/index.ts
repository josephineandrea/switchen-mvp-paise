// Supabase Edge Function: midtrans-webhook
// Deploy: supabase functions deploy midtrans-webhook
// Daftarkan URL ini di Midtrans Dashboard → Notification URL

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function sha512(str: string): Promise<string> {
  const msgBuffer = new TextEncoder().encode(str);
  const hashBuffer = await crypto.subtle.digest("SHA-512", msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
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

    const notification = await req.json();
    const {
      order_id,
      status_code,
      gross_amount,
      signature_key,
      transaction_status,
      payment_type,
    } = notification;

    // Verifikasi signature Midtrans
    const serverKey = Deno.env.get("MIDTRANS_SERVER_KEY")!;
    const expectedSignature = await sha512(
      `${order_id}${status_code}${gross_amount}${serverKey}`
    );

    if (signature_key !== expectedSignature) {
      console.error("Invalid Midtrans signature");
      return new Response(JSON.stringify({ error: "Invalid signature" }), {
        status: 401,
        headers: corsHeaders,
      });
    }

    // Tentukan status berdasarkan transaction_status
    let paymentStatus = "pending";
    let orderStatus = "pending";

    if (
      transaction_status === "capture" ||
      transaction_status === "settlement"
    ) {
      paymentStatus = "success";
      orderStatus = "paid";
    } else if (
      transaction_status === "cancel" ||
      transaction_status === "deny" ||
      transaction_status === "expire"
    ) {
      paymentStatus = "failed";
      orderStatus = "cancelled";
    }

    // Update payments
    await supabase
      .from("payments")
      .update({
        status: paymentStatus,
        paid_at: paymentStatus === "success" ? new Date().toISOString() : null,
      })
      .eq("midtrans_trx_id", order_id);

    // Get order info
    const { data: payment } = await supabase
      .from("payments")
      .select("order_id")
      .eq("midtrans_trx_id", order_id)
      .single();

    if (payment) {
      // Update order status
      await supabase
        .from("orders")
        .update({ status: orderStatus })
        .eq("id", payment.order_id);

      // Generate coupon jika berhasil bayar
      if (orderStatus === "paid") {
        const { error: fnError } = await supabase.functions.invoke(
          "generate-coupon",
          { body: { order_id: payment.order_id } }
        );
        if (fnError) console.error("Failed to generate coupon:", fnError);
      }
    }

    return new Response(JSON.stringify({ status: "ok" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});
