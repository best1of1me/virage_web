/* ==========================================================================
   VIRAGE — لوحة تحكم مدارس السياقة (نسخة HTML)
   --------------------------------------------------------------------------
   - لا Flutter ولا CanvasKit: DOM + CSS فقط.
   - نفس مشروع Supabase ونفس جداول البيانات ونفس روابط Google OAuth.
   - تعمل على /app-v2/ أثناء التجربة، ثم تُنقل إلى /app/ عند التبديل.
   ========================================================================== */

const SUPABASE_URL = "https://gwafzhdtrqvwakawjmwm.supabase.co";
const SUPABASE_KEY = "sb_publishable_gomM_R_xF7mG4hHuFblFmQ_RG6ZXSB-";
const SUPABASE_CDN = "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
const SUPABASE_CDNS = [
  SUPABASE_CDN,
  "https://esm.sh/@supabase/supabase-js@2",
];
const CHECKOUT_API = "https://virage-backend.onrender.com/api/create-checkout";
const NOMINATIM = "https://nominatim.openstreetmap.org";

const PRICE_PER_CODE = 200;
const PACKAGES = [5, 10, 25, 50, 100];

const THEME_KEY = "virage_theme_mode";
const NOTIF_KEY = "virage_notifications_enabled";
const EMAIL_KEY = "virage_email_alerts_enabled";

/* وضع تجريبي محلي فقط (لا يعمل على الإنتاج): ?demo=1 */
const IS_LOCAL =
  location.hostname === "127.0.0.1" || location.hostname === "localhost";
const DEMO = IS_LOCAL && new URLSearchParams(location.search).has("demo");

/* -------------------------------------------------------------------------- */
/* أيقونات SVG                                                                */
/* -------------------------------------------------------------------------- */

const svg = (paths) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths}</svg>`;

const ICONS = {
  home: svg('<rect x="3" y="3" width="7" height="7" rx="1.6"/><rect x="14" y="3" width="7" height="7" rx="1.6"/><rect x="14" y="14" width="7" height="7" rx="1.6"/><rect x="3" y="14" width="7" height="7" rx="1.6"/>'),
  user: svg('<circle cx="12" cy="8" r="3.5"/><path d="M4.5 20c1.6-3.4 4.4-5 7.5-5s5.9 1.6 7.5 5"/>'),
  mail: svg('<rect x="3" y="5" width="18" height="14" rx="2.2"/><path d="m3.6 6.6 8.4 6 8.4-6"/>'),
  chart: svg('<path d="M3 3v18h18"/><path d="m7 14 3.6-4 3 2.8L20 6"/>'),
  gift: svg('<rect x="3" y="8" width="18" height="4" rx="1.2"/><path d="M5 12v8h14v-8"/><path d="M12 8v12"/><path d="M12 8C12 5 9 4 8 5.5S8.6 8 12 8Z"/><path d="M12 8c0-3 3-4 4-2.5S15.4 8 12 8Z"/>'),
  settings: svg('<circle cx="12" cy="12" r="3.1"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.87l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06A1.7 1.7 0 0 0 15 19.36a1.7 1.7 0 0 0-1 1.55V21a2 2 0 1 1-4 0v-.09A1.7 1.7 0 0 0 8.9 19.36a1.7 1.7 0 0 0-1.87.34l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.7 1.7 0 0 0 4.64 15a1.7 1.7 0 0 0-1.55-1H3a2 2 0 1 1 0-4h.09A1.7 1.7 0 0 0 4.64 8.9a1.7 1.7 0 0 0-.34-1.87l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.7 1.7 0 0 0 9 4.64a1.7 1.7 0 0 0 1-1.55V3a2 2 0 1 1 4 0v.09a1.7 1.7 0 0 0 1 1.55 1.7 1.7 0 0 0 1.87-.34l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.7 1.7 0 0 0 19.36 9v.09a1.7 1.7 0 0 0 1.55 1H21a2 2 0 1 1 0 4h-.09a1.7 1.7 0 0 0-1.51 1Z"/>'),
  logout: svg('<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>'),
  moon: svg('<path d="M21 12.8A8.5 8.5 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z"/>'),
  sun: svg('<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>'),
  search: svg('<circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/>'),
  refresh: svg('<path d="M21 12a9 9 0 1 1-2.64-6.36"/><path d="M21 3v6h-6"/>'),
  copy: svg('<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>'),
  check: svg('<path d="m20 6-11 11-5-5"/>'),
  clock: svg('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),
  x: svg('<path d="m6 6 12 12M18 6 6 18"/>'),
  ticket: svg('<path d="M3 9V7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2a3 3 0 0 0 0 6v2a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2a3 3 0 0 0 0-6Z"/><path d="M13 5v2m0 4v2m0 4v2"/>'),
  plus: svg('<path d="M12 5v14M5 12h14"/>'),
  menu: svg('<path d="M4 7h16M4 12h16M4 17h16"/>'),
  chevronLeft: svg('<path d="m15 18-6-6 6-6"/>'),
  chevronRight: svg('<path d="m9 18 6-6-6-6"/>'),
  upload: svg('<path d="M12 16V4m0 0L7 9m5-5 5 5"/><path d="M4 16v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2"/>'),
  mapPin: svg('<path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="3"/>'),
  external: svg('<path d="M14 3h7v7"/><path d="M10 14 21 3"/><path d="M21 14v5a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5"/>'),
  users: svg('<circle cx="9" cy="8" r="3.2"/><path d="M3 20c1.4-3 3.8-4.5 6-4.5S13.6 17 15 20"/><path d="M16 4.2a3.2 3.2 0 0 1 0 6.2"/><path d="M17.5 15.6c1.6.6 2.8 2 3.5 4.4"/>'),
  shield: svg('<path d="M12 22s8-3.5 8-10V5l-8-3-8 3v7c0 6.5 8 10 8 10Z"/><path d="m9 12 2 2 4-4"/>'),
  alert: svg('<path d="M10.3 3.6 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.6a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4m0 4h.01"/>'),
  sparkles: svg('<path d="M12 3v4m0 10v4M3 12h4m10 0h4"/><path d="m5.6 5.6 2.8 2.8m7.2 7.2 2.8 2.8m0-12.8-2.8 2.8M8.4 15.6l-2.8 2.8"/>'),
  link: svg('<path d="M10 13a5 5 0 0 0 7.1 0l3-3a5 5 0 0 0-7.1-7.1l-1.6 1.6"/><path d="M14 11a5 5 0 0 0-7.1 0l-3 3A5 5 0 0 0 11 21.1l1.6-1.6"/>'),
  lock: svg('<rect x="4" y="10" width="16" height="11" rx="2.2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>'),
  wallet: svg('<path d="M20 7H5a2 2 0 0 1 0-4h13v4"/><path d="M3 5v14a2 2 0 0 0 2 2h15V7H5"/><path d="M16 13h.01"/>'),
  bar: svg('<path d="M6 20V10m6 10V4m6 16v-6"/>'),
  eye: svg('<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>'),
};

/* -------------------------------------------------------------------------- */
/* أدوات مساعدة                                                               */
/* -------------------------------------------------------------------------- */

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

const esc = (value) =>
  String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");

const uid = () => state.session?.user?.id ?? "";

const shortId = (id) => (id ? id.slice(0, 6).toUpperCase() : "");

const initials = (name) => {
  const value = String(name ?? "").trim();
  return value ? value[0].toUpperCase() : "V";
};

const firstRow = (value) => (Array.isArray(value) ? (value[0] ?? null) : value);

const debounce = (fn, wait = 140) => {
  let timer = 0;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), wait);
  };
};

const normalizeStatus = (raw) => {
  const s = String(raw ?? "").trim().toLowerCase();
  if (["unused", "متاح", "active", "available"].includes(s)) return "متاح";
  if (["activated", "used", "مستعمل"].includes(s)) return "مستعمل";
  if (["expired", "منتهي"].includes(s)) return "منتهي";
  return raw ? String(raw) : "متاح";
};

const fmtDate = (value) => {
  if (!value) return "—";
  const text = String(value);
  if (/^\d{4}-\d{2}-\d{2}/.test(text)) return text.slice(0, 10);
  const d = new Date(text);
  if (Number.isNaN(d.getTime())) return text;
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${d.getFullYear()}-${m}-${day}`;
};

const daysAgo = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return 0;
  return Math.max(0, Math.round((Date.now() - d.getTime()) / 86400000));
};

const money = (n) => `${Number(n).toLocaleString("fr-DZ")} دج`;

/** صياغة عربية سليمة لعدد الأكواد. */
const codesWord = (n) => {
  if (n === 1) return "كود واحد";
  if (n === 2) return "كودين";
  if (n >= 3 && n <= 10) return `${n} أكواد`;
  return `${n} كوداً`;
};

const statusBadge = (status) => {
  if (status === "متاح")
    return `<span class="badge badge-success">${ICONS.check}متاح</span>`;
  if (status === "مستعمل")
    return `<span class="badge badge-warning">${ICONS.clock}مستعمل</span>`;
  if (status === "منتهي")
    return `<span class="badge badge-danger">${ICONS.x}منتهي</span>`;
  return `<span class="badge badge-neutral">${esc(status)}</span>`;
};

/* ------------------------------- التوستات --------------------------------- */

function toast(message, type = "info", ms = 4600) {
  const box = $("#toasts");
  if (!box) return;
  const map = {
    success: ICONS.check,
    error: ICONS.alert,
    warning: ICONS.alert,
    info: ICONS.sparkles,
  };
  const el = document.createElement("div");
  el.className = `toast ${type}`;
  el.innerHTML = `${map[type] ?? ICONS.sparkles}<div>${esc(message)}</div>`;
  box.appendChild(el);
  setTimeout(() => {
    el.style.opacity = "0";
    el.style.transform = "translateY(8px)";
    el.style.transition = "0.25s ease";
    setTimeout(() => el.remove(), 260);
  }, ms);
}

async function copyText(text, okMessage = "تم النسخ إلى الحافظة") {
  const value = String(text ?? "").trim();
  if (!value) {
    toast("لا يوجد شيء لنسخه", "warning");
    return false;
  }

  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(value);
      toast(okMessage, "success", 2200);
      return true;
    }
  } catch {
    /* ننتقل إلى الطريقة الاحتياطية أدناه */
  }

  try {
    const ta = document.createElement("textarea");
    ta.value = value;
    ta.setAttribute("readonly", "");
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    const done = document.execCommand("copy");
    ta.remove();
    if (!done) throw new Error("copy");
    toast(okMessage, "success", 2200);
    return true;
  } catch {
    toast("تعذر النسخ. انسخ الكود يدوياً.", "error");
    return false;
  }
}

/* -------------------------------- النوافذ --------------------------------- */

let modalEscHandler = null;

function closeModal() {
  $("#modal-root").innerHTML = "";
  if (modalEscHandler) {
    document.removeEventListener("keydown", modalEscHandler);
    modalEscHandler = null;
  }
}

function openModal({ title, body, actions = [], tone = "" }) {
  closeModal();
  const root = $("#modal-root");
  root.innerHTML = `
    <div class="modal-back" data-close="1">
      <div class="modal" role="dialog" aria-modal="true" aria-label="${esc(title)}">
        <div class="modal-head">
          <span class="icon-chip" style="width:34px;height:34px">${tone === "error" ? ICONS.alert : ICONS.sparkles}</span>
          <span>${esc(title)}</span>
          <button class="btn-icon" style="margin-inline-start:auto" data-close="1" aria-label="إغلاق">${ICONS.x}</button>
        </div>
        <div class="modal-body">${body}</div>
        <div class="modal-foot">${actions
          .map(
            (a, i) =>
              `<button class="btn ${a.class ?? "btn-primary"}" data-action="${i}">${a.label}</button>`,
          )
          .join("")}</div>
      </div>
    </div>`;
  root.querySelectorAll("[data-close]").forEach((el) => {
    el.addEventListener("click", (event) => {
      if (el.classList.contains("modal-back") && event.target !== el) return;
      closeModal();
    });
  });
  actions.forEach((a, i) => {
    const btn = root.querySelector(`[data-action="${i}"]`);
    btn?.addEventListener("click", () => {
      if (a.onClick) a.onClick();
      else closeModal();
    });
  });
  modalEscHandler = (event) => {
    if (event.key === "Escape") closeModal();
  };
  document.addEventListener("keydown", modalEscHandler);
}

/* --------------------------------- الثيم ---------------------------------- */

function resolveTheme(mode) {
  if (mode === "dark" || mode === "light") return mode;
  return window.matchMedia?.("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

function applyTheme(mode) {
  document.documentElement.dataset.theme = resolveTheme(mode);
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) {
    meta.setAttribute(
      "content",
      document.documentElement.dataset.theme === "dark" ? "#101417" : "#0F4C81",
    );
  }
}

function getThemeMode() {
  return localStorage.getItem(THEME_KEY) || "system";
}

function setThemeMode(mode) {
  localStorage.setItem(THEME_KEY, mode);
  applyTheme(mode);
  $$(".segmented [data-theme-mode]").forEach((btn) => {
    btn.classList.toggle("is-active", btn.dataset.themeMode === mode);
  });
  toast(
    mode === "system"
      ? "تم تفعيل نمط النظام"
      : mode === "dark"
        ? "تم تفعيل الوضع الداكن"
        : "تم تفعيل الوضع الفاتح",
    "success",
    1800,
  );
}

/* -------------------------------------------------------------------------- */
/* الحالة                                                                     */
/* -------------------------------------------------------------------------- */

const state = {
  supabase: null,
  session: null,
  route: "",
  profile: null,
  codes: [],
  analyticsCodes: [],
  analyticsPeriod: "month",
  referredBy: null,
  selected: new Set(),
  search: "",
  filter: "الكل",
  sort: "newest",
  page: 1,
  pageSize: 10,
  pkg: 10,
  demoAvatar: null,
  map: null,
  mapMarker: null,
  busy: false,
};

const NAV = [
  { route: "dashboard", label: "الرئيسية", icon: "home", title: "الرئيسية" },
  { route: "analytics", label: "التحليلات", icon: "chart", title: "التحليلات" },
  { route: "referral", label: "الإحالة", icon: "gift", title: "برنامج الإحالة" },
  { route: "profile", label: "الملف الشخصي", icon: "user", title: "الملف الشخصي" },
  { route: "contact", label: "التواصل", icon: "mail", title: "التواصل والدعم" },
  { route: "settings", label: "الإعدادات", icon: "settings", title: "الإعدادات" },
];

/* -------------------------------------------------------------------------- */
/* الدخول                                                                     */
/* -------------------------------------------------------------------------- */

function oauthRedirectUrl() {
  return `${new URL(".", location.href).href}#/dashboard`;
}

/** جذر الموقع التسويقي، سواء كنا على /app-v2/ الآن أو /app/ بعد التبديل. */
function siteRootUrl() {
  return `${location.origin}${location.pathname.replace(/\/(?:app-v2|app)\/$/, "/")}`;
}

function renderLogin(errorMessage = "") {
  const root = $("#root");
  root.innerHTML = `
    <div class="login">
      <div>
        <div class="login-card">
          <img class="login-logo" src="../assets/icon-192.png" alt="شعار VIRAGE" width="76" height="76" />
          <div class="login-brand">VIRAGE</div>
          <div class="login-sub">لوحة تحكم مدارس السياقة</div>
          <p class="login-copy">
            سجّل دخولك بحساب Google الخاص بمدرستك للوصول إلى أكواد التفعيل،
            متابعة المترشحين، الإحالات والتحليلات.
          </p>
          <button class="google-btn" id="google-login" type="button">
            <span class="g-mark">G</span>
            <span>الدخول عبر Google</span>
          </button>
          ${errorMessage ? `<div class="login-error">${esc(errorMessage)}</div>` : ""}
          <p class="login-foot">
            لست مدرسة؟ تطبيق المترشح متوفّر قريباً على Google Play.
          </p>
        </div>
        <p class="login-copyright">© ${new Date().getFullYear()} VIRAGE — جميع الحقوق محفوظة</p>
      </div>
    </div>`;

  $("#google-login")?.addEventListener("click", loginWithGoogle);
  document.title = "VIRAGE | تسجيل الدخول";
}

async function loginWithGoogle() {
  const btn = $("#google-login");
  if (!btn || btn.disabled) return;

  if (DEMO) {
    state.session = demoSession();
    toast("وضع تجريبي: تم الدخول بحساب وهمي", "info");
    go("/dashboard");
    return;
  }

  btn.disabled = true;
  btn.innerHTML = `<span class="boot-ring" style="width:20px;height:20px;margin:0;border-width:2px;border-top-color:var(--primary);border-color:var(--border)"></span><span>جارٍ التحويل إلى Google…</span>`;

  const { error } = await state.supabase.auth.signInWithOAuth({
    provider: "google",
    options: { redirectTo: oauthRedirectUrl() },
  });

  if (error) {
    toast(`تعذر بدء تسجيل الدخول: ${error.message}`, "error", 7000);
    btn.disabled = false;
    btn.innerHTML = `<span class="g-mark">G</span><span>الدخول عبر Google</span>`;
  }
}

/* -------------------------------------------------------------------------- */
/* الهيكل                                                                     */
/* -------------------------------------------------------------------------- */

function currentUserLabel() {
  const profile = state.profile;
  return (
    profile?.school_name ||
    profile?.full_name ||
    state.session?.user?.email ||
    "مدرسة"
  );
}

function renderShell() {
  const root = $("#root");
  root.innerHTML = `
    <div class="app" id="app-shell">
      <aside class="sidebar" id="sidebar" aria-label="التنقل">
        <div class="brand">
          <img src="../assets/icon-192.png" alt="" width="40" height="40" />
          <div>
            <div class="brand-name">VIRAGE</div>
            <div class="brand-sub">لوحة تحكم مدارس السياقة</div>
          </div>
        </div>
        <nav class="nav">
          ${NAV.map(
            (item) => `
            <a class="nav-link" href="#/${item.route}" data-route="${item.route}">
              ${ICONS[item.icon]}<span>${item.label}</span>
            </a>`,
          ).join("")}
        </nav>
        <div class="sidebar-foot">
          <div class="side-user">
            <span class="side-avatar" id="side-avatar">${esc(initials(currentUserLabel()))}</span>
            <div>
              <strong id="side-name">${esc(currentUserLabel())}</strong>
              <span id="side-email">${esc(state.session?.user?.email ?? "")}</span>
            </div>
          </div>
          <button class="btn btn-ghost" id="theme-toggle" type="button">
            ${ICONS.moon}<span>تبديل المظهر</span>
          </button>
          <button class="btn btn-ghost" id="signout" type="button">
            ${ICONS.logout}<span>تسجيل الخروج</span>
          </button>
        </div>
      </aside>

      <div class="sidebar-backdrop hidden" id="sidebar-backdrop"></div>

      <div class="main">
        <header class="topbar">
          <button class="btn-icon" id="menu-toggle" type="button" aria-label="القائمة">${ICONS.menu}</button>
          <div class="brand-name">VIRAGE</div>
          <span class="spacer"></span>
          <button class="btn-icon" id="theme-toggle-mobile" type="button" aria-label="المظهر">${ICONS.moon}</button>
        </header>
        <main class="page" id="view"></main>
      </div>
    </div>`;

  $("#theme-toggle")?.addEventListener("click", toggleTheme);
  $("#theme-toggle-mobile")?.addEventListener("click", toggleTheme);
  $("#signout")?.addEventListener("click", confirmSignOut);
  $("#menu-toggle")?.addEventListener("click", openSidebar);
  $("#sidebar-backdrop")?.addEventListener("click", closeSidebar);
  $$("#sidebar .nav-link").forEach((link) =>
    link.addEventListener("click", closeSidebar),
  );
}

function refreshSideUser() {
  const name = currentUserLabel();
  const avatar = $("#side-avatar");
  const label = $("#side-name");
  const email = $("#side-email");
  if (label) label.textContent = name;
  if (email) email.textContent = state.session?.user?.email ?? "";
  if (avatar) {
    const url = state.profile?.avatar_url;
    if (url) {
      avatar.innerHTML = `<img src="${esc(url)}" alt="" style="width:100%;height:100%;border-radius:50%;object-fit:cover" />`;
    } else {
      avatar.textContent = initials(name);
    }
  }
}

function openSidebar() {
  $("#sidebar")?.classList.add("is-open");
  $("#sidebar-backdrop")?.classList.remove("hidden");
}

function closeSidebar() {
  $("#sidebar")?.classList.remove("is-open");
  $("#sidebar-backdrop")?.classList.add("hidden");
}

function toggleTheme() {
  const current = document.documentElement.dataset.theme;
  setThemeMode(current === "dark" ? "light" : "dark");
}

function confirmSignOut() {
  openModal({
    title: "تأكيد تسجيل الخروج",
    body: "<p>هل تريد تسجيل الخروج من لوحة التحكم؟ ستحتاج إلى تسجيل الدخول مجدداً للعودة.</p>",
    actions: [
      {
        label: "تسجيل الخروج",
        class: "btn-danger",
        onClick: async () => {
          closeModal();
          try {
            if (!DEMO) await state.supabase.auth.signOut();
          } catch {
            /* تجاهل */
          }
          state.session = null;
          state.profile = null;
          go("/login");
        },
      },
      { label: "إلغاء", class: "btn-ghost" },
    ],
  });
}

/* -------------------------------------------------------------------------- */
/* التوجيه                                                                    */
/* -------------------------------------------------------------------------- */

const VIEWS = {
  dashboard: { title: "الرئيسية", render: renderDashboard },
  analytics: { title: "التحليلات", render: renderAnalytics },
  referral: { title: "برنامج الإحالة", render: renderReferral },
  profile: { title: "الملف الشخصي", render: renderProfile },
  contact: { title: "التواصل والدعم", render: renderContact },
  settings: { title: "الإعدادات", render: renderSettings },
};

function parseRoute() {
  const raw = location.hash.replace(/^#\/?/, "").split("?")[0];
  if (!raw || raw.includes("=")) return "dashboard";
  return raw.split("/")[0] || "dashboard";
}

function go(path) {
  const target = path.startsWith("/") ? path : `/${path}`;
  if (location.hash === `#${target}`) {
    route();
    return;
  }
  location.hash = `#${target}`;
}

async function route() {
  const hash = location.hash;
  if (/access_token|error_description|error_code/.test(hash)) {
    history.replaceState(null, "", location.pathname + "#/dashboard");
  }

  // بعد تبادل رمز PKCE تبقى ?code=... في العنوان؛ ننظّفها بعد ثبوت الجلسة.
  if (state.session && new URLSearchParams(location.search).has("code")) {
    history.replaceState(null, "", `${location.pathname}${hash || "#/dashboard"}`);
  }

  const loggedIn = Boolean(state.session);
  const name = parseRoute();

  if (!loggedIn) {
    renderLogin(readAuthError());
    document.title = "VIRAGE | تسجيل الدخول";
    return;
  }

  if (name === "login") {
    go("/dashboard");
    return;
  }

  const view = VIEWS[name] ? name : "dashboard";
  if (view !== name) {
    go(`/${view}`);
    return;
  }

  state.route = view;
  if (!$("#app-shell")) renderShell();
  refreshSideUser();

  $$("#sidebar .nav-link").forEach((link) => {
    link.classList.toggle("is-active", link.dataset.route === view);
  });

  document.title = `VIRAGE | ${VIEWS[view].title}`;
  closeSidebar();
  window.scrollTo({ top: 0 });

  try {
    await VIEWS[view].render();
  } catch (error) {
    console.error(error);
    $("#view")?.replaceChildren();
    $("#view").innerHTML = errorState(
      "تعذر تحميل الصفحة. تحقق من اتصالك ثم أعد المحاولة.",
      error?.message,
    );
    bindRetry(() => route());
  }
}

function readAuthError() {
  const params = new URLSearchParams(location.search);
  const hashParams = new URLSearchParams(location.hash.replace(/^#\/?/, ""));
  return (
    params.get("error_description") ||
    hashParams.get("error_description") ||
    params.get("error") ||
    hashParams.get("error") ||
    ""
  );
}

/* -------------------------------------------------------------------------- */
/* عناصر مشتركة                                                               */
/* -------------------------------------------------------------------------- */

function skeletonPage() {
  return `
    <div class="page-head">
      <div>
        <div class="skeleton sk-title" style="width:180px"></div>
        <div class="skeleton sk-line" style="width:260px"></div>
      </div>
    </div>
    <div class="skeleton sk-card" style="height:120px;margin-bottom:18px"></div>
    <div class="metrics">
      ${Array.from({ length: 4 })
        .map(() => '<div class="skeleton sk-card"></div>')
        .join("")}
    </div>
    <div class="skeleton sk-table" style="margin-top:18px"></div>`;
}

function errorState(message, detail = "") {
  return `
    <div class="card empty">
      <div style="display:flex;justify-content:center;margin-bottom:8px;opacity:.7">${ICONS.alert}</div>
      <p style="font-weight:800;color:var(--text)">${esc(message)}</p>
      ${detail ? `<p class="small" style="margin-top:4px;direction:ltr">${esc(detail)}</p>` : ""}
      <button class="btn btn-outline btn-sm" style="margin-top:14px" data-retry>${ICONS.refresh}إعادة المحاولة</button>
    </div>`;
}

function bindRetry(callback) {
  $$("[data-retry]").forEach((btn) => btn.addEventListener("click", callback));
}

function pageHead(title, subtitle) {
  return `
    <div class="page-head">
      <div>
        <h1>${esc(title)}</h1>
        <p>${esc(subtitle)}</p>
      </div>
    </div>`;
}

/* -------------------------------------------------------------------------- */
/* الرئيسية                                                                   */
/* -------------------------------------------------------------------------- */

async function renderDashboard() {
  const view = $("#view");
  view.innerHTML = skeletonPage();

  const userId = uid();
  const [codesResult, profileResult] = await Promise.all([
    state.supabase
      .from("activation_codes")
      .select("code, status, created_at")
      .eq("school_id", userId),
    state.supabase
      .from("profiles")
      .select("full_name, school_name, referred_by, avatar_url")
      .eq("id", userId)
      .maybeSingle(),
  ]);

  if (codesResult.error) {
    view.innerHTML = errorState(
      "تعذر تحميل أكواد المدرسة.",
      codesResult.error.message,
    );
    bindRetry(renderDashboard);
    return;
  }

  state.profile = profileResult.data ?? state.profile ?? {};
  state.referredBy = state.profile.referred_by ?? null;
  state.codes = (codesResult.data ?? []).map((row) => ({
    code: String(row.code ?? ""),
    status: normalizeStatus(row.status),
    rawDate: row.created_at ?? null,
    date: fmtDate(row.created_at),
  }));
  state.selected.clear();
  state.page = 1;
  state.search = "";
  state.filter = "الكل";
  state.sort = "newest";

  drawDashboard();
  refreshSideUser();
}

function counts() {
  const codes = state.codes;
  return {
    total: codes.length,
    available: codes.filter((c) => c.status === "متاح").length,
    used: codes.filter((c) => c.status === "مستعمل").length,
    expired: codes.filter((c) => c.status === "منتهي").length,
  };
}

function drawDashboard() {
  const c = counts();
  const school = state.profile?.school_name || "";
  const firstName = state.profile?.full_name?.split(" ")[0] || "";
  const showReferral = !state.referredBy;

  $("#view").innerHTML = `
    ${pageHead("الرئيسية", "تابع أداء ومشتريات الأكواد الخاصة بمدرستك.")}

    <section class="hero">
      <div class="hero-top">
        <div>
          <span class="hero-badge"><i></i>النظام نشط ويعمل بنجاح</span>
          <h1>أهلاً بك في لوحة تحكم VIRAGE${firstName ? `، ${esc(firstName)}` : ""} 👋</h1>
          <p>${school ? `${esc(school)} — ` : ""}تابع أكواد التفعيل والمترشحين والإحالات من مكان واحد.</p>
        </div>
        ${
          showReferral
            ? `<button class="btn hero-cta" id="hero-referral" type="button">${ICONS.gift}احصل على خصم 10% 🎁</button>`
            : `<span class="badge" style="background:rgba(255,255,255,.16);color:#fff;border-color:rgba(255,255,255,.3)">${ICONS.check}خصم الإحالة مفعّل</span>`
        }
      </div>
    </section>

    <div class="metrics">
      ${metricCard("blue", ICONS.ticket, c.total, "إجمالي الأكواد")}
      ${metricCard("green", ICONS.check, c.available, "أكواد متاحة")}
      ${metricCard("amber", ICONS.users, c.used, "أكواد مستعملة")}
      ${metricCard("red", ICONS.clock, c.expired, "أكواد منتهية")}
    </div>

    <div class="section-title">${ICONS.bar}ملخص المؤشرات والإحصائيات</div>

    <div class="dash-grid">
      <section class="card" id="codes-card">
        <div class="card-head">
          <span class="icon-chip">${ICONS.ticket}</span>
          <div class="grow">
            <h2>سجل الأكواد المشتراة</h2>
            <p>إدارة وعرض حالة أكواد التفعيل الخاصة بالمؤسسة</p>
          </div>
          <div class="row">
            <button class="btn btn-outline btn-sm" id="copy-available" type="button">${ICONS.copy}نسخ المتاحة</button>
            <button class="btn-icon" id="refresh-codes" type="button" title="تحديث البيانات">${ICONS.refresh}</button>
          </div>
        </div>
        <div class="table-toolbar">
          <div class="input-icon">
            ${ICONS.search}
            <input class="input" id="code-search" type="search" placeholder="ابحث بالكود أو التاريخ…" autocomplete="off" />
          </div>
          <select class="select" id="code-filter" aria-label="تصفية الحالة">
            <option value="الكل">كل الحالات</option>
            <option value="متاح">متاح</option>
            <option value="مستعمل">مستعمل</option>
            <option value="منتهي">منتهي</option>
          </select>
          <select class="select" id="code-sort" aria-label="الترتيب">
            <option value="newest">الأحدث أولاً</option>
            <option value="oldest">الأقدم أولاً</option>
            <option value="code">حسب الكود</option>
          </select>
          <select class="select" id="code-size" aria-label="عدد العناصر">
            <option value="5">5 عناصر</option>
            <option value="10" selected>10 عناصر</option>
            <option value="25">25 عنصر</option>
            <option value="50">50 عنصر</option>
          </select>
        </div>
        <div id="codes-body"></div>
      </section>

      ${buyPanel()}
    </div>`;

  $("#hero-referral")?.addEventListener("click", () => go("/referral"));

  const onSearch = debounce(() => {
    state.search = $("#code-search").value.trim();
    state.page = 1;
    paintCodes();
  }, 130);

  $("#code-search")?.addEventListener("input", onSearch);
  $("#code-filter")?.addEventListener("change", (e) => {
    state.filter = e.target.value;
    state.page = 1;
    paintCodes();
  });
  $("#code-sort")?.addEventListener("change", (e) => {
    state.sort = e.target.value;
    state.page = 1;
    paintCodes();
  });
  $("#code-size")?.addEventListener("change", (e) => {
    state.pageSize = Number(e.target.value) || 10;
    state.page = 1;
    paintCodes();
  });

  $("#copy-available")?.addEventListener("click", () => {
    const available = state.codes.filter((c) => c.status === "متاح");
    copyText(
      available.map((c) => c.code).join("\n"),
      `تم نسخ الأكواد المتاحة (${available.length})`,
    );
  });

  $("#refresh-codes")?.addEventListener("click", (e) => {
    e.currentTarget.disabled = true;
    renderDashboard();
  });

  bindCodesBody();
  bindBuyPanel();
  paintCodes();
  bindBuyTotals();
}

function metricCard(tone, icon, value, label) {
  return `
    <div class="metric">
      <span class="metric-ico ${tone}">${icon}</span>
      <div style="min-width:0">
        <b>${Number(value).toLocaleString("fr-DZ")}</b>
        <span>${esc(label)}</span>
      </div>
    </div>`;
}

function filteredCodes() {
  const query = state.search.toLowerCase();
  const list = state.codes.filter((item) => {
    const matchesQuery =
      !query ||
      item.code.toLowerCase().includes(query) ||
      item.date.includes(query);
    const matchesFilter = state.filter === "الكل" || item.status === state.filter;
    return matchesQuery && matchesFilter;
  });

  list.sort((a, b) => {
    if (state.sort === "code") return a.code.localeCompare(b.code);
    const da = a.rawDate ? new Date(a.rawDate).getTime() : 0;
    const db = b.rawDate ? new Date(b.rawDate).getTime() : 0;
    return state.sort === "oldest" ? da - db : db - da;
  });

  return list;
}

function bulkBarHtml() {
  const n = state.selected.size;
  if (!n) return "";
  return `<div class="bulkbar">
      <span>تم تحديد ${codesWord(n)}</span>
      <button class="btn btn-sm btn-soft" data-bulk="copy" type="button">${ICONS.copy}نسخ المحددة</button>
      <button class="btn btn-sm btn-ghost" data-bulk="clear" type="button">إلغاء التحديد</button>
    </div>`;
}

/** تحديث التحديد في مكانه دون إعادة رسم الجدول (يحافظ على التركيز والتمرير). */
function paintSelection() {
  $$("table.codes tbody tr").forEach((tr) => {
    const box = tr.querySelector(".check[data-code]");
    if (!box) return;
    const on = state.selected.has(box.dataset.code);
    box.checked = on;
    tr.classList.toggle("is-selected", on);
  });

  const boxes = $$("table.codes tbody .check[data-code]");
  const selectPage = $("#select-page");
  if (selectPage) {
    selectPage.checked = boxes.length > 0 && boxes.every((b) => b.checked);
    selectPage.indeterminate =
      boxes.some((b) => b.checked) && !boxes.every((b) => b.checked);
  }

  const slot = $("#bulk-slot");
  if (slot) slot.innerHTML = bulkBarHtml();
}

function paintCodes() {
  const body = $("#codes-body");
  if (!body) return;

  const list = filteredCodes();
  const totalPages = Math.max(1, Math.ceil(list.length / state.pageSize));
  if (state.page > totalPages) state.page = totalPages;
  const start = (state.page - 1) * state.pageSize;
  const pageItems = list.slice(start, start + state.pageSize);
  const bulk = bulkBarHtml();

  const rows = pageItems
    .map(
      (item) => `
      <tr class="${state.selected.has(item.code) ? "is-selected" : ""}">
        <td style="width:34px">
          <input class="check" type="checkbox" data-code="${esc(item.code)}"
            ${state.selected.has(item.code) ? "checked" : ""}
            aria-label="تحديد الكود ${esc(item.code)}" />
        </td>
        <td><span class="code">${esc(item.code)}</span></td>
        <td>${statusBadge(item.status)}</td>
        <td><span class="date">${esc(item.date)}</span></td>
        <td class="actions">
          <button class="btn-icon" style="width:32px;height:32px" data-copy="${esc(item.code)}" type="button" title="نسخ الكود">${ICONS.copy}</button>
        </td>
      </tr>`,
    )
    .join("");

  const table = list.length
    ? `<div class="table-scroll">
        <table class="codes">
          <thead>
            <tr>
              <th style="width:34px"><input class="check" type="checkbox" id="select-page" ${pageItems.length && pageItems.every((i) => state.selected.has(i.code)) ? "checked" : ""} aria-label="تحديد الصفحة" /></th>
              <th>الكود</th>
              <th>الحالة</th>
              <th>تاريخ الإضافة</th>
              <th class="actions">إجراء</th>
            </tr>
          </thead>
          <tbody>${rows}</tbody>
        </table>
      </div>`
    : `<div class="empty">${ICONS.search}<p>لا توجد أكواد مطابقة لبحثك.</p>${
        state.search || state.filter !== "الكل"
          ? '<button class="btn btn-ghost btn-sm" data-reset-filters style="margin-top:8px">إعادة تعيين الفلاتر</button>'
          : ""
      }</div>`;

  const pager = [];
  const windowStart = Math.max(1, Math.min(state.page - 2, totalPages - 4));
  const windowEnd = Math.min(totalPages, windowStart + 4);
  for (let p = windowStart; p <= windowEnd; p += 1) {
    pager.push(
      `<button type="button" data-page="${p}" class="${p === state.page ? "is-active" : ""}">${p}</button>`,
    );
  }

  body.innerHTML = `
    <div id="bulk-slot">${bulk}</div>
    ${table}
    <div class="table-foot">
      <span>عرض ${list.length ? start + 1 : 0}–${Math.min(start + state.pageSize, list.length)} من ${codesWord(list.length)}</span>
      <div class="pager">
        <button type="button" data-page="${state.page - 1}" ${state.page <= 1 ? "disabled" : ""} aria-label="السابق">${ICONS.chevronRight}</button>
        ${pager.join("")}
        <button type="button" data-page="${state.page + 1}" ${state.page >= totalPages ? "disabled" : ""} aria-label="التالي">${ICONS.chevronLeft}</button>
      </div>
    </div>`;
}

function bindCodesBody() {
  const body = $("#codes-body");
  if (!body || body.dataset.bound) return;
  body.dataset.bound = "1";

  body.addEventListener("change", (event) => {
    const target = event.target;
    if (target.id === "select-page") {
      const list = filteredCodes();
      const start = (state.page - 1) * state.pageSize;
      const pageItems = list.slice(start, start + state.pageSize);
      pageItems.forEach((item) => {
        if (target.checked) state.selected.add(item.code);
        else state.selected.delete(item.code);
      });
      paintSelection();
      return;
    }
    const code = target.dataset?.code;
    if (code) {
      if (target.checked) state.selected.add(code);
      else state.selected.delete(code);
      paintSelection();
    }
  });

  body.addEventListener("click", (event) => {
    const copyBtn = event.target.closest("[data-copy]");
    if (copyBtn) {
      copyText(copyBtn.dataset.copy, "تم نسخ الكود");
      return;
    }

    const pageBtn = event.target.closest("[data-page]");
    if (pageBtn && !pageBtn.disabled) {
      state.page = Number(pageBtn.dataset.page) || 1;
      paintCodes();
      return;
    }

    const bulk = event.target.closest("[data-bulk]");
    if (bulk) {
      if (bulk.dataset.bulk === "clear") {
        state.selected.clear();
        paintSelection();
      } else {
        copyText(
          Array.from(state.selected).join("\n"),
          `تم نسخ ${codesWord(state.selected.size)}`,
        );
      }
      return;
    }

    if (event.target.closest("[data-reset-filters]")) {
      state.search = "";
      state.filter = "الكل";
      state.page = 1;
      const search = $("#code-search");
      if (search) search.value = "";
      const filter = $("#code-filter");
      if (filter) filter.value = "الكل";
      paintCodes();
    }
  });
}

/* ------------------------------ شراء الأكواد ------------------------------- */

function hasReferralDiscount() {
  return Boolean(state.referredBy) && state.codes.length === 0;
}

function buyPanel() {
  const discount = hasReferralDiscount();
  return `
    <aside class="card card-pad" id="buy-panel">
      <div class="row">
        <span class="icon-chip">${ICONS.wallet}</span>
        <div>
          <h2 style="font-size:17px;font-weight:800">شراء أكواد جديدة</h2>
        </div>
      </div>

      ${
        discount
          ? `<div class="buy-note">${ICONS.gift}<span>مكافأة الإحالة: خصم 10% مفعّل على أول عملية شراء لك عبر Chargily! 🎁</span></div>`
          : ""
      }

      <div class="pkg-grid" role="group" aria-label="اختر عدد الأكواد">
        ${PACKAGES.map(
          (n) => `
          <button class="pkg ${n === state.pkg ? "is-active" : ""}" type="button" data-pkg="${n}">
            ${n}<small>كود</small>
          </button>`,
        ).join("")}
      </div>

      <div class="buy-price">
        <b id="buy-total">${money(state.pkg * PRICE_PER_CODE)}</b>
        ${discount ? `<span class="old-price" id="buy-old">${money(state.pkg * PRICE_PER_CODE)}</span>` : ""}
      </div>
      <span class="small muted">${PRICE_PER_CODE} دج لكل كود${discount ? " — بعد خصم 10%" : ""}</span>

      <div class="buy-summary">
        <div><span>عدد الأكواد</span><b id="sum-count">${state.pkg}</b></div>
        <div><span>سعر الكود</span><b>${money(PRICE_PER_CODE)}</b></div>
        ${discount ? `<div><span>الخصم (10%)</span><b style="color:var(--success)">− <span id="sum-discount">${money(state.pkg * PRICE_PER_CODE * 0.1)}</span></b></div>` : ""}
        <div class="total"><span>المجموع</span><b id="sum-total">${money(state.pkg * PRICE_PER_CODE * (discount ? 0.9 : 1))}</b></div>
      </div>

      <button class="btn btn-primary btn-block" id="buy-button" type="button">
        ${ICONS.wallet}<span>الشراء عبر Chargily</span>
      </button>
      <p class="small muted center" style="margin-top:10px">
        تُضاف الأكواد إلى رصيدك تلقائياً بعد تأكيد الدفع.
      </p>
    </aside>`;
}

function bindBuyPanel() {
  $$("#buy-panel [data-pkg]").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.pkg = Number(btn.dataset.pkg) || 10;
      $$("#buy-panel [data-pkg]").forEach((b) =>
        b.classList.toggle("is-active", b === btn),
      );
      bindBuyTotals();
    });
  });
}

function bindBuyTotals() {
  const discount = hasReferralDiscount();
  const raw = state.pkg * PRICE_PER_CODE;
  const final = Math.round(raw * (discount ? 0.9 : 1));
  const set = (id, value) => {
    const el = $(id);
    if (el) el.textContent = value;
  };
  set("#buy-total", money(final));
  set("#buy-old", discount ? money(raw) : "");
  set("#sum-count", String(state.pkg));
  set("#sum-discount", money(raw * 0.1));
  set("#sum-total", money(final));

  const old = $("#buy-old");
  if (old) old.classList.toggle("hidden", !discount);

  const button = $("#buy-button");
  if (button && !button.dataset.bound) {
    button.dataset.bound = "1";
    button.addEventListener("click", startCheckout);
  }
}

async function startCheckout() {
  const button = $("#buy-button");
  if (!button || button.disabled) return;

  const schoolId = uid();
  if (!schoolId) {
    toast("لم يتم التعرف على حساب المدرسة، أعد تسجيل الدخول.", "error");
    return;
  }

  button.disabled = true;
  const original = button.innerHTML;
  button.innerHTML = `<span class="boot-ring" style="width:18px;height:18px;margin:0;border-width:2px;border-top-color:#fff;border-color:rgba(255,255,255,.4)"></span><span>جارٍ إنشاء الطلب…</span>`;

  try {
    const response = await fetch(CHECKOUT_API, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        school_id: schoolId,
        count: state.pkg,
        amount: state.pkg * PRICE_PER_CODE,
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    if (!data?.checkout_url) {
      throw new Error("لم يُرجع الخادم رابط الدفع");
    }

    toast("تم إنشاء الطلب، جارٍ تحويلك إلى Chargily…", "success");
    location.assign(data.checkout_url);
  } catch (error) {
    console.error(error);
    toast(
      "فشل إنشاء طلب الدفع. تحقق من اتصالك ثم أعد المحاولة.",
      "error",
      6500,
    );
    button.disabled = false;
    button.innerHTML = original;
  }
}

/* -------------------------------------------------------------------------- */
/* التحليلات                                                                  */
/* -------------------------------------------------------------------------- */

const PERIODS = {
  week: { label: "هذا الأسبوع", days: 7 },
  month: { label: "هذا الشهر", days: null },
  quarter: { label: "آخر 3 أشهر", days: 90 },
  year: { label: "هذه السنة", days: null },
};

function periodStart(period) {
  const now = new Date();
  if (period === "week") {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    d.setDate(d.getDate() - 7);
    return d;
  }
  if (period === "quarter") {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    d.setDate(d.getDate() - 90);
    return d;
  }
  if (period === "year") return new Date(now.getFullYear(), 0, 1);
  return new Date(now.getFullYear(), now.getMonth(), 1);
}

async function renderAnalytics() {
  const view = $("#view");
  view.innerHTML = skeletonPage();

  const result = await state.supabase
    .from("activation_codes")
    .select("code, status, created_at")
    .eq("school_id", uid());

  if (result.error) {
    view.innerHTML = errorState(
      "تعذر تحميل بيانات التحليلات.",
      result.error.message,
    );
    bindRetry(renderAnalytics);
    return;
  }

  state.analyticsCodes = (result.data ?? []).map((row) => ({
    code: String(row.code ?? ""),
    status: normalizeStatus(row.status),
    rawDate: row.created_at ?? null,
  }));

  drawAnalytics();
}

function analyticsStats() {
  const start = periodStart(state.analyticsPeriod);
  const codes = state.analyticsCodes.filter(
    (c) => c.rawDate && new Date(c.rawDate) >= start,
  );
  const total = codes.length;
  const used = codes.filter((c) => c.status === "مستعمل").length;
  const available = codes.filter((c) => c.status === "متاح").length;
  const expired = codes.filter((c) => c.status === "منتهي").length;
  const activation = total ? Math.round((used / total) * 100) : 0;
  const usedAges = codes
    .filter((c) => c.status === "مستعمل" && c.rawDate)
    .map((c) => daysAgo(c.rawDate));
  const avgAge = usedAges.length
    ? (usedAges.reduce((a, b) => a + b, 0) / usedAges.length).toFixed(1)
    : "0";

  return { codes, total, used, available, expired, activation, avgAge };
}

/** تقسيم الفترة المحددة إلى 4 فترات متساوية — نفس منطق نسخة Flutter. */
function weeklyBuckets(codes) {
  const start = periodStart(state.analyticsPeriod);
  const now = new Date();
  const totalDays = Math.max(1, Math.ceil((now - start) / 86400000));
  const intervalDays = Math.min(365, Math.max(1, Math.ceil(totalDays / 4)));
  const buckets = [];

  for (let i = 0; i < 4; i += 1) {
    const bucketStart = new Date(start.getTime() + i * intervalDays * 86400000);
    const bucketStop =
      i < 3
        ? new Date(start.getTime() + (i + 1) * intervalDays * 86400000)
        : new Date(now.getTime() + 1000);
    buckets.push({
      label: `فترة ${i + 1}`,
      start: bucketStart,
      stop: bucketStop,
      count: 0,
    });
  }

  codes.forEach((code) => {
    if (!code.rawDate) return;
    const d = new Date(code.rawDate);
    if (Number.isNaN(d.getTime())) return;
    for (const bucket of buckets) {
      if (d >= bucket.start && d < bucket.stop) {
        bucket.count += 1;
        break;
      }
    }
  });

  return buckets;
}

function drawAnalytics() {
  const s = analyticsStats();
  const buckets = weeklyBuckets(s.codes);
  const max = Math.max(1, ...buckets.map((b) => b.count));
  const pct = (n) => (s.total ? Math.round((n / s.total) * 100) : 0);

  $("#view").innerHTML = `
    ${pageHead("التحليلات", "نظرة سريعة على أداء الأكواد خلال الفترة المحددة.")}

    <div class="row-wrap" style="margin-bottom:18px">
      <select class="select" id="period" style="width:auto;min-width:170px">
        ${Object.entries(PERIODS)
          .map(
            ([key, p]) =>
              `<option value="${key}" ${state.analyticsPeriod === key ? "selected" : ""}>${p.label}</option>`,
          )
          .join("")}
      </select>
      <span class="small muted">${codesWord(s.total)} في الفترة المحددة</span>
    </div>

    <div class="stat-cards">
      <div class="stat-card">
        <div class="label">إجمالي الأكواد</div>
        <div class="value">${s.total}</div>
        <div class="sub">داخل الفترة المحددة</div>
      </div>
      <div class="stat-card">
        <div class="label">معدل التفعيل</div>
        <div class="value">${s.activation}%</div>
        <div class="sub">${s.used} من أصل ${codesWord(s.total)}</div>
      </div>
      <div class="stat-card">
        <div class="label">المترشحون النشطون</div>
        <div class="value">${s.used}</div>
        <div class="sub">كود مفعّل حالياً</div>
      </div>
      <div class="stat-card">
        <div class="label">متوسط عمر الكود</div>
        <div class="value">${s.avgAge}</div>
        <div class="sub">يوماً للأكواد المفعلة</div>
      </div>
    </div>

    <div class="dash-grid" style="grid-template-columns:minmax(0,1.5fr) minmax(280px,.9fr)">
      <section class="card">
        <div class="card-head">
          <span class="icon-chip">${ICONS.chart}</span>
          <div>
            <h2>النشاط خلال الفترة</h2>
            <p>الفترة المحددة مقسّمة إلى 4 فترات متساوية</p>
          </div>
        </div>
        <div class="card-body">
          <div class="chart">
            ${buckets
              .map(
                (b) => `
                <div class="chart-col" title="${b.count} كود">
                  <span class="val">${b.count}</span>
                  <div class="chart-bar" style="height:${Math.max(4, Math.round((b.count / max) * 150))}px"></div>
                  <span class="lbl">${b.label}</span>
                </div>`,
              )
              .join("")}
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-head">
          <span class="icon-chip">${ICONS.ticket}</span>
          <div>
            <h2>توزيع الحالات</h2>
            <p>نسبة كل حالة من إجمالي الأكواد</p>
          </div>
        </div>
        <div class="card-body">
          ${catRow("متاح", s.available, pct(s.available), "green")}
          ${catRow("مستعمل", s.used, pct(s.used), "amber")}
          ${catRow("منتهي", s.expired, pct(s.expired), "red")}
        </div>
      </section>
    </div>`;

  $("#period")?.addEventListener("change", (e) => {
    state.analyticsPeriod = e.target.value;
    drawAnalytics();
  });
}

function catRow(label, value, percent, tone) {
  return `
    <div class="cat-row">
      <span>${label}</span>
      <div class="track"><div class="fill ${tone}" style="width:${Math.min(100, percent)}%"></div></div>
      <b>${value} · ${percent}%</b>
    </div>`;
}

/* -------------------------------------------------------------------------- */
/* الإحالة                                                                    */
/* -------------------------------------------------------------------------- */

async function renderReferral() {
  const view = $("#view");
  view.innerHTML = skeletonPage();

  const userId = uid();
  const code = shortId(userId);

  const [profileResult, referralsResult] = await Promise.all([
    state.supabase
      .from("profiles")
      .select("referral_code, referred_by, school_name, full_name")
      .eq("id", userId)
      .maybeSingle(),
    state.supabase.rpc("get_my_referrals"),
  ]);

  if (profileResult.error) {
    view.innerHTML = errorState(
      "تعذر تحميل بيانات الإحالة.",
      profileResult.error.message,
    );
    bindRetry(renderReferral);
    return;
  }

  const profile = profileResult.data ?? {};
  state.referredBy = profile.referred_by ?? null;

  if (profileResult.data == null) {
    await state.supabase
      .from("profiles")
      .upsert({ id: userId, referral_code: code });
  } else if (profile.referral_code !== code) {
    await state.supabase
      .from("profiles")
      .update({ referral_code: code })
      .eq("id", userId);
  }

  let referrerName = "";
  if (profile.referred_by) {
    const { data } = await state.supabase.rpc("get_referrer_profile", {
      ref_id: profile.referred_by,
    });
    const row = firstRow(data);
    referrerName = row?.school_name || row?.full_name || "مدرسة شريكة";
  }

  const referrals = Array.isArray(referralsResult.data)
    ? referralsResult.data
    : [];
  const granted = referrals.filter((r) => r.reward_granted === true).length;

  const inviteText = `انضم إلى VIRAGE لإدارة أكواد مدرستك بسهولة. استخدم كود الدعوة ${code} لتحصل على خصم 10% على أول عملية شراء.`;
  const inviteUrl = `${siteRootUrl()}#schools`;

  view.innerHTML = `
    ${pageHead("برنامج الإحالة", "ادعُ مدرسة، واحصل على خصم أو أكواد مجانية.")}

    <div class="ref-hero">
      <section class="card card-pad">
        <div class="row">
          <span class="icon-chip">${ICONS.gift}</span>
          <div>
            <h2 style="font-size:17px;font-weight:800">كود الإحالة الخاص بك</h2>
            <p class="small muted">شارك هذا الكود مع مدارس السياقة الأخرى.</p>
          </div>
        </div>

        <div class="ref-code-box">
          <span class="ref-code" id="my-ref-code">${esc(code || "—")}</span>
          <button class="btn btn-icon" type="button" id="copy-code" title="نسخ الكود">${ICONS.copy}</button>
        </div>

        <div class="row" style="margin-top:14px">
          <button class="btn btn-primary" type="button" id="share-code">${ICONS.link}نسخ ومشاركة الكود</button>
          <span class="badge ${state.referredBy ? "badge-success" : "badge-neutral"}">
            ${state.referredBy ? `${ICONS.check}مُحال من ${esc(referrerName)}` : "لم تستخدم كود إحالة"}
          </span>
        </div>

        <div class="buy-note" style="background:var(--primary-100);color:var(--primary)">
          ${ICONS.sparkles}
          <span>
            المدرسة الجديدة: خصم 10% على أول عملية شراء.
            المدرسة الداعية: 5 أكواد مجانية بعد إتمام الدفع.
          </span>
        </div>
      </section>

      <section class="card card-pad">
        <div class="row">
          <span class="icon-chip">${ICONS.ticket}</span>
          <div>
            <h2 style="font-size:17px;font-weight:800">هل دعتك مدرسة؟</h2>
            <p class="small muted">أدخل كودها المكوّن من 6 أحرف.</p>
          </div>
        </div>
        ${
          state.referredBy
            ? `<p class="small" style="margin-top:14px;color:var(--success);font-weight:700">${ICONS.check} تم تفعيل كود إحالة سابقاً.</p>`
            : `
          <div class="field" style="margin-top:14px">
            <input class="input ltr" id="apply-code" maxlength="6" placeholder="ABC123" autocomplete="off" />
          </div>
          <button class="btn btn-outline btn-block" id="apply-button" type="button" style="margin-top:10px">${ICONS.gift}تفعيل الكود</button>`
        }
      </section>
    </div>

    <div class="section-title">${ICONS.users}إحالاتك</div>

    <div class="mini-stats">
      <div class="mini-stat"><b>${referrals.length}</b><span>إجمالي الإحالات</span></div>
      <div class="mini-stat"><b style="color:var(--success)">${granted}</b><span>مكافآت ممنوحة</span></div>
      <div class="mini-stat"><b style="color:var(--warning)">${referrals.length - granted}</b><span>قيد المعالجة</span></div>
    </div>

    <section class="card ref-list" style="margin-top:14px">
      ${
        referrals.length
          ? referrals
              .map((item) => {
                const name = item.school_name || item.full_name || "مدرسة شريكة";
                const reward = item.reward_granted === true;
                return `
                  <div class="item">
                    <span class="ref-avatar">${esc(initials(name))}</span>
                    <div class="grow">
                      <strong>${esc(name)}</strong>
                      <small>تاريخ الانضمام: ${fmtDate(item.created_at)}</small>
                    </div>
                    <span class="badge ${reward ? "badge-success" : "badge-warning"}">
                      ${reward ? ICONS.check : ICONS.clock}
                      ${reward ? "مكافأة ممنوحة" : "قيد المعالجة"}
                    </span>
                  </div>`;
              })
              .join("")
          : `<div class="empty">${ICONS.users}<p>لم تُحِل أي مدرسة بعد. شارك كودك وابدأ.</p></div>`
      }
    </section>`;

  const copy = () => copyText(code, "تم نسخ كود الإحالة");

  $("#copy-code")?.addEventListener("click", copy);
  $("#share-code")?.addEventListener("click", async () => {
    if (navigator.share) {
      try {
        await navigator.share({ title: "VIRAGE", text: inviteText, url: inviteUrl });
        return;
      } catch {
        /* المستخدم ألغى المشاركة */
      }
    }
    copyText(`${inviteText}\n${inviteUrl}`, "تم نسخ دعوة الإحالة");
  });

  $("#apply-button")?.addEventListener("click", applyReferralCode);
  $("#apply-code")?.addEventListener("keydown", (e) => {
    if (e.key === "Enter") applyReferralCode();
  });
}

async function applyReferralCode() {
  const button = $("#apply-button");
  const input = $("#apply-code");
  if (!button || !input || button.disabled) return;

  const userId = uid();
  const myCode = shortId(userId);
  const value = input.value.trim().toUpperCase();

  if (!value) {
    toast("يرجى إدخال كود الإحالة أولاً", "warning");
    return;
  }
  if (value.length !== 6) {
    toast("أدخل كود إحالة مكوّناً من 6 أحرف أو أرقام.", "warning");
    return;
  }
  if (value === myCode) {
    toast("لا يمكنك استخدام كود الإحالة الخاص بك!", "warning");
    return;
  }

  button.disabled = true;
  button.textContent = "جارٍ التحقق…";

  try {
    const { data, error } = await state.supabase.rpc("get_profile_by_referral", {
      code: value,
    });
    if (error) throw error;

    const referrer = firstRow(data);
    if (!referrer) {
      toast("كود الإحالة غير صحيح أو غير موجود.", "error");
      return;
    }

    const referrerId = referrer.ref_id;
    if (referrerId === userId) {
      toast("لا يمكنك إحالة نفسك!", "warning");
      return;
    }

    await state.supabase
      .from("profiles")
      .update({ referred_by: referrerId })
      .eq("id", userId);

    await state.supabase.from("referrals").insert({
      referrer_id: referrerId,
      referee_id: userId,
      reward_granted: false,
    });

    state.referredBy = referrerId;
    toast("تم تفعيل كود الإحالة بنجاح", "success");

    openModal({
      title: "تم تفعيل كود الإحالة 🎉",
      body: `
        <p>تم ربط حسابك بمدرسة <strong style="color:var(--text)">${esc(referrer.school_name || referrer.full_name || "شريكة")}</strong>.</p>
        <p style="margin-top:8px">الجائزة والمكافأة التي حصلت عليها:</p>
        <ul class="reward-list">
          <li>${ICONS.gift}خصم مباشر 10% على أول عملية شراء للأكواد عبر Chargily.</li>
          <li>${ICONS.ticket}وسيتم منح المدرسة الداعية 5 أكواد مجانية فور إتمام الدفع بنجاح.</li>
        </ul>`,
      actions: [{ label: "رائع، شكراً!", class: "btn-primary" }],
    });

    await renderReferral();
  } catch (error) {
    console.error(error);
    toast(`حدث خطأ أثناء تطبيق الكود: ${error.message ?? error}`, "error", 6000);
  } finally {
    if (button.isConnected) {
      button.disabled = false;
      button.textContent = "تفعيل الكود";
    }
  }
}

/* -------------------------------------------------------------------------- */
/* الملف الشخصي                                                               */
/* -------------------------------------------------------------------------- */

let leafletPromise = null;

function loadLeaflet() {
  if (window.L) return Promise.resolve(window.L);
  if (leafletPromise) return leafletPromise;
  leafletPromise = new Promise((resolve, reject) => {
    if (!document.querySelector('link[data-leaflet]')) {
      const css = document.createElement("link");
      css.rel = "stylesheet";
      css.href = "https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css";
      css.dataset.leaflet = "1";
      document.head.appendChild(css);
    }
    const script = document.createElement("script");
    script.src = "https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.js";
    script.async = true;
    script.onload = () => resolve(window.L);
    script.onerror = () => {
      leafletPromise = null;
      reject(new Error("leaflet"));
    };
    document.head.appendChild(script);
  });
  return leafletPromise;
}

async function renderProfile() {
  const view = $("#view");
  view.innerHTML = skeletonPage();

  const result = await state.supabase
    .from("profiles")
    .select()
    .eq("id", uid())
    .maybeSingle();

  if (result.error) {
    view.innerHTML = errorState(
      "تعذر تحميل الملف الشخصي.",
      result.error.message,
    );
    bindRetry(renderProfile);
    return;
  }

  const profile = result.data ?? {};
  state.profile = { ...state.profile, ...profile };
  const lat = Number(profile.latitude ?? 36.7538);
  const lng = Number(profile.longitude ?? 3.0588);
  const displayName =
    profile.school_name || profile.full_name || "مدرستي";

  view.innerHTML = `
    ${pageHead("الملف الشخصي", "بيانات مدرستك تظهر في أكواد التفعيل وفواتير الشراء.")}

    <form class="profile-grid" id="profile-form" novalidate>
      <section class="card card-pad">
        <div class="avatar-row">
          <span class="avatar-preview" id="avatar-preview">
            ${
              profile.avatar_url
                ? `<img src="${esc(profile.avatar_url)}" alt="" style="width:100%;height:100%;object-fit:cover" />`
                : esc(initials(displayName))
            }
          </span>
          <div>
            <strong style="display:block;font-size:14px">صورة المدرسة أو الشعار</strong>
            <span class="small muted">PNG أو JPG، تُصغَّر تلقائياً إلى 800 بكسل.</span>
            <div class="row" style="margin-top:8px">
              <button class="btn btn-outline btn-sm" type="button" id="pick-avatar">${ICONS.upload}اختيار صورة</button>
              <input type="file" id="avatar-file" accept="image/png,image/jpeg,image/webp" hidden />
            </div>
          </div>
        </div>

        <div class="form-grid">
          <div class="field span-2">
            <label for="full-name">الاسم الكامل لصاحب المدرسة *</label>
            <input class="input" id="full-name" value="${esc(profile.full_name ?? "")}" placeholder="أدخل الاسم الكامل" required />
          </div>
          <div class="field">
            <label for="phone">رقم الهاتف</label>
            <input class="input ltr" id="phone" value="${esc(profile.phone_number ?? "")}" placeholder="06XX XX XX XX" inputmode="tel" />
          </div>
          <div class="field">
            <label for="school-name">اسم مدرسة السياقة</label>
            <input class="input" id="school-name" value="${esc(profile.school_name ?? "")}" placeholder="أدخل اسم المؤسسة أو المدرسة" />
          </div>
          <div class="field">
            <label for="profile-id">معرّف الحساب</label>
            <input class="input ltr" id="profile-id" value="${esc(shortId(uid()))}" readonly />
            <span class="hint">هذا هو كود الإحالة الخاص بك.</span>
          </div>
          <div class="field">
            <label for="address">العنوان</label>
            <input class="input" id="address" value="" placeholder="يُجلب من الخريطة" />
            <span class="hint" id="address-hint">حرّك الدبوس أو ابحث عن موقعك.</span>
          </div>
          <div class="field">
            <label for="lat">خط العرض</label>
            <input class="input ltr" id="lat" value="${lat}" inputmode="decimal" />
          </div>
          <div class="field">
            <label for="lng">خط الطول</label>
            <input class="input ltr" id="lng" value="${lng}" inputmode="decimal" />
          </div>
        </div>

        <div class="row" style="margin-top:20px">
          <button class="btn btn-primary" type="submit" id="save-profile">${ICONS.check}حفظ البيانات</button>
          <span class="small muted" id="save-hint">تُحدَّث خريطة المترشحين بعد الحفظ.</span>
        </div>
      </section>

      <aside class="card card-pad">
        <div class="row" style="margin-bottom:12px">
          <span class="icon-chip">${ICONS.mapPin}</span>
          <strong>موقع المدرسة</strong>
        </div>
        <div class="field">
          <div class="input-icon">
            ${ICONS.search}
            <input class="input" id="map-search" placeholder="ابحث عن مدينة أو عنوان…" />
          </div>
        </div>
        <button class="btn btn-outline btn-sm btn-block" type="button" id="map-search-btn" style="margin-top:8px">${ICONS.search}بحث</button>
        <button class="btn btn-ghost btn-sm btn-block" type="button" id="map-locate" style="margin-top:6px">${ICONS.mapPin}استخدم موقعي الحالي</button>
        <div id="map" style="margin-top:12px"></div>
        <p class="map-note" id="map-note">انقر على الخريطة أو اسحب الدبوس لتحديد الموقع.</p>
      </aside>
    </form>`;

  const fileInput = $("#avatar-file");
  let selectedFile = null;

  $("#pick-avatar")?.addEventListener("click", () => fileInput?.click());
  fileInput?.addEventListener("change", async () => {
    const file = fileInput.files?.[0];
    if (!file) return;
    selectedFile = file;
    try {
      const blob = await resizeImage(file, 800, 0.85);
      selectedFile = new File([blob], "avatar.jpg", { type: "image/jpeg" });
      const url = URL.createObjectURL(blob);
      $("#avatar-preview").innerHTML =
        `<img src="${url}" alt="" style="width:100%;height:100%;object-fit:cover" />`;
    } catch {
      $("#avatar-preview").innerHTML = esc(initials(displayName));
      toast("تعذر معالجة الصورة، سيتم رفع الملف كما هو.", "warning");
    }
  });

  $("#profile-form")?.addEventListener("submit", (event) => {
    event.preventDefault();
    saveProfile(selectedFile);
  });

  initProfileMap({ lat, lng });
}

function resizeImage(file, maxSize, quality) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(url);
      const scale = Math.min(1, maxSize / Math.max(img.width, img.height));
      const canvas = document.createElement("canvas");
      canvas.width = Math.round(img.width * scale);
      canvas.height = Math.round(img.height * scale);
      const ctx = canvas.getContext("2d");
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(
        (blob) => (blob ? resolve(blob) : reject(new Error("blob"))),
        "image/jpeg",
        quality,
      );
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("image"));
    };
    img.src = url;
  });
}

async function initProfileMap({ lat, lng }) {
  let L;
  try {
    L = await loadLeaflet();
  } catch {
    $("#map")?.classList.add("hidden");
    const note = $("#map-note");
    if (note) {
      note.textContent =
        "تعذر تحميل الخريطة (قد يكون الاتصال محجوباً). يمكنك تعديل الإحداثيات يدوياً بالأعلى.";
    }
    return;
  }

  if (state.map) {
    state.map.remove();
    state.map = null;
  }

  const map = L.map("map", { zoomControl: true, attributionControl: true }).setView(
    [lat, lng],
    13,
  );
  L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: "© OpenStreetMap",
  }).addTo(map);

  const marker = L.marker([lat, lng], { draggable: true }).addTo(map);

  state.map = map;
  state.mapMarker = marker;

  const updateCoords = (latlng, reverse = true) => {
    $("#lat").value = latlng.lat.toFixed(6);
    $("#lng").value = latlng.lng.toFixed(6);
    if (reverse) reverseGeocode(latlng.lat, latlng.lng);
  };

  marker.on("dragend", () => updateCoords(marker.getLatLng()));
  map.on("click", (event) => {
    marker.setLatLng(event.latlng);
    updateCoords(event.latlng);
  });

  setTimeout(() => map.invalidateSize(), 120);

  $("#map-search-btn")?.addEventListener("click", () => {
    searchLocation(map, marker);
  });
  $("#map-search")?.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      searchLocation(map, marker);
    }
  });

  $("#map-locate")?.addEventListener("click", () => {
    if (!navigator.geolocation) {
      toast("متصفحك لا يدعم تحديد الموقع.", "warning");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const next = [pos.coords.latitude, pos.coords.longitude];
        map.setView(next, 15);
        marker.setLatLng(next);
        updateCoords({ lat: next[0], lng: next[1] });
      },
      () => toast("تعذر الحصول على موقعك. اسمح بالوصول أو ابحث يدوياً.", "error"),
      { enableHighAccuracy: true, timeout: 9000 },
    );
  });

  reverseGeocode(lat, lng);
}

async function reverseGeocode(lat, lng) {
  const hint = $("#address-hint");
  if (hint) hint.textContent = "جارٍ جلب العنوان…";
  try {
    const response = await fetch(
      `${NOMINATIM}/reverse?format=json&lat=${lat}&lon=${lng}&accept-language=ar&zoom=16`,
      { headers: { Accept: "application/json" } },
    );
    if (!response.ok) throw new Error("nominatim");
    const data = await response.json();
    const address = data?.display_name || "";
    if (address && $("#address")) {
      $("#address").value = address;
      $("#address").dataset.auto = "1";
    }
    if (hint) hint.textContent = "يمكنك تعديل العنوان يدوياً إذا لزم.";
  } catch {
    if (hint) hint.textContent = "تعذر جلب العنوان، لكن الإحداثيات محفوظة.";
  }
}

async function searchLocation(map, marker) {
  const input = $("#map-search");
  const query = input?.value.trim();
  if (!query) return;

  const coords = query.match(/^(-?\d+(\.\d+)?)\s*[, ]\s*(-?\d+(\.\d+)?)$/);
  if (coords) {
    const lat = Number(coords[1]);
    const lng = Number(coords[3]);
    map.setView([lat, lng], 15);
    marker.setLatLng([lat, lng]);
    $("#lat").value = lat.toFixed(6);
    $("#lng").value = lng.toFixed(6);
    reverseGeocode(lat, lng);
    return;
  }

  const button = $("#map-search-btn");
  if (button) button.disabled = true;
  try {
    const response = await fetch(
      `${NOMINATIM}/search?format=json&q=${encodeURIComponent(query)}&accept-language=ar&limit=1`,
      { headers: { Accept: "application/json" } },
    );
    const data = await response.json();
    const first = Array.isArray(data) ? data[0] : null;
    if (!first) {
      toast("لم يتم العثور على الموقع. جرّب اسماً آخر.", "warning");
      return;
    }
    const lat = Number(first.lat);
    const lng = Number(first.lon);
    map.setView([lat, lng], 15);
    marker.setLatLng([lat, lng]);
    $("#lat").value = lat.toFixed(6);
    $("#lng").value = lng.toFixed(6);
    const address = $("#address");
    if (address) address.value = first.display_name || query;
    if ($("#address-hint")) $("#address-hint").textContent = "تم تحديد الموقع.";
  } catch {
    toast("تعذر البحث عن الموقع الآن.", "error");
  } finally {
    if (button) button.disabled = false;
  }
}

async function saveProfile(selectedFile) {
  const button = $("#save-profile");
  if (!button || button.disabled) return;

  const fullName = $("#full-name").value.trim();
  if (!fullName) {
    toast("الاسم الكامل مطلوب.", "warning");
    $("#full-name").focus();
    return;
  }

  button.disabled = true;
  button.textContent = "جارٍ الحفظ…";

  try {
    let avatarUrl = state.profile?.avatar_url ?? null;

    if (selectedFile) {
      const path = `${uid()}/avatar.jpg`;
      const { error: uploadError } = await state.supabase.storage
        .from("avatars")
        .upload(path, selectedFile, { contentType: "image/jpeg", upsert: true });
      if (uploadError) throw uploadError;

      const { data } = state.supabase.storage.from("avatars").getPublicUrl(path);
      avatarUrl = `${data.publicUrl}?t=${Date.now()}`;
    }

    const updates = {
      id: uid(),
      referral_code: shortId(uid()),
      full_name: fullName,
      phone_number: $("#phone").value.trim(),
      school_name: $("#school-name").value.trim(),
      latitude: Number($("#lat").value) || null,
      longitude: Number($("#lng").value) || null,
      avatar_url: avatarUrl,
      updated_at: new Date().toISOString(),
    };

    const { error } = await state.supabase.from("profiles").upsert(updates);
    if (error) throw error;

    state.profile = { ...state.profile, ...updates };
    refreshSideUser();
    toast("تم حفظ البيانات بنجاح!", "success");
  } catch (error) {
    console.error(error);
    toast(`خطأ أثناء الحفظ: ${error.message ?? error}`, "error", 6000);
  } finally {
    button.disabled = false;
    button.innerHTML = `${ICONS.check}حفظ البيانات`;
  }
}

/* -------------------------------------------------------------------------- */
/* التواصل                                                                    */
/* -------------------------------------------------------------------------- */

const SUBJECTS = [
  "استفسار عام",
  "مشكلة في التفعيل والأكواد",
  "دعم تقني في لوحة التحكم",
  "اقتراح ميزة جديدة",
  "أخرى",
];

async function renderContact() {
  const view = $("#view");
  view.innerHTML = skeletonPage();

  const result = await state.supabase
    .from("profiles")
    .select("full_name, school_name, phone_number")
    .eq("id", uid())
    .maybeSingle();

  const profile = result.data ?? state.profile ?? {};
  const name = profile.school_name
    ? `${profile.school_name}${profile.full_name ? ` (${profile.full_name})` : ""}`
    : profile.full_name || "";

  view.innerHTML = `
    ${pageHead("التواصل والدعم", "نحن هنا لمساعدتك. أرسل رسالتك وسنرد في أقرب وقت.")}

    <div class="contact-grid">
      <section class="card card-pad">
        <form id="contact-form">
          <div class="form-grid">
            <div class="field">
              <label for="c-name">الاسم أو اسم المدرسة *</label>
              <input class="input" id="c-name" value="${esc(name)}" required />
            </div>
            <div class="field">
              <label for="c-phone">رقم الهاتف</label>
              <input class="input ltr" id="c-phone" value="${esc(profile.phone_number ?? "")}" inputmode="tel" />
            </div>
            <div class="field span-2">
              <label for="c-subject">موضوع الرسالة</label>
              <select class="select" id="c-subject">
                ${SUBJECTS.map((s) => `<option>${s}</option>`).join("")}
              </select>
            </div>
            <div class="field span-2">
              <label for="c-message">الرسالة *</label>
              <textarea class="textarea" id="c-message" placeholder="اكتب تفاصيل استفسارك هنا…" required></textarea>
            </div>
          </div>
          <button class="btn btn-primary" type="submit" id="send-message" style="margin-top:16px">
            ${ICONS.mail}إرسال الرسالة
          </button>
        </form>
      </section>

      <aside class="contact-side">
        <div class="info-tile">
          <span>${ICONS.mail}</span>
          <div>
            <strong>البريد الإلكتروني</strong>
            <span class="ltr">support@virage-app.com</span>
          </div>
        </div>
        <div class="info-tile">
          <span>${ICONS.clock}</span>
          <div>
            <strong>وقت الرد</strong>
            <span>من الأحد إلى الخميس، 9:00 – 17:00</span>
          </div>
        </div>
        <div class="info-tile">
          <span>${ICONS.shield}</span>
          <div>
            <strong>بياناتك محمية</strong>
            <span>تُستخدم بياناتك للدعم فقط ولا تُشارك مع أي طرف.</span>
          </div>
        </div>
      </aside>
    </div>`;

  $("#contact-form")?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const button = $("#send-message");
    if (!button || button.disabled) return;

    const sender = $("#c-name").value.trim();
    const message = $("#c-message").value.trim();
    if (!sender) {
      toast("يرجى إدخال الاسم.", "warning");
      return;
    }
    if (message.length < 5) {
      toast("يرجى كتابة رسالة أوضح.", "warning");
      return;
    }

    button.disabled = true;
    button.textContent = "جارٍ الإرسال…";

    try {
      const { error } = await state.supabase.from("contact_messages").insert({
        user_id: uid(),
        name: sender,
        phone: $("#c-phone").value.trim(),
        subject: $("#c-subject").value,
        message,
      });
      if (error) throw error;

      $("#c-message").value = "";
      toast("تم إرسال رسالتك بنجاح، وسنتواصل معك قريباً.", "success");
    } catch (error) {
      console.error(error);
      toast(`تعذر إرسال الرسالة: ${error.message ?? error}`, "error", 6000);
    } finally {
      button.disabled = false;
      button.innerHTML = `${ICONS.mail}إرسال الرسالة`;
    }
  });
}

/* -------------------------------------------------------------------------- */
/* الإعدادات                                                                  */
/* -------------------------------------------------------------------------- */

function renderSettings() {
  const email = state.session?.user?.email ?? "";
  const mode = getThemeMode();
  const notifications = localStorage.getItem(NOTIF_KEY) !== "false";
  const emailAlerts = localStorage.getItem(EMAIL_KEY) === "true";

  $("#view").innerHTML = `
    ${pageHead("الإعدادات", "المظهر، التنبيهات، الأمان وإدارة الحساب.")}

    <section class="card">
      <div class="settings-row">
        <div class="grow">
          <strong>المظهر</strong>
          <small>اختر الوضع الفاتح أو الداكن أو اتبع إعدادات جهازك.</small>
        </div>
        <div class="segmented" role="group" aria-label="المظهر">
          <button type="button" data-theme-mode="light" class="${mode === "light" ? "is-active" : ""}">فاتح</button>
          <button type="button" data-theme-mode="dark" class="${mode === "dark" ? "is-active" : ""}">داكن</button>
          <button type="button" data-theme-mode="system" class="${mode === "system" ? "is-active" : ""}">النظام</button>
        </div>
      </div>

      <div class="settings-row">
        <div class="grow">
          <strong>تنبيهات داخل اللوحة</strong>
          <small>إظهار تنبيهات الأكواد الجديدة والتحديثات المهمة.</small>
        </div>
        <label class="switch">
          <input type="checkbox" id="notif-toggle" ${notifications ? "checked" : ""} />
          <span></span>
        </label>
      </div>

      <div class="settings-row">
        <div class="grow">
          <strong>تنبيهات البريد الإلكتروني</strong>
          <small>إرسال ملخص دوري إلى بريد حسابك.</small>
        </div>
        <label class="switch">
          <input type="checkbox" id="email-toggle" ${emailAlerts ? "checked" : ""} />
          <span></span>
        </label>
      </div>
    </section>

    <div class="section-title">${ICONS.lock}الأمان والحساب</div>

    <section class="card">
      <div class="settings-row">
        <div class="grow">
          <strong>البريد الإلكتروني</strong>
          <small class="ltr">${esc(email)}</small>
        </div>
        <span class="badge badge-success">${ICONS.shield}حساب Google موثّق</span>
      </div>

      <div class="settings-row">
        <div class="grow">
          <strong>كلمة المرور</strong>
          <small>سنرسل رابط تعيين كلمة المرور إلى بريدك.</small>
        </div>
        <button class="btn btn-outline btn-sm" type="button" id="reset-password">${ICONS.lock}إرسال الرابط</button>
      </div>

      <div class="settings-row">
        <div class="grow">
          <strong>تسجيل الخروج</strong>
          <small>ستحتاج إلى الدخول عبر Google مجدداً.</small>
        </div>
        <button class="btn btn-danger btn-sm" type="button" id="settings-signout">${ICONS.logout}تسجيل الخروج</button>
      </div>
    </section>

    <p class="small muted center" style="margin-top:22px">
      VIRAGE — لوحة تحكم مدارس السياقة · ${new Date().getFullYear()}
    </p>`;

  $$("[data-theme-mode]").forEach((btn) => {
    btn.addEventListener("click", () => setThemeMode(btn.dataset.themeMode));
  });

  $("#notif-toggle")?.addEventListener("change", (event) => {
    localStorage.setItem(NOTIF_KEY, event.target.checked ? "true" : "false");
    toast("تم حفظ إعداد التنبيهات", "success", 1800);
  });

  $("#email-toggle")?.addEventListener("change", (event) => {
    localStorage.setItem(EMAIL_KEY, event.target.checked ? "true" : "false");
    toast("تم حفظ إعداد تنبيهات البريد", "success", 1800);
  });

  $("#reset-password")?.addEventListener("click", async (event) => {
    if (!email) {
      toast("لا يوجد بريد مرتبط بالحساب الحالي.", "warning");
      return;
    }
    const button = event.currentTarget;
    button.disabled = true;
    try {
      const { error } = await state.supabase.auth.resetPasswordForEmail(email);
      if (error) throw error;
      toast(`تم إرسال رابط التعيين إلى ${email}`, "success", 5000);
    } catch (error) {
      toast(`تعذر إرسال الرابط: ${error.message ?? error}`, "error", 6000);
    } finally {
      button.disabled = false;
    }
  });

  $("#settings-signout")?.addEventListener("click", confirmSignOut);
}

/* -------------------------------------------------------------------------- */
/* الإقلاع                                                                    */
/* -------------------------------------------------------------------------- */

function hideBoot() {
  const boot = $("#boot");
  if (!boot) return;
  setTimeout(() => {
    boot.classList.add("is-hidden");
    try {
      performance.mark("virage:app-visible");
    } catch {
      /* تجاهل */
    }
    setTimeout(() => boot.remove(), 420);
  }, 60);
}

function renderFatal(message) {
  hideBoot();
  $("#root").innerHTML = `
    <div class="login">
      <div class="login-card">
        <img class="login-logo" src="../assets/icon-192.png" alt="" width="76" height="76" />
        <div class="login-brand">VIRAGE</div>
        <p class="login-copy">${esc(message)}</p>
        <button class="btn btn-primary btn-block" onclick="location.reload()">إعادة المحاولة</button>
      </div>
    </div>`;
}

/** تحميل مكتبة Supabase: نجرّب مصدرين حتى لا يتوقف الدخول إذا تعطّل أحدهما. */
async function loadSupabase() {
  let lastError = null;
  for (const url of SUPABASE_CDNS) {
    try {
      return await import(url);
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? new Error("supabase-js load failed");
}

async function init() {
  applyTheme(getThemeMode());
  const media = window.matchMedia?.("(prefers-color-scheme: dark)");
  media?.addEventListener?.("change", () => {
    if (getThemeMode() === "system") applyTheme("system");
  });

  try {
    if (DEMO) {
      state.supabase = createDemoClient();
    } else {
      const { createClient } = await loadSupabase();
      state.supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
          // نفس تدفق نسخة Flutter (PKCE) حتى يعمل رابط العودة #/dashboard كما هو.
          flowType: "pkce",
        },
      });
    }
  } catch (error) {
    console.error(error);
    renderFatal("تعذر تحميل مكتبة الاتصال بالخادم. تحقق من الإنترنت ثم أعد تحميل الصفحة.");
    return;
  }

  state.supabase.auth.onAuthStateChange((event, session) => {
    state.session = session;
    if (event === "SIGNED_OUT") {
      go("/login");
      return;
    }
    if (session && (event === "SIGNED_IN" || event === "TOKEN_REFRESHED")) {
      if (parseRoute() === "login" || !location.hash) go("/dashboard");
      else route();
    }
  });

  try {
    const { data } = await state.supabase.auth.getSession();
    state.session = data?.session ?? null;
  } catch (error) {
    console.error(error);
  }

  if (!location.hash) {
    history.replaceState(null, "", `${location.pathname}#/${state.session ? "dashboard" : "login"}`);
  }

  window.addEventListener("hashchange", route);
  await route();
  hideBoot();
}

/* -------------------------------------------------------------------------- */
/* عميل تجريبي محلي (?demo=1) — لا يُنفَّذ على الإنتاج                        */
/* -------------------------------------------------------------------------- */

function demoSession() {
  return {
    user: {
      id: "demo0000-0000-4000-8000-000000000001",
      email: "demo@virage.dz",
    },
  };
}

function createDemoClient() {
  const session = demoSession();
  const userId = session.user.id;
  const now = Date.now();
  const statuses = ["unused", "used", "unused", "expired", "used", "unused"];
  const codes = Array.from({ length: 37 }, (_, i) => ({
    code: `VRG-${(1000 + i * 37).toString(36).toUpperCase()}-${String(i).padStart(3, "0")}`,
    status: statuses[i % statuses.length],
    school_id: userId,
    created_at: new Date(now - (i * 2 + 1) * 86400000).toISOString(),
  }));

  const profile = {
    id: userId,
    full_name: "أحمد بن علي",
    school_name: "مدرسة الأمل لتعليم السياقة",
    phone_number: "0555 12 34 56",
    referral_code: userId.slice(0, 6).toUpperCase(),
    referred_by: null,
    avatar_url: null,
    latitude: 36.7538,
    longitude: 3.0588,
  };

  const referrals = [
    {
      referee_id: "r1",
      school_name: "مدرسة النجاح لتعليم السياقة",
      reward_granted: true,
      created_at: new Date(now - 19 * 86400000).toISOString(),
    },
    {
      referee_id: "r2",
      school_name: "مدرسة المستقبل",
      reward_granted: true,
      created_at: new Date(now - 9 * 86400000).toISOString(),
    },
    {
      referee_id: "r3",
      school_name: "مدرسة الوفاء",
      reward_granted: false,
      created_at: new Date(now - 2 * 86400000).toISOString(),
    },
  ];

  const builder = (result) => {
    const b = {
      select: () => b,
      eq: () => b,
      limit: () => b,
      order: () => b,
      maybeSingle: () =>
        Promise.resolve({
          data: Array.isArray(result) ? (result[0] ?? null) : result,
          error: null,
        }),
      single: () =>
        Promise.resolve({
          data: Array.isArray(result) ? (result[0] ?? null) : result,
          error: null,
        }),
      then: (resolve, reject) =>
        Promise.resolve({ data: result, error: null }).then(resolve, reject),
      catch: (reject) =>
        Promise.resolve({ data: result, error: null }).catch(reject),
      finally: (fn) =>
        Promise.resolve({ data: result, error: null }).finally(fn),
    };
    return b;
  };

  const writes = [];
  const write = (fn) => {
    writes.push(fn);
    return builder(null);
  };

  return {
    auth: {
      getSession: async () => ({ data: { session }, error: null }),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe() {} } } }),
      signInWithOAuth: async () => ({ error: null }),
      signOut: async () => ({ error: null }),
      resetPasswordForEmail: async () => ({ error: null }),
    },
    from(table) {
      if (table === "activation_codes") {
        return {
          ...builder(codes),
          select: () => builder(codes),
        };
      }
      if (table === "profiles") {
        const api = {
          select: () => builder(profile),
          eq: () => api,
          maybeSingle: () => Promise.resolve({ data: profile, error: null }),
          update(patch) {
            Object.assign(profile, patch);
            return builder(null);
          },
          upsert(patch) {
            Object.assign(profile, patch);
            return builder(null);
          },
          insert(patch) {
            Object.assign(profile, patch);
            return builder(null);
          },
        };
        return api;
      }
      if (table === "referrals") {
        return {
          insert: (row) => {
            referrals.unshift({ ...row, school_name: "مدرسة جديدة", created_at: new Date().toISOString() });
            return builder(null);
          },
        };
      }
      if (table === "contact_messages") {
        return { insert: () => builder(null) };
      }
      return { select: () => builder([]) };
    },
    rpc(name) {
      if (name === "get_my_referrals") return Promise.resolve({ data: referrals, error: null });
      if (name === "get_referrer_profile")
        return Promise.resolve({
          data: { school_name: "مدرسة الشروق" },
          error: null,
        });
      if (name === "get_profile_by_referral")
        return Promise.resolve({
          data: { ref_id: "other-user-id", school_name: "مدرسة الشروق" },
          error: null,
        });
      return Promise.resolve({ data: null, error: null });
    },
    storage: {
      from() {
        return {
          upload: async () => ({ data: { path: "demo/avatar.jpg" }, error: null }),
          getPublicUrl: () => ({
            data: {
              publicUrl:
                state.demoAvatar ||
                "https://gwafzhdtrqvwakawjmwm.supabase.co/storage/v1/object/public/avatars/demo.jpg",
            },
          }),
        };
      },
    },
  };
}

init();
