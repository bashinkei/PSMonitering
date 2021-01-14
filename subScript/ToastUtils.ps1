# 必要なライブラリの読み込み
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null

enum ToastType {
    Remind
    Alarm
}

function GetToastXmlFileFromType {
    param (
        [Parameter(Mandatory)]
        [ToastType] $toastType
    )
    if ($toastType -eq [ToastType]::Alarm) { return $Global:TOAST_ALARM_TEMPLATE_FILE }
    if ($toastType -eq [ToastType]::Remind) { return $Global:TOAST_REMINDER_TEMPLATE_FILE }
}

function GetToastScript {
    param (
        [string] $message,
        [Parameter(Mandatory)]
        [ToastType] $toastType
    )
    $xmlFile = GetToastXmlFileFromType $toastType
    $xmlOrg = [xml](Get-Content $xmlFile)
    $xml = GetToastXml $message $xmlOrg

    $app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    $toastScrit = { [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show($toast) }.GetNewClosure()
    return $toastScrit
}
function GetToastXml {
    param (
        [string] $message,
        [Parameter(Mandatory)]
        [xml] $toastXml
    )
    $template = $toastXml

    $template.toast.visual.binding.text = "$message"
    if (test-path $Global:ICON_PNG_FILE) {
        $template.toast.visual.binding.image.src = $Global:ICON_PNG_FILE.ToString()
    }
    else {
        $null = $template.toast.visual.binding.RemoveChild($template.toast.visual.binding.image)
    }
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument

    $xml.LoadXml($template.InnerXml)

    return $xml
}