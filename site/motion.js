// Respect system motion preferences; visitors can explicitly play or pause.
(() => {
  const preference = matchMedia("(prefers-reduced-motion: reduce)");
  const buttons = [...document.querySelectorAll("[data-motion-toggle]")];
  const images = [...document.querySelectorAll("img[data-motion-src]")];
  const videos = [...document.querySelectorAll("video[data-motion-video]")];
  let enabled = !preference.matches;
  images.forEach((image) => {
    image.dataset.stillSrc = image.getAttribute("src");
  });
  function update() {
    images.forEach((image) => {
      const source = enabled ? image.dataset.motionSrc : image.dataset.stillSrc;
      if (
        enabled &&
        image.getAttribute("src") === image.dataset.stillSrc &&
        (!image.complete || image.naturalWidth === 0)
      ) {
        // Keep the fast poster visible before requesting an animated resource.
        image.addEventListener(
          "load",
          () => {
            if (enabled) image.src = image.dataset.motionSrc;
          },
          { once: true },
        );
      } else if (image.getAttribute("src") !== source) image.src = source;
    });
    videos.forEach((video) => {
      if (enabled && video.dataset.onScreen !== "false")
        video.play().catch(() => {});
      else video.pause();
    });
    buttons.forEach((button) => {
      button.hidden = false;
      button.textContent = enabled ? "Pause motion" : "Play motion";
      button.setAttribute(
        "aria-label",
        enabled ? "Pause motion" : "Play motion",
      );
    });
  }
  buttons.forEach((button) => {
    button.onclick = () => {
      enabled = !enabled;
      update();
    };
  });
  preference.addEventListener("change", () => {
    enabled = !preference.matches;
    update();
  });
  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(({ target, isIntersecting }) => {
        target.dataset.onScreen = String(isIntersecting);
        if (enabled && isIntersecting) target.play().catch(() => {});
        else target.pause();
      });
    });
    videos.forEach((video) => observer.observe(video));
  }
  update();
})();
