// Supabase Edge Function: send-notification
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface NotifRequest {
  user_id?: string;        // kirim ke 1 user
  user_ids?: string[];     // kirim ke banyak user
  broadcast?: boolean;     // kirim ke semua user
  title: string;
  body: string;
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

    const payload: NotifRequest = await req.json();
    const { title, body, user_id, user_ids, broadcast } = payload;

    // Tentukan target user IDs
    let targetUserIds: string[] = [];

    if (broadcast) {
      const { data } = await supabase
        .from("profiles")
        .select("id")
        .not("fcm_token", "is", null);
      targetUserIds = (data ?? []).map((p) => p.id);
    } else if (user_ids) {
      targetUserIds = user_ids;
    } else if (user_id) {
      targetUserIds = [user_id];
    }

    if (targetUserIds.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Ambil FCM tokens
    const { data: profiles } = await supabase
      .from("profiles")
      .select("id, fcm_token")
      .in("id", targetUserIds)
      .not("fcm_token", "is", null);

    const tokens = (profiles ?? []).map((p) => p.fcm_token as string);

    // Kirim FCM
    const fcmKey = Deno.env.get("FCM_SERVER_KEY")!;
    let sent = 0;

    // Send in batches of 500 (FCM limit)
    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      const fcmPayload = {
        registration_ids: batch,
        notification: { title, body },
        data: { title, body },
      };

      const fcmRes = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          Authorization: `key=${fcmKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      });

      if (fcmRes.ok) sent += batch.length;
    }

    // Save to notifications table
    await supabase.from("notifications").insert(
      targetUserIds.map((uid) => ({ user_id: uid, title, body }))
    );

    return new Response(JSON.stringify({ sent }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});
