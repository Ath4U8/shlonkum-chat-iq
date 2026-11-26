function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status: status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Webhook-Secret"
    }
  });
}

async function handleWorkerRequest(request) {
  const secretEnv =
    typeof WEBHOOK_SECRET !== "undefined" ? String(WEBHOOK_SECRET).trim() : "";

  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Webhook-Secret"
      }
    });
  }

  if (request.method === "GET") {
    return jsonResponse({
      ok: true,
      service: "shlonkum-chat-iq-notify",
      region_scope: "IQ"
    });
  }

  if (request.method !== "POST") {
    return jsonResponse({ ok: false, error: "Method not allowed" }, 405);
  }

  if (secretEnv.length > 0) {
    const providedSecret = request.headers.get("X-Webhook-Secret") || "";
    if (providedSecret !== secretEnv) {
      return jsonResponse({ ok: false, error: "Unauthorized webhook" }, 401);
    }
  }

  let payload;
  try {
    payload = await request.json();
  } catch (e) {
    return jsonResponse({ ok: false, error: "Invalid JSON payload" }, 400);
  }

  const bodyObj = payload && typeof payload === "object" ? payload : {};
  const record =
    bodyObj.record && typeof bodyObj.record === "object" ? bodyObj.record : {};

  const recipientId = String(
    bodyObj.recipient_id || record.receiver_id || ""
  ).trim();
  const senderId = String(bodyObj.sender_id || record.sender_id || "").trim();
  const senderName = String(bodyObj.sender_name || "مستخدم شلونكم").trim();
  const rawBody = String(bodyObj.body || record.content || "").trim();

  if (!recipientId || !rawBody) {
    return jsonResponse(
      { ok: false, error: "recipient_id and body are required" },
      400
    );
  }

  const notification = {
    id: crypto.randomUUID(),
    event: String(bodyObj.event || bodyObj.type || "new_message").trim(),
    recipient_id: recipientId,
    sender_id: senderId,
    title: String(bodyObj.title || `رسالة جديدة من ${senderName}`).trim(),
    body: rawBody.length > 160 ? `${rawBody.slice(0, 157)}...` : rawBody,
    timestamp: new Date().toISOString()
  };

  return jsonResponse({
    ok: true,
    delivered: true,
    notification: notification
  });
}

addEventListener("fetch", (event) => {
  event.respondWith(handleWorkerRequest(event.request));
});
