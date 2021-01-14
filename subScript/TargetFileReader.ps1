function TargetFileRead {

    # ÉtÉ@ÉCÉãì«Ç›çûÇ›
    $monitoringApps = Get-Content -Raw $TARGET_FILE | ConvertFrom-Csv -Delimiter ","

    $monitoringApps = AddNumberToPsobjectArray -array $monitoringApps

    $OK = @()
    $NG = @()

    foreach ($monitoringApp  in $monitoringApps ) {
        if (Test-Path $monitoringApp.Path) {
            $OK += $monitoringApp
        }
        else {
            $NG += $monitoringApp
        }
    }

    return [PSCustomObject] @{
        OK       = $OK
        NG       = $NG
        OKUnique = $OK | Select-Object -Property "Path", "Args" -Unique
    }

}