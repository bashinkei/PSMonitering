# PscustomObjectの配列にNoのカラムを追加
function AddNumberToPsobjectArray {
    param (
        [Parameter(Mandatory)]
        [array] $array
    )
    $pops = @()
    $pops += $array[0].psobject.Properties.Name # プロパティの一覧取得(追加順で取得できる)
    $pops += @{name = 'No'; expression = { $count } }
    $count = 0
    $AddNoArray = foreach ($object in $array ) {
        $count += 1
        $object | Select-Object -Property $pops
    }

    return $AddNoArray
}