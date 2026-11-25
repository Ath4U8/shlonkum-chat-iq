// شلونكم چات - IQ | Shlonkum Chat - IQ
// Cloudflare Worker للإشعارات عبر Firebase Cloud Messaging (FCM v1)
// يستقبل Webhook من Supabase عند إدراج رسالة جديدة في جدول messages

export interface Env {
  WEBHOOK_SECRET: string;
  FCM_PROJECT_ID: string;
  FCM_SERVICE_ACCOUNT_JSON: string;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

function base64UrlEncode(input: string | ArrayBuffer): string {
  const bytes =
    typeof input === "string"
      ? new TextEncoder().encode(input)
      : new Uint8Array(input);
  let binary = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const clean = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const binary = atob(clean);
  const buffer = new ArrayBuffer(binary.length);
  const view = new Uint8Array(buffer);
  for (let i = 0; i < binary.length; i++) {
    view[i] = binary.charCodeAt(i);
  }
  return buffer;
}

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64UrlEncode(
    JSON.stringify({
      iss: sa.client_email,
      sub: sa.client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    })
  );

  const unsignedToken = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedToken)
  );

  const jwt = `${unsignedToken}.${base64UrlEncode(signature)}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenRes.ok) {
    const errText = await tokenRes.text();
    throw new Error(`OAuth token error: ${errText}`);
  }

  const tokenData = (await tokenRes.json()) as { access_token: string };
  return tokenData.access_token;
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
      const body = (await request.json()) as {
        record?: {
          id?: string;
          chat_id?: string;
          sender_id?: string;
          body?: string;
        };
        fcm_token?: string;
        topic?: string;
      };

      const record = body.record ?? {};
      const messageText = (record.body ?? "رسالة جديدة في شلونكم چات - IQ").slice(0, 140);
      const chatId = record.chat_id ?? "general";

      const sa = JSON.parse(env.FCM_SERVICE_ACCOUNT_JSON) as ServiceAccount;
      const accessToken = await getGoogleAccessToken(sa);

      const target = body.fcm_token
        ? { token: body.fcm_token }
        : { topic: body.topic ?? `chat_${chatId}` };

      const fcmRes = await fetch(
        `https://fcm.googleapis.com/v1/projects/${env.FCM_PROJECT_ID}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              ...target,
              notification: {
                title: "شلونكم چات - IQ",
                body: messageText,
              },
              data: {
                chat_id: String(chatId),
                message_id: String(record.id ?? ""),
              },
            },
          }),
        }
      );

      const fcmResult = await fcmRes.text();
      return new Response(fcmResult, {
        status: fcmRes.status,
        headers: { "Content-Type": "application/json" },
      });
    } catch (err) {
      return new Response(
        JSON.stringify({ ok: false, error: String(err) }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
  },
};
