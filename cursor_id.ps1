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

    # 生成新的 ID
    [ordered]@{
        'telemetry.macMachineId' = New-RandomId
        'telemetry.machineId'    = New-RandomId
        'telemetry.devDeviceId'  = New-RandomUuid
    }
}

# 更新 storage.json 文件
function Update-StorageJson {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable]$NewIds,
        
        [Parameter()]
        [string]$Path
    )
    
    process {
        if (Test-Path $Path) {
            $storageContent = Get-Content $Path -Raw | ConvertFrom-Json
            
            foreach ($key in $NewIds.Keys) {
                $storageContent.$key = $NewIds[$key]
            }
            
            $storageContent | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
            Write-Host "Successfully updated storage.json file: $Path"
        } else {
            Write-Error "File not found: $Path"
        }
    }
}

# 生成新的 ID 並直接更新 storage.json
New-CursorId | Update-StorageJson -Path (Join-Path $PSScriptRoot "storage.json")

# 如果需要顯示新生成的 ID，可以使用 Tee-Object
# New-CursorId | Tee-Object -Variable newIds | Update-StorageJson

