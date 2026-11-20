export function geometryPreview(kind, host) {
  if (!["resize", "crop"].includes(kind)) return null;
  host.innerHTML = `<div class="resize-stage ${kind === "crop" ? "crop-stage" : ""}" aria-label="${kind === "crop" ? "Crop" : "Resize"} geometry illustration"><div class="resize-box"><span>${kind === "crop" ? "Crop selection" : "Your content"}</span></div></div><output aria-live="polite"></output><p class="preview-note">Drag a handle, or focus it and use arrow keys. Escape cancels a drag.</p>`;
  const stage = host.querySelector(".resize-stage"),
    box = host.querySelector(".resize-box"),
    output = host.querySelector("output");
  let rect = { x: 40, y: 35, w: 140, h: kind === "crop" ? 140 : 105 },
    start;
  const points = {
    n: [50, 0],
    s: [50, 100],
    e: [100, 50],
    w: [0, 50],
    nw: [0, 0],
    ne: [100, 0],
    sw: [0, 100],
    se: [100, 100],
    move: [50, 50],
  };
  function render() {
    Object.assign(box.style, {
      left: `${rect.x}px`,
      top: `${rect.y}px`,
      width: `${rect.w}px`,
      height: `${rect.h}px`,
    });
    output.textContent = `${rect.w.toFixed(0)} × ${rect.h.toFixed(0)} · position ${rect.x.toFixed(0)}, ${rect.y.toFixed(0)}`;
  }
  function apply(handle, dx, dy, from) {
    if (handle === "move") {
      rect = {
        ...from,
        x: Math.max(
          0,
          Math.min((start?.width ?? stage.clientWidth) - from.w, from.x + dx),
        ),
        y: Math.max(
          0,
          Math.min((start?.height ?? stage.clientHeight) - from.h, from.y + dy),
        ),
      };
      render();
      return;
    }
    const west = handle.includes("w"),
      east = handle.includes("e"),
      north = handle.includes("n"),
      south = handle.includes("s");
    let w = from.w + (east ? dx : west ? -dx : 0),
      h = from.h + (south ? dy : north ? -dy : 0);
    const maxW = west
        ? from.x + from.w
        : (start?.width ?? stage.clientWidth) - from.x,
      maxH = north
        ? from.y + from.h
        : (start?.height ?? stage.clientHeight) - from.y;
    if (kind === "crop") {
      w = east || west ? w : h;
      w = Math.max(30, Math.min(w, maxW, maxH));
      h = w;
    } else {
      w = Math.max(30, Math.min(w, maxW));
      h = Math.max(30, Math.min(h, maxH));
    }
    rect = {
      x: west ? from.x + from.w - w : from.x,
      y: north ? from.y + from.h - h : from.y,
      w,
      h,
    };
    render();
  }
  for (const [handle, position] of Object.entries(points)) {
    const b = document.createElement("button");
    b.className = "resize-handle";
    b.setAttribute("aria-label", `Resize ${handle}`);
    Object.assign(b.style, { left: `${position[0]}%`, top: `${position[1]}%` });
    box.append(b);
    b.onpointerdown = (e) => {
      e.preventDefault();
      b.focus({ preventScroll: true });
      start = {
        pointer: e.pointerId,
        x: e.clientX,
        y: e.clientY,
        rect: { ...rect },
        handle,
        width: stage.clientWidth,
        height: stage.clientHeight,
      };
      b.setPointerCapture(e.pointerId);
    };
    b.onpointermove = (e) => {
      if (start && start.handle === handle && start.pointer === e.pointerId)
        apply(handle, e.clientX - start.x, e.clientY - start.y, start.rect);
    };
    b.onpointerup = () => (start = null);
    b.onpointercancel = () => {
      if (start) {
        rect = start.rect;
        start = null;
        render();
      }
    };
    b.onkeydown = (e) => {
      const amount = e.shiftKey ? 10 : 1,
        delta = {
          ArrowLeft: [-amount, 0],
          ArrowRight: [amount, 0],
          ArrowUp: [0, -amount],
          ArrowDown: [0, amount],
        }[e.key];
      if (delta) {
        e.preventDefault();
        apply(handle, ...delta, { ...rect });
      }
      if (e.key === "Escape" && start) {
        rect = start.rect;
        start = null;
        render();
      }
    };
  }
  render();
  return () => {
    start = null;
  };
}
