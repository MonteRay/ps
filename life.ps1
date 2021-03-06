[void][Reflection.Assembly]::LoadWithPartialName("system.windows.forms")

function Fill-Field($field,$fill=30) {
    for ([int32]$y=0;$y -lt $field.height;$y++) {
        for ([int32]$x=0;$x -lt $field.width;$x++) {
            if ((Get-Random 101) -lt $fill) {
                $field[$x,$y]=$true
            } else {
                $field[$x,$y]=$false
            }
        }
    }
    return $field
}

function Draw-Field ($field, [int]$scaleFactor=1) {
    #[int]$x=0;[int]$y=0;[int]$dx=0;[int]$dy=0;[int]$ix=0;[int]$iy=0
    $bitmap = New-Object System.Drawing.Bitmap(($field.width*$scaleFactor), ($field.height*$scaleFactor))
    for ($y=0;$y -lt $field.height;$y++) {
        for ($x=0;$x -lt $field.width;$x++) {
            if ($field[$x,$y]) {
                #$color="black"
                $color=[system.drawing.color]::Black
            } else {
                #$color="white"
                $color=[system.drawing.color]::White
            }
            #$stopwatch.Restart()
            $ix=[int]($x*$scaleFactor)
            $iy=[int]($y*$scaleFactor)
            for ($dx=0;$dx -lt $scaleFactor;$dx++) {
                for ($dy=0;$dy -lt $scaleFactor;$dy++) {
                    #$cx=$ix+$dx
                    #$cy=[int]($y*$scaleFactor+$dy)
                    $bitmap.SetPixel($ix+$dx,$iy+$dy,$color)
                }
            }
            #Write-Host $stopwatch.ElapsedMilliseconds
        }
    }
    return $bitmap
}

function formClick {
    <#$pbar.Visible=$true
    $pBar.Minimum=0
    $pBar.Maximum=$size.Height*$size.Width
    $pBar.Value=0
    $pBar.Step=1
    

    #$bitmap = New-Object System.Drawing.Bitmap($size.Width, $size.Height)
    #$bitmap.SetResolution(50,50)
    
    #Get-Random $field
    
    $pBar.PerformStep()
    
    $pbar.Visible=$false
    #>

    
}

function formResize {
    $pic.Width=$form.ClientRectangle.Width-110
    $pic.Height=$form.ClientRectangle.Height-20
}

function genBtnClick {

    $scaleFactor=$nodeSizeNum.Value
    
    $size=$pic.ClientRectangle;
    $size.Width=$size.Width/$scaleFactor
    $size.Height=$size.Height/$scaleFactor

    $field = New-Object "object[,]" $size.Width, $size.Height
    Add-Member -MemberType NoteProperty -Name width -InputObject $field -Value $size.Width
    Add-Member -MemberType NoteProperty -Name height -InputObject $field -Value $size.Height
    
    Fill-Field $field
    
    $stopwatch.Restart()
    $pic.Image=Draw-Field $field $scaleFactor
    Write-Host $stopwatch.ElapsedMilliseconds

}

$stopwatch = New-Object System.Diagnostics.Stopwatch

$form = New-Object windows.forms.form; 
    <#
    $formSize=New-Object system.drawing.size(200,200)
    $form.MinimumSize=$formSize
    $form.MaximumSize=$formSize
    #>



$pic = New-Object windows.forms.picturebox
    $pic.Left=100
    $pic.Top=10

$nodeSizeLabel = New-Object windows.forms.label 
    $nodeSizeLabel.Top=10
    $nodeSizeLabel.Left=10
    $nodeSizeLabel.Width=80
    $nodeSizeLabel.Height=20
    $nodeSizeLabel.Text='Node size (px)'

$nodeSizeNum = New-Object windows.forms.numericUpDown 
    $nodeSizeNum.Top=30
    $nodeSizeNum.Left=10
    $nodeSizeNum.Width=80
    #$nodeSizeNum.Height
    $nodeSizeNum.Minimum=1
    $nodeSizeNum.Maximum=20
    $nodeSizeNum.Value=5

$genBtn = New-Object windows.forms.button
    $genBtn.Top=60
    $genBtn.Left=10
    $genBtn.Width=80
    $genBtn.Height=25
    $genBtn.Text="Generate"
    $genBtn.add_click($Function:genBtnClick)

<#
$pBar = New-Object windows.forms.progressBar
$pBar.Width=$form.ClientRectangle.Width
$pBar.Top=$form.ClientRectangle.Height/2-$pBar.Height/2
$pBar.Visible=$false
#>



#$form.Controls.Add($pbar)
#$form.add_click($function:formClick)

$form.Width=200
$form.Height=130

$form.add_resize($function:formResize)

$form.Controls.Add($pic)
$form.Controls.Add($nodeSizeLabel)
$form.Controls.Add($nodeSizeNum)
$form.Controls.Add($genBtn)


#$form.Controls.a
formResize
$form.ShowDialog()

