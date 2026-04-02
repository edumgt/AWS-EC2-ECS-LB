#!/usr/bin/env bash

set -euo pipefail

KEY_PATH="${KEY_PATH:-/home/AWS-EC2-ECS-LB/bastion-host-key.pem}"
FE_HOST="${FE_HOST:-3.37.72.33}"
BE_HOST="${BE_HOST:-43.201.85.182}"
SSH_USER="${SSH_USER:-ubuntu}"
FE_APP_DIR="${FE_APP_DIR:-/var/www/html/daegu-grid}"
BE_APP_ROOT="${BE_APP_ROOT:-/opt/daegu-tour-api}"
BE_PORT="${BE_PORT:-80}"
BE_APP_PORT="${BE_APP_PORT:-8000}"
WORK_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_command ssh
require_command scp

if [[ ! -f "$KEY_PATH" ]]; then
  echo "PEM file not found: $KEY_PATH" >&2
  exit 1
fi

chmod 400 "$KEY_PATH"

API_BASE_URL="http://${BE_HOST}"
FE_BUILD_DIR="$WORK_DIR/frontend"
BE_BUILD_DIR="$WORK_DIR/backend"

mkdir -p "$FE_BUILD_DIR" "$BE_BUILD_DIR/app"

cat > "$FE_BUILD_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="ko">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Daegu Tourism Board</title>
    <meta
      name="description"
      content="Tailwind 기반 AG Grid 대시보드로 대구시 관광지 목록을 조회하는 정적 웹앱"
    />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+KR:wght@400;500;600;700&display=swap"
      rel="stylesheet"
    />
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="styles.css" />
    <script src="https://cdn.jsdelivr.net/npm/ag-grid-community@34.1.2/dist/ag-grid-community.min.js"></script>
  </head>
  <body class="min-h-screen bg-stone-100 text-slate-900">
    <div class="relative min-h-screen overflow-hidden">
      <div class="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(13,148,136,0.18),transparent_28%),radial-gradient(circle_at_top_right,rgba(249,115,22,0.14),transparent_24%),linear-gradient(180deg,#f8f3eb_0%,#efe8de_100%)]"></div>
      <div class="relative flex min-h-screen">
        <div id="menuBackdrop" class="menu-backdrop hidden"></div>

        <aside id="appSidebar" class="sidebar-panel fixed inset-y-0 left-0 z-40 hidden w-[290px] -translate-x-full">
          <div class="flex h-full flex-col bg-slate-950/95 p-5 text-slate-100 shadow-2xl shadow-slate-950/30">
            <div class="mb-8 flex items-start justify-between">
              <div>
                <p class="text-xs font-bold uppercase tracking-[0.32em] text-teal-300">Tour Console</p>
                <h1 class="mt-3 text-2xl font-semibold leading-tight">Daegu Explorer SPA</h1>
                <p class="mt-3 text-sm leading-6 text-slate-400">로그인으로 시작해서 관광지 데이터와 API 문서까지 한 화면 흐름으로 탐색합니다.</p>
              </div>
              <button id="closeSidebar" class="ghost-nav" type="button">닫기</button>
            </div>

            <nav class="space-y-2">
              <button type="button" class="nav-link is-active" data-view="login">로그인</button>
              <button type="button" class="nav-link" data-view="dashboard">관광 대시보드</button>
              <button type="button" class="nav-link" data-view="docs">API 문서</button>
              <button type="button" class="nav-link" data-view="logout">로그아웃</button>
            </nav>

            <div class="mt-8 rounded-3xl border border-white/10 bg-white/5 p-4">
              <p class="text-xs uppercase tracking-[0.24em] text-slate-400">Live Endpoint</p>
              <p class="mt-3 break-all text-sm text-slate-200">${API_BASE_URL}/api/attractions</p>
            </div>

            <div class="mt-auto rounded-3xl border border-teal-400/20 bg-teal-400/10 p-4">
              <p class="text-sm font-semibold text-teal-200">현재 기본 화면</p>
              <p class="mt-2 text-sm leading-6 text-teal-50/80">앱을 처음 열면 로그인 카드가 먼저 보이고, 로그인 버튼으로 대시보드로 이동합니다.</p>
            </div>
          </div>
        </aside>

        <div class="flex min-h-screen flex-1 flex-col">
          <header id="appHeader" class="hidden px-4 py-4 sm:px-6 lg:px-8">
            <div class="mx-auto flex w-full max-w-7xl items-center justify-between rounded-[26px] border border-white/70 bg-white/75 px-4 py-4 shadow-[0_24px_70px_rgba(51,37,18,0.12)] backdrop-blur sm:px-6">
              <div>
                <p class="text-xs font-bold uppercase tracking-[0.32em] text-teal-700">Single Page App</p>
                <h2 class="mt-2 text-2xl font-semibold text-slate-900 sm:text-3xl">로그인 후 열리는 오프캔버스 운영 콘솔</h2>
              </div>
              <button id="openSidebar" class="ghost-button" type="button">☰ 메뉴</button>
            </div>
          </header>

          <main class="mx-auto flex w-full max-w-7xl flex-1 flex-col gap-5 px-4 pb-6 sm:px-6 lg:px-8">
            <section id="viewLogin" class="view-panel flex min-h-[calc(100vh-3rem)] items-center justify-center">
              <div class="grid w-full max-w-6xl gap-5 xl:grid-cols-[1.15fr_0.85fr]">
                <div class="rounded-[30px] border border-white/70 bg-white/80 p-6 shadow-[0_24px_70px_rgba(51,37,18,0.12)] backdrop-blur">
                  <p class="text-xs font-bold uppercase tracking-[0.3em] text-teal-700">Welcome</p>
                  <h3 class="mt-4 text-4xl font-semibold leading-tight text-slate-900 sm:text-5xl">처음에는 로그인 화면만 보이는 SPA</h3>
                  <p class="mt-5 max-w-2xl text-base leading-8 text-slate-600 sm:text-lg">
                    로그인 전에는 다른 뒤쪽 화면을 노출하지 않고 인증 화면만 보여줍니다. 로그인에 성공하면 상단 햄버거 버튼이 나타나고, 좌측 offcanvas 메뉴를 열어서 대시보드와 API 문서로 이동합니다.
                  </p>
                  <div class="mt-6 flex flex-wrap gap-3 text-sm text-slate-600">
                    <span class="inline-flex items-center rounded-full border border-teal-200 bg-teal-50 px-4 py-2 font-medium text-teal-800">Frontend: Tailwind SPA</span>
                    <span class="inline-flex items-center rounded-full border border-orange-200 bg-orange-50 px-4 py-2 font-medium text-orange-800">Backend: FastAPI Swagger</span>
                  </div>
                </div>

                <div class="rounded-[30px] border border-slate-200 bg-slate-950/95 p-6 text-slate-100 shadow-[0_24px_70px_rgba(15,23,42,0.35)]">
                  <p class="text-sm font-medium uppercase tracking-[0.25em] text-teal-300">Login Menu</p>
                  <form id="loginForm" class="mt-6 space-y-4">
                    <label class="block">
                      <span class="mb-2 block text-sm text-slate-300">이메일</span>
                      <input id="emailInput" type="email" value="test1@test.com" class="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-slate-100 outline-none transition focus:border-teal-400" />
                    </label>
                    <label class="block">
                      <span class="mb-2 block text-sm text-slate-300">비밀번호</span>
                      <input id="passwordInput" type="password" value="123456" class="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-slate-100 outline-none transition focus:border-teal-400" />
                    </label>
                    <label class="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-slate-300">
                      <input id="rememberMe" type="checkbox" checked class="h-4 w-4 rounded border-white/20 bg-transparent text-teal-500 focus:ring-teal-400" />
                      세션 유지
                    </label>
                    <button type="submit" class="w-full rounded-2xl bg-teal-500 px-4 py-3 text-base font-semibold text-white transition hover:bg-teal-400">로그인하고 대시보드 열기</button>
                  </form>
                  <div id="loginMessage" class="mt-4 rounded-2xl border border-teal-400/20 bg-teal-400/10 px-4 py-3 text-sm text-teal-100">
                    기본 계정은 test1@test.com / 123456 입니다.
                  </div>
                </div>
              </div>
            </section>

            <section id="viewDashboard" class="view-panel hidden">
              <div class="grid gap-5">
                <section class="grid gap-5 rounded-[28px] border border-white/70 bg-white/75 p-6 shadow-[0_24px_70px_rgba(51,37,18,0.12)] backdrop-blur xl:grid-cols-[1.4fr_0.9fr]">
                  <div>
                    <p class="text-xs font-bold uppercase tracking-[0.3em] text-teal-700">Daegu Tourism Data Grid</p>
                    <h3 class="mt-3 max-w-3xl text-4xl font-semibold leading-tight text-slate-900 sm:text-5xl">
                      Tailwind UI와 커스텀 AG Grid로 보는 대구 관광지
                    </h3>
                    <p class="mt-5 max-w-3xl text-base leading-8 text-slate-600 sm:text-lg">
                      프론트는 정적 Nginx 앱으로 서빙하고, 백엔드는 FastAPI JSON API와 Swagger UI를 제공합니다.
                      AG Grid는 기본 테마 느낌 대신 대시보드 스타일에 맞춰 직접 다듬었습니다.
                    </p>
                    <div class="mt-6 flex flex-wrap gap-3 text-sm text-slate-600">
                      <span class="inline-flex items-center rounded-full border border-teal-200 bg-teal-50 px-4 py-2 font-medium text-teal-800">Frontend: Nginx Static</span>
                      <span class="inline-flex items-center rounded-full border border-orange-200 bg-orange-50 px-4 py-2 font-medium text-orange-800">Backend: FastAPI + Swagger</span>
                      <span class="inline-flex items-center rounded-full border border-slate-200 bg-slate-50 px-4 py-2 font-medium text-slate-700">API: ${API_BASE_URL}/api/attractions</span>
                    </div>
                  </div>
                  <div class="grid gap-3">
                    <div class="rounded-3xl border border-slate-200 bg-white px-5 py-4">
                      <span class="block text-sm text-slate-500">총 관광지</span>
                      <strong id="spotCount" class="mt-2 block text-4xl font-semibold text-slate-900">0</strong>
                    </div>
                    <div class="rounded-3xl border border-slate-200 bg-white px-5 py-4">
                      <span class="block text-sm text-slate-500">대표 카테고리</span>
                      <strong id="topCategory" class="mt-2 block text-3xl font-semibold text-slate-900">-</strong>
                    </div>
                    <div class="rounded-3xl border border-slate-200 bg-white px-5 py-4">
                      <span class="block text-sm text-slate-500">API 상태</span>
                      <strong id="apiState" class="mt-2 block text-3xl font-semibold text-slate-900">Checking</strong>
                    </div>
                  </div>
                </section>

                <section class="rounded-[24px] border border-white/70 bg-white/75 p-5 shadow-[0_24px_70px_rgba(51,37,18,0.1)] backdrop-blur">
                  <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
                    <label class="block w-full max-w-xl">
                      <span class="mb-2 block text-sm font-medium text-slate-600">Quick Search</span>
                      <input
                        id="quickFilter"
                        type="search"
                        placeholder="관광지명, 구/군, 카테고리로 검색"
                        class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 outline-none transition focus:border-teal-400"
                      />
                    </label>
                    <div class="flex flex-wrap gap-2">
                      <button type="button" class="chip is-active" data-category="all">전체</button>
                      <button type="button" class="chip" data-category="자연">자연</button>
                      <button type="button" class="chip" data-category="역사">역사</button>
                      <button type="button" class="chip" data-category="문화">문화</button>
                      <button type="button" class="chip" data-category="전망">전망</button>
                      <button type="button" class="ghost-button" id="reloadData">새로고침</button>
                    </div>
                  </div>
                </section>

                <section class="rounded-[28px] border border-white/70 bg-white/80 p-5 shadow-[0_24px_70px_rgba(51,37,18,0.1)] backdrop-blur">
                  <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                    <div>
                      <p class="text-xs font-bold uppercase tracking-[0.25em] text-teal-700">Live Tourism Board</p>
                      <h3 class="mt-2 text-2xl font-semibold text-slate-900 sm:text-3xl">대구 관광지 상세 목록</h3>
                    </div>
                    <div class="flex flex-wrap gap-2 text-sm text-slate-600">
                      <button type="button" class="ghost-button" data-view-trigger="docs">API 문서 보기</button>
                    </div>
                  </div>

                  <div id="statusBanner" class="status-banner mt-4 rounded-2xl border border-teal-200 bg-teal-50 px-4 py-3 text-sm font-medium text-teal-800">
                    데이터를 불러오는 중입니다.
                  </div>

                  <div class="mt-5 overflow-hidden rounded-[24px] border border-slate-200 bg-slate-950/95 p-3 shadow-inner shadow-slate-950/20">
                    <div id="tourGrid" class="grid-frame"></div>
                  </div>
                </section>
              </div>
            </section>

            <section id="viewDocs" class="view-panel hidden">
              <div class="grid gap-5 xl:grid-cols-[0.95fr_1.05fr]">
                <div class="rounded-[30px] border border-white/70 bg-white/80 p-6 shadow-[0_24px_70px_rgba(51,37,18,0.12)] backdrop-blur">
                  <p class="text-xs font-bold uppercase tracking-[0.3em] text-teal-700">API Docs</p>
                  <h3 class="mt-4 text-3xl font-semibold text-slate-900 sm:text-4xl">Swagger와 OpenAPI 경로</h3>
                  <p class="mt-4 text-base leading-8 text-slate-600">
                    FastAPI 백엔드는 Swagger UI, ReDoc, OpenAPI JSON을 모두 제공합니다. 메뉴 이동만으로 문서 섹션을 볼 수 있고, 새 탭으로도 바로 열 수 있습니다.
                  </p>
                  <div class="mt-6 space-y-3">
                    <a class="docs-link" href="${API_BASE_URL}/docs" target="_blank" rel="noreferrer">Swagger Docs 열기</a>
                    <a class="docs-link" href="${API_BASE_URL}/redoc" target="_blank" rel="noreferrer">ReDoc 열기</a>
                    <a class="docs-link" href="${API_BASE_URL}/openapi.json" target="_blank" rel="noreferrer">OpenAPI JSON 열기</a>
                  </div>
                </div>
                <div class="rounded-[30px] border border-slate-200 bg-slate-950/95 p-6 text-slate-100 shadow-[0_24px_70px_rgba(15,23,42,0.35)]">
                  <p class="text-xs font-bold uppercase tracking-[0.3em] text-teal-300">Quick Reference</p>
                  <div class="mt-5 space-y-4 text-sm leading-7 text-slate-300">
                    <div class="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <p class="font-semibold text-white">Health</p>
                      <p class="mt-2 break-all">${API_BASE_URL}/health</p>
                    </div>
                    <div class="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <p class="font-semibold text-white">Attractions</p>
                      <p class="mt-2 break-all">${API_BASE_URL}/api/attractions</p>
                    </div>
                    <div class="rounded-2xl border border-white/10 bg-white/5 p-4">
                      <p class="font-semibold text-white">SPA Flow</p>
                      <p class="mt-2">로그인 메뉴에서 시작하고, 좌측 메뉴 또는 버튼으로 대시보드와 문서 섹션을 전환합니다.</p>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </main>
        </div>
      </div>
    </div>

    <script>
      tailwind.config = {
        theme: {
          extend: {
            fontFamily: {
              sans: ['IBM Plex Sans KR', 'sans-serif']
            }
          }
        }
      };
    </script>
    <script>
      window.APP_CONFIG = {
        apiBaseUrl: "${API_BASE_URL}"
      };
    </script>
    <script src="app.js"></script>
  </body>
</html>
EOF

cat > "$FE_BUILD_DIR/styles.css" <<'EOF'
* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  min-height: 100%;
}

.menu-backdrop {
  position: fixed;
  inset: 0;
  z-index: 30;
  background: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(3px);
}

.sidebar-panel {
  transition: transform 220ms ease;
}

.sidebar-panel.is-open {
  transform: translateX(0);
}

.nav-link,
.docs-link,
.ghost-nav {
  appearance: none;
  display: inline-flex;
  align-items: center;
  justify-content: flex-start;
  border-radius: 18px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.04);
  padding: 14px 16px;
  color: #e2e8f0;
  font: inherit;
  font-weight: 600;
  text-decoration: none;
  transition: transform 180ms ease, border-color 180ms ease, background-color 180ms ease;
}

.nav-link:hover,
.docs-link:hover,
.ghost-nav:hover {
  transform: translateY(-1px);
  border-color: rgba(45, 212, 191, 0.28);
}

.nav-link.is-active {
  background: linear-gradient(135deg, rgba(20, 184, 166, 0.24), rgba(14, 165, 233, 0.24));
  border-color: rgba(45, 212, 191, 0.4);
}

.docs-link {
  width: 100%;
  justify-content: space-between;
  color: #0f172a;
  border-color: rgba(148, 163, 184, 0.24);
  background: rgba(255, 255, 255, 0.92);
}

.ghost-nav {
  color: #cbd5e1;
}

.chip,
.ghost-button {
  appearance: none;
  border: 1px solid rgba(148, 163, 184, 0.24);
  border-radius: 999px;
  padding: 10px 16px;
  background: rgba(255, 255, 255, 0.94);
  color: #0f172a;
  font: inherit;
  font-weight: 600;
  cursor: pointer;
  transition: transform 180ms ease, background-color 180ms ease, border-color 180ms ease, color 180ms ease;
}

.chip:hover,
.ghost-button:hover {
  transform: translateY(-1px);
  border-color: rgba(15, 118, 110, 0.42);
}

.chip.is-active {
  background: #0f766e;
  color: white;
  border-color: #0f766e;
}

.ghost-button {
  color: #0f766e;
}

.status-banner {
  transition: background-color 180ms ease, color 180ms ease, border-color 180ms ease;
}

.status-banner.is-error {
  border-color: rgba(220, 38, 38, 0.2);
  background: rgba(254, 242, 242, 0.96);
  color: #b91c1c;
}

.grid-frame {
  width: 100%;
  height: 620px;
  overflow: hidden;
}

.category-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 6px 12px;
  border-radius: 999px;
  background: linear-gradient(135deg, rgba(15, 118, 110, 0.18), rgba(14, 165, 233, 0.22));
  color: #e0f2fe;
  font-weight: 700;
  font-size: 0.82rem;
}

.ag-root-wrapper,
.ag-root,
.ag-header,
.ag-paging-panel,
.ag-row,
.ag-cell,
.ag-header-cell,
.ag-header-group-cell {
  border: 0 !important;
}

.ag-root-wrapper {
  background: linear-gradient(180deg, rgba(2, 6, 23, 0.96), rgba(15, 23, 42, 0.96));
  color: #e2e8f0;
  border-radius: 18px;
}

.ag-header {
  background: rgba(15, 23, 42, 0.96);
  border-bottom: 1px solid rgba(148, 163, 184, 0.18) !important;
}

.ag-header-cell,
.ag-header-group-cell {
  color: #cbd5e1;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.ag-row {
  background: transparent;
  color: #e2e8f0;
}

.ag-row-even {
  background: rgba(15, 23, 42, 0.72);
}

.ag-row-odd {
  background: rgba(15, 23, 42, 0.38);
}

.ag-row-hover::before,
.ag-row-selected::before {
  background: rgba(20, 184, 166, 0.12) !important;
}

.ag-cell {
  display: flex;
  align-items: center;
  font-size: 0.92rem;
}

.ag-floating-filter,
.ag-floating-filter-body,
.ag-input-field-input,
.ag-text-field-input,
.ag-picker-field-wrapper,
.ag-select {
  background: rgba(15, 23, 42, 0.94) !important;
  color: #e2e8f0 !important;
}

.ag-input-field-input,
.ag-text-field-input,
.ag-picker-field-wrapper {
  border: 1px solid rgba(148, 163, 184, 0.18) !important;
  border-radius: 12px !important;
}

.ag-paging-panel {
  color: #cbd5e1;
  background: rgba(15, 23, 42, 0.92);
  border-top: 1px solid rgba(148, 163, 184, 0.18) !important;
}

.ag-icon {
  color: #94a3b8;
}

@media (max-width: 900px) {
  .grid-frame {
    height: 560px;
  }
}

@media (max-width: 1023px) {
  .sidebar-panel {
    transform: translateX(-100%);
  }
}

@media (max-width: 640px) {
  .grid-frame {
    height: 540px;
  }
}
EOF

cat > "$FE_BUILD_DIR/app.js" <<'EOF'
const apiBaseUrl = window.APP_CONFIG.apiBaseUrl;
const statusBanner = document.getElementById("statusBanner");
const gridElement = document.getElementById("tourGrid");
const sidebar = document.getElementById("appSidebar");
const sidebarBackdrop = document.getElementById("menuBackdrop");
const appHeader = document.getElementById("appHeader");
const navLinks = document.querySelectorAll(".nav-link");
const loginMessage = document.getElementById("loginMessage");
const emailInput = document.getElementById("emailInput");
const passwordInput = document.getElementById("passwordInput");
const views = {
  login: document.getElementById("viewLogin"),
  dashboard: document.getElementById("viewDashboard"),
  docs: document.getElementById("viewDocs"),
};
const TOKEN_KEY = "daegu_access_token";

const gridTheme = agGrid.themeQuartz.withParams({
  browserColorScheme: "dark",
  backgroundColor: "#020617",
  foregroundColor: "#e2e8f0",
  headerBackgroundColor: "#0f172a",
  headerTextColor: "#cbd5e1",
  rowHoverColor: "rgba(20, 184, 166, 0.10)",
  selectedRowBackgroundColor: "rgba(14, 165, 233, 0.10)",
  borderColor: "rgba(148, 163, 184, 0.14)",
  wrapperBorder: false,
  rowBorder: { color: "rgba(148, 163, 184, 0.10)" },
  columnBorder: false,
  headerColumnBorder: false,
  fontFamily: "IBM Plex Sans KR, sans-serif",
  cellTextColor: "#e2e8f0",
  spacing: 10,
  borderRadius: 16,
  headerHeight: 48,
  rowHeight: 64,
  accentColor: "#14b8a6",
  inputBorder: { color: "rgba(148, 163, 184, 0.18)" },
  inputBackgroundColor: "#0f172a",
  inputTextColor: "#e2e8f0",
});

function categoryCellRenderer(params) {
  return `<span class="category-pill">${params.value}</span>`;
}

const gridOptions = {
  rowData: [],
  theme: gridTheme,
  columnDefs: [
    { headerName: "관광지명", field: "name", minWidth: 200, pinned: "left" },
    { headerName: "카테고리", field: "category", minWidth: 120, cellRenderer: categoryCellRenderer },
    { headerName: "구/군", field: "district", minWidth: 120 },
    { headerName: "주소", field: "address", minWidth: 250 },
    { headerName: "추천 포인트", field: "highlight", minWidth: 240 },
    { headerName: "운영시간", field: "open_hours", minWidth: 160 },
    { headerName: "전화번호", field: "phone", minWidth: 150 },
  ],
  defaultColDef: {
    flex: 1,
    sortable: true,
    filter: true,
    floatingFilter: true,
    resizable: true,
  },
  animateRows: true,
  pagination: true,
  paginationPageSize: 8,
  paginationPageSizeSelector: [8, 16, 24],
};

const gridApi = agGrid.createGrid(gridElement, gridOptions);

function openSidebar() {
  if (sidebar.classList.contains("hidden")) {
    return;
  }
  sidebar.classList.add("is-open");
  sidebarBackdrop.classList.remove("hidden");
}

function closeSidebar() {
  sidebar.classList.remove("is-open");
  sidebarBackdrop.classList.add("hidden");
}

function setActiveNav(viewName) {
  navLinks.forEach((button) => {
    button.classList.toggle("is-active", button.dataset.view === viewName);
  });
}

function showView(viewName) {
  Object.entries(views).forEach(([name, element]) => {
    element.classList.toggle("hidden", name !== viewName);
  });
  setActiveNav(viewName === "logout" ? "login" : viewName);
  if (window.innerWidth < 1024) {
    closeSidebar();
  }
}

function setBanner(message, isError = false) {
  statusBanner.textContent = message;
  statusBanner.classList.toggle("is-error", isError);
}

function getToken() {
  return sessionStorage.getItem(TOKEN_KEY);
}

function setToken(token) {
  sessionStorage.setItem(TOKEN_KEY, token);
}

function clearToken() {
  sessionStorage.removeItem(TOKEN_KEY);
}

function setAuthenticatedLayout(isAuthenticated) {
  appHeader.classList.toggle("hidden", !isAuthenticated);
  sidebar.classList.toggle("hidden", !isAuthenticated);
  if (!isAuthenticated) {
    closeSidebar();
  }
}

function updateMetrics(items) {
  document.getElementById("spotCount").textContent = String(items.length);
  const categoryCount = items.reduce((acc, item) => {
    acc[item.category] = (acc[item.category] || 0) + 1;
    return acc;
  }, {});
  const topCategoryEntry = Object.entries(categoryCount).sort((a, b) => b[1] - a[1])[0];
  document.getElementById("topCategory").textContent = topCategoryEntry ? topCategoryEntry[0] : "-";
}

async function loadApiState() {
  try {
    const response = await fetch(`${apiBaseUrl}/health`);
    if (!response.ok) {
      throw new Error(`health check failed: ${response.status}`);
    }
    const data = await response.json();
    document.getElementById("apiState").textContent = data.status || "ok";
  } catch (error) {
    document.getElementById("apiState").textContent = "error";
  }
}

async function loadAttractions() {
  try {
    const token = getToken();
    if (!token) {
      throw new Error("로그인이 필요합니다.");
    }
    setBanner("대구시 관광지 데이터를 불러오는 중입니다.");
    const response = await fetch(`${apiBaseUrl}/api/attractions`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    if (!response.ok) {
      if (response.status === 401) {
        clearToken();
        showView("login");
        throw new Error("세션이 만료되어 다시 로그인해야 합니다.");
      }
      throw new Error(`request failed: ${response.status}`);
    }

    const payload = await response.json();
    const items = payload.items || [];
    gridApi.setGridOption("rowData", items);
    updateMetrics(items);
    setBanner(`총 ${items.length}개의 대구 관광지를 표시하고 있습니다.`);
  } catch (error) {
    setBanner(`데이터를 불러오지 못했습니다: ${error.message}`, true);
  }
}

document.getElementById("quickFilter").addEventListener("input", (event) => {
  gridApi.setGridOption("quickFilterText", event.target.value);
});

document.querySelectorAll("[data-category]").forEach((button) => {
  button.addEventListener("click", () => {
    document
      .querySelectorAll("[data-category]")
      .forEach((chip) => chip.classList.remove("is-active"));
    button.classList.add("is-active");

    const category = button.dataset.category;
    if (category === "all") {
      gridApi.setFilterModel(null);
      return;
    }

    gridApi.setFilterModel({
      category: {
        filterType: "text",
        type: "equals",
        filter: category,
      },
    });
  });
});

document.getElementById("reloadData").addEventListener("click", async () => {
  await loadApiState();
  await loadAttractions();
});

document.getElementById("openSidebar").addEventListener("click", openSidebar);
document.getElementById("closeSidebar").addEventListener("click", closeSidebar);
sidebarBackdrop.addEventListener("click", closeSidebar);

navLinks.forEach((button) => {
  button.addEventListener("click", () => {
    if (button.dataset.view === "logout") {
      clearToken();
      setAuthenticatedLayout(false);
      loginMessage.textContent = "로그아웃되었습니다.";
      showView("login");
      return;
    }
    showView(button.dataset.view);
    if (button.dataset.view === "dashboard") {
      loadApiState();
      loadAttractions();
    }
  });
});

document.querySelectorAll("[data-view-trigger]").forEach((button) => {
  button.addEventListener("click", () => {
    showView(button.dataset.viewTrigger);
  });
});

document.getElementById("loginForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const email = emailInput.value || "test1@test.com";
  try {
    loginMessage.textContent = "로그인 요청 중입니다.";
    const body = new URLSearchParams();
    body.set("username", email);
    body.set("password", passwordInput.value || "123456");

    const response = await fetch(`${apiBaseUrl}/auth/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body,
    });

    if (!response.ok) {
      throw new Error(`login failed: ${response.status}`);
    }

    const payload = await response.json();
    setToken(payload.access_token);
    loginMessage.textContent = `${email} 계정으로 로그인되었습니다. JWT 세션이 저장되었습니다.`;
    setAuthenticatedLayout(true);
    showView("dashboard");
    await loadApiState();
    await loadAttractions();
  } catch (error) {
    clearToken();
    setAuthenticatedLayout(false);
    loginMessage.textContent = `로그인 실패: ${error.message}`;
  }
});

loadApiState();
if (getToken()) {
  setAuthenticatedLayout(true);
  showView("dashboard");
  loadAttractions();
} else {
  setAuthenticatedLayout(false);
  showView("login");
}
EOF

cat > "$BE_BUILD_DIR/requirements.txt" <<'EOF'
fastapi==0.115.0
uvicorn[standard]==0.30.6
sqlalchemy==2.0.36
python-jose==3.3.0
passlib==1.7.4
python-multipart==0.0.20
pymysql==1.1.1
EOF

cat > "$BE_BUILD_DIR/app/main.py" <<'EOF'
import os
import ssl
from datetime import datetime, timedelta, timezone

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.hash import pbkdf2_sha256
from pydantic import BaseModel
from sqlalchemy.engine import URL
from sqlalchemy import Boolean, Integer, String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, sessionmaker

DB_HOST = os.getenv("DB_HOST", "database-1.cg0ugoglztrn.ap-northeast-2.rds.amazonaws.com")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_NAME = os.getenv("DB_NAME", "daegu_tourism")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "Admin1234!!")
DB_SSL_ENABLED = os.getenv("DB_SSL_ENABLED", "true").lower() == "true"
SECRET_KEY = "daegu-tour-api-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    full_name: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class Attraction(Base):
    __tablename__ = "attractions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(255), index=True)
    category: Mapped[str] = mapped_column(String(100), index=True)
    district: Mapped[str] = mapped_column(String(100), index=True)
    address: Mapped[str] = mapped_column(String(255))
    highlight: Mapped[str] = mapped_column(String(255))
    open_hours: Mapped[str] = mapped_column(String(100))
    phone: Mapped[str] = mapped_column(String(50))


class Token(BaseModel):
    access_token: str
    token_type: str


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    is_active: bool


class AttractionCreate(BaseModel):
    name: str
    category: str
    district: str
    address: str
    highlight: str
    open_hours: str
    phone: str


class AttractionResponse(AttractionCreate):
    id: int


database_url = URL.create(
    "mysql+pymysql",
    username=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT,
    database=DB_NAME,
)

connect_args = {"ssl": {"cert_reqs": ssl.CERT_NONE}} if DB_SSL_ENABLED else {}
engine = create_engine(database_url, pool_pre_ping=True, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

app = FastAPI(
    title="Daegu Tourism API",
    version="2.0.0",
    description="MySQL(RDS), JWT 로그인, users/attractions CRUD를 제공하는 FastAPI 백엔드입니다.",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_access_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def verify_password(plain_password: str, password_hash: str) -> bool:
    return pbkdf2_sha256.verify(plain_password, password_hash)


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        if not email:
            raise credentials_exception
    except JWTError as exc:
        raise credentials_exception from exc

    user = db.scalar(select(User).where(User.email == email))
    if not user:
        raise credentials_exception
    return user


def attraction_to_dict(item: Attraction) -> dict[str, object]:
    return {
        "id": item.id,
        "name": item.name,
        "category": item.category,
        "district": item.district,
        "address": item.address,
        "highlight": item.highlight,
        "open_hours": item.open_hours,
        "phone": item.phone,
    }


def seed_initial_data():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        user = db.scalar(select(User).where(User.email == "test1@test.com"))
        if not user:
            db.add(
                User(
                    email="test1@test.com",
                    password_hash=pbkdf2_sha256.hash("123456"),
                    full_name="Test One",
                    is_active=True,
                )
            )

        existing_attractions = db.scalar(select(Attraction.id))
        if existing_attractions is None:
            db.add_all(
                [
                    Attraction(name="동성로", category="문화", district="중구", address="대구광역시 중구 동성로 일대", highlight="대구 대표 번화가, 쇼핑과 야간 산책 코스", open_hours="상시 개방", phone="053-000-0001"),
                    Attraction(name="앞산전망대", category="전망", district="남구", address="대구광역시 남구 앞산순환로 454", highlight="도심과 산 능선을 함께 볼 수 있는 야경 포인트", open_hours="09:00-18:00", phone="053-000-0002"),
                    Attraction(name="서문시장", category="문화", district="중구", address="대구광역시 중구 큰장로26길 45", highlight="야시장과 먹거리로 유명한 전통시장", open_hours="09:00-19:00", phone="053-000-0003"),
                    Attraction(name="팔공산 케이블카", category="자연", district="동구", address="대구광역시 동구 팔공산로 185길 51", highlight="사계절 산세를 감상할 수 있는 대표 자연 코스", open_hours="09:30-18:00", phone="053-000-0004"),
                    Attraction(name="대구근대골목", category="역사", district="중구", address="대구광역시 중구 계산동 일대", highlight="근대 건축과 골목 스토리텔링 산책 코스", open_hours="상시 개방", phone="053-000-0005"),
                    Attraction(name="수성못", category="자연", district="수성구", address="대구광역시 수성구 두산동 512", highlight="산책, 분수, 카페거리가 어우러진 호수 명소", open_hours="상시 개방", phone="053-000-0006"),
                    Attraction(name="김광석다시그리기길", category="문화", district="중구", address="대구광역시 중구 달구벌대로 2238 일대", highlight="벽화와 음악 감성이 살아 있는 골목", open_hours="상시 개방", phone="053-000-0007"),
                    Attraction(name="달성공원", category="역사", district="중구", address="대구광역시 중구 달성공원로 35", highlight="도심 속 역사와 휴식 공간을 함께 즐길 수 있는 공원", open_hours="05:00-21:00", phone="053-000-0008"),
                ]
            )
        db.commit()
    finally:
        db.close()


@app.on_event("startup")
def on_startup():
    seed_initial_data()


@app.get("/", tags=["meta"])
def root() -> dict[str, str]:
    return {
        "message": "Daegu Tourism API is running",
        "docs": "/docs",
        "redoc": "/redoc",
        "openapi": "/openapi.json",
        "login": "/auth/login",
    }


@app.get("/health", tags=["meta"])
def health(db: Session = Depends(get_db)) -> dict[str, object]:
    user_count = len(db.scalars(select(User)).all())
    attraction_count = len(db.scalars(select(Attraction)).all())
    return {"status": "ok", "db": "mysql", "users": user_count, "attractions": attraction_count}


@app.post("/auth/login", response_model=Token, tags=["auth"])
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)) -> Token:
    user = db.scalar(select(User).where(User.email == form_data.username))
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    access_token = create_access_token(user.email)
    return Token(access_token=access_token, token_type="bearer")


@app.get("/auth/me", response_model=UserResponse, tags=["auth"])
def me(current_user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
    )


@app.get("/api/attractions", tags=["attractions"])
def list_attractions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    items = db.scalars(select(Attraction).order_by(Attraction.id.asc())).all()
    return {
        "city": "Daegu",
        "count": len(items),
        "items": [attraction_to_dict(item) for item in items],
        "user": current_user.email,
    }


@app.get("/api/attractions/{attraction_id}", response_model=AttractionResponse, tags=["attractions"])
def get_attraction(
    attraction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AttractionResponse:
    item = db.get(Attraction, attraction_id)
    if not item:
        raise HTTPException(status_code=404, detail="Attraction not found")
    return AttractionResponse(**attraction_to_dict(item))


@app.post("/api/attractions", response_model=AttractionResponse, tags=["attractions"])
def create_attraction(
    payload: AttractionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AttractionResponse:
    item = Attraction(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return AttractionResponse(**attraction_to_dict(item))


@app.put("/api/attractions/{attraction_id}", response_model=AttractionResponse, tags=["attractions"])
def update_attraction(
    attraction_id: int,
    payload: AttractionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AttractionResponse:
    item = db.get(Attraction, attraction_id)
    if not item:
        raise HTTPException(status_code=404, detail="Attraction not found")
    for key, value in payload.model_dump().items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return AttractionResponse(**attraction_to_dict(item))


@app.delete("/api/attractions/{attraction_id}", tags=["attractions"])
def delete_attraction(
    attraction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    item = db.get(Attraction, attraction_id)
    if not item:
        raise HTTPException(status_code=404, detail="Attraction not found")
    db.delete(item)
    db.commit()
    return {"deleted": True, "id": attraction_id}
EOF

cat > "$BE_BUILD_DIR/daegu-tour-api.service" <<EOF
[Unit]
Description=Daegu Tourism FastAPI Service
After=network.target

[Service]
User=${SSH_USER}
WorkingDirectory=${BE_APP_ROOT}
EnvironmentFile=/etc/default/daegu-tour-api
ExecStart=${BE_APP_ROOT}/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port ${BE_APP_PORT}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

cat > "$BE_BUILD_DIR/daegu-tour-api.env" <<'EOF'
DB_HOST=database-1.cg0ugoglztrn.ap-northeast-2.rds.amazonaws.com
DB_PORT=3306
DB_NAME=daegu_tourism
DB_USER=admin
DB_PASSWORD=Admin1234!!
DB_SSL_ENABLED=true
EOF

cat > "$BE_BUILD_DIR/daegu-tour-api.nginx.conf" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:${BE_APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "Uploading frontend bundle to ${FE_HOST}"
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "${SSH_USER}@${FE_HOST}" "rm -rf /tmp/daegu-grid && mkdir -p /tmp/daegu-grid"
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no -r "$FE_BUILD_DIR"/* "${SSH_USER}@${FE_HOST}:/tmp/daegu-grid/"

echo "Deploying frontend on ${FE_HOST}"
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "${SSH_USER}@${FE_HOST}" bash <<EOF
set -euo pipefail
sudo apt-get update
sudo apt-get install -y nginx
sudo mkdir -p "${FE_APP_DIR}"
sudo cp -r /tmp/daegu-grid/* "${FE_APP_DIR}/"
sudo rm -rf /tmp/daegu-grid
sudo chown -R www-data:www-data "${FE_APP_DIR}"
sudo systemctl enable nginx
sudo systemctl restart nginx
EOF

echo "Uploading backend bundle to ${BE_HOST}"
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "${SSH_USER}@${BE_HOST}" "rm -rf /tmp/daegu-tour-api && mkdir -p /tmp/daegu-tour-api"
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no -r "$BE_BUILD_DIR"/* "${SSH_USER}@${BE_HOST}:/tmp/daegu-tour-api/"

echo "Deploying backend on ${BE_HOST}"
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "${SSH_USER}@${BE_HOST}" bash <<EOF
set -euo pipefail
sudo apt-get update
sudo apt-get install -y python3 python3-venv python3-pip nginx default-mysql-client
sudo mkdir -p "${BE_APP_ROOT}"
sudo cp -r /tmp/daegu-tour-api/* "${BE_APP_ROOT}/"
sudo rm -rf /tmp/daegu-tour-api
sudo chown -R "${SSH_USER}:${SSH_USER}" "${BE_APP_ROOT}"
mysql -h database-1.cg0ugoglztrn.ap-northeast-2.rds.amazonaws.com -u admin -p'Admin1234!!' -e "CREATE DATABASE IF NOT EXISTS daegu_tourism CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
cd "${BE_APP_ROOT}"
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
sudo cp daegu-tour-api.service /etc/systemd/system/daegu-tour-api.service
sudo cp daegu-tour-api.env /etc/default/daegu-tour-api
sudo cp daegu-tour-api.nginx.conf /etc/nginx/sites-available/daegu-tour-api
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/daegu-tour-api /etc/nginx/sites-enabled/daegu-tour-api
sudo nginx -t
sudo systemctl daemon-reload
sudo systemctl enable daegu-tour-api
sudo systemctl restart daegu-tour-api
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl status --no-pager daegu-tour-api
EOF

cat <<EOF

Deployment completed.

Frontend URL:
  http://${FE_HOST}/daegu-grid/

Backend health:
  http://${BE_HOST}/health

Backend Swagger:
  http://${BE_HOST}/docs

Backend ReDoc:
  http://${BE_HOST}/redoc

Backend data:
  http://${BE_HOST}/api/attractions
EOF
