function SetGlobalConst {
    param (
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [Object] $value
    )
    # �萔�̐ݒ�i�ς������Ƃ���powersehll���̂��ċN���E�萔�͕ς����Ȃ����ۂ��E�ǂݍ��ݍς݂ł��G���[�ɂȂ�Ȃ��悤��"Ignore"�����Ă�j
    Set-Variable $Name -Value $value -Scope "Global" -Option "Constant" -ErrorAction "Ignore"

}

SetGlobalConst "SCRIPT_ROOT" (Split-Path $PSScriptRoot -Parent)
SetGlobalConst "RESOURCES_PATH" (Join-Path $SCRIPT_ROOT "resources")

# �e��ݒ�t�@�C����
SetGlobalConst "SETTING_JSON" (Join-Path $SCRIPT_ROOT "settings.json")
SetGlobalConst "TARGET_FILE" (Join-Path $SCRIPT_ROOT "Target.csv")

SetGlobalConst "TOAST_REMINDER_TEMPLATE_FILE" (join-path $RESOURCES_PATH "toastReminder.xml")
SetGlobalConst "TOAST_ALARM_TEMPLATE_FILE" (join-path $RESOURCES_PATH "toastAlarm.xml")

SetGlobalConst "ICON_FILE" (Join-Path $RESOURCES_PATH "icon.ico")
SetGlobalConst "ICON_PNG_FILE" (join-path $RESOURCES_PATH "icon64.png")

