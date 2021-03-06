[void][Reflection.Assembly]::LoadWithPartialName("system.windows.forms")

[int]$rInd=150

# Add-Type @"
#    public class itemInfo {
#        public int64 size;
#        public string type;
#    }
#"@ 

#\/ \/ \/ \/ \/ \/ \/ Start Independent functions \/ \/ \/ \/ \/ \/ \/


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

function showDlg($srcPath) {
    $openDialog=New-Object windows.forms.folderBrowserDialog
    $openDialog.SelectedPath=$srcPath
    [System.Windows.Forms.DialogResult] $result = $openDialog.ShowDialog()
    if ($result -eq "OK") {
        return $openDialog.selectedPath
    } else {
        return $null
    }
    
}

function getValueColor($value,$low,$high) {
    $nValue=$value-$low
    $range=$high-$low
    $k=255/$Range
    if ($nValue -lt ($range/2)) {
        $R=$k*$nValue*2
        $G=255
    } else {
        $R=255
        $G=$k*($range-$nValue)*2
    }
    $color=New-Object system.drawing.color
    $color=[system.drawing.color]::fromARGB(0,$R,$G,0)
    return $color
}

function onKeyDown ([object] $sender, [System.Windows.Forms.KeyEventArgs] $keyArgs) {
if (($keyArgs.keyCode -as [int] -eq 13) -and $keyArgs.control) {onClick; $keyArgs.SuppressKeyPress=$true}
}

function Build-Nodes([string]$path='./',$parent,$maxLevel=0,$curLevel,$showFiles) {
    [int64]$sumSize=0
    $curLevel+=1
    foreach ($item in Get-ChildItem $path) {
        if (Test-Path $item.FullName -PathType Container) {
            $node=$parent.Nodes.Add($item.name)
            
            #$node.ForeColor=$color
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

#/\ /\ /\ /\ /\ /\ /\ End Independent functions /\ /\ /\ /\ /\ /\ /\ 

#\/ \/ \/ \/ \/ \/ \/ Start Event Handlers \/ \/ \/ \/ \/ \/ \/


function onResize {
    #$minWidth=400
    #$minHeight=220
    
    #if ($form.Width -lt $minWidth) {$form.Width=$minWidth}
    #if ($form.Height -lt $minHeight) {$form.Height=$minHeight}

    $brd=$form.ClientRectangle.width-$rInd
    $tree.width=$brd-20
    $tree.height=$form.ClientRectangle.Height-40
    $levelLabel.Left=$brd
    $levelBox.Left=$brd
    $doBtn.left=$brd
    $checkBox.Left=$brd
    #$pathLabel.Left=$brd
    #$pathBox.Left=$brd
    $pathBox.Width=$form.ClientRectangle.width-$pathLabel.Width-50
    $pathBtn.Left=$form.ClientRectangle.width-40
    
    
    #>
}

function onClick {
    $tree.BeginUpdate()
    $tree.Nodes.Clear()
    [int]$curLevel=-1
    [int]$maxLevel=$levelBox.Value
    $showFiles=$checkBox.Checked
    $basePath=$pathBox.Text
    Build-Nodes $basePath $tree $maxLevel $curLevel $showFiles
    $tree.EndUpdate()
}

function pathBtnClick {
    $path=showDlg $pathBox.Text
    if ($path -ne $null) {$pathBox.Text=$path}
}

#/\ /\ /\ /\ /\ /\ /\ End Event Handlers /\ /\ /\ /\ /\ /\ /\ 

$form = New-Object windows.forms.form
$form.height = 220
$form.width = 400
$form.MinimumSize=New-Object system.drawing.size(400,220)


#$font = New-Object system.drawing.font ($form.Font.Name, 12, $form.Font.Style)

$tree = New-Object windows.forms.treeView
$tree.Left=10
$tree.Top=30

$pathLabel = New-Object windows.forms.label
$pathLabel.Top=10
#$pathLabel.Width=$rInd-10
$pathLabel.Left=10
$pathLabel.Height=15
$pathLabel.Width=80
$pathLabel.Text="Базовый путь:"

$pathBox = New-Object windows.forms.textbox
$pathBox.Top=7
$pathBox.Left=$pathLabel.Width+10
#$pathBox.Enabled=$false
$pathBox.Text=Split-Path $MyInvocation.MyCommand.Path -Parent
$pathBox.add_KeyDown($function:onKeyDown)

$pathBtn = New-Object windows.forms.button
$pathBtn.Text="..."
$pathBtn.Width=30
$pathBtn.Height=20
$pathBtn.Top=7
#$doBtn.Font = New-Object system.drawing.font ($doBtn.Font.Name, 12, $doBtn.Font.Style);
$pathBtn.add_click($Function:pathBtnClick)


$levelLabel = New-Object windows.forms.label
$levelLabel.Top=30
$levelLabel.Width=$rInd-10
$levelLabel.Height=30
$levelLabel.Text="Уровень вложенности. `n'-1' не ограничено"


$levelBox = New-Object windows.forms.numericUpDown
$levelBox.Top=60
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
$checkBox.Top=80
$checkBox.Width=$rInd-10

$doBtn = New-Object windows.forms.button
$doBtn.Text="Build tree (CTRL+ENTER)"
$doBtn.Width=$rInd-10
$doBtn.Height=35
$doBtn.Top=110
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
