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

  // Theme: dark / light / system, persisted as "scoria-theme". "system" follows
  // the OS via prefers-color-scheme and reacts to live OS changes. The pre-paint
  // script in root.html.heex applies the stored mode before first paint (no FOUC);
  // this module re-applies it, cycles modes, and keeps control metadata in sync.
  var THEME_KEY = "scoria-theme";
  var THEME_MODES = ["dark", "light", "system"];

  function themeStoredMode() {
    var v = null;
    try { v = localStorage.getItem(THEME_KEY); } catch (e) {}
    return THEME_MODES.indexOf(v) >= 0 ? v : "system";
  }
  function themeResolve(mode) {
    if (mode === "system") {
      return window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
    }
    return mode === "light" ? "light" : "dark";
  }
  function themeUpdateControls(mode) {
    var label = mode.charAt(0).toUpperCase() + mode.slice(1);
    var btns = document.querySelectorAll("[data-theme-toggle]");
    for (var i = 0; i < btns.length; i++) {
      btns[i].setAttribute("title", "Theme: " + label + " — click to cycle dark / light / system");
      btns[i].setAttribute("aria-label", "Theme: " + label + ". Click to cycle dark, light, system.");
    }
  }
  function themeApply(mode) {
    document.documentElement.setAttribute("data-theme-mode", mode);
    document.documentElement.setAttribute("data-theme", themeResolve(mode));
    themeUpdateControls(mode);
  }
  function themeCycle() {
    var next = THEME_MODES[(THEME_MODES.indexOf(themeStoredMode()) + 1) % THEME_MODES.length];
    try { localStorage.setItem(THEME_KEY, next); } catch (e) {}
    themeApply(next);
    return next;
  }
  // Live OS theme changes only matter while the user is on "system".
  try {
    window.matchMedia("(prefers-color-scheme: light)").addEventListener("change", function () {
      if (themeStoredMode() === "system") themeApply("system");
    });
  } catch (e) {}

  Hooks.ThemeToggle = {
    mounted: function () {
      themeApply(themeStoredMode());
      this.el.addEventListener("click", function () { themeCycle(); });
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

  function forEachNode(nodes, callback) {
    Array.prototype.forEach.call(nodes || [], callback);
  }

  function scoriaBaseFor(el) {
    var shell = el && el.closest ? el.closest("[data-scoria-base]") : null;
    return shell ? shell.getAttribute("data-scoria-base") || "" : "";
  }

  function recentsKeyFor(el) {
    return "scoria:recents:" + scoriaBaseFor(el);
  }

  function readJson(key, fallback) {
    try {
      var raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (e) {
      return fallback;
    }
  }

  function writeJson(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (e) {}
  }

  function editableTarget(target) {
    if (!target || !target.closest) return false;
    return !!target.closest("input, textarea, select, button, [contenteditable]");
  }

  function focusableElements(root) {
    return Array.prototype.filter.call(
      root.querySelectorAll(
        "a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])"
      ),
      function (el) {
        return !el.hidden && el.getClientRects().length > 0;
      }
    );
  }

  function setPrimaryKbdHints() {
    var combo = /Mac|iPhone|iPad|iPod/.test(navigator.platform) ? "Cmd K" : "Ctrl K";
    forEachNode(document.querySelectorAll("[data-command-primary-kbd]"), function (el) {
      el.textContent = combo;
    });
  }

  Hooks.CommandPalette = {
    mounted: function () {
      var self = this;
      this.input = this.el.querySelector("[data-command-input]");
      this.list = this.el.querySelector("[data-command-list]");
      this.empty = this.el.querySelector("[data-command-empty]");
      this.recentSection = this.findSection("Recent");
      this.shortcutOverlay = document.querySelector("[data-shortcuts-overlay]");
      this.shortcutPanel = document.querySelector("[data-shortcuts-panel]");
      this.recentsKey = recentsKeyFor(this.el);
      this.activeIndex = 0;
      this.gChord = null;
      this.gTimer = null;
      this.restoreFocus = null;
      this.shortcutRestoreFocus = null;
      this.closeTimer = null;
      this.shortcutCloseTimer = null;

      setPrimaryKbdHints();
      this.el.hidden = true;
      this.el.setAttribute("aria-hidden", "true");
      this.buildChordMap();

      this.openClick = function (e) {
        e.preventDefault();
        self.openPalette(e.currentTarget);
      };
      forEachNode(document.querySelectorAll("[data-command-open]"), function (button) {
        button.addEventListener("click", self.openClick);
      });

      this.closeClick = function (e) {
        e.preventDefault();
        self.closePalette(true);
      };
      forEachNode(this.el.querySelectorAll("[data-command-close]"), function (button) {
        button.addEventListener("click", self.closeClick);
      });

      this.inputHandler = function () {
        self.filterRows();
      };
      if (this.input) this.input.addEventListener("input", this.inputHandler);

      this.listClick = function (e) {
        var row = e.target.closest("[data-command-row]");
        if (!row) return;

        var action = row.getAttribute("data-command-action");
        if (action) {
          e.preventDefault();
          self.runAction(action);
          return;
        }

        self.closePalette(false);
      };
      if (this.list) this.list.addEventListener("click", this.listClick);

      this.keydown = function (e) {
        self.handlePaletteKeydown(e);
      };
      this.el.addEventListener("keydown", this.keydown);

      this.shortcutCloseClick = function (e) {
        e.preventDefault();
        self.closeShortcuts(true);
      };
      forEachNode(document.querySelectorAll("[data-shortcuts-close]"), function (button) {
        button.addEventListener("click", self.shortcutCloseClick);
      });

      this.documentKeydown = function (e) {
        self.handleDocumentKeydown(e);
      };
      document.addEventListener("keydown", this.documentKeydown);
    },

    destroyed: function () {
      var self = this;
      forEachNode(document.querySelectorAll("[data-command-open]"), function (button) {
        button.removeEventListener("click", self.openClick);
      });
      forEachNode(this.el.querySelectorAll("[data-command-close]"), function (button) {
        button.removeEventListener("click", self.closeClick);
      });
      forEachNode(document.querySelectorAll("[data-shortcuts-close]"), function (button) {
        button.removeEventListener("click", self.shortcutCloseClick);
      });
      if (this.input) this.input.removeEventListener("input", this.inputHandler);
      if (this.list) this.list.removeEventListener("click", this.listClick);
      this.el.removeEventListener("keydown", this.keydown);
      document.removeEventListener("keydown", this.documentKeydown);
      clearTimeout(this.gTimer);
      clearTimeout(this.closeTimer);
      clearTimeout(this.shortcutCloseTimer);
    },

    findSection: function (label) {
      var found = null;
      forEachNode(this.el.querySelectorAll("[data-command-section]"), function (section) {
        var heading = section.querySelector("h3");
        if (heading && heading.textContent.trim() === label) found = section;
      });
      return found;
    },

    refreshRows: function () {
      this.rows = Array.prototype.slice.call(this.el.querySelectorAll("[data-command-row]"));
    },

    buildChordMap: function () {
      var map = {};
      forEachNode(this.el.querySelectorAll("[data-command-row][href][data-command-kbd]"), function (row) {
        var kbd = row.getAttribute("data-command-kbd");
        if (kbd) map[kbd] = row.getAttribute("href");
      });
      this.chordMap = map;
    },

    openPalette: function (opener) {
      clearTimeout(this.closeTimer);
      this.restoreFocus = opener || document.activeElement;
      this.renderRecents();
      this.filterRows();
      this.el.hidden = false;
      this.el.removeAttribute("aria-hidden");
      this.el.setAttribute("data-state", "open");
      if (this.input) {
        this.input.value = "";
        this.filterRows();
        this.input.focus({ preventScroll: true });
      }
    },

    closePalette: function (restore) {
      var self = this;
      this.el.setAttribute("data-state", "closed");
      this.el.setAttribute("aria-hidden", "true");
      if (this.input) this.input.value = "";
      this.filterRows();
      clearTimeout(this.closeTimer);
      this.closeTimer = setTimeout(function () {
        self.el.hidden = true;
      }, 120);
      if (restore && this.restoreFocus && this.restoreFocus.focus) {
        this.restoreFocus.focus({ preventScroll: true });
      }
    },

    paletteOpen: function () {
      return !this.el.hidden && this.el.getAttribute("data-state") === "open";
    },

    renderRecents: function () {
      if (!this.recentSection) return;
      var rows = this.recentSection.querySelector(".scoria-command__rows");
      if (!rows) return;

      rows.textContent = "";
      var recents = readJson(this.recentsKey, []).slice(0, 5);
      forEachNode(recents, function (item) {
        if (!item || !item.path || !item.label) return;
        var row = document.createElement("a");
        row.className = "scoria-command__row";
        row.href = item.path;
        row.id = "command-recent-" + Math.abs(hashString(item.path + item.label));
        row.setAttribute("role", "option");
        row.setAttribute("aria-selected", "false");
        row.setAttribute("data-command-row", "");
        row.setAttribute("data-command-recent", "true");
        row.setAttribute(
          "data-command-search",
          [item.label, item.kind, item.id].filter(Boolean).join(" ")
        );

        var label = document.createElement("span");
        label.className = "scoria-command__label";
        label.textContent = item.label;
        row.appendChild(label);
        rows.appendChild(row);
      });
      this.refreshRows();
    },

    filterRows: function () {
      this.refreshRows();
      var query = this.input ? this.input.value.trim().toLowerCase() : "";
      var visibleRows = [];

      forEachNode(this.rows, function (row) {
        var haystack = (row.getAttribute("data-command-search") || row.textContent || "").toLowerCase();
        var visible = query === "" || haystack.indexOf(query) !== -1;
        row.hidden = !visible;
        row.setAttribute("aria-selected", "false");
        if (visible) visibleRows.push(row);
      });

      forEachNode(this.el.querySelectorAll("[data-command-section]"), function (section) {
        var visibleInSection = section.querySelector("[data-command-row]:not([hidden])");
        section.hidden = !visibleInSection;
      });

      if (this.empty) this.empty.hidden = visibleRows.length !== 0;
      this.visibleRows = visibleRows;
      this.activeIndex = 0;
      this.updateActiveRow();
    },

    updateActiveRow: function () {
      var active = this.visibleRows && this.visibleRows[this.activeIndex];
      forEachNode(this.rows, function (row) {
        row.setAttribute("aria-selected", row === active ? "true" : "false");
      });
      if (this.list) {
        if (active) this.list.setAttribute("aria-activedescendant", active.id);
        else this.list.removeAttribute("aria-activedescendant");
      }
    },

    moveActive: function (delta) {
      if (!this.visibleRows || this.visibleRows.length === 0) return;
      this.activeIndex = (this.activeIndex + delta + this.visibleRows.length) % this.visibleRows.length;
      this.updateActiveRow();
    },

    activateCurrent: function () {
      if (!this.visibleRows || this.visibleRows.length === 0) return;
      this.visibleRows[this.activeIndex].click();
    },

    handlePaletteKeydown: function (e) {
      if (e.key === "Escape") {
        e.preventDefault();
        this.closePalette(true);
        return;
      }
      if (e.key === "ArrowDown") {
        e.preventDefault();
        this.moveActive(1);
        return;
      }
      if (e.key === "ArrowUp") {
        e.preventDefault();
        this.moveActive(-1);
        return;
      }
      if (e.key === "Enter") {
        e.preventDefault();
        this.activateCurrent();
        return;
      }
      if (e.key === "Tab") {
        this.trapFocus(e, this.el);
      }
    },

    handleDocumentKeydown: function (e) {
      if (e.isComposing) return;

      if (e.key === "Escape") {
        if (this.shortcutsOpen()) {
          e.preventDefault();
          this.closeShortcuts(true);
          return;
        }
        if (this.paletteOpen()) {
          e.preventDefault();
          this.closePalette(true);
          return;
        }
      }

      if (this.shortcutsOpen() && e.key === "Tab") {
        this.trapFocus(e, this.shortcutOverlay);
        return;
      }

      if (editableTarget(e.target)) return;

      var key = e.key ? e.key.toLowerCase() : "";
      if ((e.metaKey || e.ctrlKey) && key === "k") {
        e.preventDefault();
        this.openPalette(document.activeElement);
        return;
      }

      if (!e.metaKey && !e.ctrlKey && !e.altKey && e.key === "?") {
        e.preventDefault();
        this.openShortcuts(document.activeElement);
        return;
      }

      if (e.metaKey || e.ctrlKey || e.altKey) return;

      if (key === "g") {
        e.preventDefault();
        this.awaitGChord();
        return;
      }

      if (this.gChord) {
        e.preventDefault();
        this.activateGChord("g " + key);
      }
    },

    awaitGChord: function () {
      var self = this;
      clearTimeout(this.gTimer);
      this.gChord = "g";
      this.gTimer = setTimeout(function () {
        self.gChord = null;
      }, 1500);
    },

    activateGChord: function (chord) {
      clearTimeout(this.gTimer);
      this.gChord = null;
      if (this.chordMap && this.chordMap[chord]) {
        window.location.assign(this.chordMap[chord]);
      }
    },

    runAction: function (action) {
      if (action === "toggle-theme") {
        var toggle = document.getElementById("scoria-theme-toggle");
        if (toggle) toggle.click();
        this.closePalette(true);
        return;
      }
      if (action === "show-shortcuts") {
        this.closePalette(false);
        this.openShortcuts(this.restoreFocus || document.activeElement);
        return;
      }
      if (action === "copy-url") {
        if (navigator.clipboard) navigator.clipboard.writeText(window.location.href);
        this.closePalette(true);
      }
    },

    openShortcuts: function (opener) {
      if (!this.shortcutOverlay) return;
      clearTimeout(this.shortcutCloseTimer);
      this.shortcutRestoreFocus = opener || document.activeElement;
      this.shortcutOverlay.hidden = false;
      this.shortcutOverlay.removeAttribute("aria-hidden");
      this.shortcutOverlay.setAttribute("data-state", "open");
      if (this.shortcutPanel) this.shortcutPanel.focus({ preventScroll: true });
    },

    closeShortcuts: function (restore) {
      var self = this;
      if (!this.shortcutOverlay) return;
      this.shortcutOverlay.setAttribute("data-state", "closed");
      this.shortcutOverlay.setAttribute("aria-hidden", "true");
      clearTimeout(this.shortcutCloseTimer);
      this.shortcutCloseTimer = setTimeout(function () {
        self.shortcutOverlay.hidden = true;
      }, 120);
      if (restore && this.shortcutRestoreFocus && this.shortcutRestoreFocus.focus) {
        this.shortcutRestoreFocus.focus({ preventScroll: true });
      }
    },

    shortcutsOpen: function () {
      return (
        this.shortcutOverlay &&
        !this.shortcutOverlay.hidden &&
        this.shortcutOverlay.getAttribute("data-state") === "open"
      );
    },

    trapFocus: function (e, root) {
      var focusables = focusableElements(root);
      if (focusables.length === 0) return;
      var first = focusables[0];
      var last = focusables[focusables.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    },
  };

  // Mobile off-canvas nav drawer open/close/trap/restore.
  // Reuses focusableElements and trapFocus helpers from CommandPalette.
  // JS owns only open/close/focus/hidden-delay — motion is CSS-owned via data-state (D-19).
  Hooks.MobileNav = {
    mounted: function () {
      var self = this;
      this.panel = this.el.querySelector(".scoria-mobile-drawer");
      this.closeTimer = null;
      this.restoreFocus = null;
      this.desktopMedia = window.matchMedia ? window.matchMedia("(min-width: 768px)") : null;

      this.openNav = function (opener) {
        if (self.desktopMedia && self.desktopMedia.matches) return;
        clearTimeout(self.closeTimer);
        self.restoreFocus = opener || document.activeElement;
        self.el.hidden = false;
        self.el.setAttribute("data-state", "open");
        // Update opener aria-expanded
        var openerEl = document.querySelector("[data-mobile-nav-open]");
        if (openerEl) openerEl.setAttribute("aria-expanded", "true");
        // Move focus into the panel
        if (self.panel) self.panel.focus({ preventScroll: true });
      };

      this.closeNav = function (restore) {
        self.el.setAttribute("data-state", "closed");
        // Update opener aria-expanded
        var openerEl = document.querySelector("[data-mobile-nav-open]");
        if (openerEl) openerEl.setAttribute("aria-expanded", "false");
        // Delay hidden so the CSS fade/slide can run (200ms scoria-slide, D-15/D-19)
        clearTimeout(self.closeTimer);
        self.closeTimer = setTimeout(function () {
          self.el.hidden = true;
        }, 200);
        if (restore && self.restoreFocus && self.restoreFocus.focus) {
          self.restoreFocus.focus({ preventScroll: true });
        }
      };

      this.forceCloseForDesktop = function () {
        clearTimeout(self.closeTimer);
        self.el.setAttribute("data-state", "closed");
        self.el.hidden = true;
        var openerEl = document.querySelector("[data-mobile-nav-open]");
        if (openerEl) openerEl.setAttribute("aria-expanded", "false");
      };

      this.isOpen = function () {
        return !self.el.hidden && self.el.getAttribute("data-state") === "open";
      };

      // Open button click
      this.openHandler = function (e) {
        var btn = e.target && e.target.closest ? e.target.closest("[data-mobile-nav-open]") : null;
        if (btn) self.openNav(btn);
      };

      // Close button / scrim click
      this.closeHandler = function (e) {
        var closeEl = e.target && e.target.closest ? e.target.closest("[data-mobile-nav-close]") : null;
        if (closeEl && self.isOpen()) self.closeNav(true);
      };

      // Keyboard: Escape dismiss + focus trap
      this.keydownHandler = function (e) {
        if (!self.isOpen()) return;
        if (e.key === "Escape") {
          e.preventDefault();
          e.stopPropagation();
          self.closeNav(true);
          return;
        }
        if (e.key === "Tab" && self.panel) {
          self.trapFocusInPanel(e);
        }
      };

      this.mediaHandler = function (event) {
        if (event.matches) self.forceCloseForDesktop();
      };

      this.trapFocusInPanel = function (e) {
        var focusables = focusableElements(self.panel);
        if (focusables.length === 0) return;
        var first = focusables[0];
        var last = focusables[focusables.length - 1];
        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      };

      document.addEventListener("click", this.openHandler);
      document.addEventListener("click", this.closeHandler);
      document.addEventListener("keydown", this.keydownHandler, true);
      if (this.desktopMedia) {
        if (this.desktopMedia.addEventListener) {
          this.desktopMedia.addEventListener("change", this.mediaHandler);
        } else if (this.desktopMedia.addListener) {
          this.desktopMedia.addListener(this.mediaHandler);
        }
        if (this.desktopMedia.matches) this.forceCloseForDesktop();
      }
    },

    destroyed: function () {
      document.removeEventListener("click", this.openHandler);
      document.removeEventListener("click", this.closeHandler);
      document.removeEventListener("keydown", this.keydownHandler, true);
      if (this.desktopMedia) {
        if (this.desktopMedia.removeEventListener) {
          this.desktopMedia.removeEventListener("change", this.mediaHandler);
        } else if (this.desktopMedia.removeListener) {
          this.desktopMedia.removeListener(this.mediaHandler);
        }
      }
      clearTimeout(this.closeTimer);
    },
  };

  Hooks.RecordRecentObject = {
    mounted: function () {
      var kind = this.el.getAttribute("data-scoria-kind");
      var id = this.el.getAttribute("data-scoria-id");
      var label = this.el.getAttribute("data-scoria-label");
      if (!kind || !id || !label) return;

      var key = recentsKeyFor(this.el);
      var path = window.location.pathname;
      var next = { kind: kind, id: id, label: label, path: path };
      var recents = readJson(key, []);
      recents = recents.filter(function (item) {
        return item && !(item.kind === next.kind && item.id === next.id);
      });
      recents.unshift(next);
      writeJson(key, recents.slice(0, 8));
    },
  };

  function hashString(value) {
    var hash = 0;
    for (var i = 0; i < value.length; i++) {
      hash = (hash << 5) - hash + value.charCodeAt(i);
      hash |= 0;
    }
    return hash;
  }

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
