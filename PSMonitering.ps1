$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Set-StrictMode -Version Latest

# �e�X�g�ȊO�̃T�u�X�N���v�g�̓ǂݍ���
Get-ChildItem  -Path ".\subScript" -File | ? { $_.Extension -eq ".ps1" -and $_.BaseName -notlike "*Tests*" } | % { . $_.FullName }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName presentationframework

# �萔��`
$MUTEX_NAME = "0a1c04be-4cb4-9e8d-bb64-804df258da83" # ���d�N���`�F�b�N�p

# ���[�U�[�ݒ�擾
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
    # �t�@�C���ǂݍ���
    $monitoringApps = (TargetFileRead).OKUnique

    #�v���Z�X�ꗗ�擾
    $processes = Get-Process

    # �Ώۊm�F
    foreach ($monitoringApp in $monitoringApps) {
        $targetProcess = @()
        # �Ώۂ����s�����m�F
        $targetProcess += $processes | Where-Object { $_.Path -ieq $monitoringApp.Path }
        # ���s���Ȃ�A�v���N��
        if ($targetProcess.Length -eq 0) {
            StartApp -appPath $monitoringApp.Path -appArgs $monitoringApp.Args
        }
    }
}

function targetFileCheck {
    $NGline = (TargetFileRead).NG

    $errMsg = ""
    if ($NGline.count -ne 0) {
        $errMsg = "�G���[�s����`n�s�F"
        $errMsg = "$errMsg $($NGline.No) "
    }
    else {
        $errMsg = "�G���[�Ȃ�"
    }
    Invoke-Command -ScriptBlock (GetToastScript -toastType Alarm -message $errMsg)
}

function RenewDropDown {
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.ToolStripItemCollection] $dropdownItems
    )
    # ������h���b�v�_�E�������ׂč폜
    $dropdownItemNum = $dropdownItems.count
    for ($i = 0; $i -lt $dropdownItemNum; $i++) {
        $dropdownItems.RemoveAt(0)
    }

    $targets = TargetFileRead
    $targets.OK | % {
        $monitoringApp = $_
        $appName = Split-path -Path $monitoringApp.Path -Leaf
        $menuText = "$($monitoringApp.No)�s�� - $appName"

        $execScript = {
            StartApp -appPath $monitoringApp.Path -appArgs $monitoringApp.Args
        }.GetNewClosure()

        $appExecItem = NewToolStripMenuItem -name $menuText -action $execScript
        $dropdownItems.Add($appExecItem)
    }
}

$mutex = New-Object System.Threading.Mutex($false, $MUTEX_NAME)
# ���d�N���`�F�b�N
if ($mutex.WaitOne(0) -eq $false) {
    OutHostMessage "���łɎ��s�����ȁE�E�E�H"
    $null = $mutex.Close()
    return
}
try {
    # �^�X�N�o�[��\��
    HideWindow

    # �ʒm�̈�A�C�R���̎擾
    $notify_icon = New-Object System.Windows.Forms.NotifyIcon
    $timer = New-Object Windows.Forms.Timer
    try {
        # �ʒm�̈�A�C�R���̃A�C�R����ݒ�
        $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:ICON_FILE)
        $notify_icon.Visible = $true
        $notify_icon.Text = "�Ď���"

        # �A�C�R���N���b�N����window�̕\���E��\���𔽓]
        $notify_icon.add_Click( {
                OutHostMessage "�A�C�R���N���b�N�I"
                if ($_.Button -ne [Windows.Forms.MouseButtons]::Left) { return }
                if ((GetWindowState) -eq [nCmdShow]::SW_HIDE) { ShowWindow } else { HideWindow }
            } )


        # �A�C�R���Ƀ��j���[��ǉ�
        $notify_icon.ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip

        # ���j���[�ɊĎ�ON�EOFF�ǉ�
        $script = {
            OutHostMessage "Monitoring On�N���b�N�I"
            SetMonitoringStatus -status On
        }
        $monitoringOn = NewToolStripMenuItem -name "Monitoring On" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOn)

        $script = {
            OutHostMessage "Monitoring Off�N���b�N�I"
            SetMonitoringStatus -status Off
        }
        $monitoringOff = NewToolStripMenuItem -name "Monitoring Off" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOff)

        # ���j���[�ɃZ�p���[�^�ǉ�
        $ToolStripSeparator = New-Object System.Windows.Forms.ToolStripSeparator
        $null = $notify_icon.ContextMenuStrip.Items.Add($ToolStripSeparator)

        # ���j���[�Ƀ^�[�Q�b�g�t�@�C�����J����ǉ�
        $script = {
            OutHostMessage "Open Target File�N���b�N�I"
            . $TARGET_FILE
        }
        $openTargetFile = NewToolStripMenuItem -name "Open Target File" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($openTargetFile)

        # ���j���[�Ƀ^�[�Q�b�g�t�@�C���`�F�b�N��ǉ�
        $script = {
            OutHostMessage "Target File Check�N���b�N�I"
            targetFileCheck
        }
        $checkTargetFile = NewToolStripMenuItem -name "Target File Check" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($checkTargetFile)

        # ���j���[�Ɋe�^�[�Q�b�g���s�ǉ�
        $excuteTarget = NewToolStripMenuItem -name "Excute Target" -action {}

        ## ">"��\�������邽�߁A�_�~�[�̃A�C�e����ǉ�
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

        # ���j���[�ɃZ�p���[�^�ǉ�
        $ToolStripSeparator = New-Object System.Windows.Forms.ToolStripSeparator
        $null = $notify_icon.ContextMenuStrip.Items.Add($ToolStripSeparator)

        # ���j���[��Exit���j���[��ǉ�
        $exitScript = {
            OutHostMessage "Exit�N���b�N�I"
            [void][System.Windows.Forms.Application]::Exit()
        }
        $menuItemExit = NewToolStripMenuItem -name "Exit" -action $exitScript
        $null = $notify_icon.ContextMenuStrip.Items.Add($menuItemExit)


        # �^�C�}�[�C�x���g
        $timerEvent = {
            OutHostMessage  "Timer���s�I"
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

        # exit�����܂őҋ@
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
