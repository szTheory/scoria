/*
 * Scoria dashboard client init. Concatenated AFTER phoenix.min.js (global `Phoenix`),
 * phoenix_live_view.min.js (global `LiveView`), and phoenix_html.js by mix scoria.assets.build.
 * No bundler required — the library ships its own self-contained LiveSocket + hooks.
 */
(function () {
  "use strict";

  if (typeof window.Phoenix === "undefined" || typeof window.LiveView === "undefined") {
    console.error("[scoria] Phoenix / LiveView globals missing — dashboard JS not bundled correctly");
    return;
  }

  var Socket = window.Phoenix.Socket;
  var LiveSocket = window.LiveView.LiveSocket;

  var Hooks = {};

  // Click-to-copy for monospace identifiers (run ids, trace ids, ...). Brand: copyable IDs.
  Hooks.CopyId = {
    mounted: function () {
      var el = this.el;
      el.addEventListener("click", function () {
        var text = el.getAttribute("data-copy") || el.textContent.trim();
        if (!navigator.clipboard) return;
        navigator.clipboard.writeText(text).then(function () {
          var prev = el.getAttribute("data-copied-label");
          el.classList.add("scoria-id--copied");
          el.setAttribute("title", "Copied");
          setTimeout(function () {
            el.classList.remove("scoria-id--copied");
            if (prev) el.setAttribute("title", prev);
          }, 1200);
        });
      });
    },
  };

  // Light/dark theme toggle. Persists choice; defaults to dark (brand-first).
  Hooks.ThemeToggle = {
    mounted: function () {
      var root = document.documentElement;
      var stored = null;
      try { stored = localStorage.getItem("scoria-theme"); } catch (e) {}
      if (stored) root.setAttribute("data-theme", stored);
      this.el.addEventListener("click", function () {
        var next = root.getAttribute("data-theme") === "light" ? "dark" : "light";
        root.setAttribute("data-theme", next);
        try { localStorage.setItem("scoria-theme", next); } catch (e) {}
      });
    },
  };

  // Escape closes the topmost open drawer/modal that opts in via data-scoria-dismiss.
  Hooks.Dismissable = {
    mounted: function () {
      var self = this;
      this.handler = function (e) {
        if (e.key === "Escape") {
          var event = self.el.getAttribute("data-scoria-dismiss");
          if (event) self.pushEvent(event, {});
        }
      };
      window.addEventListener("keydown", this.handler);
    },
    destroyed: function () {
      window.removeEventListener("keydown", this.handler);
    },
  };

  var csrfEl = document.querySelector("meta[name='csrf-token']");
  var csrfToken = csrfEl ? csrfEl.getAttribute("content") : null;
  var socketPath = (document.documentElement.getAttribute("data-scoria-socket")) || "/live";

  var liveSocket = new LiveSocket(socketPath, Socket, {
    params: { _csrf_token: csrfToken },
    hooks: Hooks,
  });

  liveSocket.connect();
  window.scoriaLiveSocket = liveSocket;

  // Readiness sentinel for the screenshot harness + tests.
  window.addEventListener("phx:page-loading-stop", function () {
    document.documentElement.setAttribute("data-scoria-ready", "true");
  });
})();
