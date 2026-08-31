# 安裝教程

## Claude Code 安裝、更新與移除

官方 marketplace 的 `mattpocock-skills` 版本號不會隨上游改動調整，所以這裡改用自己的 fork 當 marketplace，需要時直接移除再安裝就能拿到最新內容。

每個步驟都有兩種寫法：終端機的 `claude plugin ...`，或在 Claude Code 對話中輸入 `/plugin ...`，擇一即可。

安裝前先確認沒有裝官方那一份，否則同一組 skills 會重複載入：

```powershell
claude plugin list
```

```text
/plugin list
```

若清單裡有官方來源的 `mattpocock-skills`，先移除：

```powershell
claude plugin uninstall mattpocock-skills
```

```text
/plugin uninstall mattpocock-skills
```

### 安裝

```powershell
claude plugin marketplace add asd880921/matt-skills
claude plugin install mattpocock-skills@mattpocock
```

```text
/plugin marketplace add asd880921/matt-skills
/plugin install mattpocock-skills@mattpocock
```

`mattpocock` 是 fork 內 `.claude-plugin/marketplace.json` 定義的 marketplace 名稱，不是 GitHub 帳號。安裝完成後重開 Claude Code，skills 才會載入。

### 更新

先讓本機的 marketplace 拉到 fork 最新內容：

```powershell
claude plugin marketplace update mattpocock
```

```text
/plugin marketplace update mattpocock
```

再更新 plugin 本體。`/plugin` 沒有 `update` 子命令，這一步只能在終端機執行：

```powershell
claude plugin update mattpocock-skills@mattpocock
```

更新後要重開 Claude Code 才會套用。

因為這個 fork 不會調整 `.claude-plugin/plugin.json` 的版本號，`update` 有機會判定版本相同而不重裝。確認 skills 沒有跟著更新時，改用移除再安裝，這組在對話中也能執行：

```powershell
claude plugin uninstall mattpocock-skills@mattpocock
claude plugin install mattpocock-skills@mattpocock
```

```text
/plugin uninstall mattpocock-skills@mattpocock
/plugin install mattpocock-skills@mattpocock
```

### 移除

```powershell
claude plugin uninstall mattpocock-skills@mattpocock
claude plugin marketplace remove mattpocock
```

```text
/plugin uninstall mattpocock-skills@mattpocock
/plugin marketplace remove mattpocock
```

## Codex 安裝、更新與移除

### 安裝

開啟終端機後依序執行：

```powershell
codex plugin marketplace add asd880921/matt-skills
```

```powershell
codex plugin add mattpocock-skills@matt-skills
```

安裝完成後開啟新的 Codex 對話，讓 plugin 中的 skills 載入。

### 更新

```powershell
codex plugin marketplace upgrade matt-skills
```

```powershell
codex plugin add mattpocock-skills@matt-skills
```

更新完成後開啟新的 Codex 對話。

### 移除

```powershell
codex plugin remove mattpocock-skills@matt-skills
```

```powershell
codex plugin marketplace remove matt-skills
```

## 維護者同步方式（不需 clone）

第一次設定時，先到此 fork 的 **Actions** 頁籤啟用 workflows。若 workflow 無法 push，請到 **Settings → Actions → General → Workflow permissions** 確認 Actions 允許寫入 repository contents。

1. 在 GitHub 開啟 `asd880921/matt-skills`。
2. 點選 **Sync fork**，確認後選擇 **Update branch**。
3. 等待 GitHub Actions 的 **Sync Codex plugin** workflow 完成。

workflow 會自動依照上游的 Claude plugin promoted skill 清單重新產生 Codex plugin，並以 `chore: 同步 Codex plugin` commit 回 `main`。整個流程都能在 GitHub 網頁完成。

如果 GitHub 顯示上游同步有衝突，需在 GitHub 建立 PR 並解決衝突；在沒有同名檔案的正常情況下不會碰到原始 skills。

### 本機備援方式

只有需要在送上 GitHub 前預覽產物時，才在倉庫根目錄執行：

```powershell
.\codex-plugin\sync.ps1
.\codex-plugin\sync.ps1 -Check
```

同步工具只會重新產生 Codex 專用的 `plugins/mattpocock-skills` 與 `.agents/plugins/marketplace.json`，不會修改原始 skills 或 Claude Code plugin。
