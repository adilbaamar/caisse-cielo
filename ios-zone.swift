import CoreLocation
import UserNotifications

/// Surveille une zone autour de Cielo (iOS la gère, même app fermée) et affiche une notification locale à l'entrée.
class CieloZone: NSObject, CLLocationManagerDelegate {
    static let shared = CieloZone()
    let lm = CLLocationManager()
    let d = UserDefaults.standard
    var cfg: [String: Any] {
        get { d.dictionary(forKey: "cieloZoneCfg") ?? [:] }
        set { d.set(newValue, forKey: "cieloZoneCfg") }
    }
    override init() { super.init(); lm.delegate = self }

    /// Appelé au lancement de l'app (y compris un relancement en arrière-plan par iOS)
    func demarrer() {
        NotificationCenter.default.addObserver(forName: Notification.Name("CieloZoneMaj"), object: nil, queue: .main) { [weak self] _ in self?.maj() }
        surveiller()
    }
    func maj() {
        if cfg["actif"] as? Bool != true { for x in lm.monitoredRegions { lm.stopMonitoring(for: x) }; return }
        if cfg["demander"] as? Bool == true {
            switch lm.authorizationStatus {
            case .notDetermined: lm.requestWhenInUseAuthorization(); return
            case .authorizedWhenInUse: var c = cfg; c["demander"] = false; cfg = c; lm.requestAlwaysAuthorization(); return
            default: break
            }
        }
        surveiller()
    }

    func surveiller() {
        guard let lat = cfg["lat"] as? Double, let lng = cfg["lng"] as? Double, cfg["actif"] as? Bool == true else { return }
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        let r = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: (cfg["rayon"] as? Double) ?? 250, identifier: "cielo")
        r.notifyOnEntry = true; r.notifyOnExit = false
        for x in lm.monitoredRegions where x.identifier == "cielo" { lm.stopMonitoring(for: x) }
        lm.startMonitoring(for: r)
    }

    func peutNotifier() -> Bool {
        let now = Date(), cal = Calendar.current
        var tz = cal; tz.timeZone = TimeZone(identifier: "America/Toronto")!
        let h = tz.component(.hour, from: now) * 60 + tz.component(.minute, from: now)
        let ouv = (cfg["ouverture"] as? Int) ?? 11 * 60, ferm = (cfg["fermeture"] as? Int) ?? 19 * 60 + 30
        if h < ouv || h > ferm { return false }
        let jour = tz.startOfDay(for: now).timeIntervalSince1970
        if let c = d.object(forKey: "cieloDerniereCommande") as? Double, c >= jour { return false }      // déjà commandé aujourd'hui
        let delai = Double((cfg["joursEntre"] as? Int) ?? 7) * 86400
        if let n = d.object(forKey: "cieloZoneDerniere") as? Double, now.timeIntervalSince1970 - n < delai { return false }
        return true
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier == "cielo", peutNotifier() else { return }
        d.set(Date().timeIntervalSince1970, forKey: "cieloZoneDerniere")
        let c = UNMutableNotificationContent()
        let en = (cfg["langue"] as? String) == "en"
        c.title = (cfg["titre"] as? String) ?? (en ? "You're nearby 👋" : "T'es dans le coin 👋")
        c.body = (cfg["corps"] as? String) ?? (en ? "Your bowl can be ready in 15 min. Order in the app." : "Ton bol peut être prêt en 15 min. Commande dans l'app.")
        c.sound = .default
        c.userInfo = ["url": "https://commande.cielomontreal.ca/commande.html?app=1&src=zone"]
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "cielo-zone-\(Int(Date().timeIntervalSince1970))", content: c, trigger: nil))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse, cfg["demander"] as? Bool == true {
            var c = cfg; c["demander"] = false; cfg = c
            manager.requestAlwaysAuthorization()
        }
        if manager.authorizationStatus == .authorizedAlways { surveiller() }
    }
}

