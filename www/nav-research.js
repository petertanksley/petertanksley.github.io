// The navbar's "Research" dropdown label doubles as the link to the Research page, which is not listed
// inside the menu. On hover-capable desktops the label is a plain link and the menu opens on hover (see
// theme.scss). On touch screens and in the collapsed phone menu, the first tap opens the menu as usual
// and a second tap on the label, with the menu open, goes to the page.
(function () {
  var toggle = document.getElementById("nav-menu-research");
  var brand = document.querySelector(".navbar-brand");
  if (!toggle || !brand) return;
  // the brand href is Quarto's relative path to index.html from the current page
  var target = brand.getAttribute("href").replace(/index\.html$/, "research.html");
  var desktop = window.matchMedia("(min-width: 992px) and (hover: hover)");

  function apply() {
    if (desktop.matches) {
      toggle.setAttribute("href", target);
      toggle.removeAttribute("data-bs-toggle");
      toggle.removeAttribute("role");
    } else {
      toggle.setAttribute("href", "#");
      toggle.setAttribute("data-bs-toggle", "dropdown");
      toggle.setAttribute("role", "link");
    }
  }
  // fires before Bootstrap's delegated handler, so aria-expanded is still the pre-tap state
  toggle.addEventListener("click", function (e) {
    if (!desktop.matches && toggle.getAttribute("aria-expanded") === "true") {
      e.preventDefault();
      e.stopPropagation();
      window.location.href = target;
    }
  });
  // no menu item matches research.html, so Quarto never marks the tab active there; do it here
  if (/\/research\.html$/.test(window.location.pathname)) toggle.classList.add("active");
  apply();
  desktop.addEventListener("change", apply);
})();
