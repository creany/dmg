function Get-TxMaster {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0)]
        [String]$HouseNumber,
        
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1)]
        [String]$LogFile
    )
    
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-Log -Message "START FUNCTION - $FunctionName" -Path $LogFile
        Write-Log -Message "HouseNumber = $HouseNumber, LogFile = $LogFile" -Path $LogFile

        $path_records = '/gpfs1/data/dmg/records'
        $file_name = $HouseNumber + '.json'
        $jsondocument = Join-Path -Path $path_records -ChildPath $file_name
    }
    
    process {
        try {
            if (Test-Path -Path $jsondocument -PathType Leaf){
                $jsonrecord = Get-Content -Path $jsondocument -Raw | ConvertFrom-Json
                if($jsonrecord.ABC_TxMaster_FilePath){
                    if (Test-Path -Path $jsonrecord.ABC_TxMaster_FilePath -PathType Leaf){
                        Return $jsonrecord.ABC_TxMaster_FilePath
                    }
                }
            }
        }
        catch {
            Write-Log -Message "An error occurred. (error: $($Error[0]))" -Path $LogFile -Level 'Warn'
            Return "Fail"
            Exit 1

        }
    }
    
    end {
        Write-Log -Message "END FUNCTION - $FunctionName" -Path $LogFile
    }
}
Import-Module -Name WriteLog
# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$LogFile = Join-Path -Path $ScriptDir -ChildPath dmginventory.log 

Remove-Item $LogFile -ErrorAction Ignore

$OutputFile=Join-Path -Path $ScriptDir -ChildPath transferlist.txt
Remove-Item $OutputFile -ErrorAction Ignore

Write-Log -Message "Start Script" -Path $LogFile
Write-Log -Message "Log File = $LogFile, OutputFile = $OutputFile" -Path $LogFile
$jsonfile = '/gpfs1/data/dmg/database/7days.json'
$json = Get-Content -Path $jsonfile -Raw | ConvertFrom-Json

[System.Collections.ArrayList]$arrRecords=@()
foreach($item in $json.items){
    $house_number=$Item.HOUSE_NUMBER
    $TxMaster_Path = Get-TxMaster -HouseNumber $house_number -LogFile $LogFile
    if (!($TxMaster_Path -eq "Fail")){
        $arrRecords.Add($TxMaster_Path) | Out-Null
    }
}
$arrRecords | Out-File -FilePath $OutputFile

$arrRecords | Select-Object -First 10 | format-table -Autosize
