import "../js/alpine.js";
import "../js/lightswitch.js";
import "../js/click-to-copy";
import "../js/otp-input.js";
import { registerWebauthn } from "../js/webauthn-registration.js";
import { authenticateWebauthn } from "../js/webauthn-authentication.js";
import htmx from "htmx.org"
window.htmx = htmx

window.registerWebauthn = registerWebauthn;
window.authenticateWebauthn = authenticateWebauthn;

// Add CSRF token to all HTMX requests
document.addEventListener('htmx:configRequest', (event) => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) {
    event.detail.headers['X-CSRF-Token'] = csrfToken;
  }
});

document.addEventListener('DOMContentLoaded', () => {
  registerWebauthn.init();
  authenticateWebauthn.init();
});

document.addEventListener('htmx:afterSwap', () => {
  registerWebauthn.init();
  authenticateWebauthn.init();
});