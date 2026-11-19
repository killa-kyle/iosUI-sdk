import { components } from "./components.js";
import { guides } from "./guides.js";
import { foundationPreview } from "./preview-foundations.js";
import { advancedPreview } from "./preview-advanced.js";
import { geometryPreview } from "./preview-geometry.js";
const pages = [...guides.slice(0, 3), ...components, ...guides.slice(3)];
const $ = (id) => document.getElementById(id);
let cleanup = () => {},
  current,
  codeText = "";
let theme = matchMedia("(prefers-color-scheme: dark)").matches
  ? "dark"
  : "light";
try {
  theme = localStorage.getItem("iosui-docs-theme") || theme;
} catch {}
function applyTheme() {
  document.documentElement.dataset.theme = theme;
  $("theme").setAttribute("aria-pressed", String(theme === "dark"));
  $("theme").setAttribute(
    "aria-label",
    theme === "dark" ? "Use light theme" : "Use dark theme",
  );
}
applyTheme();
$("theme").onclick = () => {
  theme = theme === "dark" ? "light" : "dark";
  applyTheme();
  try {
    localStorage.setItem("iosui-docs-theme", theme);
  } catch {}
};
function closeNavigation() {
  $("sidebar").dataset.open = "false";
  $("navigation-toggle").setAttribute("aria-expanded", "false");
}
$("navigation-toggle").onclick = () => {
  const open = $("sidebar").dataset.open !== "true";
  $("sidebar").dataset.open = String(open);
  $("navigation-toggle").setAttribute("aria-expanded", String(open));
  if (open) $("search").focus();
};
function navigation() {
  const query = $("search").value.trim().toLowerCase();
  const filtered = pages.filter((p) =>
    `${p.title} ${p.description} ${p.core}`.toLowerCase().includes(query),
  );
  $("navigation").replaceChildren();
  for (const group of ["Get started", "Behaviors", "Agents", "Reference"]) {
    const matches = filtered.filter((p) => p.group === group);
    if (!matches.length) continue;
    const section = document.createElement("div");
    section.className = "nav-group";
    const heading = document.createElement("h2");
    heading.textContent = group;
    section.append(heading);
    for (const page of matches) {
      const link = document.createElement("a");
      link.href = `#${page.id}`;
      link.textContent = page.title;
      if (page.id === current?.id) link.setAttribute("aria-current", "page");
      link.onclick = () => {
        closeNavigation();
        if (page.id === current?.id) $("article").focus();
      };
      section.append(link);
    }
    $("navigation").append(section);
  }
  $("search-empty").hidden = filtered.length !== 0;
}
$("search").oninput = navigation;
document.addEventListener("keydown", (event) => {
  if (
    event.key === "/" &&
    !["INPUT", "TEXTAREA"].includes(document.activeElement?.tagName) &&
    !document.activeElement?.isContentEditable
  ) {
    event.preventDefault();
    if (innerWidth < 761) {
      $("sidebar").dataset.open = "true";
      $("navigation-toggle").setAttribute("aria-expanded", "true");
    }
    $("search").focus();
  }
  if (event.key === "Escape" && $("sidebar").dataset.open === "true") {
    closeNavigation();
    $("navigation-toggle").focus();
  }
});
for (const anchor of document.querySelectorAll("[data-anchor]"))
  anchor.onclick = (event) => {
    event.preventDefault();
    $(anchor.dataset.anchor).scrollIntoView({
      behavior: matchMedia("(prefers-reduced-motion: reduce)").matches
        ? "auto"
        : "smooth",
    });
  };
function showCode(page) {
  const tabs = [{ name: page.codeTitle || "SwiftUI", code: page.code }];
  if (page.uikit) tabs.push({ name: "UIKit", code: page.uikit });
  if (page.previewCode) tabs.push({ name: "Preview", code: page.previewCode });
  $("code-tabs").replaceChildren();
  function select(index, focus = false) {
    for (const [i, button] of [...$("code-tabs").children].entries()) {
      button.setAttribute("aria-selected", String(i === index));
      button.tabIndex = i === index ? 0 : -1;
    }
    codeText = tabs[index].code;
    $("code").textContent = codeText;
    $("code-panel").setAttribute("aria-labelledby", `code-tab-${index}`);
    $("copy-status").textContent = "";
    $("copy-code").textContent = "Copy code";
    if (focus) $("code-tabs").children[index].focus();
  }
  for (const [i, tab] of tabs.entries()) {
    const button = document.createElement("button");
    button.type = "button";
    button.role = "tab";
    button.id = `code-tab-${i}`;
    button.textContent = tab.name;
    button.setAttribute("aria-controls", "code-panel");
    button.onclick = () => select(i);
    button.onkeydown = (event) => {
      if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
        event.preventDefault();
        const next =
          event.key === "Home"
            ? 0
            : event.key === "End"
              ? tabs.length - 1
              : (i + (event.key === "ArrowLeft" ? -1 : 1) + tabs.length) %
                tabs.length;
        select(next, true);
      }
    };
    $("code-tabs").append(button);
  }
  select(0);
}
$("copy-code").onclick = async () => {
  try {
    await navigator.clipboard.writeText(codeText);
    $("copy-code").textContent = "Copied ✓";
    $("copy-status").textContent = "Code copied.";
  } catch {
    $("copy-status").textContent =
      "Clipboard unavailable. Select the code to copy it.";
  }
};
function preview(page) {
  cleanup();
  cleanup = () => {};
  $("preview").replaceChildren();
  const result =
    foundationPreview(page.kind, $("preview")) ??
    advancedPreview(page.kind, $("preview")) ??
    geometryPreview(page.kind, $("preview"));
  if (typeof result === "function") cleanup = result;
}
$("reset-preview").onclick = () => preview(current);
function render(initial = false) {
  let id;
  try {
    id = decodeURIComponent(location.hash.slice(1)) || "introduction";
  } catch {
    id = "introduction";
  }
  const page = pages.find((p) => p.id === id);
  cleanup();
  cleanup = () => {};
  current = page || guides[0];
  document.title = `${page?.title || "Page not found"} — iosUI-sdk`;
  $("title").textContent = page?.title || "Page not found";
  $("breadcrumb").textContent = page?.title || "Not found";
  $("description").textContent =
    page?.description ||
    "Choose a page from the navigation, or search for a behavior.";
  $("badge").textContent = current.extended
    ? "Extended native API · 0.2.1"
    : "Native Swift";
  $("badge").dataset.status = current.extended ? "extended" : "stable";
  $("guide-content").replaceChildren();
  for (const text of current.body || []) {
    const p = document.createElement("p");
    p.textContent = text;
    $("guide-content").append(p);
  }
  if (current.links) {
    const links = document.createElement("p");
    links.className = "guide-links";
    for (const [title, url] of current.links) {
      const a = document.createElement("a");
      a.href = url;
      a.textContent = `${title} ↗`;
      links.append(a);
    }
    $("guide-content").append(links);
  }
  $("preview-section").hidden = current.kind === "guide" || !page;
  if (current.kind !== "guide" && page) preview(current);
  showCode(current);
  document.querySelector(".usage-note").hidden =
    current.kind === "guide" || current.codeTitle === "Core";
  $("api-body").replaceChildren();
  for (const values of current.api) {
    const tr = document.createElement("tr");
    for (const value of values) {
      const td = document.createElement("td");
      td.textContent = value;
      tr.append(td);
    }
    $("api-body").append(tr);
  }
  $("notes").replaceChildren();
  for (const note of current.notes) {
    const li = document.createElement("li");
    li.textContent = note;
    $("notes").append(li);
  }
  const path = current.source.startsWith("UIBehavior")
    ? `Sources/${current.source}`
    : current.source;
  $("source-link").href =
    `https://github.com/killa-kyle/iosUI-sdk/blob/0.2.1/${path}`;
  const index = pages.indexOf(current);
  for (const [direction, offset] of [
    ["previous", -1],
    ["next", 1],
  ]) {
    const sibling = pages[index + offset];
    $(direction).hidden = !sibling;
    if (sibling) {
      $(direction).href = `#${sibling.id}`;
      $(direction).textContent =
        offset < 0 ? `← ${sibling.title}` : `${sibling.title} →`;
    }
  }
  navigation();
  if (!initial) {
    scrollTo(0, 0);
    $("article").focus({ preventScroll: true });
  }
}
addEventListener("hashchange", () => render());
render(true);
