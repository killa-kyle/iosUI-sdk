export function foundationPreview(kind, host) {
  const output = () => host.querySelector("output");
  if (["selection", "focus", "typeahead"].includes(kind)) {
    host.innerHTML = `${kind === "typeahead" ? '<label>Type to find <input aria-label="Find an option" placeholder="Try c…"></label>' : ""}<div class="demo-row" role="group" aria-label="Native choice illustration"><button>Café</button><button>Color</button><button>Motion</button><button disabled>Unavailable</button></div><output aria-live="polite">Nothing selected</output>`;
    const choices = [...host.querySelectorAll("button:not(:disabled)")],
      selected = new Set();
    for (const [i, b] of choices.entries()) {
      b.setAttribute("aria-pressed", "false");
      b.onclick = () => {
        if (selected.has(i)) selected.delete(i);
        else selected.add(i);
        choices.forEach((item, j) =>
          item.setAttribute("aria-pressed", String(selected.has(j))),
        );
        output().textContent = `Selected: ${[...selected].map((j) => choices[j].textContent).join(", ") || "none"}`;
      };
      b.onkeydown = (e) => {
        if (
          [
            "ArrowRight",
            "ArrowDown",
            "ArrowLeft",
            "ArrowUp",
            "Home",
            "End",
          ].includes(e.key)
        ) {
          e.preventDefault();
          const next =
            e.key === "Home"
              ? 0
              : e.key === "End"
                ? choices.length - 1
                : (i +
                    (["ArrowLeft", "ArrowUp"].includes(e.key) ? -1 : 1) +
                    choices.length) %
                  choices.length;
          choices[next].focus();
          output().textContent = `Focused: ${choices[next].textContent}. Selection unchanged.`;
        }
      };
    }
    const input = host.querySelector("input");
    if (input)
      input.oninput = () => {
        const q = input.value
          .normalize("NFD")
          .replace(/\p{Diacritic}/gu, "")
          .toLowerCase();
        const match = choices.find((b) =>
          b.textContent
            .normalize("NFD")
            .replace(/\p{Diacritic}/gu, "")
            .toLowerCase()
            .startsWith(q),
        );
        output().textContent =
          match && q ? `Match: ${match.textContent}` : "No query or match";
      };
    return () => {};
  }
  if (kind === "values") {
    host.innerHTML =
      '<div class="demo-row"><button aria-label="Decrease value">−</button><output>40</output><button aria-label="Increase value">+</button></div><label>Energy <input type="range" min="0" max="100" step="10" value="40"></label>';
    const input = host.querySelector("input"),
      buttons = host.querySelectorAll("button");
    const set = (n) => {
      n = Math.max(0, Math.min(100, Math.round(n / 10) * 10));
      input.value = n;
      output().textContent = String(n);
      buttons[0].disabled = n === 0;
      buttons[1].disabled = n === 100;
    };
    input.oninput = () => set(+input.value);
    buttons[0].onclick = () => set(+input.value - 10);
    buttons[1].onclick = () => set(+input.value + 10);
    set(40);
    return () => {};
  }
  if (kind === "disclosure") {
    host.innerHTML =
      '<details><summary>How it works</summary><p>Compose small behaviors. Keep your own design.</p></details><output aria-live="polite">Collapsed</output>';
    host.querySelector("details").ontoggle = (e) =>
      (output().textContent = e.currentTarget.open ? "Expanded" : "Collapsed");
    return () => {};
  }
  if (kind === "validation") {
    host.innerHTML =
      '<form novalidate><label>Project name <input aria-describedby="field-error" autocomplete="off"></label><p id="field-error" class="field-error" hidden>Enter a project name.</p><button>Validate</button></form><output aria-live="polite">Validation appears after blur or submit.</output>';
    const input = host.querySelector("input"),
      error = host.querySelector("#field-error");
    let touched = false;
    const validate = () => {
      const invalid = !input.value.trim();
      error.hidden = !touched || !invalid;
      input.setAttribute("aria-invalid", String(touched && invalid));
      output().textContent = touched
        ? invalid
          ? "Needs a project name."
          : "Valid project name."
        : "Not yet touched.";
    };
    input.onblur = () => {
      touched = true;
      validate();
    };
    input.oninput = validate;
    host.querySelector("form").onsubmit = (e) => {
      e.preventDefault();
      touched = true;
      validate();
    };
    return () => {};
  }
  if (kind === "reorder") {
    let items = ["First", "Second", "Locked"];
    const render = () => {
      host.replaceChildren();
      for (const [i, label] of items.entries()) {
        const row = document.createElement("div");
        row.className = "demo-row";
        const text = document.createElement("span");
        text.textContent = label;
        row.append(text);
        for (const [name, d] of [
          ["up", -1],
          ["down", 1],
        ]) {
          const b = document.createElement("button");
          b.textContent = `Move ${label} ${name}`;
          b.disabled =
            label === "Locked" ||
            i + d < 0 ||
            i + d >= items.length ||
            items[i + d] === "Locked";
          b.onclick = () => {
            const next = i + d;
            [items[i], items[next]] = [items[next], items[i]];
            render();
          };
          row.append(b);
        }
        host.append(row);
      }
      const out = document.createElement("output");
      out.textContent = items.join(" → ");
      out.setAttribute("aria-live", "polite");
      host.append(out);
    };
    render();
    return () => {};
  }
  if (kind === "virtual") {
    host.innerHTML =
      '<div tabindex="0" aria-label="Virtual row preview" style="height:180px;overflow:auto;width:100%;max-width:330px;border:1px solid var(--line)"><div style="height:44000px;position:relative"></div></div><output aria-live="polite"></output>';
    const scroller = host.querySelector("[tabindex]"),
      canvas = scroller.firstElementChild;
    const render = () => {
      const first = Math.max(0, Math.floor(scroller.scrollTop / 44) - 2),
        last = Math.min(1000, Math.ceil((scroller.scrollTop + 180) / 44) + 2);
      canvas.replaceChildren();
      for (let i = first; i < last; i++) {
        const row = document.createElement("div");
        row.textContent = `Row ${i + 1}`;
        Object.assign(row.style, {
          position: "absolute",
          top: `${i * 44}px`,
          height: "44px",
          padding: "8px 15px",
        });
        canvas.append(row);
      }
      output().textContent = `Rendering ${first}..<${last} of 1000 rows`;
    };
    scroller.onscroll = render;
    render();
    return () => {};
  }
  if (kind === "viewport") {
    host.innerHTML =
      '<div class="resize-stage" style="height:160px;touch-action:none"><div style="position:absolute;left:90px;top:55px;padding:15px;background:var(--selection);border-radius:8px">Pan this canvas ↗</div></div><div class="demo-row"><button>Zoom out</button><button>Zoom in</button></div><output aria-live="polite"></output>';
    let x = 0,
      y = 0,
      scale = 1,
      start;
    const stage = host.querySelector(".resize-stage"),
      content = stage.firstElementChild;
    const render = () => {
      content.style.transform = `translate(${x}px,${y}px) scale(${scale})`;
      output().textContent = `Scale ${scale.toFixed(2)} · translation ${x.toFixed(0)}, ${y.toFixed(0)}`;
    };
    stage.onpointerdown = (e) => {
      start = { px: e.clientX, py: e.clientY, x, y };
      stage.setPointerCapture(e.pointerId);
    };
    stage.onpointermove = (e) => {
      if (start) {
        x = start.x + e.clientX - start.px;
        y = start.y + e.clientY - start.py;
        render();
      }
    };
    stage.onpointerup = () => (start = null);
    stage.onpointercancel = () => {
      if (start) {
        x = start.x;
        y = start.y;
        start = null;
        render();
      }
    };
    const buttons = host.querySelectorAll("button");
    buttons[0].onclick = () => {
      scale = Math.max(0.25, scale / 1.25);
      render();
    };
    buttons[1].onclick = () => {
      scale = Math.min(8, scale * 1.25);
      render();
    };
    render();
    return () => {};
  }
  return null;
}
