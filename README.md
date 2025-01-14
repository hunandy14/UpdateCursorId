更新 Cursor 中 storage.json 的 id

## 使用方法

快速使用

```ps1
irm bit.ly/4jimLvR|iex; Update-CursorId
```

詳細用法

```ps1
# 載入函式
irm https://raw.githubusercontent.com/hunandy14/UpdateCursorId/refs/heads/main/Update-CursorId.ps1 | iex

# 生成新的 ID 並更新 Cursor 的 storage.json
New-CursorId | Update-JsonProperty -Path (Join-Path $env:APPDATA ".\Cursor\User\globalStorage\storage.json")

```
