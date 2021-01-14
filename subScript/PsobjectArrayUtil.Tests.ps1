$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
# この中のTestWorkDayを使うが、スコープの問題があるので、テスト時にモックを定義

function GetPSObjectArray {
    [OutputType([array])]
    param ()

    $array = @()
    $array += [PSCustomObject]@{Name = "Value1" }
    $array += [PSCustomObject]@{Name = "Value2" }
    $array += [PSCustomObject]@{Name = "Value3" }
    $array += [PSCustomObject]@{Name = "Value4" }

    return $array
}

Describe "AddNumberToPsobjectArray" {
    It "Noの列が追加される" {

        $psobject = GetPSObjectArray
        $object = AddNumberToPsobjectArray -array $psobject
        $propName = (Get-Member -InputObject $object[0] -MemberType "NoteProperty").name
        $propName -contains "No" | Should Be $true
    }
}
