// شلونكم چات - IQ | Shlonkum Chat - IQ
// Cloudflare Worker للإشعارات والتنبيهات الفورية عبر Supabase فقط

export interface Env {
  WEBHOOK_SECRET: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "GET") {
      return new Response(
        JSON.stringify({ ok: true, service: "Shlonkum Chat IQ - Notify Worker" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    if (request.method !== "POST") {
      return new Response("Method Not Allowed", { status: 405 });
    }

    const authHeader = request.headers.get("x-webhook-secret");
    if (!env.WEBHOOK_SECRET || authHeader !== env.WEBHOOK_SECRET) {
      return new Response("Unauthorized", { status: 401 });
    }

    try {
      const payload = (await request.json()) as {
        record?: {
          id?: string;
          chat_id?: string;
          sender_id?: string;
          body?: string;
        };
      };

      const record = payload.record ?? {};
      const messageText = (record.body ?? "رسالة جديدة في شلونكم چات - IQ").slice(0, 140);
      const chatId = record.chat_id ?? "general";

      return new Response(
        JSON.stringify({
          ok: true,
          title: "شلونكم چات - IQ",
          body: messageText,
          chat_id: String(chatId),
          message_id: String(record.id ?? ""),
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    } catch (err) {
      return new Response(
        JSON.stringify({ ok: false, error: String(err) }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
  },
};
