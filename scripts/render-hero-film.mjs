#!/usr/bin/env node
/** Compose authored typography/code motion around actual native video clips. */
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { resolve, dirname, extname } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const staging = resolve(process.argv[2] || "");
if (!process.argv[2])
  throw new Error("Usage: render-hero-film.mjs EXTERNAL_STAGING_DIR");
if (staging === root || staging.startsWith(root + "/"))
  throw new Error("Use staging outside the checkout");
console.log("Loading browser renderer");
const { chromium } = await import(
  process.env.PLAYWRIGHT_MODULE || "playwright"
);
console.log("Loaded browser renderer");
const specs = [
  {
    key: "morph",
    component: "MorphingPlanPicker",
    adapter: "SELECTION + ANYLAYOUT",
    title: "Change the component.",
    description: "Cards, segments and chips keep the same selection.",
  },
  {
    key: "workspace",
    component: "MediaWorkspace",
    adapter: "CROP + NESTED OVERLAYS + SELECTION",
    title: "Crop, review, publish.",
    description: "Keep the draft through nested sheets. Commit it once.",
  },
  {
    key: "conversation",
    component: "ChatInteractionCatalog",
    adapter: "STREAM + READING ANCHOR + ACTIVITY + KEYBOARD",
    title: "Read while it streams.",
    description: "Keep your place, tool details and draft through updates.",
  },
];
const data = [];
for (const spec of specs) {
  const clip = resolve(staging, spec.key + ".mp4");
  await readFile(clip);
  const source = await readFile(
    resolve(
      root,
      spec.key === "conversation"
        ? "Examples/Catalog"
        : "Examples/Catalog/Recipes",
      spec.component + ".swift",
    ),
    "utf8",
  );
  const lines = source.split("\n");
  const excerpt =
    spec.key === "morph"
      ? [
          ...lines.slice(8, 10),
          "",
          ...lines.slice(12, 17),
          "",
          ...lines.slice(21, 25),
        ]
      : spec.key === "workspace"
        ? [
            ...lines.slice(8, 11),
            "",
            ...lines.slice(43, 45),
            "",
            lines[53],
            "",
            ...lines.slice(78, 82),
          ]
        : [
            ...lines.slice(6, 9),
            "",
            ...lines.slice(264, 269),
            "",
            lines[275],
            lines[281],
          ];
  data.push({
    ...spec,
    source: excerpt.map((line) => line.replace(/^ {2}/, "")).join("\n"),
  });
}
console.log("Loaded native clips and compiled source");
const html = await readFile(resolve(root, "scripts/hero-stage.html"));
const server = createServer(async (req, res) => {
  try {
    const pathname = new URL(req.url, "http://localhost").pathname;
    if (pathname === "/film-data.json") {
      res.setHeader("content-type", "application/json");
      return res.end(JSON.stringify(data));
    }
    if (pathname === "/") {
      res.setHeader("content-type", "text/html");
      return res.end(html);
    }
    const item = specs.find(
      (s) => pathname === "/native-media/" + s.key + ".mp4",
    );
    if (!item) return res.writeHead(404).end();
    res.setHeader("content-type", "video/mp4");
    res.end(await readFile(resolve(staging, item.key + ".mp4")));
  } catch {
    res.writeHead(500).end();
  }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
await mkdir(resolve(staging, "hero-recording"), { recursive: true });
await mkdir(resolve(staging, "tmp"), { recursive: true });
process.env.TMPDIR = resolve(staging, "tmp");
console.log("Launching browser compositor");
const browser = await chromium.launch({
  headless: true,
  args: ["--disable-gpu"],
});
let raw;
try {
  const context = await browser.newContext({
    viewport: { width: 1600, height: 900 },
    deviceScaleFactor: 1,
    recordVideo: {
      dir: resolve(staging, "hero-recording"),
      size: { width: 1600, height: 900 },
    },
  });
  const page = await context.newPage();
  page.on("pageerror", (error) => console.log("Stage error:", error.message));
  console.log("Loading motion stage");
  await page.goto(`http://127.0.0.1:${server.address().port}`, {
    waitUntil: "load",
  });
  await page.evaluate(() =>
    Promise.race([
      window.filmReady,
      new Promise((_, reject) =>
        setTimeout(
          () => reject(new Error("Native media readiness timeout")),
          20000,
        ),
      ),
    ]),
  );
  console.log("Recording native-and-code motion");
  await page.waitForTimeout(700);
  await Promise.race([
    page.evaluate(() => window.playFilm()),
    new Promise((_, reject) =>
      setTimeout(
        () => reject(new Error("Hero capture exceeded 50 seconds")),
        50000,
      ),
    ),
  ]);
  await page.waitForTimeout(700);
  raw = await page.video().path();
  await context.close();
} finally {
  await browser.close();
  await new Promise((r) => server.close(r));
}
function probe(path) {
  return JSON.parse(
    execFileSync(
      "ffprobe",
      [
        "-v",
        "error",
        "-show_entries",
        "stream=width,height,nb_frames:format=duration",
        "-of",
        "json",
        path,
      ],
      { encoding: "utf8" },
    ),
  );
}
console.log("Encoding hero movie");
const metadata = probe(raw),
  total = Number(metadata.format.duration);
const offset = Math.max(0, total - 30.7);
const target = resolve(root, "site/motion/hero.mp4");
await mkdir(dirname(target), { recursive: true });
execFileSync("ffmpeg", [
  "-v",
  "error",
  "-y",
  "-i",
  raw,
  "-vf",
  `trim=start=${offset}:duration=30,setpts=PTS-STARTPTS,fps=30,scale=1280:720:flags=lanczos,format=yuv420p`,
  "-an",
  "-c:v",
  "libx264",
  "-preset",
  "medium",
  "-crf",
  "21",
  "-movflags",
  "+faststart",
  target,
]);
const poster = resolve(root, "site/motion/poster.png");
execFileSync("ffmpeg", [
  "-v",
  "error",
  "-y",
  "-ss",
  "1.4",
  "-i",
  target,
  "-frames:v",
  "1",
  poster,
]);
const final = probe(target),
  video = await readFile(target);
if (Number(final.streams[0].nb_frames) < 400)
  throw new Error("Hero movie lacks real motion frames");
if (video.length > 8_000_000) throw new Error("Hero movie exceeds 8 MB budget");
const hash = (b) => createHash("sha256").update(b).digest("hex");
const receipt = {
  source:
    "Three real native recipe recordings, composed with authored code-window and typography animation",
  duration: Number(final.format.duration),
  pixels: [1280, 720],
  frames: Number(final.streams[0].nb_frames),
  bytes: video.length,
  sha256: hash(video),
  posterSHA256: hash(await readFile(poster)),
  nativeMotionReceiptSHA256: hash(
    await readFile(resolve(root, "site/examples/motion.json")),
  ),
  graphicsSourceSHA256: hash(html),
  rendererSourceSHA256: hash(await readFile(fileURLToPath(import.meta.url))),
  processing:
    "Browser-rendered graphic motion with actual native MP4 playback; crop/trim/resize/time scaling only for native footage; H.264 silent 30 fps fast-start output. No recreated native control animations.",
  chapters: specs.map((s, i) => ({
    component: s.component,
    seconds: [i * 10, (i + 1) * 10],
  })),
};
await writeFile(
  resolve(root, "site/motion/capture.json"),
  JSON.stringify(receipt, null, 2) + "\n",
);
console.log(JSON.stringify(receipt, null, 2));
