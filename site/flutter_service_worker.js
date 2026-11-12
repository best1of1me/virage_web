// ---------------------------------------------------------------------------
// عامل خدمة "منتحر" (self-destructing service worker)
// ---------------------------------------------------------------------------
// الإصدارات القديمة من الموقع كانت تسجّل عامل خدمة يخزّن نسخة Flutter كاملة
// (CanvasKit + main.dart.js). بعد الانتقال إلى الصفحة الثابتة، بقي الزائر
// القديم يرى النسخة الثقيلة القديمة من الكاش، لأن Flutter مع
// --pwa-strategy=none يولّد ملفاً فارغاً لا يستطيع المتصفح تحديث العامل به.
//
// هذا الملف يُنشر مكان الملف القديم بنفس المسار، فيُحدّث المتصفح العامل،
// ثم يحذف كل الكاشات ويلغي تسجيل نفسه ويعيد تحميل الصفحات المفتوحة مرة واحدة.
// ---------------------------------------------------------------------------

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    (async function () {
      try {
        var keys = await caches.keys();
        await Promise.all(
          keys.map(function (key) {
            return caches.delete(key);
          })
        );
      } catch (e) {
        // تجاهل: بعض المتصفحات تمنع الوصول إلى caches هنا
      }

      try {
        await self.registration.unregister();
      } catch (e) {
        // تجاهل
      }

      try {
        var clients = await self.clients.matchAll({ type: 'window' });
        clients.forEach(function (client) {
          client.navigate(client.url).catch(function () {});
        });
      } catch (e) {
        // تجاهل
      }
    })()
  );
});
