"""Route Gradle through the platform's existing proxy without exporting secrets."""
import os
from pathlib import Path
from urllib.parse import urlsplit


def main():
    proxy = urlsplit(os.environ.get("HTTPS_PROXY", ""))
    if not proxy.hostname:
        return
    if proxy.username or proxy.password:
        raise SystemExit("Authenticated proxy requires secure Gradle configuration.")
    root = Path(os.environ["GRADLE_USER_HOME"])
    root.mkdir(parents=True, exist_ok=True)
    target = root / "gradle.properties"
    keys = {
        "systemProp.http.proxyHost": proxy.hostname,
        "systemProp.https.proxyHost": proxy.hostname,
        "systemProp.http.proxyPort": str(proxy.port or 80),
        "systemProp.https.proxyPort": str(proxy.port or 80),
        "systemProp.http.nonProxyHosts": "localhost|127.*",
    }
    # Reuse the environment's administered trust anchors, including its HTTPS
    # proxy CA. Keep certificate and hostname verification enabled.
    trust_store = Path('/etc/ssl/certs/java/cacerts')
    if trust_store.is_file():
        keys['systemProp.javax.net.ssl.trustStore'] = str(trust_store)
    existing = target.read_text().splitlines() if target.exists() else []
    retained = [line for line in existing if line.split("=", 1)[0].strip() not in keys]
    target.write_text("\n".join(retained + [f"{k}={v}" for k, v in keys.items()]) + "\n")
    target.chmod(0o600)


if __name__ == "__main__":
    main()
