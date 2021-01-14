$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Set-StrictMode -Version Latest

# テスト以外のサブスクリプトの読み込み
Get-ChildItem  -Path ".\subScript" -File | ? { $_.Extension -eq ".ps1" -and $_.BaseName -notlike "*Tests*" } | % { . $_.FullName }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName presentationframework

# 定数定義
$MUTEX_NAME = "0a1c04be-4cb4-9e8d-bb64-804df258da83" # 多重起動チェック用

# ユーザー設定取得
$userSetting = Get-Content $SETTING_JSON -Raw | ConvertFrom-Json

function OutHostMessage {
    param (
        [Parameter(Mandatory)]
        [string] $message
    )
    Write-Host (Get-date).ToString("yyyy/MM/dd HH:mm:ss.fff") $message
}

function SetMonitoringStatus {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("On", "Off")]
        [string] $status
    )
    $isMonitoring = $true
    if ($status -eq "On") {
        $timer.Start()
        $isMonitoring = $true
    }
    else {
        $timer.Stop()
        $isMonitoring = $false
    }

    $monitoringOn.Checked = $isMonitoring
    $monitoringOff.Checked = -not $isMonitoring

}

function StartApp {
    param (
        [parameter(Mandatory)]
        [string]$appPath,
        [string]$appArgs
    )

    if ( [string]::IsNullOrEmpty($appArgs)) {
        Start-Process $appPath
    }
    else {
        Start-Process $appPath -ArgumentList $args.sprit(" ")
    }

}
function MonitoringApplications {
    # ファイル読み込み
    $monitoringApps = (TargetFileRead).OKUnique

    #プロセス一覧取得
    $processes = Get-Process

    # 対象確認
    foreach ($monitoringApp in $monitoringApps) {
        $targetProcess = @()
        # 対象が実行中か確認
        $targetProcess += $processes | Where-Object { $_.Path -ieq $monitoringApp.Path }
        # 実行中ならアプリ起動
        if ($targetProcess.Length -eq 0) {
            StartApp -appPath $monitoringApp.Path -appArgs $monitoringApp.Args
        }
    }
}

function targetFileCheck {
    $NGline = (TargetFileRead).NG

    $errMsg = ""
    if ($NGline.count -ne 0) {
        $errMsg = "エラー行あり`n行："
        $errMsg = "$errMsg $($NGline.No) "
    }
    else {
        $errMsg = "エラーなし"
    }
    Invoke-Command -ScriptBlock (GetToastScript -toastType Alarm -message $errMsg)
}

function RenewDropDown {
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.ToolStripItemCollection] $dropdownItems
    )
    # 今あるドロップダウンをすべて削除
    $dropdownItemNum = $dropdownItems.count
    for ($i = 0; $i -lt $dropdownItemNum; $i++) {
        $dropdownItems.RemoveAt(0)
    }

    $targets = TargetFileRead
    $targets.OK | % {
        $monitoringApp = $_
        $appName = Split-path -Path $monitoringApp.Path -Leaf
        $menuText = "$($monitoringApp.No)行目 - $appName"

        $execScript = {
            StartApp -appPath $monitoringApp.Path -appArgs $monitoringApp.Args
        }.GetNewClosure()

        $appExecItem = NewToolStripMenuItem -name $menuText -action $execScript
        $dropdownItems.Add($appExecItem)
    }
}

$mutex = New-Object System.Threading.Mutex($false, $MUTEX_NAME)
# 多重起動チェック
if ($mutex.WaitOne(0) -eq $false) {
    OutHostMessage "すでに実行中かな・・・？"
    $null = $mutex.Close()
    return
}
try {
    # タスクバー非表示
    HideWindow

    # 通知領域アイコンの取得
    $notify_icon = New-Object System.Windows.Forms.NotifyIcon
    $timer = New-Object Windows.Forms.Timer
    try {
        # 通知領域アイコンのアイコンを設定
        $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:ICON_FILE)
        $notify_icon.Visible = $true
        $notify_icon.Text = "監視中"

        # アイコンクリック時にwindowの表示・非表示を反転
        $notify_icon.add_Click( {
                OutHostMessage "アイコンクリック！"
                if ($_.Button -ne [Windows.Forms.MouseButtons]::Left) { return }
                if ((GetWindowState) -eq [nCmdShow]::SW_HIDE) { ShowWindow } else { HideWindow }
            } )


        # アイコンにメニューを追加
        $notify_icon.ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip

        # メニューに監視ON・OFF追加
        $script = {
            OutHostMessage "Monitoring Onクリック！"
            SetMonitoringStatus -status On
        }
        $monitoringOn = NewToolStripMenuItem -name "Monitoring On" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOn)

        $script = {
            OutHostMessage "Monitoring Offクリック！"
            SetMonitoringStatus -status Off
        }
        $monitoringOff = NewToolStripMenuItem -name "Monitoring Off" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOff)

        # メニューにセパレータ追加
        $ToolStripSeparator = New-Object System.Windows.Forms.ToolStripSeparator
        $null = $notify_icon.ContextMenuStrip.Items.Add($ToolStripSeparator)

        # メニューにターゲットファイルを開くを追加
        $script = {
            OutHostMessage "Open Target Fileクリック！"
            . $TARGET_FILE
        }
        $openTargetFile = NewToolStripMenuItem -name "Open Target File" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($openTargetFile)

        # メニューにターゲットファイルチェックを追加
        $script = {
            OutHostMessage "Target File Checkクリック！"
            targetFileCheck
        }
        $checkTargetFile = NewToolStripMenuItem -name "Target File Check" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($checkTargetFile)

        # メニューに各ターゲット実行追加
        $excuteTarget = NewToolStripMenuItem -name "Excute Target" -action {}

        ## ">"を表示させるため、ダミーのアイテムを追加
        $dropdown = New-Object System.Windows.Forms.ToolStripDropDown
        $null = $dropdown.Items.Add( (NewToolStripMenuItem -name "Dummy" -action {}))
        $excuteTarget.DropDown = $dropdown

        $dropDownOpeningScript = [scriptblock] {
            OutHostMessage "open drop "
            $dropdownItems = $args[0].DropDown.Items
            RenewDropDown -dropdownItems $dropdownItems
        }
        $null = $excuteTarget.Add_DropDownOpening($dropDownOpeningScript)
        $null = $notify_icon.ContextMenuStrip.Items.Add($excuteTarget)

        # メニューにセパレータ追加
        $ToolStripSeparator = New-Object System.Windows.Forms.ToolStripSeparator
        $null = $notify_icon.ContextMenuStrip.Items.Add($ToolStripSeparator)

        # メニューにExitメニューを追加
        $exitScript = {
            OutHostMessage "Exitクリック！"
            [void][System.Windows.Forms.Application]::Exit()
        }
        $menuItemExit = NewToolStripMenuItem -name "Exit" -action $exitScript
        $null = $notify_icon.ContextMenuStrip.Items.Add($menuItemExit)


        # タイマーイベント
        $timerEvent = {
            OutHostMessage  "Timer実行！"
            MonitoringApplications
        }

        $timer.Enabled = $true
        $timer.Add_Tick($timerEvent)
        $timer.Interval = $userSetting.interval_second * 1000

        if ($userSetting.MonitorAtStart) {
            SetMonitoringStatus -status On
        }
        else {
            SetMonitoringStatus -status Off
        }

        # exitされるまで待機
        [void][System.Windows.Forms.Application]::Run()

    }
    finally {
        $null = $notify_icon.Dispose()
        $null = $timer.Dispose()
    }
}
finally {
    $null = $mutex.ReleaseMutex()
    $null = $mutex.Close()
}
