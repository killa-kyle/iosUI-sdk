// Capture real site interactions, including intermediate pointer positions.
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { resolve, extname } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
const staging = process.argv[2];
assert(staging, "Pass an external staging directory for PNG frames");
const root = fileURLToPath(new URL("../site/", import.meta.url));
const output = fileURLToPath(new URL("../docs/media/", import.meta.url));
const { chromium } = await import(
  process.env.PLAYWRIGHT_MODULE || "playwright"
);
const server = createServer(async (req, res) => {
  try {
    let pathname = new URL(req.url, "http://localhost").pathname;
    if (pathname.endsWith("/")) pathname += "index.html";
    const file = resolve(root, "." + pathname);
    if (!file.startsWith(root)) throw Error("Invalid path");
    res.setHeader(
      "Content-Type",
      { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" }[
        extname(file)
      ] || "application/octet-stream",
    );
    res.end(await readFile(file));
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const browser = await chromium.launch();
try {
  await mkdir(staging, { recursive: true });
  await mkdir(output, { recursive: true });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 1100 },
    deviceScaleFactor: 1,
    colorScheme: "light",
  });
  const examples = {};
  for (const kind of ["calendar", "drag", "crop"]) {
    await page.goto(`http://127.0.0.1:${server.address().port}/docs/#${kind}`);
    await page.locator("#preview > *").first().waitFor();
    await page.evaluate(() => document.fonts.ready);
    const heading = await page.locator(".page-heading").boundingBox(),
      preview = await page.locator("#preview").boundingBox();
    const clip = {
      x: heading.x - 24,
      y: heading.y - 24,
      width: preview.width + 48,
      height: preview.y + preview.height - heading.y + 48,
    };
    let number = 0;
    const frames = [];
    const frame = async (seconds = 0.1) => {
      const filename = resolve(
        staging,
        `${kind}-${String(number++).padStart(3, "0")}.png`,
      );
      await page.screenshot({ path: filename, clip });
      frames.push({ filename, seconds });
    };
    await frame(1);
    if (kind === "calendar") {
      for (const day of ["05", "09", "12", "15"]) {
        await page
          .getByRole("button", { name: `2026-11-${day}`, exact: true })
          .click();
        await frame(0.9);
      }
      assert.match(
        await page.locator("#preview output").textContent(),
        /2026-11-12.*2026-11-15/,
      );
    } else {
      const handle =
        kind === "drag"
          ? page.locator(".drag-card")
          : page.getByRole("button", { name: "Resize se", exact: true });
      const box = await handle.boundingBox();
      const from = { x: box.x + box.width / 2, y: box.y + box.height / 2 };
      const zone =
        kind === "drag" ? await page.locator(".drop-zone").boundingBox() : null;
      const to = zone
        ? { x: zone.x + zone.width / 2, y: zone.y + zone.height / 2 }
        : { x: from.x + 55, y: from.y + 55 };
      await page.mouse.move(from.x, from.y);
      await page.mouse.down();
      for (let i = 1; i <= 18; i++) {
        await page.mouse.move(
          from.x + ((to.x - from.x) * i) / 18,
          from.y + ((to.y - from.y) * i) / 18,
        );
        await frame();
      }
      await page.mouse.up();
      await frame(1.5);
      if (kind === "drag")
        assert.match(
          await page.locator("#preview output").textContent(),
          /Moved card to archive/,
        );
      else {
        const size = (
          await page.locator("#preview output").textContent()
        ).match(/(\d+) × (\d+)/);
        assert(
          size &&
            size[1] === size[2] &&
            Number(size[1]) > 140 &&
            Number(size[1]) <= 195,
        );
      }
    }
    const sequence = resolve(staging, `${kind}.txt`);
    const quote = (filename) => filename.replaceAll("'", "'\\''");
    await writeFile(
      sequence,
      frames
        .map((f) => `file '${quote(f.filename)}'\nduration ${f.seconds}`)
        .join("\n") + `\nfile '${quote(frames.at(-1).filename)}'\n`,
    );
    execFileSync("ffmpeg", [
      "-v",
      "error",
      "-y",
      "-f",
      "concat",
      "-safe",
      "0",
      "-i",
      sequence,
      "-filter_complex",
      "[0:v]scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=sierra2_4a",
      "-fps_mode",
      "vfr",
      "-loop",
      "0",
      resolve(output, `${kind}.gif`),
    ]);
    examples[kind] = { frames: frames.length, motion: kind !== "calendar" };
  }
  await writeFile(
    resolve(output, "capture.json"),
    JSON.stringify(
      {
        source: "Actual site/docs previews",
        styling: "Unmodified site CSS, light theme",
        capture:
          "Playwright pointer input and browser screenshots; ffmpeg GIF encoding",
        semantics:
          "Browser illustrations, not Swift execution or native recordings",
        examples,
      },
      null,
      2,
    ) + "\n",
  );
  console.log(JSON.stringify(examples));
} finally {
  await browser.close();
  await new Promise((r) => server.close(r));
}
