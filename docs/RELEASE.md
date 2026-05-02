# 发行说明（Git Tag → GitHub Release + Netlify）

版本号采用 **语义化版本 `X.Y.Z`**（例如 `1.0.1`、`1.0.2`），**不再使用** `1.0.0+1`、`**+2**` 这类构建后缀。

## 你需要准备的（一次性）

### 1. GitHub 仓库密钥（Netlify 自动部署线上试玩）

在 GitHub：`Settings` → `Secrets and variables` → `Actions` → `New repository secret`：

| Secret 名称 | 含义 |
|-------------|------|
| `NETLIFY_AUTH_TOKEN` | Netlify 用户设置里生成的 Personal access token |
| `NETLIFY_SITE_ID` | Netlify 站点「Site settings → Site details → Site information」里的 API ID |

若暂不配置这两项，Release 工作流仍会 **构建并上传 GitHub Releases**，只是 **跳过 Netlify**（日志里会有提示）。

### 2. Netlify 构建要能读到 Git Tag（推荐）

站点连接 GitHub 分支构建时，建议使用 **完整克隆**，以便脚本用 `git describe` 解析最新版本号。可在 Netlify：

- `Site configuration` → `Build & deploy` → `Environment variables` 添加 **`GIT_FETCH_DEPTH`** = **`0`**（若变量名无效，可在 UI 里关闭 shallow clone，以 Netlify 当前文档为准）。

## 日常发版怎么做（推荐流程）

1. 在 **`develop`**（或你的开发分支）完成开发与自测。
2. 合并到 **`main`**（保持主分支可发布）。
3. **打 Tag**（两种写法任选其一，与工作流一致即可）：
   - `git tag v1.0.2`
   - 或 `git tag 1.0.2`
4. **推送 Tag**：
   - `git push origin v1.0.2`（或对应 tag 名）
5. 打开 GitHub → **Actions**，查看 **Release** 工作流是否成功。
6. 成功后：
   - **Release 资产**：在仓库 **Releases** 页面下载 Web zip、Windows zip、macOS zip、Android APK。
   - **在线试玩**：若配置了 Netlify Secrets，与本次构建一致的 Web 包会部署到你在 Netlify 绑定的站点。

## 版本号如何写进游戏

打 Tag 后，CI 会设置 `RELEASE_VERSION` 并运行 `scripts/ci/sync_version.py`，统一写入：

- `project.godot` 的 `config/version`、`config/version_code`
- `export_presets.cfg` 中 Android / Windows / macOS 等与版本相关的字段

Android **version_code** 规则：`major * 10000 + minor * 100 + patch`（例如 `1.0.2` → `10002`）。

## Android 签名说明

仓库 **不包含** 私有 keystore 文件（在 `.gitignore` 的 `export_build/` 下）。CI 首次构建时会执行 `scripts/ci/android_export_prep.sh`，用 **`keytool`** 在 Runner 上生成 **仅供 CI 使用的测试库**，密码与 `export_presets.cfg` 中一致。

若你要 **上架 Google Play**，需自行替换为正式签名并在安全的 Secrets / 本地环境中导出，**不要**把正式 keystore 提交到 Git。

## 相关脚本路径（整理后）

| 用途 | 路径 |
|------|------|
| 版本同步 | `scripts/ci/sync_version.py` |
| Linux 安装 Godot + 模板 | `scripts/ci/install_godot_linux.sh` |
| GitHub Actions 全平台导出 | `scripts/ci/release_export.sh` |
| Netlify 仅 Web | `scripts/ci/netlify_build_web.sh` |
