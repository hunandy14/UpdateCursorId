# 設定嚴格模式和錯誤處理
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 用於輸出統一格式狀態訊息的函式
function Write-StatusMessage {
    param (
        [Parameter(Mandatory)]
        [string]$Status,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [string]$Detail,
        
        [Parameter()]
        [string]$DetailPrefix = "",
        
        [Parameter()]
        [System.ConsoleColor]$StatusColor = 'Blue',
        
        [Parameter()]
        [System.ConsoleColor]$MessageColor = 'DarkGray',
        
        [Parameter()]
        [System.ConsoleColor]$DetailColor = 'Cyan'
    )
    
    # 輸出狀態標記
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host $Status -NoNewline -ForegroundColor $StatusColor
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    
    # 輸出主要訊息
    Write-Host $Message -ForegroundColor $MessageColor
    
    # 如果有詳細資訊，則輸出
    if ($Detail) {
        Write-Host "  $DetailPrefix" -NoNewline -ForegroundColor $MessageColor
        Write-Host $Detail -ForegroundColor $DetailColor
    }
}

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
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]$PropertyKeyPair,
        
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )
    
    begin {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Path = [IO.Path]::GetFullPath($Path)
        $storageContent = Get-Content $Path -Raw | ConvertFrom-Json
        
        # 顯示目標檔案
        Write-StatusMessage `
            -Status "TARGET" `
            -Message "Processing file:" `
            -DetailPrefix "Path: " -Detail $Path
        Write-Host ""
    } 
    
    process {
        try {
            # 驗證屬性是否存在
            if (-not $storageContent.PSObject.Properties.Name.Contains($PropertyKeyPair.Key)) {
                throw "Property '$($PropertyKeyPair.Key)' does not exist in the JSON file"
            }
            
            # 取得屬性名稱和值
            $keyName = $PropertyKeyPair.Key
            $newValue = $PropertyKeyPair.Value
            $oldValue = $storageContent.$keyName
            
            # 更新值
            $storageContent.$keyName = $newValue
            
            # 顯示更新內容
            Write-StatusMessage `
                -Status "STAGE" -StatusColor DarkCyan `
                -Message "Preparing to update property..."
            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host $keyName -NoNewline -ForegroundColor Yellow
            Write-Host "]" -ForegroundColor DarkGray
            Write-Host "    Current  : " -NoNewline -ForegroundColor DarkGray
            Write-Host $oldValue -ForegroundColor DarkGray
            Write-Host "    Update to: " -NoNewline -ForegroundColor DarkGray
            Write-Host "$newValue`n" -ForegroundColor DarkYellow
        }
        catch {
            Write-StatusMessage `
                -Status "FAILED" -StatusColor Red `
                -Message "Failed to update property" `
                -DetailPrefix "Error: " -Detail $_.Exception.Message
            throw
        }
    } 
    
    end {
        # 收集所有已更新的屬性
        $confirmMessage = "您確定要更新以下屬性嗎？`n"
        $confirmMessage += ($storageContent.PSObject.Properties | ForEach-Object {
            "  $($_.Name): $($_.Value)"
        } | Out-String)

        if ($PSCmdlet.ShouldProcess($Path, "Save changes to file")) {
            try {
                # 保存到文件
                $storageContent | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
                Write-StatusMessage `
                    -Status "COMMIT" -StatusColor Green `
                    -Message "All changes have been saved to file" `
                    -DetailPrefix "Path: " -Detail $Path
            }
            catch {
                Write-StatusMessage `
                    -Status "FAILED" -StatusColor Red `
                    -Message "Failed to save changes" `
                    -DetailPrefix "Error: " -Detail $_.Exception.Message
                throw
            }
        }
        else {
            if ($WhatIfPreference) {
                Write-StatusMessage `
                    -Status "WHATIF" -StatusColor Magenta `
                    -Message "No changes were made to the file (WhatIf mode is enabled)" `
                    -DetailPrefix "Path: " -Detail $Path
            }
            else {
                Write-StatusMessage `
                    -Status "ABORT" -StatusColor Yellow `
                    -Message "Operation cancelled by user" `
                    -DetailPrefix "Path: " -Detail $Path
            }
        }
    }
}

# 更新 Cursor 的 ID
function Update-CursorId {
    New-CursorId | Update-JsonProperty -Path (Join-Path $env:APPDATA "\Cursor\User\globalStorage\storage.json")
}

# 生成新的 ID 並更新測試用 storage.json
# New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json") -WhatIf
# New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json") -Confirm:$false
# New-CursorId | Update-JsonProperty -Path (Join-Path $PSScriptRoot "storage.json")

# 生成新的 ID 並更新 Cursor 的 storage.json
# New-CursorId | Update-JsonProperty -Path (Join-Path $env:APPDATA "\Cursor\User\globalStorage\storage.json") -WhatIf
# New-CursorId | Update-JsonProperty -Path (Join-Path $env:APPDATA "\Cursor\User\globalStorage\storage.json")
