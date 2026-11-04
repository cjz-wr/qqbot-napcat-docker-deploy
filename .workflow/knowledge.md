# Knowledge index

- Compose owns the `init → napcat → bot` dependency chain. `init` and `bot` use
  the same image; the init process must run as root to assign volume ownership.
- NapCat reads the saved account from read-only `/qqbot-data/config.json`, then
  hands `ACCOUNT` to the original image entrypoint. Empty selects QR login.
- Installers share a fixed project name via Compose and preserve user `.env`.
- The PowerShell installer is ASCII without a BOM so the original ScriptBlock.Create invocation can parse the HTTP response text. Non-ASCII log labels use regex Unicode escapes.
- Only deployment files are published. Source is obtained by the release runner
  and the Docker context includes only runtime source files.
