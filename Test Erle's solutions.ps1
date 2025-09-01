# Test Erle's output

###### Configureation Here ######
# Dimensions of the box
$boxXSize = 5
$boxYSize = 5
$boxZSize = 5

# The counts of each piece
$pieces = @(5, 6, 6)

# The possible orientations for each piece. Must be in the same order as $pieces
$orientations = @(
    ,@('111')
    ,@('223', '232', '322')
    ,@('124', '142', '214', '241', '412', '421')
)
###### End Configuration ######

# Build the box
$box = New-Object 'object[,,]' $boxXSize, $boxYSize, $boxZSize

# Backup box for comparison
$backup = New-Object 'object[,,]' $boxXSize, $boxYSize, $boxZSize

# Sets all values in the box to 0
function Backup-Box {
    0..($boxZSize - 1) | ForEach-Object {
        $z = $_
        0..($boxYSize - 1) | ForEach-Object {
            $y = $_
            0..($boxXSize - 1) | ForEach-Object {
                $x = $_
                $backup[$x, $y, $z] = $box[$x, $y, $z]
            }
        }    
    }
}

# Sets all values in the box to 0
function Clear-Box {
    0..($boxZSize - 1) | ForEach-Object {
        $z = $_
        0..($boxYSize - 1) | ForEach-Object {
            $y = $_
            0..($boxXSize - 1) | ForEach-Object {
                $x = $_
                $box[$x, $y, $z] = 0
            }
        }    
    }
}

# Display the box for troubleshooting
function Show-Box {
    '-' * $boxXSize
    for ($z = ($boxZSize - 1); $z -ge 0; $z--) {
        for ($y = ($boxYSize - 1); $y -ge 0; $y--) {
            for ($x = 0; $x -lt $boxXSize; $x++) {
                if ($box[$x, $y, $z] -eq $backup[$x, $y, $z]) {
                    $color = 'White'
                } else {
                    $color = 'Green'
                }
                $icon = if ($box[$x, $y, $z]) {'X'} else {' '}
                Write-Host $icon -NoNewline -ForegroundColor $color
            }
            Write-Host
        }
        '-' * $boxXSize
    }
}

# Try and add a piece to the current box.
function Place-Piece ([string]$p, [string]$e) {
    $ex = [int]$e.Substring(0, 1)
    $ey = [int]$e.Substring(1, 1)
    $ez = [int]$e.Substring(2, 1)
    $px = [int]$p.Substring(0, 1)
    $py = [int]$p.Substring(1, 1)
    $pz = [int]$p.Substring(2, 1)

    for ($z = $ez; $z -lt $ez + $pz; $z++) {
        for ($y = $ey; $y -lt $ey + $py; $y++) {
            for ($x = $ex; $x -lt $ex + $px; $x++) {
                if ($box[$x, $y, $z] -eq 0) {
                    $box[$x, $y, $z] = 1
                } else {
                    return $false
                }
            }
        }
    }
    return $true
}

# See if the current sequece will fit in a box, starting empty
function Test-Sequence {
    Clear-Box
    foreach ($piece in $sequence) {
        Backup-Box

        $shape, $empty = $piece.Split('@')
        if (-not (Place-Piece $shape $empty)) {
            Show-Box
            Read-Host $piece
            return $false
        }
        Show-Box
        Read-Host $piece
    }
    return $true
}

$sequence = @(
'223@232'
'223@100'
'322@213'
'322@020'
'232@301'
'232@022'
'124@000'
'241@300'
'412@040'
'124@431'
'241@014'
'412@103'
'111@113'
'111@222'
'111@004'
'111@440'
'111@331'
)

Test-Sequence