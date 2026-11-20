# Exécute les étapes « run » du workflow GitHub (.github/workflows/ios.yml) sur un autre service (Codemagic).
# Une seule source de vérité pour la compilation iOS.
import os, re, subprocess, sys, time, yaml
wf = yaml.safe_load(open(".github/workflows/ios.yml"))
steps = wf["jobs"]["build"]["steps"]
build = os.environ.get("CIELO_BUILD") or time.strftime("%y%m%d%H%M")
home = os.path.expanduser("~")
def sub(s):
    s = str(s)
    s = s.replace("${{ github.run_number }}", build)
    s = re.sub(r"\$\{\{\s*secrets\.(\w+)\s*\}\}", lambda m: os.environ.get(m.group(1), ""), s)
    return s.replace("/Users/runner", home)
for st in steps:
    if "run" not in st: continue
    print("\n==== " + st.get("name", "étape") + " ====", flush=True)
    env = dict(os.environ)
    for k, v in (st.get("env") or {}).items(): env[k] = sub(v)
    r = subprocess.run(["bash", "-e", "-o", "pipefail", "-c", sub(st["run"])], env=env)
    if r.returncode != 0: sys.exit(r.returncode)
