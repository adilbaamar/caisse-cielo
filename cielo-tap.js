// Pont « window.CieloTap » injecté dans la caisse quand elle tourne dans l'app native.
// Utilise @capacitor-community/stripe-terminal (Tap to Pay sur iPhone).
(function () {
  var Cap = window.Capacitor; if (!Cap || !Cap.isNativePlatform || !Cap.isNativePlatform()) return;
  var ST = Cap.Plugins.StripeTerminal; if (!ST) return;
  var ready = null, locationId = null;
  function init() {
    if (ready) return ready;
    ready = fetch("/.netlify/functions/terminal?a=location").then(function (r) { return r.json(); }).then(function (loc) {
      locationId = loc.id;
      return ST.initialize({ tokenProviderEndpoint: location.origin + "/.netlify/functions/terminal?a=token", isTest: false });
    }).then(function () {
      return ST.discoverReaders({ type: "tap-to-pay", locationId: locationId });
    }).then(function (res) {
      var reader = (res.readers || [])[0]; if (!reader) throw new Error("Tap to Pay non disponible sur cet appareil");
      return ST.connectReader({ reader: reader, locationId: locationId, merchantDisplayName: "Cielo Montréal" });
    });
    return ready;
  }
  window.CieloTap = {
    available: true,
    collect: function (clientSecret, onMsg) {
      return init().then(function () {
        onMsg && onMsg("Approchez la carte du haut de l'iPhone");
        return ST.collectPaymentMethod({ paymentIntent: clientSecret });
      }).then(function () {
        onMsg && onMsg("Traitement…");
        return ST.confirmPaymentIntent();
      }).then(function (res) {
        return { paymentIntentId: res && res.paymentIntent ? res.paymentIntent.id || res.paymentIntent : null, raw: res };
      });
    },
    cancel: function () { try { ST.cancelCollectPaymentMethod(); } catch (e) {} }
  };
})();
