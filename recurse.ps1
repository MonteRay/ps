function Get-DirStruct([string]$path='.\') {
    foreach ($item in Get-ChildItem $path) {
        if (Test-Path $item -PathType Container) {
            $item
            Get-DirStruct $item.FullName
        } else {
            $item
        }
    }
}