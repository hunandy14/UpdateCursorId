# 設定嚴格模式和錯誤處理
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 生成 Cursor ID 的主要函式
function New-CursorId {
    # 生成随机 ID
    function New-RandomId {
        $bytes = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng.GetBytes($bytes)
        return ([System.BitConverter]::ToString($bytes) -replace '-','').ToLower()
    }

    # 生成随机 UUID
    function New-RandomUuid {
        return [guid]::NewGuid().ToString().ToLower()
    }

    # 生成新的 ID 並一個一個輸出
    [PSCustomObject]@{
        Key   = 'telemetry.macMachineId'
        Value = New-RandomId
    }
    
    [PSCustomObject]@{
        Key   = 'telemetry.machineId'
        Value = New-RandomId
    }
    
    [PSCustomObject]@{
        Key   = 'telemetry.devDeviceId'
        Value = New-RandomUuid
    }
}

# 更新 JSON 文件的屬性
function Update-JsonProperty {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]$KeyValuePair,
        
        [Parameter()]
        [string]$Path
    )
    
    begin {
        $storageContent = Get-Content $Path -Raw | ConvertFrom-Json
        
        if ($WhatIfPreference) {
            Write-Host "`n【Preview Changes】" -ForegroundColor Magenta
            Write-Host "Target File: " -NoNewline
            Write-Host $Path -ForegroundColor Cyan
            Write-Host ""
        }
    } 
    
    process {
        try {
            # 驗證屬性是否存在
            if (-not $storageContent.PSObject.Properties.Name.Contains($KeyValuePair.Key)) {
                throw "Property '$($KeyValuePair.Key)' does not exist in the JSON file"
            }
            
            # 先取得值
            $oldValue = $storageContent.$($KeyValuePair.Key)
            $newValue = $KeyValuePair.Value
            
            # 更新值 (WhatIf的時候不更新)
            if ($PSCmdlet.ShouldProcess("$($KeyValuePair.Key)", "Update property")) {
                Write-Host "[" -NoNewline -ForegroundColor DarkGray
                Write-Host "STAGE" -NoNewline -ForegroundColor DarkCyan
                Write-Host "]" -NoNewline -ForegroundColor DarkGray
                Write-Host " Preparing to update property..." -ForegroundColor DarkGray
                $storageContent.$($KeyValuePair.Key) = $newValue
            }
            
            # 顯示更新內容
            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host $KeyValuePair.Key -NoNewline -ForegroundColor Yellow
            Write-Host "]" -ForegroundColor DarkGray
            
            Write-Host "    Current  : " -NoNewline -ForegroundColor DarkGray
            Write-Host $oldValue -ForegroundColor DarkGray
            
            Write-Host "    Update to: " -NoNewline -ForegroundColor DarkGray
            Write-Host "$newValue`n" -ForegroundColor DarkYellow
        }
        catch {
            Write-Host "[" -NoNewline -ForegroundColor DarkGray
            Write-Host "FAILED" -NoNewline -ForegroundColor Red
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            Write-Host "Failed to update property" -ForegroundColor DarkGray
            Write-Host "  Error: " -NoNewline -ForegroundColor DarkGray
            Write-Host $_.Exception.Message -ForegroundColor Red
            throw
        }
    } 
    
    end {
        if ($PSCmdlet.ShouldProcess($Path, "Save changes to file")) {
            try {
                # 保存到文件
                $storageContent | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
                Write-Host "[" -NoNewline -ForegroundColor DarkGray
                Write-Host "COMMIT" -NoNewline -ForegroundColor Green
                Write-Host "] " -NoNewline -ForegroundColor DarkGray
                Write-Host "All changes have been saved to file" -ForegroundColor DarkGray
                Write-Host "  Path: " -NoNewline -ForegroundColor DarkGray
                Write-Host $Path -ForegroundColor Cyan
            }
            catch {
                Write-Host "[" -NoNewline -ForegroundColor DarkGray
                Write-Host "FAILED" -NoNewline -ForegroundColor Red
                Write-Host "]" -NoNewline -ForegroundColor DarkGray
                Write-Host " Failed to save changes" -ForegroundColor DarkGray
                Write-Host "  Error: " -NoNewline -ForegroundColor DarkGray
                Write-Host $_.Exception.Message -ForegroundColor Red
                throw
            }
        }
    }
}

# 生成新的 ID 並直接更新 storage.json
# New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json") -WhatIf
# New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json")
