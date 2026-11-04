# Repository guidelines

- This repository contains deployment configuration, installers and publishing automation.
- Keep concrete build-source locations and access details in maintainer settings; public documentation uses generic variable names only.
- Never commit runtime data, `.env`, credentials, image archives, or a source checkout.
- Use Compose V2 and preserve existing volumes and `.env` when installing or updating.
- Maintain equivalent Windows PowerShell 5.1 and Bash 3.2+ installation behavior.
- Keep NapCat initialization dependencies and saved-account quick login intact.
- Publish images only from a release or an explicit workflow dispatch, never from pull requests.
- Use Conventional Commits and feature branches for future changes.
- User requested no tests or service startup for this initial implementation.
- Record progress and decisions in `.workflow/`; update README when behavior changes.
