// Fix webview overlays to align with editor bounds.
//
// VS Code positions webviews at layout time using its own coordinate system.
// We re-sync after each VS Code update via MutationObserver + setInterval.
//
// Clamps width/height of all webview containers (extensions, notebooks, etc.)
// to stay within .part.editor bounds, and applies bottom border-radius.
(function () {
  var RADIUS = 24; // --islands-panel-radius
  var GAP = 8;     // --islands-panel-gap

  function getEditorRect() {
    var editor = document.querySelector('.part.editor');
    if (!editor) return null;
    return editor.getBoundingClientRect();
  }

  function fixWebview(el) {
    if (!el || !el.hasAttribute('data-parent-flow-to-element-id')) return;

    var rawLeft = parseFloat(el.style.left || 0);
    if (rawLeft < -1000) return; // hidden/inactive webview

    var editorRect = getEditorRect();
    if (!editorRect) return;

    var elTop = parseFloat(el.style.top || 0);
    var maxWidth = editorRect.right - rawLeft - GAP;
    if (parseFloat(el.style.width || 0) > maxWidth) {
      el.style.setProperty('width', maxWidth + 'px', 'important');
    }
    var maxHeight = editorRect.bottom - elTop;
    if (parseFloat(el.style.height || 0) > maxHeight) {
      el.style.setProperty('height', maxHeight + 'px', 'important');
    }

    el.style.setProperty('border-radius', '0 0 ' + RADIUS + 'px ' + RADIUS + 'px', 'important');
    el.style.setProperty('overflow', 'hidden', 'important');
  }

  function fixAll() {
    document.querySelectorAll('div[data-parent-flow-to-element-id]').forEach(fixWebview);
  }

  // Debounce via double-rAF to run after VS Code's layout pass
  var fixTimer = null;
  function scheduleFix() {
    if (fixTimer) cancelAnimationFrame(fixTimer);
    fixTimer = requestAnimationFrame(function () {
      fixTimer = requestAnimationFrame(fixAll);
    });
  }

  // ResizeObserver on .part.editor to catch resize layout passes
  var editorResizeObserver = null;
  function setupEditorObserver() {
    if (editorResizeObserver) return;
    var editorEl = document.querySelector('.part.editor');
    if (!editorEl) return;
    editorResizeObserver = new ResizeObserver(scheduleFix);
    editorResizeObserver.observe(editorEl);
  }

  // MutationObserver to detect new/changed webview containers
  var observer = new MutationObserver(function (mutations) {
    var needsFix = false;
    for (var i = 0; i < mutations.length; i++) {
      var mutation = mutations[i];
      for (var j = 0; j < mutation.addedNodes.length; j++) {
        var node = mutation.addedNodes[j];
        if (node.nodeType === 1) {
          if (node.hasAttribute && node.hasAttribute('data-parent-flow-to-element-id')) {
            needsFix = true;
          }
          if (node.querySelectorAll && node.querySelectorAll('div[data-parent-flow-to-element-id]').length > 0) {
            needsFix = true;
          }
        }
      }
      if (mutation.type === 'attributes' &&
          mutation.target.hasAttribute &&
          mutation.target.hasAttribute('data-parent-flow-to-element-id')) {
        needsFix = true;
      }
    }
    if (needsFix) scheduleFix();
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['style']
  });

  window.addEventListener('resize', scheduleFix);
  setInterval(fixAll, 500);
  setTimeout(function () { fixAll(); setupEditorObserver(); }, 1000);
})();
