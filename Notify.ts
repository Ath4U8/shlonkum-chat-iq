export interface Env {
  WEBHOOK_SECRET?: string;
}

interface SupabaseMessageRecord {
  id?: string;
  sender_id?: string;
  receiver_id?: string;
  content?: string;
  created_at?: string;
}

interface NotifyPayload {
  type?: string;
  table?: string;
  schema?: string;
  record?: SupabaseMessageRecord;
  event?: string;
  recipient_id?: string;
  sender_id?: string;
  sender_name?: string;
  title?: string;
  body?: string;
}

function jsonResponse(data: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Webhook-Secret",
    },
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Webhook-Secret",
        },
      });
    }

    if (request.method === "GET") {
      return jsonResponse({
        ok: true,
        service: "shlonkum-chat-iq-notify",
        region_scope: "IQ",
      });
    }

    if (request.method !== "POST") {
      return jsonResponse({ ok: false, error: "Method not allowed" }, 405);
    }

    if (env.WEBHOOK_SECRET && env.WEBHOOK_SECRET.trim().length > 0) {
      const providedSecret = request.headers.get("X-Webhook-Secret") ?? "";
      if (providedSecret !== env.WEBHOOK_SECRET.trim()) {
        return jsonResponse({ ok: false, error: "Unauthorized webhook" }, 401);
      }
    }

    let payload: NotifyPayload;
    try {
      payload = (await request.json()) as NotifyPayload;
    } catch {
      return jsonResponse({ ok: false, error: "Invalid JSON payload" }, 400);
    }

    const record = payload.record ?? {};
    const recipientId = (payload.recipient_id ?? record.receiver_id ?? "").trim();
    const senderId = (payload.sender_id ?? record.sender_id ?? "").trim();
    const senderName = (payload.sender_name ?? "مستخدم شلونكم").trim();
    const rawBody = (payload.body ?? record.content ?? "").trim();

    if (!recipientId || !rawBody) {
      return jsonResponse(
        { ok: false, error: "recipient_id and body are required" },
        400
      );
    }

    const notification = {
      id: crypto.randomUUID(),
      event: (payload.event ?? payload.type ?? "new_message").trim(),
      recipient_id: recipientId,
      sender_id: senderId,
      title: (payload.title ?? `رسالة جديدة من ${senderName}`).trim(),
      body: rawBody.length > 160 ? `${rawBody.slice(0, 157)}...` : rawBody,
      timestamp: new Date().toISOString(),
    };

    return jsonResponse({
      ok: true,
      delivered: true,
      notification,
    });
  },
};
