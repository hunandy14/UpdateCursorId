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
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]$KeyValuePair,
        
        [Parameter()]
        [string]$Path
    )
    
    begin {
        if (-not (Test-Path $Path)) { throw "File not found: $Path" }
        $storageContent = Get-Content $Path -Raw | ConvertFrom-Json
    } process {
        $storageContent.$($KeyValuePair.Key) = $KeyValuePair.Value
        Write-Host "$($KeyValuePair.Key.PadRight(30)) $($KeyValuePair.Value)"
    } end {
        $storageContent | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
        Write-Host "`nSuccessfully updated JSON file: $Path"
    }
}

# 生成新的 ID 並直接更新 storage.json
New-CursorId
# New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json")

# 如果需要顯示新生成的 ID，可以使用 Tee-Object
# New-CursorId | Tee-Object -Variable newIds | Update-JsonProperty

