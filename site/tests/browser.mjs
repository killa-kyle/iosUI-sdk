import assert from "node:assert/strict";
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { resolve, extname, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { components } from "../docs/components.js";
import { guides } from "../docs/guides.js";
assert.equal(
  new Set([...guides, ...components].map((p) => p.id)).size,
  guides.length + components.length,
  "Documentation page IDs must be unique",
);
const root = fileURLToPath(new URL("../", import.meta.url));
const { chromium } = await import(
  process.env.PLAYWRIGHT_MODULE || "playwright"
);
const server = createServer(async (req, res) => {
  try {
    let pathname = decodeURIComponent(
      new URL(req.url, "http://localhost").pathname,
    );
    if (pathname.endsWith("/")) pathname += "index.html";
    const file = resolve(root, "." + pathname);
    if (!file.startsWith(resolve(root) + sep)) {
      res.writeHead(403).end();
      return;
    }
    const bytes = await readFile(file);
    res.setHeader(
      "Content-Type",
      { ".html": "text/html", ".css": "text/css", ".js": "text/javascript" }[
        extname(file)
      ] || "application/octet-stream",
    );
    res.end(bytes);
  } catch {
    res.writeHead(404).end("Not found");
  }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const origin = `http://127.0.0.1:${server.address().port}`;
let browser;
try {
  browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 1440, height: 1000 },
    reducedMotion: "reduce",
  });
  await context.grantPermissions(["clipboard-read", "clipboard-write"], {
    origin,
  });
  const page = await context.newPage(),
    errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  const visit = async (id) => {
    await page.goto(`${origin}/docs/#${id}`);
    await page.locator("#title").waitFor();
    await page.waitForFunction(
      (id) =>
        location.hash === `#${id}` &&
        document.querySelector("#title").textContent.length > 0,
      id,
    );
  };
  for (const entry of [...guides, ...components]) {
    await visit(entry.id);
    assert.equal(await page.locator("#title").textContent(), entry.title);
    assert.equal(await page.locator("#code").textContent(), entry.code);
    if (entry.kind !== "guide")
      assert.ok(
        await page.locator("#preview").evaluate((e) => e.children.length > 0),
        `Missing preview: ${entry.id}`,
      );
  }
  await visit("calendar");
  await page.getByRole("tab", { name: "UIKit", exact: true }).click();
  assert.match(
    await page.locator("#code").textContent(),
    /BehaviorUIKit.calendar/,
  );
  await page.keyboard.press("Home");
  assert.match(await page.locator("#code").textContent(), /BehaviorCalendar/);
  await page.getByRole("button", { name: "Copy code", exact: true }).click();
  await page.getByText("Code copied.", { exact: true }).waitFor();
  await page.locator("#search").fill("crop");
  assert.equal(await page.locator("#navigation a").count(), 1);
  assert.match(await page.locator("#navigation a").textContent(), /cropper/);
  await page.locator("#search").fill("");
  await page.getByRole("button", { name: "2026-11-01", exact: true }).click();
  await page.getByRole("button", { name: "2026-11-05", exact: true }).click();
  assert.match(
    await page.locator("#preview output").textContent(),
    /crosses November 3/,
  );
  assert.ok(
    await page
      .getByRole("button", { name: "2026-11-03", exact: true })
      .isDisabled(),
  );
  await page.getByRole("button", { name: "2026-11-02", exact: true }).click();
  assert.match(
    await page.locator("#preview output").textContent(),
    /2026-11-01 → 2026-11-02/,
  );
  await visit("selection");
  await page.getByRole("button", { name: "Café", exact: true }).click();
  await page.getByRole("button", { name: "Color", exact: true }).click();
  assert.match(
    await page.locator("#preview output").textContent(),
    /Café, Color/,
  );
  await visit("values");
  await page.getByRole("button", { name: "Increase value" }).click();
  assert.equal(await page.locator("#preview output").textContent(), "50");
  await visit("grid");
  await page.getByRole("gridcell", { name: "Row 1 column 1" }).click();
  await page
    .getByRole("gridcell", { name: "Row 3 column 4" })
    .click({ modifiers: ["Shift"] });
  assert.equal(
    await page.locator("#preview output").textContent(),
    "Selected cells: 11",
  );
  await visit("tree");
  await page.getByRole("button", { name: "Expand Library" }).click();
  await page.getByRole("button", { name: "Photos", exact: true }).click();
  assert.match(
    await page.locator("#preview output").textContent(),
    /Selected: Photos/,
  );
  await visit("drag");
  const card = page.locator(".drag-card"),
    zone = page.locator(".drop-zone");
  const initialCard = await card.boundingBox(),
    targetZone = await zone.boundingBox();
  await page.mouse.move(
    initialCard.x + initialCard.width / 2,
    initialCard.y + initialCard.height / 2,
  );
  await page.mouse.down();
  await page.mouse.move(
    initialCard.x + initialCard.width / 2 + 20,
    initialCard.y + initialCard.height / 2 + 8,
  );
  assert.match(await card.getAttribute("style"), /translate/);
  await page.keyboard.press("Escape");
  await page.mouse.up();
  assert.ok(!(await card.getAttribute("style")).includes("translate"));
  assert.equal(await page.locator("#preview output").textContent(), "No drop");
  await page.mouse.move(
    initialCard.x + initialCard.width / 2,
    initialCard.y + initialCard.height / 2,
  );
  await page.mouse.down();
  await page.mouse.move(
    targetZone.x + targetZone.width / 2,
    targetZone.y + targetZone.height / 2,
    { steps: 12 },
  );
  assert.match(await card.getAttribute("style"), /translate/);
  assert.equal(await zone.getAttribute("data-targeted"), "true");
  await page.mouse.up();
  assert.equal(await zone.locator(".drag-card").count(), 1);
  assert.match(
    await page.locator("#preview output").textContent(),
    /Moved card to archive/,
  );
  await visit("resize");
  await page.getByRole("button", { name: "Resize se", exact: true }).focus();
  await page.keyboard.press("ArrowRight");
  assert.match(
    await page.locator("#preview output").textContent(),
    /141 × 105/,
  );
  await visit("crop");
  await page.getByRole("button", { name: "Resize se", exact: true }).focus();
  await page.keyboard.press("ArrowRight");
  assert.match(
    await page.locator("#preview output").textContent(),
    /141 × 141/,
  );
  await visit("carousel");
  await page.getByRole("button", { name: "Next slide", exact: true }).click();
  assert.equal(await page.locator(".slide-preview").textContent(), "Harbor");
  await visit("editor");
  await page.getByRole("button", { name: "Apply bold", exact: true }).click();
  assert.ok(await page.locator(".rich-editor strong").count());
  await visit("menu");
  await page.getByText("Open menu", { exact: true }).click();
  await page
    .getByRole("menuitemcheckbox", { name: "Favorite", exact: true })
    .click();
  assert.match(
    await page.locator("#preview output").textContent(),
    /Action: favorite/,
  );
  await visit("overlays");
  await page
    .getByRole("button", { name: "Open inspector", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Open nested overlay", exact: true })
    .click();
  await page
    .getByRole("dialog", { name: "Confirmation", exact: true })
    .waitFor();
  await page
    .getByRole("button", { name: "Close confirmation", exact: true })
    .click();
  assert.match(
    await page.locator("#preview output").textContent(),
    /Overlay count: 1/,
  );
  await page
    .getByRole("button", { name: "Close inspector", exact: true })
    .click();
  assert.match(
    await page.locator("#preview output").textContent(),
    /Overlay count: 0/,
  );
  await visit("agent");
  await page
    .getByRole("button", { name: "Capture snapshot", exact: true })
    .click();
  await page.getByRole("button", { name: "Agent next", exact: true }).click();
  assert.match(
    await page.locator(".agent-json").textContent(),
    /Accepted next/,
  );
  await page.getByRole("button", { name: "Agent next", exact: true }).click();
  assert.match(
    await page.locator(".agent-json").textContent(),
    /stale snapshot/,
  );
  await page
    .getByRole("button", { name: "Capture snapshot", exact: true })
    .click();
  await page.getByRole("checkbox", { name: "Host allows action" }).uncheck();
  await page.getByRole("button", { name: "Agent next", exact: true }).click();
  assert.match(await page.locator(".agent-json").textContent(), /Denied/);
  for (const width of [1440, 390])
    for (const theme of ["light", "dark"]) {
      await page.setViewportSize({ width, height: 900 });
      await visit("calendar");
      await page.evaluate((theme) => {
        document.documentElement.dataset.theme = theme;
      }, theme);
      assert.ok(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= innerWidth,
        ),
        `Overflow at ${width}`,
      );
      if (process.env.DOCS_SCREENSHOT_DIR) {
        await mkdir(process.env.DOCS_SCREENSHOT_DIR, { recursive: true });
        await page.screenshot({
          path: resolve(
            process.env.DOCS_SCREENSHOT_DIR,
            `docs-${width}-${theme}.png`,
          ),
          fullPage: true,
        });
      }
    }
  await page.getByRole("button", { name: "Browse", exact: true }).click();
  await page.locator("#search").fill("carousel");
  await page.locator("#navigation a").click();
  await page.waitForFunction(
    () => document.querySelector("#title").textContent === "Carousel",
  );
  assert.equal(await page.locator("#title").textContent(), "Carousel");
  assert.equal(
    await page.locator("#navigation-toggle").getAttribute("aria-expanded"),
    "false",
  );
  // Controls stay under the pointer and retain keyboard focus as state changes.
  for (const viewport of [
    { width: 390, height: 844 },
    { width: 1440, height: 1000 },
  ]) {
    await page.setViewportSize(viewport);
    await visit("calendar");
    const date = page.getByRole("button", { name: "2026-11-01", exact: true });
    await date.click();
    assert.ok(
      await date.evaluate((e) => document.activeElement === e),
      "Calendar selection must retain focus",
    );
    await page.keyboard.press("Tab");
    assert.equal(
      await page.evaluate(() =>
        document.activeElement.getAttribute("aria-label"),
      ),
      "2026-11-02",
    );
    await visit("disclosure");
    const trigger = page.locator("summary");
    await trigger.scrollIntoViewIfNeeded();
    const closed = await trigger.boundingBox();
    await trigger.click();
    const opened = await trigger.boundingBox();
    assert.ok(
      Math.abs(opened.y - closed.y) < 1,
      "Disclosure trigger must stay in place",
    );
    await visit("drag");
    const target = page.locator(".drop-zone");
    await page
      .getByRole("button", { name: "Move to archive", exact: true })
      .scrollIntoViewIfNeeded();
    const before = await target.boundingBox();
    await page
      .getByRole("button", { name: "Move to archive", exact: true })
      .click();
    const after = await target.boundingBox();
    assert.ok(
      Math.abs(after.y - before.y) < 1 &&
        Math.abs(after.height - before.height) < 1,
      "Drop target must retain its bounds",
    );
  }
  await page.goto(`${origin}/examples/`);
  assert.equal(await page.locator("article.recipe").count(), 3);
  for (const image of await page.locator("article.recipe img").all()) {
    await image.scrollIntoViewIfNeeded();
    await image.evaluate((img) => img.decode());
    assert.ok(
      await image.evaluate((img) => img.complete && img.naturalWidth > 0),
      "Real native capture must load",
    );
  }
  for (const width of [390, 1440]) {
    await page.setViewportSize({ width, height: 1000 });
    assert.ok(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
      "Recipe page must fit the viewport",
    );
    if (width === 390) {
      const image = await page
        .locator("#confirmation .recipe-result")
        .boundingBox();
      const source = await page
        .locator("#confirmation .recipe-source")
        .boundingBox();
      assert.ok(
        image.y < source.y,
        "Show the native result before the complete listing on phones",
      );
    }
  }
  const swift = await page.request.get(`${origin}/examples/PlanPicker.swift`);
  assert.ok((await swift.text()).includes("BehaviorChoiceList("));
  await page.goto(`${origin}/`);
  await page.getByRole("link", { name: "Docs", exact: true }).click();
  await page.locator("#title").waitFor();
  assert.deepEqual(errors, []);
  console.log(
    JSON.stringify({
      pages: guides.length + components.length,
      behaviorPreviews: components.length,
      interactions: "passed",
      responsiveThemes: 4,
      consoleErrors: 0,
    }),
  );
} finally {
  if (browser) await browser.close();
  await new Promise((r) => server.close(r));
}
