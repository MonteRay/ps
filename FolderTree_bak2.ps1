[void][Reflection.Assembly]::LoadWithPartialName("system.windows.forms")

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
    $tree.width=$form.ClientRectangle.Width-20
    $tree.height=$form.ClientRectangle.Height-20
    <#
    $btndo.top=$form.ClientRectangle.Height-40
    $btndo.Width=$form.ClientRectangle.Width-20
    #>
}


function Build-Nodes([string]$path='./',$parent) {
    [int64]$sumSize=0
    foreach ($item in Get-ChildItem $path) {
        if (Test-Path $item -PathType Container) {
            $node=$parent.Nodes.Add($item.name)
            $node.ForeColor='green'
            #$node.NodeFont=$font
            $size = Build-Nodes $item.FullName $node
            $node.text+=" ("+(autoSizeUnits $size)+")"
        } else {
            $size=$item.length
            $formatedName=$item.name +" ("+(autoSizeUnits $size)+")"
            $node=$parent.Nodes.Add($formatedName)
        }
        $sumSize+=$size
    }
    return $sumSize
}




$form = New-Object windows.forms.form
$form.height = 220
$form.width = 350

$font = New-Object system.drawing.font ($form.Font.Name, 12, $form.Font.Style)

$tree = New-Object windows.forms.treeView
$tree.Width=100
$tree.Height=100
$tree.Left=10
$tree.Top=10

$tree.BeginUpdate()
Build-Nodes './' $tree
$tree.EndUpdate()


#$form.Controls.Add($inputBox)
#$form.Controls.Add($btndo)
$form.Controls.Add($tree)
$form.Add_Shown({$form.Activate()})
$form.Add_Resize($function:onResize)
onResize
$form.ShowDialog()
