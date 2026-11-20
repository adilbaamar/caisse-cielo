import Foundation
import Capacitor
import CoreLocation

/// Côté JS : enregistre la configuration de la zone ; la surveillance vit dans l'app (CieloZone, AppDelegate).
@objc(CieloGeofencePlugin)
public class CieloGeofencePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CieloGeofencePlugin"
    public let jsName = "CieloGeofence"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "activer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "statut", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "commandePassee", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "desactiver", returnType: CAPPluginReturnPromise)
    ]
    let d = UserDefaults.standard
    func statutTexte() -> String {
        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways: return "toujours"
        case .authorizedWhenInUse: return "utilisation"
        case .denied, .restricted: return "refuse"
        default: return "inconnu"
        }
    }
    func majZone() { DispatchQueue.main.async { NotificationCenter.default.post(name: Notification.Name("CieloZoneMaj"), object: nil) } }
    @objc func activer(_ call: CAPPluginCall) {
        var c = d.dictionary(forKey: "cieloZoneCfg") ?? [:]
        c["actif"] = true
        c["lat"] = call.getDouble("lat") ?? 45.491945
        c["lng"] = call.getDouble("lng") ?? -73.561246
        c["rayon"] = call.getDouble("rayon") ?? 250
        c["joursEntre"] = call.getInt("joursEntre") ?? 7
        c["ouverture"] = call.getInt("ouverture") ?? 660
        c["fermeture"] = call.getInt("fermeture") ?? 1170
        if let l = call.getString("langue") { c["langue"] = l }
        if let t = call.getString("titre") { c["titre"] = t }
        if let b = call.getString("corps") { c["corps"] = b }
        c["demander"] = true
        d.set(c, forKey: "cieloZoneCfg")
        majZone()
        call.resolve(["statut": statutTexte()])
    }
    @objc func statut(_ call: CAPPluginCall) { call.resolve(["statut": statutTexte(), "actif": (d.dictionary(forKey: "cieloZoneCfg")?["actif"] as? Bool) ?? false]) }
    @objc func commandePassee(_ call: CAPPluginCall) { d.set(Date().timeIntervalSince1970, forKey: "cieloDerniereCommande"); call.resolve() }
    @objc func desactiver(_ call: CAPPluginCall) {
        var c = d.dictionary(forKey: "cieloZoneCfg") ?? [:]; c["actif"] = false; d.set(c, forKey: "cieloZoneCfg"); majZone(); call.resolve()
    }
}
