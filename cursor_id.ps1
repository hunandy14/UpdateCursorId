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
        if (-not (Test-Path $Path)) { throw "File not found: $Path" }
        $storageContent = Get-Content $Path -Raw | ConvertFrom-Json
        
        if ($WhatIfPreference) {
            Write-Host "`n【Preview Changes】" -ForegroundColor Magenta
            Write-Host "Target File: " -NoNewline
            Write-Host $Path -ForegroundColor Cyan
            Write-Host ""
        }
    } 
    
    process {
        # 先取得值
        $oldValue = $storageContent.$($KeyValuePair.Key)
        $newValue = $KeyValuePair.Value
        
        # 使用 Write-Host 來確保輸出格式
        if ($PSCmdlet.ShouldProcess("$($KeyValuePair.Key)", "Update property")) {
            $storageContent.$($KeyValuePair.Key) = $newValue
            Write-Host "$($KeyValuePair.Key.PadRight(30)) " -NoNewline -ForegroundColor Yellow
            Write-Host $newValue -ForegroundColor DarkYellow
        }
        if ($WhatIfPreference) {
            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host $KeyValuePair.Key -NoNewline -ForegroundColor Yellow
            Write-Host "]" -ForegroundColor DarkGray
            
            Write-Host "  Current  : " -NoNewline -ForegroundColor DarkGray
            Write-Host $oldValue -ForegroundColor DarkGray
            
            Write-Host "  Update to: " -NoNewline -ForegroundColor DarkGray
            Write-Host "$newValue`n" -ForegroundColor DarkYellow
        }
    } 
    
    end {
        if ($PSCmdlet.ShouldProcess($Path, "Save changes to file")) {
            $storageContent | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
            Write-Host "`nSuccessfully updated JSON file: " -NoNewline
            Write-Host $Path -ForegroundColor Cyan
        }
    }
}

# 生成新的 ID 並直接更新 storage.json
New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json") -WhatIf
# New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json")
