export function advancedPreview(kind, host) {
  const out = () => host.querySelector("output");
  if (kind === "calendar") {
    let month = 10,
      start = null,
      end = null,
      message = "Choose a start and end. November 3 is disabled.";
    const blocked = "2026-11-03",
      min = "2026-11-01",
      max = "2026-12-31";
    const render = () => {
      host.innerHTML =
        '<div class="demo-row"><button aria-label="Previous month">←</button><strong></strong><button aria-label="Next month">→</button></div><div class="date-grid" aria-label="Date selection"></div><output aria-live="polite"></output>';
      host.querySelector("strong").textContent = new Intl.DateTimeFormat("en", {
        month: "long",
        year: "numeric",
        timeZone: "UTC",
      }).format(new Date(Date.UTC(2026, month, 1)));
      const controls = host.querySelectorAll(".demo-row button");
      controls[0].disabled = month === 10;
      controls[1].disabled = month === 11;
      controls[0].onclick = () => {
        month--;
        render();
      };
      controls[1].onclick = () => {
        month++;
        render();
      };
      const grid = host.querySelector(".date-grid");
      for (const name of ["S", "M", "T", "W", "T", "F", "S"]) {
        const day = document.createElement("span");
        day.className = "date-week";
        day.textContent = name;
        grid.append(day);
      }
      const offset = new Date(Date.UTC(2026, month, 1)).getUTCDay();
      for (let i = 0; i < 42; i++) {
        const date = new Date(Date.UTC(2026, month, i - offset + 1)),
          iso = date.toISOString().slice(0, 10),
          b = document.createElement("button");
        b.textContent = String(date.getUTCDate());
        b.setAttribute("aria-label", iso);
        b.disabled = iso < min || iso > max || iso === blocked;
        b.setAttribute(
          "aria-pressed",
          String(
            Boolean(
              start && (end ? iso >= start && iso <= end : iso === start),
            ),
          ),
        );
        b.onclick = () => {
          if (start && !end) {
            const lo = iso < start ? iso : start,
              hi = iso > start ? iso : start;
            if (lo <= blocked && blocked <= hi) {
              message = "That range crosses November 3. Choose another end.";
            } else {
              start = lo;
              end = hi;
              message = `${start} → ${end}`;
            }
          } else {
            start = iso;
            end = null;
            message = `Start: ${start}. Choose an end.`;
          }
          render();
        };
        grid.append(b);
      }
      out().textContent = message;
    };
    render();
    return () => {};
  }
  if (kind === "color") {
    host.innerHTML =
      '<div class="swatch"></div><div class="demo-row"><label>Color <input type="color" value="#4f46e5" aria-label="Color value"></label><label>Opacity <input type="range" min="0" max="100" value="100"></label></div><output aria-live="polite"></output>';
    const color = host.querySelector("[type=color]"),
      alpha = host.querySelector("[type=range]");
    const render = () => {
      const rgb = [1, 3, 5].map(
          (i) => parseInt(color.value.slice(i, i + 2), 16) / 255,
        ),
        a = +alpha.value / 100;
      host.querySelector(".swatch").style.background =
        `rgb(${rgb.map((v) => v * 255).join(" ")} / ${a})`;
      const linear = (v) =>
        v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
      const mixed = rgb.map((v) => v * a + 1 - a);
      const luminance = mixed
        .map(linear)
        .reduce((s, v, i) => s + v * [0.2126, 0.7152, 0.0722][i], 0);
      out().textContent = `${color.value.toUpperCase()}${Math.round(a * 255)
        .toString(16)
        .padStart(2, "0")
        .toUpperCase()} · Contrast on white ${(1.05 / (luminance + 0.05)).toFixed(2)}:1`;
    };
    color.oninput = render;
    alpha.oninput = render;
    render();
    return () => {};
  }
  if (kind === "tree") {
    host.innerHTML =
      '<div class="tree-demo"><button aria-expanded="false" aria-controls="tree-children" aria-label="Expand Library">▸ Library</button><div id="tree-children" class="tree-children" hidden><button aria-pressed="false">Photos</button><button aria-pressed="false">Notes</button></div><button disabled>Unavailable</button></div><output aria-live="polite">No selection</output>';
    const root = host.querySelector("button"),
      children = host.querySelector("#tree-children");
    const toggle = (open) => {
      root.setAttribute("aria-expanded", String(open));
      root.setAttribute(
        "aria-label",
        `${open ? "Collapse" : "Expand"} Library`,
      );
      root.textContent = `${open ? "▾" : "▸"} Library`;
      children.hidden = !open;
    };
    root.onclick = () => toggle(children.hidden);
    for (const b of children.children)
      b.onclick = () => {
        for (const c of children.children)
          c.setAttribute("aria-pressed", String(c === b));
        out().textContent = `Selected: ${b.textContent}`;
      };
    host.onkeydown = (e) => {
      const buttons = [
          root,
          ...(!children.hidden ? [...children.children] : []),
        ],
        i = buttons.indexOf(document.activeElement);
      if (i < 0) return;
      if (["ArrowDown", "ArrowUp", "Home", "End"].includes(e.key)) {
        e.preventDefault();
        const n =
          e.key === "Home"
            ? 0
            : e.key === "End"
              ? buttons.length - 1
              : Math.min(
                  buttons.length - 1,
                  Math.max(0, i + (e.key === "ArrowUp" ? -1 : 1)),
                );
        buttons[n].focus();
      }
      if (e.key === "ArrowRight" && i === 0) {
        e.preventDefault();
        if (children.hidden) toggle(true);
        else children.firstElementChild.focus();
      }
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        if (i === 0) toggle(false);
        else root.focus();
      }
    };
    return () => {
      host.onkeydown = null;
    };
  }
  if (kind === "grid") {
    host.innerHTML =
      '<div class="cell-grid" role="grid" aria-label="Range selection grid"></div><output aria-live="polite">Select a cell. Shift-click or Shift-arrow to extend.</output>';
    let anchor = null,
      selected = new Set();
    const cells = [];
    const select = (index, extend) => {
      if (index === 1) return;
      if (!extend || anchor === null) anchor = index;
      selected.clear();
      if (extend) {
        const r1 = Math.floor(anchor / 4),
          c1 = anchor % 4,
          r2 = Math.floor(index / 4),
          c2 = index % 4;
        for (let r = Math.min(r1, r2); r <= Math.max(r1, r2); r++)
          for (let c = Math.min(c1, c2); c <= Math.max(c1, c2); c++) {
            const i = r * 4 + c;
            if (i !== 1) selected.add(i);
          }
      } else selected.add(index);
      cells.forEach((b, i) =>
        b.setAttribute("aria-selected", String(selected.has(i))),
      );
      out().textContent = `Selected cells: ${selected.size}`;
    };
    for (let row = 0; row < 3; row++) {
      const line = document.createElement("div");
      line.role = "row";
      line.style.display = "contents";
      host.querySelector(".cell-grid").append(line);
      for (let c = 0; c < 4; c++) {
        const i = row * 4 + c,
          b = document.createElement("button");
        b.role = "gridcell";
        b.textContent = `${row + 1}, ${c + 1}`;
        b.setAttribute("aria-label", `Row ${row + 1} column ${c + 1}`);
        b.disabled = i === 1;
        b.setAttribute("aria-selected", "false");
        b.onclick = (e) => select(i, e.shiftKey);
        b.onkeydown = (e) => {
          const d = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -4, ArrowDown: 4 }[
            e.key
          ];
          if (d === undefined) return;
          e.preventDefault();
          let n = i + d;
          while (n === 1) n += d;
          if (
            n < 0 ||
            n >= 12 ||
            (Math.abs(d) === 1 && Math.floor(n / 4) !== row)
          )
            return;
          cells[n].focus();
          if (e.shiftKey) select(n, true);
        };
        cells.push(b);
        line.append(b);
      }
    }
    return () => {};
  }
  if (kind === "drag") {
    host.innerHTML =
      '<div class="drag-card" tabindex="0" role="button" aria-label="Draggable card">Drag this card</div><div class="drop-zone">Archive drop zone</div><button>Move to archive</button><output aria-live="polite">No drop</output>';
    const card = host.querySelector(".drag-card"),
      zone = host.querySelector(".drop-zone");
    let start;
    const cancel = () => {
      start = null;
      card.style.transform = "";
      card.classList.remove("is-dragging");
      delete zone.dataset.targeted;
    };
    const commit = () => {
      cancel();
      zone.append(card);
      out().textContent = "Moved card to archive";
    };
    card.onpointerdown = (e) => {
      if (e.button !== 0) return;
      start = { x: e.clientX, y: e.clientY, pointer: e.pointerId };
      card.setPointerCapture(e.pointerId);
      card.classList.add("is-dragging");
    };
    card.onpointermove = (e) => {
      if (!start || start.pointer !== e.pointerId) return;
      card.style.transform = `translate(${e.clientX - start.x}px, ${e.clientY - start.y}px)`;
      const bounds = zone.getBoundingClientRect();
      zone.dataset.targeted = String(
        e.clientX >= bounds.left &&
          e.clientX <= bounds.right &&
          e.clientY >= bounds.top &&
          e.clientY <= bounds.bottom,
      );
    };
    card.onpointerup = (e) => {
      if (!start || start.pointer !== e.pointerId) return;
      const bounds = zone.getBoundingClientRect();
      if (
        e.clientX >= bounds.left &&
        e.clientX <= bounds.right &&
        e.clientY >= bounds.top &&
        e.clientY <= bounds.bottom
      )
        commit();
      else cancel();
    };
    card.onpointercancel = card.onlostpointercapture = cancel;
    card.onkeydown = (e) => {
      if (e.key === "Escape") cancel();
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        commit();
      }
    };
    host.querySelector("button").onclick = commit;
    return cancel;
  }
  if (kind === "carousel" || kind === "agent") {
    host.innerHTML = `<div class="slide-preview">Mountains</div><div class="demo-row"><button>Previous slide</button><output aria-live="polite"></output><button>Next slide</button></div>${kind === "agent" ? '<div class="demo-row"><button>Capture snapshot</button><button>Agent next</button><label><input type="checkbox" checked> Host allows action</label></div><pre class="agent-json" aria-live="polite">Capture a snapshot to begin.</pre>' : ""}`;
    let index = 0,
      revision = 0,
      captured;
    const buttons = host.querySelectorAll("button");
    const render = () => {
      host.querySelector(".slide-preview").textContent = [
        "Mountains",
        "Harbor",
        "Forest",
      ][index];
      out().textContent = `${index + 1} of 3`;
      buttons[0].disabled = index === 0;
      buttons[1].disabled = index === 2;
    };
    buttons[0].onclick = () => {
      index = Math.max(0, index - 1);
      revision++;
      render();
    };
    buttons[1].onclick = () => {
      index = Math.min(2, index + 1);
      revision++;
      render();
    };
    if (kind === "agent") {
      const log = host.querySelector("pre");
      buttons[2].onclick = () => {
        captured = {
          revision,
          coordinateSpace: "browser-css-pixels",
          components: [
            {
              ref: "gallery",
              component: "carousel",
              label: "Scenery",
              state: { index },
              actions: ["next", "previous"],
            },
          ],
        };
        log.textContent = JSON.stringify(captured, null, 2);
      };
      buttons[3].onclick = () => {
        if (!captured) log.textContent = "Capture a snapshot first.";
        else if (captured.revision !== revision)
          log.textContent = "Rejected: stale snapshot. Observe again.";
        else if (!host.querySelector("[type=checkbox]").checked)
          log.textContent = "Denied by the host. State unchanged.";
        else {
          index = Math.min(2, index + 1);
          revision++;
          render();
          log.textContent = `Accepted next. Visible slide: ${index + 1}. Observe again before another action.`;
        }
      };
    }
    render();
    return () => {};
  }
  if (kind === "editor") {
    host.innerHTML =
      '<div class="demo-row"><button>Apply bold</button><button>Apply italic</button></div><div class="rich-editor" contenteditable="true" role="textbox" aria-multiline="true" aria-label="Rich text illustration">Select some of this text, then apply formatting.</div><output aria-live="polite">Native package editing is provided by TextKit.</output>';
    const editor = host.querySelector("[contenteditable]");
    for (const [i, b] of [...host.querySelectorAll("button")].entries()) {
      b.onpointerdown = (e) => e.preventDefault();
      b.onclick = () => {
        const selection = getSelection();
        let range = selection.rangeCount ? selection.getRangeAt(0) : null;
        if (
          !range ||
          !editor.contains(range.commonAncestorContainer) ||
          range.collapsed
        ) {
          range = document.createRange();
          range.selectNodeContents(editor);
        }
        const mark = document.createElement(i ? "em" : "strong");
        mark.append(range.extractContents());
        range.insertNode(mark);
        range.selectNodeContents(mark);
        selection.removeAllRanges();
        selection.addRange(range);
        out().textContent = `Applied ${i ? "italic" : "bold"} to the selected text.`;
      };
    }
    return () => {};
  }
  if (kind === "menu") {
    host.innerHTML =
      '<details><summary>Open menu</summary><div class="menu-panel" role="menu"><button role="menuitem">Copy sample</button><button role="menuitemcheckbox" aria-checked="false">Favorite</button><button role="menuitem" disabled>Unavailable</button></div></details><output aria-live="polite">No action</output>';
    const details = host.querySelector("details"),
      buttons = [...host.querySelectorAll("button:not(:disabled)")];
    buttons.forEach((b, i) => {
      b.onclick = () => {
        if (i === 1)
          b.setAttribute(
            "aria-checked",
            String(b.getAttribute("aria-checked") !== "true"),
          );
        out().textContent = `Action: ${i ? "favorite" : "copy"}`;
        details.open = false;
        details.querySelector("summary").focus();
      };
      b.onkeydown = (e) => {
        if (["ArrowUp", "ArrowDown", "Home", "End"].includes(e.key)) {
          e.preventDefault();
          buttons[
            e.key === "Home"
              ? 0
              : e.key === "End"
                ? buttons.length - 1
                : (i + (e.key === "ArrowUp" ? -1 : 1) + buttons.length) %
                  buttons.length
          ].focus();
        }
        if (e.key === "Escape" || e.key === "Tab") {
          details.open = false;
          if (e.key === "Escape") {
            e.preventDefault();
            details.querySelector("summary").focus();
          }
        }
      };
    });
    details.ontoggle = () => {
      if (details.open) buttons[0].focus();
    };
    return () => {};
  }
  if (kind === "overlays") {
    host.innerHTML =
      '<button>Open inspector</button><output aria-live="polite">Overlay count: 0</output><dialog aria-label="Inspector"><h3>Inspector</h3><p>A native browser dialog illustrates the presentation stack.</p><button>Open nested overlay</button><button>Close inspector</button></dialog><dialog aria-label="Confirmation"><h3>Confirmation</h3><p>Closing this leaves the inspector open.</p><button>Close confirmation</button></dialog>';
    const dialogs = host.querySelectorAll("dialog"),
      buttons = host.querySelectorAll("button"),
      render = () =>
        (out().textContent = `Overlay count: ${[...dialogs].filter((d) => d.open).length}`);
    buttons[0].onclick = () => {
      dialogs[0].showModal();
      render();
    };
    buttons[1].onclick = () => {
      dialogs[1].showModal();
      render();
    };
    buttons[2].onclick = () => {
      if (dialogs[1].open) dialogs[1].close();
      dialogs[0].close();
      render();
    };
    buttons[3].onclick = () => {
      dialogs[1].close();
      render();
    };
    dialogs.forEach((d) => d.addEventListener("close", render));
    return () => {
      dialogs.forEach((d) => {
        d.removeEventListener("close", render);
        if (d.open) d.close();
      });
    };
  }
  if (kind === "measurements") {
    host.innerHTML =
      '<label>Width <input type="range" min="100" max="280" value="180"></label><div class="measure-box" style="width:180px">Measured view</div><output aria-live="polite"></output>';
    const box = host.querySelector(".measure-box");
    const render = () => {
      const r = box.getBoundingClientRect();
      out().textContent = `${r.width.toFixed(0)} × ${r.height.toFixed(0)} CSS pixels (browser illustration)`;
    };
    const observer = new ResizeObserver(render);
    observer.observe(box);
    host.querySelector("input").oninput = (e) =>
      (box.style.width = `${e.target.value}px`);
    render();
    return () => observer.disconnect();
  }
  return null;
}
