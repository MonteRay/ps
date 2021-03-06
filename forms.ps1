$swTableFileName='.\swtable.txt';

[void][Reflection.Assembly]::LoadWithPartialName("system.windows.forms")

#function sw{
#    param (
#        [parameter(Mandatory=$true)][System.String]$s,
#        [parameter(Mandatory=$true)][System.Collections.Hashtable]$t
#    )


function sw([String]$s,[System.Collections.Hashtable]$t) {    
    [string]$tmp=''
    for ($i=0; $i -lt $s.length; $i++) {
        $c=$t[$s[$i]]
        if ($c -ne $null) {$tmp+=$c} else {$tmp+=$s[$i]}
    }
    return $tmp
}

function onClick {
    #Write-Host $inputBox.Text
    $inputBox.text=sw -s $inputBox.text -t $t
}

function onKeyDown ([object] $sender, [System.Windows.Forms.KeyEventArgs] $keyArgs) {
if (($keyArgs.keyCode -as [int] -eq 13) -and $keyArgs.control) {onClick; $keyArgs.SuppressKeyPress=$true}

}

function onResize {
    $inputBox.width=$form.ClientRectangle.Width-20
    $inputBox.height=$form.ClientRectangle.Height-60
    $btndo.top=$form.ClientRectangle.Height-40
    $btndo.Width=$form.ClientRectangle.Width-20
}

$f=Get-Content $swTableFileName
$t=@{}

for ($i=0; $i -lt $f[0].length; $i++) {
    try{$t.Add($f[0][$i],$f[1][$i])} catch {}
    try{$t.Add($f[1][$i],$f[0][$i])} catch {}
}
#}
#Finally {write-host 'Already exists'}
    #$t.Add($f[1][$i],$f[0][$i])
    #DotNetMethodException


$form = New-Object windows.forms.form
$form.height = 220
$form.width = 350

$inputBox = New-Object windows.forms.textbox
$inputBox.left=10
$inputBox.top=10
$inputBox.Multiline=$true
$inputBox.AcceptsReturn=$true
$inputBox.WordWrap=$true
$inputBox.ScrollBars='vertical'
$inputBox.Text=""
$inputBox.add_KeyDown($function:onKeyDown)

$btndo = New-Object windows.forms.button
$btndo.Text="Fix charset (CTRL+ENTER)"
$btndo.left=10
$btndo.Height=30
$btndo.Font = New-Object system.drawing.font ($btndo.Font.Name, 12, $btndo.Font.Style);
$btndo.add_click($Function:onClick)


$form.Controls.Add($inputBox)
$form.Controls.Add($btndo)
$form.Add_Shown({$form.Activate()})
$form.Add_Resize($function:onResize)
onResize
$form.ShowDialog()
