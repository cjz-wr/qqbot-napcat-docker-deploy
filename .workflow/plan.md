# Public Docker deployment repository

Date: 2026-11-04
State: DONE
Transitions: INIT → ANALYZE → PLAN_READY → PREPARE → IMPLEMENTING → REVIEW → COMMITTING → DONE

## Requirements

Create the public `cjz-wr/qqbot-napcat-docker-deploy` repository inside the existing
project, with its own history. Publish deployment configuration, cross-platform
install/update scripts, environment examples, documentation, MIT license and
release automation. The user confirmed this name and scope and requested no
tests or service startup. Build input is selected through repository variables.

## Before snapshot / impact

- Independent deployment history; no pre-existing deployment files.
- New repository: no pre-existing files or history.
- Risk L2: installation and container publishing; no database/API changes.
- Existing Compose and init_docker.py provide the startup/volume contract.
- Static code relationships: installers → public Compose → init / NapCat / bot;
  release workflow → authenticated source checkout → Dockerfile → Docker Hub.
- Runtime files and build inputs never enter this repository.

## Acceptance criteria

- [x] Implement Compose registry images, initialization, persistent QQ state and saved-account quick login.
- [x] Implement Bash/PowerShell first install and explicit update with `.env` preservation and Compose backups.
- [x] Implement release/manual AMD64/ARM64 publishing from the separate source repository.
- [x] Document actual URLs, configuration, updates, platform limits and publisher credentials.
- [x] Create the remote repository with public visibility and push its own history.
- [x] Link the public repository from the parent as a Git submodule.

## Knowledge backend

Markdown fallback, no new dependencies. Index: knowledge.md. Code graph: static
file/command relationships. Validation: source review only at the user's request;
no automated tests, image builds or service starts.

## Publication notes

The deployment repository has been created with public visibility. Build input
and authentication are configured by the maintainer. Docker Hub metadata
confirms the default 1.1.10 tag
exists and is AMD64 only. Credentials were neither logged nor persisted locally.
Source review was performed; no tests, builds or service startup were run.

Public deployment: https://github.com/cjz-wr/qqbot-napcat-docker-deploy
The maintainer must configure DOCKER_USERNAME, DOCKER_PASSWORD and
SOURCE_REPOSITORY before running image publishing; SOURCE_REPO_TOKEN is optional
depending on build-input authentication. No release was created or workflow
dispatched. The Git submodule registration remains local to its feature branch.
Public documentation and workflow defaults use generic build-input variables;
concrete values belong in maintainer settings.

## Windows remote installer encoding correction (2026-11-04)

State: IMPLEMENTING
Before: 9a17925; clean worktree; feature/windows-installer-encoding; risk L1.
Impact: HTTP response text → ScriptBlock.Create → installer parameter block.
An encoded leading BOM can be treated as content before #Requires/attributes.

- [x] Remove the file BOM and keep the script ASCII, with Unicode regex escapes.
- [x] Preserve the user's original ScriptBlock.Create remote invocation.
- [x] Preserve installer parameters and deployment behavior.
- [ ] Publish the fix and update the parent submodule reference.

No tests or deployment startup are performed, following the user's preference.
