// ShelfDrop landing page interactions.
// All motion is gated on prefers-reduced-motion. No scroll listeners are used:
// scroll-driven UI relies on IntersectionObserver only.

(function () {
  "use strict";

  // Mark JS as available so CSS can hide reveal elements only when we can show them.
  document.documentElement.classList.add("js");

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var finePointer = window.matchMedia("(pointer: fine)").matches;

  // ---------------------------------------------------------------------------
  // Scroll-reveal (IntersectionObserver, not a scroll listener)
  // ---------------------------------------------------------------------------
  // Stagger grouped reveals so cells/steps cascade in rather than popping together.
  if (!reduceMotion) {
    document.querySelectorAll(".bento .cell").forEach(function (el, i) {
      el.style.transitionDelay = (i * 0.07).toFixed(2) + "s";
    });
    document.querySelectorAll(".steps .step").forEach(function (el, i) {
      el.style.transitionDelay = (i * 0.09).toFixed(2) + "s";
    });
  }

  var reveals = document.querySelectorAll(".reveal");
  if (reduceMotion || !("IntersectionObserver" in window)) {
    reveals.forEach(function (el) { el.classList.add("in"); });
  } else {
    var revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          revealObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15, rootMargin: "0px 0px -8% 0px" });
    reveals.forEach(function (el) { revealObserver.observe(el); });
  }

  // ---------------------------------------------------------------------------
  // Nav background toggle via a top sentinel (no scroll listener)
  // ---------------------------------------------------------------------------
  var nav = document.getElementById("nav");
  var sentinel = document.getElementById("top-sentinel");
  if (nav && sentinel && "IntersectionObserver" in window) {
    var navObserver = new IntersectionObserver(function (entries) {
      nav.classList.toggle("scrolled", !entries[0].isIntersecting);
    }, { threshold: 0 });
    navObserver.observe(sentinel);
  }

  // ---------------------------------------------------------------------------
  // Pointer-tracked specular highlight on glass surfaces
  // ---------------------------------------------------------------------------
  if (finePointer && !reduceMotion) {
    document.querySelectorAll(".glass").forEach(function (el) {
      var queued = false, lastX = 50, lastY = 0;
      el.addEventListener("pointermove", function (e) {
        var rect = el.getBoundingClientRect();
        lastX = ((e.clientX - rect.left) / rect.width) * 100;
        lastY = ((e.clientY - rect.top) / rect.height) * 100;
        if (!queued) {
          queued = true;
          requestAnimationFrame(function () {
            el.style.setProperty("--mx", lastX + "%");
            el.style.setProperty("--my", lastY + "%");
            queued = false;
          });
        }
      });
      el.addEventListener("pointerleave", function () {
        el.style.setProperty("--mx", "50%");
        el.style.setProperty("--my", "-10%");
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Copy-to-clipboard buttons on code blocks
  // ---------------------------------------------------------------------------
  document.querySelectorAll(".copy-btn").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var block = btn.closest(".code-block");
      var code = block ? block.querySelector("code") : null;
      if (!code || !navigator.clipboard) return;
      navigator.clipboard.writeText(code.textContent.trim()).then(function () {
        var icon = btn.querySelector("i");
        btn.classList.add("copied");
        if (icon) icon.className = "ph ph-check";
        setTimeout(function () {
          btn.classList.remove("copied");
          if (icon) icon.className = "ph ph-copy";
        }, 1600);
      });
    });
  });
})();
