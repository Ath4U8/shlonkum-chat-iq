// Shlonkum Chat - IQ - Cloudflare Worker
// وظيفة: إرسال إشعار عند نشر منشور جديد بقناة رسمية
// المرحلة الأولى: سحابي فقط
export default {
  async fetch(request: Request) {
    return new Response("Shlonkum Chat - IQ Worker is running - Iraq 18 governorates");
  }
}
