[void][Reflection.Assembly]::LoadWithPartialName("system.windows.forms")

[int]$rInd=150

# Add-Type @"
#    public class itemInfo {
#        public int64 size;
#        public string type;
#    }
#"@ 

function autoSizeUnits ([int64]$sizeInBytes) {
    [string]$formatedSize=""
    if ($sizeInBytes -eq $Null) {$formatedSize="0B"}
    elseif ($sizeInBytes -gt 1TB) {$formatedSize=('{0:N2}' -f ($sizeInBytes/1TB))+"TB"}
    elseif ($sizeInBytes -gt 1GB) {$formatedSize=('{0:N2}' -f ($sizeInBytes/1GB))+"GB"}     
    elseif ($sizeInBytes -gt 1MB) {$formatedSize=('{0:N2}' -f ($sizeInBytes/1MB))+"MB"}
    elseif ($sizeInBytes -gt 1KB) {$formatedSize=('{0:N2}' -f ($sizeInBytes/1KB))+"KB"}          
    else   {$formatedSize=('{0:N0}' -f $sizeInBytes)+"B"} 
        
    return $formatedSize    
}

function onResize {
    $brd=$form.ClientRectangle.width-$rInd
    $tree.width=$brd-20
    $tree.height=$form.ClientRectangle.Height-20
    $levelLabel.Left=$brd
    $levelBox.Left=$brd
    $doBtn.left=$brd
    $checkBox.Left=$brd
    $pathLabel.Left=$brd
    $pathBox.Left=$brd
    $pathBtn.Left=$brd+$pathBox.Width
    #>
}


function Build-Nodes([string]$path='./',$parent,$maxLevel=0,$curLevel,$showFiles) {
    [int64]$sumSize=0
    $curLevel+=1
    foreach ($item in Get-ChildItem $path) {
        if (Test-Path $item.FullName -PathType Container) {
            $node=$parent.Nodes.Add($item.name)
            $node.ForeColor='green'
            #$node.NodeFont=$font
            if (($maxLevel -lt 0) -or ($curLevel -lt $maxLevel)) {
                $size = Build-Nodes $item.FullName $node $maxLevel $curLevel $showFiles
            } else {
                $size = (Get-ChildItem $item.fullName -Recurse | Measure-Object -Property length -sum).sum
            }
            $node.text+=" ("+(autoSizeUnits $size)+")"
        } else {
            $size=$item.length
            if ($showFiles) {
                $formatedName=$item.name +" ("+(autoSizeUnits $size)+")"
                $node=$parent.Nodes.Add($formatedName)
            }
        }
        $sumSize+=$size
    }
    return $sumSize
}

function onClick {
    $tree.BeginUpdate()
    $tree.Nodes.Clear()
    [int]$curLevel=-1
    [int]$maxLevel=$levelBox.Value
    $showFiles=$checkBox.Checked
    Build-Nodes './' $tree $maxLevel $curLevel $showFiles
    $tree.EndUpdate()
}

function showDlg {
    $openDialog=New-Object windows.forms.openFileDialog
    
}

function onKeyDown ([object] $sender, [System.Windows.Forms.KeyEventArgs] $keyArgs) {
if (($keyArgs.keyCode -as [int] -eq 13) -and $keyArgs.control) {onClick; $keyArgs.SuppressKeyPress=$true}

}


$form = New-Object windows.forms.form
$form.height = 220
$form.width = 400

$font = New-Object system.drawing.font ($form.Font.Name, 12, $form.Font.Style)

$tree = New-Object windows.forms.treeView
$tree.Left=10
$tree.Top=10

$pathLabel = New-Object windows.forms.label
$pathLabel.Top=10
$pathLabel.Width=$rInd-10
$pathLabel.Height=15
$pathLabel.Text="Базовый путь:"

$pathBox = New-Object windows.forms.textbox
$pathBox.Top=30
$pathBox.Width=$rInd-40
$pathBox.Enabled=$false
$pathBox.Text=Split-Path $MyInvocation.MyCommand.Path -Parent
$pathBox.add_KeyDown($function:onKeyDown)

$pathBtn = New-Object windows.forms.button
$pathBtn.Text="..."
$pathBtn.Width=30
$pathBtn.Height=20
$pathBtn.Top=30
#$doBtn.Font = New-Object system.drawing.font ($doBtn.Font.Name, 12, $doBtn.Font.Style);
$pathBtn.add_click($Function:showDlg)


$levelLabel = New-Object windows.forms.label
$levelLabel.Top=60
$levelLabel.Width=$rInd-10
$levelLabel.Height=30
$levelLabel.Text="Уровень вложенности. `n'-1' не ограничено"


$levelBox = New-Object windows.forms.numericUpDown
$levelBox.Top=90
$levelBox.Width=$rInd-10
$levelBox.Minimum=-1
$levelBox.Value=-1
#$levelBox.Multiline=$true
#$levelBox.AcceptsReturn=$true
#$levelBox.WordWrap=$true
#$levelBox.ScrollBars='vertical'
#$levelBox.Text=""
$levelBox.add_KeyDown($function:onKeyDown)

$checkBox = New-Object windows.forms.checkBox
$checkBox.Text="Отображать файлы"
$checkBox.Checked=$true
$checkBox.Top=110
$checkBox.Width=$rInd-10

$doBtn = New-Object windows.forms.button
$doBtn.Text="Build tree (CTRL+ENTER)"
$doBtn.Width=$rInd-10
$doBtn.Height=35
$doBtn.Top=140
#$doBtn.Font = New-Object system.drawing.font ($doBtn.Font.Name, 12, $doBtn.Font.Style);
$doBtn.add_click($Function:onClick)


$form.Controls.Add($pathLabel)
$form.Controls.Add($pathBox)
$form.Controls.Add($pathBtn)
$form.Controls.Add($levelLabel)
$form.Controls.Add($levelBox)
$form.Controls.Add($checkBox)
$form.Controls.Add($doBtn)
$form.Controls.Add($tree)
$form.Add_Shown({$form.Activate()})
$form.Add_Resize($function:onResize)
$form.add_KeyDown($function:onKeyDown)
onResize
$form.ShowDialog()
