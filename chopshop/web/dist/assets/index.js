const root = document.getElementById("root");
const emptyContract = {
  title: "Active Contract",
  subtitle: "Street vehicle list",
  hint: "Find matching vehicles already driving around the city and bring each one to the chop zone.",
  vehicles: [],
  completedCount: 0,
  totalCount: 0,
  complete: false
};

let visible = false;
let contract = emptyContract;

function resourceName() {
  return typeof GetParentResourceName === "function" ? GetParentResourceName() : "chopshop";
}

function post(event, data = {}) {
  return fetch(`https://${resourceName()}/${event}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data)
  }).catch(() => {});
}

function icon(name) {
  const paths = {
    close: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    refresh: '<path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M3 21v-5h5"/><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M16 8h5V3"/>',
    list: '<rect width="8" height="4" x="8" y="2" rx="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="M9 14h6"/><path d="M9 10h6"/><path d="M9 18h6"/>',
    money: '<path d="M11 15h2a2 2 0 1 0 0-4h-3a2 2 0 0 0-2 2v.5"/><path d="M12 7v2"/><path d="M12 15v2"/><path d="M5 11h2"/><path d="M17 13h2"/><path d="M4 7h16v10H4z"/>',
    check: '<path d="M20 6 9 17l-5-5"/>',
    circle: '<circle cx="12" cy="12" r="8"/>'
  };

  return `<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${paths[name] ?? ""}</svg>`;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function render() {
  if (!visible) {
    root.innerHTML = "";
    return;
  }

  const progress = contract.totalCount > 0 ? Math.max(0, Math.min(100, contract.completedCount / contract.totalCount * 100)) : 0;
  const rows = contract.vehicles.map((vehicle) => {
    const done = vehicle.completed === true;
    return `
      <div class="vehicle-row">
        <div class="vehicle-status ${done ? "done" : ""}">${icon(done ? "check" : "circle")}</div>
        <div class="vehicle-copy">
          <div class="vehicle-label">${escapeHtml(vehicle.label)}</div>
          <div class="vehicle-model">${escapeHtml(vehicle.model)}</div>
        </div>
        <div class="badge ${done ? "done" : ""}">${done ? "Done" : `#${escapeHtml(vehicle.index)}`}</div>
      </div>
    `;
  }).join("");

  root.innerHTML = `
    <main class="screen">
      <section class="panel" role="dialog" aria-label="${escapeHtml(contract.title)}">
        <header class="panel-header">
          <div class="header-copy">
            <div class="badge accent">${icon("list")}${escapeHtml(contract.subtitle)}</div>
            <h1>${escapeHtml(contract.title)}</h1>
            <p>${escapeHtml(contract.hint)}</p>
          </div>
          <button class="icon-button" id="closeButton" type="button" title="Close" aria-label="Close">${icon("close")}</button>
        </header>

        <div class="panel-body">
          <div class="progress-box">
            <div class="progress-label">
              <span>Progress</span>
              <strong>${escapeHtml(contract.completedCount)}/${escapeHtml(contract.totalCount)}</strong>
            </div>
            <div class="progress-track"><div class="progress-fill" style="width:${progress}%"></div></div>
          </div>
          <div class="vehicle-list">${rows}</div>
        </div>

        <footer class="panel-footer">
          <button class="button secondary" id="refreshButton" type="button">${icon("refresh")}Refresh</button>
          <button class="button primary" id="turnInButton" type="button" ${contract.complete ? "" : "disabled"}>${icon("money")}Turn in</button>
        </footer>
      </section>
    </main>
  `;

  document.getElementById("closeButton")?.addEventListener("click", () => post("close"));
  document.getElementById("refreshButton")?.addEventListener("click", () => post("refresh"));
  document.getElementById("turnInButton")?.addEventListener("click", () => post("turnIn"));
}

window.addEventListener("message", (event) => {
  const { action, payload } = event.data ?? {};
  if (action === "openContract") {
    contract = payload ?? emptyContract;
    visible = true;
    render();
  }
  if (action === "updateContract") {
    contract = payload ?? emptyContract;
    render();
  }
  if (action === "closeContract") {
    visible = false;
    render();
  }
});

window.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && visible) {
    visible = false;
    render();
    post("close");
  }
});

