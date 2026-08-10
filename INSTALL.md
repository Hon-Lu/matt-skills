# 安裝教程

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
