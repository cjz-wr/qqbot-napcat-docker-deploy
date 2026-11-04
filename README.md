# QQBot + NapCat Docker 部署

[![Publish Docker image](https://github.com/cjz-wr/qqbot-napcat-docker-deploy/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/cjz-wr/qqbot-napcat-docker-deploy/actions/workflows/docker-publish.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

公开的部署仓库：下载配置即可运行 QQBot 后端与 NapCat / QQ，无需本地安装 Python、QQ，
也无需下载大型 `.tar` 镜像包。

- Windows、Linux、macOS、Docker NAS 共用一套 Compose。
- 安装脚本检查 Docker Linux 容器模式，拉取镜像并启动服务。
- 配置、数据库、QQ 登录凭据、NapCat 插件和表情包通过命名卷持久化。
- 支持控制台保存账号后快速登录；初始化自动配置 API 与事件上报。
- 发布 Release 或手动运行 Actions，构建 `linux/amd64`、`linux/arm64` 镜像。

## 准备环境

安装并启动 [Docker Desktop](https://www.docker.com/products/docker-desktop/)（Windows / macOS），
Linux / NAS 安装 Docker Engine 与 Compose V2。Windows 选择 **Linux containers**。
Linux 当前用户需要 Docker 访问权限；支持 x86_64 / ARM64 的前提是所选两套镜像均包含该平台。

默认后端镜像为已公开发布的 `cjzwr/qqbot-napcat:1.1.10`。目前该标签只有 AMD64，
因此 `BOT_PLATFORM` 默认固定为 `linux/amd64`；Apple Silicon 的 Docker Desktop 使用仿真运行。
需要原生 ARM64（例如 ARM NAS）时，先用下方发布流程生成多架构标签，再把
`BOT_PLATFORM` 改为 `linux/arm64`。本仓库不包含后端源码或预构建镜像。

## 一键安装

默认安装到当前用户的 `qqbot-napcat` 目录，无需管理员 PowerShell。

**Windows PowerShell 5.1+：**

```powershell
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/cjz-wr/qqbot-napcat-docker-deploy/main/scripts/install.ps1').Content))
```

自定义目录或不自动打开浏览器，在命令结尾加：

```powershell
-InstallDir 'D:\qqbot' -NoOpen
```

**Linux / macOS / NAS：**

```bash
curl -fsSL https://raw.githubusercontent.com/cjz-wr/qqbot-napcat-docker-deploy/main/scripts/install.sh | bash
```

指定目录或用于远程服务器：

```bash
curl -fsSL https://raw.githubusercontent.com/cjz-wr/qqbot-napcat-docker-deploy/main/scripts/install.sh | bash -s -- --dir "$HOME/qqbot" --no-open
```

脚本只创建缺失的 `.env`，保留已有 `.env` 和 Compose；初装失败后可以原样重跑。
脚本在启动后显示登录信息；首次初始化尚未完成时，在安装目录运行 `docker compose logs bot napcat`。

## 克隆后部署

```bash
git clone https://github.com/cjz-wr/qqbot-napcat-docker-deploy.git
cd qqbot-napcat-docker-deploy
```

Linux / macOS：

```bash
cp -n .env.example .env
docker compose pull
docker compose up -d
```

Windows PowerShell：

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose pull
docker compose up -d
```

也可运行克隆后的 `bash scripts/install.sh` / `powershell -File scripts/install.ps1`，
脚本会把部署文件安装到默认用户目录。指定 `--dir .` / `-InstallDir .` 可以就地安装。

## 登录与快速登录

| 默认地址 | 用途 |
| --- | --- |
| [NapCat 管理页](http://127.0.0.1:6099/webui) | 使用 NapCat Token 登录，用手机 QQ 扫码授权 |
| [机器人控制台](http://127.0.0.1:8881/) | 使用首次启动日志中的初始口令登录，随后修改口令 |
| `http://napcat:3000` | 容器内部 OneBot API，未发布到宿主机 |

在安装目录查看两个控制台的初始登录信息：

```bash
docker compose logs --tail=100 bot napcat
```

在机器人控制台「连接与安全 → QQ 登录」保存 QQ 号，然后执行：

```bash
docker compose restart napcat
```

NapCat 每次启动读取保存的账号，经官方 `ACCOUNT` 参数传入 `-q`。
留空则扫码登录；已有登录凭据失效时仍需重新扫码。仅重启 `bot` 不会切换 QQ 账号。

`.env` 的 `NAPCAT_ACCOUNT` 可用于部署时直接指定账号，它的优先级高于控制台设置；
如需跟随控制台，保持该项为空。修改 `.env` 后执行 `docker compose up -d` 重建受影响容器，
`docker compose restart` 不会重新载入环境变量。

## 配置与数据

编辑安装目录下的 `.env`，再运行 `docker compose up -d`。

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `COMPOSE_PROJECT_NAME` | `qqbot-napcat` | 数据卷和容器的项目名前缀 |
| `BOT_IMAGE` | `cjzwr/qqbot-napcat:1.1.10` | 后端与初始化共用的已发布镜像 |
| `BOT_PLATFORM` | `linux/amd64` | 现有镜像的平台；多架构发版后 ARM 主机可设为 `linux/arm64` |
| `NAPCAT_IMAGE` | `mlikiowa/napcat-docker:latest` | NapCat 官方推荐镜像，可指定版本 |
| `BIND_ADDRESS` | `127.0.0.1` | 管理端口绑定地址 |
| `BOT_PORT` | `8881` | 宿主机机器人控制台端口 |
| `NAPCAT_WEBUI_PORT` | `6099` | 宿主机 NapCat 管理端口 |
| `TZ` | `Asia/Shanghai` | 容器时区 |
| `NAPCAT_ACCOUNT` | 空 | 可选账号覆盖项；空时读取控制台账号 |

六个命名卷分别保存机器人配置/数据库、日志、表情包、NapCat 配置、QQ 登录状态和插件。
更新、重建容器不会删除卷；`docker compose down -v` 会删除这些数据。
迁移已有部署时保留原 `COMPOSE_PROJECT_NAME`，否则 Docker 会为新项目名创建另一套卷。
若旧版使用不同项目名，请先把 `.env` 改成原名再启动。

远程服务器可通过 SSH 转发访问默认只绑定回环的管理端口：

```bash
ssh -L 8881:127.0.0.1:8881 -L 6099:127.0.0.1:6099 用户名@服务器
```

## 更新与停止

在安装目录更新镜像（固定版本需先修改 `.env` 的 `BOT_IMAGE`）：

```bash
docker compose pull
docker compose up -d
```

同时更新本仓库管理的部署文件和镜像：

```bash
bash scripts/install.sh --dir . --update --no-open
```

```powershell
powershell -File scripts/install.ps1 -InstallDir . -Update -NoOpen
```

`--update` / `-Update` 会先备份当前 Compose 到 `.backups/`，再获取指定分支/标签的新配置；
始终保留 `.env`，自定义 Compose 修改可从备份恢复。更新默认不会改变 `.env` 中固定的镜像版本。
克隆仓库的用户也可以通过 `git pull --ff-only` 更新部署文件，然后执行上面的拉取/启动命令。

```bash
docker compose ps
docker compose logs --tail=100 bot napcat
docker compose down
```

## 维护者：镜像发布

本仓库不带后端源码，工作流会单独检出源仓库，然后用 `docker/Dockerfile` 构建。
源仓库的 `app/`、`scripts/init_docker.py`、`requirements.txt`、`plugins/` 需要存在。

在 GitHub 仓库 **Settings → Secrets and variables → Actions** 中设置：

| 类型 | 名称 | 内容 |
| --- | --- | --- |
| Secret | `DOCKER_USERNAME` | 有目标 Docker Hub 仓库推送权限的用户名 |
| Secret | `DOCKER_PASSWORD` | Docker Hub access token（需要写入权限） |
| Secret | `SOURCE_REPO_TOKEN` | 可选构建源访问令牌；按构建源的访问要求配置，只需读取 Contents |
| Variable | `SOURCE_REPOSITORY` | 维护者指定的构建源，格式 `owner/repository`，必填 |
| Variable | `SOURCE_REF` | 默认 `main`；建议设置为审核过的源代码 commit SHA |
| Variable | `DOCKER_IMAGE` | 默认 `cjzwr/qqbot-napcat`，不含标签 |
| Variable | `PIP_USE_DEPRECATED` | 通常留空；确有 pip 元数据问题时可填 `legacy-resolver` |

先创建或确认 Docker Hub 镜像仓库允许公开拉取，再选择以下一种发版方式：

1. 在本仓库发布 Release，例如 `v1.1.10`，稳定版本会推送 `1.1.10` 与 `latest`。
2. 在 Actions → Publish Docker image → Run workflow 手动输入版本，
   可指定源代码 ref，并选择是否更新 `latest`。

版本会去掉开头的 `v`，并要求与源代码 `app.__version__` 一致，防止把错误版本打成正式标签。
预发布 Release 不更新 `latest`。工作流支持 AMD64/ARM64 构建，源码专用白名单排除运行数据；
默认关闭 provenance，不附加构建溯源信息。
工作流不会因为普通 push 或 PR 自动发布，也不会把检出的源码推回本仓库。

新版本发布后，维护者更新 `.env.example` 与 Compose 默认镜像标签，用户再显式选择升级版本。
部署文件使用独立的版本历史。

## 仓库结构

```text
.github/workflows/docker-publish.yml
docker/Dockerfile
docker/Dockerfile.dockerignore
scripts/install.sh
scripts/install.ps1
docker-compose.yml
.env.example
README.md
LICENSE
```

安装脚本也支持 `--repository` / `-Repository` 与 `--ref` / `-Ref`，方便 fork 或固定部署版本。
GitHub 仓库可镜像到 Gitee；安装脚本默认下载源仍为 GitHub Raw。

部署代码使用 [MIT License](LICENSE)；NapCat、QQ 以及镜像中的其他组件遵循各自许可。

参考：[NapCat Docker](https://github.com/NapNeko/NapCat-Docker)、
[Docker 多平台构建](https://docs.docker.com/build/ci/github-actions/multi-platform/)、
[Checkout 配置](https://github.com/actions/checkout)。
