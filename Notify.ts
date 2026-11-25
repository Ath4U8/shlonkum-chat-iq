// شلونكم چات - IQ - Notify.ts
// Cloudflare Worker - الإشعارات
// التحديث الأخير: عام لكل العراق - بدون أسماء محافظات
// لا تذكر 18 محافظة في أي رسالة

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === '/health') {
      return new Response('Shlonkum Chat - IQ Worker is running - Iraq', {
        headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      });
    }
    if (url.pathname === '/notify' && request.method === 'POST') {
      // هنا يرسل الإشعار عبر Supabase / FCM
      // للمرحلة الأولى نرجع نجاح فقط
      return new Response(JSON.stringify({ ok: true, message: 'Notification received' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }
    return new Response('Shlonkum Chat - IQ Worker is running - Iraq', {
      headers: { 'Content-Type': 'text/plain; charset=utf-8' },
    });
  },
};
