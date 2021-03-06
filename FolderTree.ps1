[void][Reflection.Assembly]::LoadWithPartialName("system.windows.forms")

[int]$rInd=150

$basePath = Split-Path $MyInvocation.MyCommand.Path -Parent

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

function showDlg($srcPath,$parent) {
    $openDialog=New-Object windows.forms.folderBrowserDialog
    $openDialog.SelectedPath=$srcPath
    [System.Windows.Forms.DialogResult] $result = $openDialog.ShowDialog($parent)
    if ($result -eq "OK") {
        return $openDialog.selectedPath
    } else {
        return $null
    }
    
}

function getValueColor($value,$low,$high) {
    $color=New-Object system.drawing.color
    $nValue=$value-$low
    $range=$high-$low
    if ($range -le 0) {
        $color=[system.drawing.color]::fromARGB(0,0,255,0)
        return $color
    }
    $k=255/$Range
    if ($nValue -lt ($range/2)) {
        [int]$R=$k*$nValue*2
        $G=255
    } else {
        $R=255
        [int]$G=$k*($range-$nValue)*2
    }
    if ($R -lt 0) {$R=0}
    if ($R -gt 255) {$R=255}
    if ($G -lt 0) {$G=0}
    if ($G -gt 255) {$G=255}
    $color=[system.drawing.color]::fromARGB(0,$R,$G,0)
    return $color
}

function onKeyDown ([object] $sender, [System.Windows.Forms.KeyEventArgs] $keyArgs) {
if (($keyArgs.keyCode -as [int] -eq 13) -and $keyArgs.control) {onClick; $keyArgs.SuppressKeyPress=$true}
}

function Build-Nodes([string]$path='./',$parent,$maxLevel=0,$curLevel,$showFiles,$minSize,$maxSize) {
    [int64]$sumSize=0
    $curLevel+=1
    foreach ($item in Get-ChildItem $path) {
        if (Test-Path $item.FullName -PathType Container) {
            $node=$parent.Nodes.Add($item.name)
            
            #$node.ForeColor='green'
            #$node.NodeFont=$font
            if (($maxLevel -lt 0) -or ($curLevel -lt $maxLevel)) {
                $size = Build-Nodes $item.FullName $node $maxLevel $curLevel $showFiles $minSize $maxSize
            } else {
                $size = (Get-ChildItem $item.fullName -Recurse | Measure-Object -Property length -sum).sum
            }
            $node.text+=" ("+(autoSizeUnits $size)+")"
            $node.ForeColor=getValueColor $size $minSize $maxSize
            $node.ImageIndex=0
            $node.SelectedImageIndex=0
        } else {
            $size=$item.length
            if ($showFiles) {
                $formatedName=$item.name +" ("+(autoSizeUnits $size)+")"
                $node=$parent.Nodes.Add($formatedName)
                $node.ForeColor=getValueColor $size $minSize $maxSize
                $node.ImageIndex=1
                $node.SelectedImageIndex=1
            }
        }
        $sumSize+=$size
    }
    return $sumSize
}

#/\ /\ /\ /\ /\ /\ /\ End Independent functions /\ /\ /\ /\ /\ /\ /\ 

#\/ \/ \/ \/ \/ \/ \/ Start Event Handlers \/ \/ \/ \/ \/ \/ \/


function onResize {
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
    $gLabel.Left=$brd
    $gNum.Left=$brd
    $gCmb.Left=$brd+$gNum.Width
    $rLabel.Left=$brd
    $rNum.Left=$brd
    $rCmb.Left=$brd+$rNum.Width
    
    #>
}

function onClick {
    $tree.BeginUpdate()
    $tree.Nodes.Clear()
    [int]$curLevel=-1
    [int]$maxLevel=$levelBox.Value
    $showFiles=$checkBox.Checked
    $basePath=$pathBox.Text
    $minSize=$gNum.Value*[math]::pow(1024,$gCmb.SelectedIndex)
    $maxSize=$rNum.Value*[math]::pow(1024,$rCmb.SelectedIndex)
    if ($minSize -gt $maxSize) {
        $maxSize=$minSize
        $rCmb.SelectedIndex=$gCmb.SelectedIndex
        $rNum.Value=$gNum.Value
    }
    Build-Nodes $basePath $tree $maxLevel $curLevel $showFiles $minSize $maxSize
    $tree.EndUpdate()
}

function pathBtnClick {
    $path=showDlg $pathBox.Text $form
    if ($path -ne $null) {$pathBox.Text=$path}
}

#/\ /\ /\ /\ /\ /\ /\ End Event Handlers /\ /\ /\ /\ /\ /\ /\ 

$form = New-Object windows.forms.form
$form.height = 300
$form.width = 400
$form.MinimumSize=New-Object system.drawing.size(400,300)

#$font = New-Object system.drawing.font ($form.Font.Name, 12, $form.Font.Style)


$tree = New-Object windows.forms.treeView
$tree.Left=10
$tree.Top=30
#$tree.BackColor=New-Object system.drawing.color
$tree.BackColor=[system.drawing.color]::fromARGB(150,150,150)

$imageList = New-Object Windows.Forms.imageList
$imagePath=Join-Path $basePath "folder.png"
$image = [System.Drawing.Image]::FromFile($imagePath)
$imageList.Images.Add($image)
$imagePath=Join-Path $basePath "file.png"
$image = [System.Drawing.Image]::FromFile($imagePath)
$imageList.Images.Add($image)
$tree.ImageList=$imageList

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
$pathBox.Text=$basePath
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

$gLabel = New-Object windows.forms.label
$gLabel.Top=110
$gLabel.Height=15
$gLabel.Width=$rInd-10
$gLabel.ForeColor="green"
$gLabel.Text="Зеленый уровень:"

$gNum = New-Object windows.forms.numericUpDown
$gNum.Top=125
$gNum.Width=$rInd-50
$gNum.Maximum=[system.decimal]::maxValue
$gNum.Value=1
#$levelBox.Minimum=-1
#$levelBox.Value=-1

$gCmb = New-Object windows.forms.comboBox
$gCmb.Top=125
$gCmb.Width=40
$gCmb.DropDownStyle=[windows.forms.comboBoxStyle]::dropDownList
$gCmb.Items.AddRange(@("B","KB","MB","GB","TB"))
$gCmb.SelectedIndex=2

$rLabel = New-Object windows.forms.label
$rLabel.Top=160
$rLabel.Height=15
$rLabel.Width=$rInd-10
$rLabel.ForeColor="red"
$rLabel.Text="Красный уровень:"

$rNum = New-Object windows.forms.numericUpDown
$rNum.Top=175
$rNum.Width=$rInd-50
$rNum.Maximum=[system.decimal]::maxValue
$rNum.Value=1
#$levelBox.Minimum=-1
#$levelBox.Value=-1

$rCmb = New-Object windows.forms.comboBox
$rCmb.Top=175
$rCmb.Width=40
$rCmb.DropDownStyle=[windows.forms.comboBoxStyle]::dropDownList
$rCmb.Items.AddRange(@("B","KB","MB","GB","TB"))
$rCmb.SelectedIndex=3

#$rNum = New-Object windows.forms.numericUpDown
#$rNum.Top=60
#$rNum.Width=$rInd-10


$doBtn = New-Object windows.forms.button
$doBtn.Text="Build tree (CTRL+ENTER)"
$doBtn.Width=$rInd-10
$doBtn.Height=35
$doBtn.Top=210
#$doBtn.Font = New-Object system.drawing.font ($doBtn.Font.Name, 12, $doBtn.Font.Style);
$doBtn.add_click($Function:onClick)


$form.Controls.Add($pathLabel)
$form.Controls.Add($pathBox)
$form.Controls.Add($pathBtn)
$form.Controls.Add($levelLabel)
$form.Controls.Add($levelBox)
$form.Controls.Add($checkBox)
$form.Controls.Add($gLabel)
$form.Controls.Add($gNum)
$form.Controls.Add($gCmb)
$form.Controls.Add($rLabel)
$form.Controls.Add($rNum)
$form.Controls.Add($rCmb)
$form.Controls.Add($doBtn)
$form.Controls.Add($tree)
$form.Add_Shown({$form.Activate()})
$form.Add_Resize($function:onResize)
$form.add_KeyDown($function:onKeyDown)
onResize
$form.ShowDialog()
