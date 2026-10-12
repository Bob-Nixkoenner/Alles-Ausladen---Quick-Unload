# Design: „Weiche“ (Arbeitstitel) – Split-Tunneling & DNS-Router für WireGuard

> **Status:** Entwurf v0.1 · **Lizenz (geplant):** Apache-2.0
> Der Name ist ein Platzhalter. Das Dokument zieht ins eigene Repo um, sobald es einen Namen gibt.

---

## 1. Ziel

Ein Open-Source-WireGuard-Client, der entscheidet, **welcher Traffic welchen Weg nimmt** – pro App, IP, Domain, Port oder Dienst – und **welcher DNS-Server für welchen Weg** zuständig ist. Linux (Pop!_OS) zuerst, Architektur von Anfang an portierbar (Android, Windows, macOS).

Kurz: *Rethink DNS für den Desktop, mit Kernel-Speed.*

### Ziele

- Split-Tunneling pro **App**, **CIDR**, **Domain**, **Port/Protokoll**, **ASN-/IP-Liste**, **Preset-Bundle**
- **Mehrere Tunnel gleichzeitig** (App A → Tunnel 1, App B → Tunnel 2, Rest direkt)
- **DNS-Upstream pro Route** (z. B. direkt → lokales Pi-hole, Tunnel → AdGuard Home am Tunnelende)
- **Fail-closed** in jeder Lage (Absturz, Boot, Tunnel weg)
- Austauschbare Frontends über eine stabile API
- Keine Telemetrie, keine Cloud, keine Accounts

### Nicht-Ziele

- Anonymisierung (kein Tor-Ersatz, kein Schutz vor Browser-Fingerprinting)
- VPN-Anbieter-Integration / Server-Marktplatz
- Schutz vor einem kompromittierten Root-Account auf dem eigenen Rechner

---

## 2. Abgrenzung

| Projekt | Was es kann | Was fehlt / Warum nicht einfach das |
|---|---|---|
| **WireSock** (Windows) | App-Split, IP-Ausnahmen, Backup-Tunnel | Closed Source, proprietärer Kernel-Treiber, nur Windows |
| **Mullvad-App** | App-Split (Linux via cgroups) | Nur Mullvad-Server, keine Domain-Regeln, kein DNS pro Route |
| **Rethink DNS / firestack** | Firewall, DNS, Multi-WireGuard, App-Regeln | Nur Android; Userspace-Netstack (langsamer auf Desktop) |
| **OpenSnitch** | App-Firewall Linux | Kein Routing, kein WireGuard |
| **wireguird** | GTK-GUI für wg-quick | Nur Tunnel an/aus, GUI läuft als root |

`firestack` (MPL-2.0) ist ein Kandidat als **Bibliothek für den DNS-Resolver-Teil** (DoH/DoT/ODoH/DNSCrypt). MPL-2.0 ist mit Apache-2.0 kompatibel; geänderte firestack-Dateien bleiben MPL.

---

## 3. Architektur

```
┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
│    CLI     │ │  Web-UI    │ │  Tauri /   │ │  Android-  │
│  (wsctl)   │ │ (localhost)│ │  Flutter   │ │    App     │
└─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
      └──────── gRPC über Unix-Socket (polkit) ────┘
┌──────────────────────────────────────────────────────────┐
│ CORE (Go, plattformneutral)                              │
│  • Config & Profile        • Regel-Engine (Compiler)     │
│  • Tunnel-Manager          • DNS-Proxy (pro Route)       │
│  • State/Health/Killswitch • Event-Bus, Leak-Selbsttest  │
└─────┬───────────────────────┬────────────────────────┬───┘
      │      Backend-Interface (Enforcer + Tunnel)      │
┌─────┴──────────┐  ┌─────────┴────────┐  ┌────────────┴─────┐
│ Linux          │  │ Android          │  │ Windows          │
│ nftables,      │  │ VpnService,      │  │ WFP,             │
│ cgroup v2,     │  │ wireguard-go     │  │ wireguard-nt     │
│ ip rule, Kernel│  │ (gomobile)       │  │                  │
│ WireGuard      │  │                  │  │                  │
└────────────────┘  └──────────────────┘  └──────────────────┘
```

### Prozesse (Linux)

| Prozess | Rechte | Aufgabe |
|---|---|---|
| `weiched` | systemd-Service, nur `CAP_NET_ADMIN` (+`CAP_NET_BIND_SERVICE`), gehärtet | Tunnel, nftables, Routing, DNS-Proxy, API |
| `weiche` (CLI) | User | API-Client, `weiche run --via X -- app` |
| `weiche-ui` | User | Lokale Web-UI, spricht nur mit dem Socket |

**Grundregel:** Keine Oberfläche läuft jemals mit Root-Rechten.

### Backend-Interface (Skizze)

```go
type Backend interface {
    TunnelUp(ctx context.Context, t TunnelSpec) (TunnelHandle, error)
    TunnelDown(ctx context.Context, h TunnelHandle) error
    Apply(ctx context.Context, plan CompiledPlan) error   // atomar!
    DomainSetAdd(target RouteID, ips []netip.Addr, ttl time.Duration) error
    LaunchInRoute(ctx context.Context, route RouteID, cmd []string) error
    Lockdown(ctx context.Context, on bool) error
    Capabilities() BackendCaps // was kann die Plattform? (UI blendet aus)
}
```

Die Regel-Engine kompiliert die Config in einen plattformneutralen `CompiledPlan`; das Backend übersetzt ihn in native Mechanismen. **`Apply` ist atomar** (nftables-Transaktion), es gibt nie einen halb angewendeten Zustand.

### Technik-Stack (alles permissiv lizenziert)

- `golang.zx2c4.com/wireguard/wgctrl` – Kernel-WG konfigurieren
- `github.com/vishvananda/netlink` – Interfaces, Routen, ip rules
- `github.com/google/nftables` – nftables via Netlink (kein `nft`-Shell-Out)
- `github.com/miekg/dns` – DNS-Proxy (ggf. Teile aus firestack)
- `github.com/coreos/go-systemd` – Scopes/Slices über D-Bus
- gRPC + protobuf – API

---

## 4. Regel-Modell

### Bausteine

- **Route** (Ziel): `direct`, `block`, `tunnel:<name>`
- **Selektor**: `app`, `cidr`, `domain`, `port`, `asn`, `list`, `preset`
- **Regel**: Selektor(en) → Route, optional `killswitch`, `lan` (allow/deny), `dns` (Override)

### Auswertung

1. Regeln haben eine explizite Reihenfolge, **first match wins**.
2. Mehrere Selektoren in einer Regel = UND-Verknüpfung.
3. Empfohlene Default-Reihenfolge (UI sortiert so vor):
   `block` → `domain` / `cidr` / `port` → `app` → Default-Route.
   *Begründung:* Spezifisches (diese Seite) schlägt Allgemeines (diese App).
4. Ohne Treffer greift die **Default-Route** des aktiven Profils.

### Beispiel-Config (TOML)

```toml
[profile.zuhause]
default_route = "direct"
dns.direct    = "pihole"

[profile.unterwegs]
default_route = "tunnel:home"      # alles nach Hause
killswitch    = true
net_hygiene   = { random_mac = true, hide_dhcp_hostname = true }
match.ssid_not = ["MeinWLAN"]       # automatische Umschaltung

[dns.upstream.pihole]
addr = "192.168.1.2:53"

[dns.upstream.adguard-vps]
addr  = "https://10.8.0.1/dns-query"  # DoH, über den Tunnel erreichbar
route = "tunnel:vps"                  # MUSS über diese Route laufen

[tunnel.vps]
config = "/etc/weiche/tunnels/vps.conf"   # wg-quick-kompatibel, 0600
dns    = "adguard-vps"

[tunnel.home]
config = "/etc/weiche/tunnels/home.conf"
dns    = "pihole"

[[rule]]
name  = "Torrent nur über VPS, sonst gar nicht"
app   = ["flatpak:org.qbittorrent.qBittorrent"]
route = "tunnel:vps"
killswitch = true
lan   = "deny"

[[rule]]
name   = "Streaming direkt"
preset = ["streaming/netflix"]
route  = "direct"

[[rule]]
name   = "Firefox über VPS"
app    = ["desktop:org.mozilla.firefox", "exe:/usr/lib/firefox/firefox"]
route  = "tunnel:vps"

[[rule]]
name = "SSH immer direkt"
port = ["tcp/22"]
route = "direct"
```

---

## 5. DNS-Design

### Grundprinzip

> **Was durch einen Tunnel geht, wird durch diesen Tunnel aufgelöst.**
> Das ist keine Option, die Engine erzwingt es. (Sonst fragt z. B. Unbound am Pi-hole die Root-Server mit der Heim-IP und der Provider sieht's.)

### Ablauf

1. Jede Route bekommt einen **eigenen Listener** des DNS-Proxys (z. B. `127.0.77.1:53` = direct, `127.0.77.2:53` = tunnel:vps …).
2. nftables leitet DNS-Anfragen per **DNAT pro cgroup/Route** auf den passenden Listener um. Der Proxy weiß damit *ohne Raten*, aus welcher Route die Anfrage stammt.
3. Proxy prüft **Domain-Regeln**:
   - Treffer → Upstream der Ziel-Route der Domain-Regel verwenden; aufgelöste IPs (A/AAAA, CNAME-Kette folgen) mit TTL in das nft-Set der Ziel-Route schreiben.
   - kein Treffer → Upstream der Route des Listeners.
4. Antwort erst zurückgeben, **nachdem** die IPs im Set stehen (sonst Race: erstes Paket nimmt die falsche Route).
5. Der Proxy selbst erreicht Upstreams über die passende Route (eigene fwmark pro Upstream-Socket).

### Upstream-Typen

Plain DNS (UDP/TCP), DoT, DoH, DNSCrypt, ODoH (via firestack, optional).

### Durchsetzung (Pflicht)

- Ausgehend `udp/tcp 53` und `tcp 853` von allen außer `weiched` → DNAT auf Proxy bzw. Drop.
- Blockliste bekannter DoH-Endpunkte (pflegbar) + Canary-Domain `use-application-dns.net` → NXDOMAIN (Firefox schaltet DoH ab).
- UI zeigt deutlich: *„Domain-Regeln greifen nicht für Apps mit eigenem DoH.“*

### Hygiene

- EDNS Client Subnet entfernen
- EDNS-Padding (RFC 7830/8467) bei verschlüsselten Upstreams
- DNSSEC-Validierung optional
- Query-Logs nur im RAM, standardmäßig aus

### Bekannte Grenzen

- **CDN-Sharing:** Domain-Regeln routen IPs, nicht Domains. Andere Seiten auf derselben CDN-IP nehmen dieselbe Route. Wird dokumentiert, nicht „gefixt“.
- **Hardcodierte IPs / eigene Resolver** in Apps umgehen Domain-Regeln (App- oder CIDR-Regeln greifen weiterhin).
- **nss-resolve (Varlink/D-Bus zu systemd-resolved)** umgeht Port 53. Pop!_OS/Ubuntu nutzen standardmäßig den Stub `127.0.0.53` → abfangbar. Daemon prüft `nsswitch.conf` beim Start und warnt.

---

## 6. Linux-Backend (Pop!_OS)

### 6.1 App-Zuordnung via cgroup v2

- Pro Route eine **persistente systemd-Slice** im User-Manager:
  `weiche-tunnel-vps.slice`, `weiche-direct.slice`, `weiche-block.slice`.
- `weiche run --via vps -- firefox` → `systemd-run --user --scope --slice=weiche-tunnel-vps.slice …`
  Kindprozesse erben die cgroup automatisch (Browser-Multiprozess ✔).
- **Wichtig:** nftables löst `socket cgroupv2`-Pfade **beim Laden der Regel** in eine cgroup-ID auf. Deshalb matchen wir auf die **langlebige Slice-Ebene**, nicht auf flüchtige Scopes.
- **Flatpak/Snap** haben eigene Scopes (`app-flatpak-<id>-<n>.scope`). Der Daemon beobachtet systemd (D-Bus `UnitNew`) und hängt beim Erscheinen eine Regel für genau diesen Scope ein (bzw. entfernt sie beim Verschwinden).
- **Desktop-Starts:** Moderne Desktops starten Apps in `app-<launcher>-<appid>-<rand>.scope`. ⚠️ Für COSMIC zu verifizieren. Falls ja: App-Regeln greifen auch ohne Wrapper.
- **`exe:`-Selektor** (Auto-Zuordnung bereits laufender/fremd gestarteter Prozesse) via Proc-Connector (`PROC_EVENT_EXEC`) + Umhängen in die Slice. **Race:** Erste Pakete vor dem Umhängen könnten falsch laufen → bei `killswitch=true` nur mit „unklassifiziert = block“-Modus erlaubt. Bestehende Verbindungen behalten ihre alte Route.

### 6.2 Markierung & Routing

```
nft table inet weiche
 ├─ chain output   (type route, hook output, priority mangle)
 │    ct mark != 0  → meta mark set ct mark ; return       # bestehende Verbindungen
 │    <kompilierte Regeln, first match wins>                # setzt meta mark
 │    meta mark != 0 → ct mark set meta mark
 ├─ chain nat_out  (type nat, hook output)                  # DNS-DNAT pro Route
 ├─ chain postrouting (type nat) oifname "wg-*" masquerade  # Quell-IP fixen nach Reroute
 ├─ chain filter_out (type filter, hook output, policy drop bei Lockdown/Killswitch)
 └─ sets: dst_<route>_v4 / _v6 (flags timeout), lan_nets, doh_block
```

- Änderung der Mark in einer `type route`-Chain löst im Kernel ein **Reroute** aus.
- Pro Route: eigene Routing-Tabelle + `ip rule fwmark <m> lookup <t>` (v4 **und** v6).
- **Jede Tunnel-Tabelle enthält immer `unreachable default` mit hoher Metrik.** Ist der Tunnel weg, fällt Traffic **nicht** in die Main-Tabelle durch → Killswitch ist Eigenschaft der Tabelle, nicht des Daemons.
- WireGuard-eigene UDP-Pakete: `wg set fwmark <bypass>` → Main-Tabelle (kein Routing-Loop).
- `net.ipv4.conf.all.src_valid_mark=1` (wie wg-quick), rp_filter für `wg-*` auf loose.
- **IPv6:** Tunnel ohne v6 → v6-Tabelle der Route nur `unreachable default` = v6 für diese Apps blockiert, nicht geleakt.
- `wg-quick` wird **nicht** verwendet; Configs im wg-quick-Format werden nur **importiert**.

### 6.3 Fail-closed

| Situation | Verhalten |
|---|---|
| Daemon stürzt ab | nft-Regeln & Routen bleiben im Kernel → weiter blockiert/geroutet |
| Tunnel down | `unreachable default` greift für Regeln mit Killswitch; ohne Killswitch fällt die Regel bewusst auf `direct` zurück (Opt-out, in UI rot markiert) |
| Boot | `weiche-lockdown.service` (`Before=network-pre.target`) lädt Minimal-Ruleset: Drop außer lo, DHCP, ggf. LAN. Aufgehoben, sobald `weiched` den Plan angewendet hat |
| Config-Fehler | Alter Plan bleibt aktiv (atomare Transaktion), Fehler an UI |
| Panik-Knopf | Ein Aufruf → `filter_out` Policy drop für alles außer lo |

### 6.4 Härtung des Daemons

- systemd: `CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE`, `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome=read-only`*, `PrivateTmp`, `SystemCallFilter=@system-service`, `RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK`
  (*Lesen von `/proc/<pid>` für `exe:` nötig, sonst kein Home-Zugriff.)
- Scope-/Slice-Steuerung für User-Sessions über D-Bus des User-Managers bzw. durch die CLI selbst (läuft als der User → keine Rechteausweitung).
- API: Unix-Socket `/run/weiche/api.sock`, Gruppe `weiche`; schreibende Aktionen über **polkit**.
- Keys: `/etc/weiche/tunnels/*.conf`, root:root 0600. API gibt Private Keys **nie** zurück.
- Web-UI: eigener User-Prozess, bindet nur `127.0.0.1` mit Zufallstoken, prüft `Host`/`Origin` (gegen DNS-Rebinding/CSRF).

---

## 7. Andere Plattformen (Ausblick)

| | Android | Windows | macOS |
|---|---|---|---|
| Tunnel | wireguard-go (gomobile) | wireguard-nt | wireguard-go / NE |
| App-Split | `VpnService.addAllowed/DisallowedApplication` (nativ!) | WFP-Filter auf App-ID (ALE) – aufwändig | NetworkExtension Per-App-VPN (MDM-lastig) |
| Domain-Regeln | DNS-Proxy im VpnService + Routen | WFP + Routen | NE DNS-Proxy |
| Bemerkung | Großteil existiert in Rethink → Kooperation statt Klon prüfen | „Hier wohnen Drachen“ | niedrige Priorität |

Der Core bleibt identisch; `Capabilities()` meldet, was die Plattform kann, Frontends blenden Nichtunterstütztes aus.

---

## 8. Bedrohungsmodell

### Gegner (in scope)

1. **Fremdes Netz** (Café/Hotel-WLAN, bösartiger DHCP: TunnelVision CVE-2024-3661, TunnelCrack LocalNet/ServerIP)
2. **Internetprovider** (passiv: DNS, Metadaten)
3. **Neugierige lokale Apps** ohne Root (LAN-Scans, eigenes DNS, Umgehung)
4. **Upstream-DNS / VPN-Gegenstelle** (sieht nur, was über die jeweilige Route läuft – Minimierung via Routing)

### Nicht in scope

Root-Malware auf dem Host, globaler passiver Angreifer, Browser-Fingerprinting, Account-Tracking.

### Pflicht-Anforderungen (nicht verhandelbar, MVP)

- [ ] Fail-closed bei Absturz, Boot, Tunnel-Ausfall (6.3)
- [ ] Policy-Routing per fwmark, nie Main-Tabellen-Fallthrough bei Killswitch
- [ ] Tests gegen TunnelVision (Option-121-Routen) & TunnelCrack
- [ ] IPv6 strikt (blockieren statt ignorieren)
- [ ] DNS-Zwang (53/853 nur über Proxy) + „durch Tunnel aufgelöst“-Regel
- [ ] Daemon-Härtung, keine Root-GUI, Keys nie über API
- [ ] Null Telemetrie, Logs nur RAM

---

## 9. Roadmap

| Phase | Inhalt |
|---|---|
| **P0** | Dieses Design, Name, Repo, Lizenz, CI-Gerüst |
| **P1 – PoC** | `weiched` + CLI, 1 Tunnel, App-Regeln (Slices), CIDR-Regeln, Killswitch, IPv6-Block, Lockdown-Service, Integrationstests in Netns |
| **P2 – DNS** | DNS-Proxy pro Route, Upstreams (Plain/DoT/DoH), Domain-Regeln + nft-Sets, DNS-Zwang, DoH-Blockliste |
| **P3 – Komfort** | Mehrere Tunnel, Profile (SSID-Umschaltung, MAC/Hostname-Hygiene), Port/ASN/Presets, Web-UI, Leak-Selbsttest |
| **P4 – Release** | `.deb` für Pop!_OS, signierte reproduzierbare Builds + SBOM, App-Firewall (Default-Deny/Nachfragen), LAN-Sperre pro App, Panik-Hotkey |
| **P5 – Kür** | Multi-Hop, Rosenpass (PQ-PSK), AmneziaWG-Modus, Padding/Cover-Traffic, Android/Windows-Backends, Tauri/Flutter-UI |

---

## 10. Offene Fragen

1. **Name** (blockiert Repo, Binärnamen, Pfade – alles hier ist `weiche` als Platzhalter).
2. COSMIC: Startet es Apps in eigenen `app-*.scope`-Units? (Auf Pop!_OS testen: `systemd-cgls --user-unit`.)
3. `nsswitch.conf` auf Pop!_OS: `resolve` oder `dns`? (`grep hosts /etc/nsswitch.conf`)
4. firestack als DNS-Bibliothek nutzen oder schlank mit `miekg/dns` + eigene DoH/DoT-Clients?
5. Unklassifizierte Prozesse im „Unterwegs“-Profil: Default-Route oder Block?
6. Wie sollen ASN-/Preset-Listen gepflegt und **verifiziert** (signiert) verteilt werden?
