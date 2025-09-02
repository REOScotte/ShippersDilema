# Replacing Clear-Box - not faster

###### Configureation Here ######

# Number of sequences tried
[uint64]$counter = 0

# Collection of solutions found
$solutions = [System.Collections.ArrayList]::new()

# Sequence to begin with. Start with empty string to begin at the beginning.
$startSequence = '421 111 142'

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
$global:box = New-Object 'object[,,]' $boxXSize, $boxYSize, $boxZSize

# Build the current sequence by adding the start pieces
$sequence = [System.Collections.ArrayList]::new()

$startPieces = $startSequence.Split(' ')
foreach ($startPiece in $startPieces) {
    for ($i = 0; $i -lt $orientations.Count; $i++) {
        if ($startPiece -in $orientations[$i]) {
            $pieces[$i]--
            $sequence.Add($startPiece) | Out-Null
        }
    }
}

# Shape to start with.
if ($sequence) {
    $shape = $sequence[-1]
    $sequence.RemoveAt($sequence.Count - 1)

    # Put it back
    for ($i = 0; $i -lt $orientations.Count; $i++) {
        if ($shape -in $orientations[$i]) {$pieces[$i]++}
    }
} else {
    $shape = $orientations[0][0]
}

# Sets all values in the box to 0
function Clear-Box {
    0..($boxZSize - 1) | ForEach-Object {
        $z = $_
        0..($boxYSize - 1) | ForEach-Object {
            $y = $_
            0..($boxXSize - 1) | ForEach-Object {
                $x = $_
                $global:box[$x, $y, $z] = 0
            }
        }    
    }
}

# Display the box for troubleshooting
function Show-Box {
    '-' * $boxXSize
    for ($z = ($boxZSize - 1); $z -ge 0; $z--) {
        for ($y = ($boxYSize - 1); $y -ge 0; $y--) {
            $(for ($x = 0; $x -lt $boxXSize; $x++) {
                $global:box[$x, $y, $z]
            }) -join ''
        }
        '-' * $boxXSize
    }
}

# Find the spot to put the next shape
function Get-NextEmptyCoordinates {
    for ($z = 0; $z -lt $boxZSize; $z++) {
        for ($y = 0; $y -lt $boxYSize; $y++) {
            for ($x = 0; $x -lt $boxXSize; $x++) {
                if ($global:box[$x, $y, $z] -eq 0) {
                    return $x, $y, $z
                }
            }
        }
    }
}

# Try and add a piece to the current box.
function Place-Piece ([string]$p) {
    $ex, $ey, $ez = Get-NextEmptyCoordinates
    $px = [int]$p.Substring(0, 1)
    $py = [int]$p.Substring(1, 1)
    $pz = [int]$p.Substring(2, 1)

    for ($z = $ez; $z -lt $ez + $pz; $z++) {
        for ($y = $ey; $y -lt $ey + $py; $y++) {
            for ($x = $ex; $x -lt $ex + $px; $x++) {
                if ($global:box[$x, $y, $z] -ne 1) {
                    if ($x -ge $boxXSize -or $y -ge $boxYSize -or $z -ge $boxZSize) { return $false }
                    $global:box[$x, $y, $z] = 1
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
#    $global:box = New-Object 'object[,,]' $boxXSize, $boxYSize, $boxZSize
    foreach ($piece in $sequence) {
        if (-not (Place-Piece $piece)) {
            return $false
        }
    }
    return $true
}

function Get-NextPiece ($p) {
    [array]$availableOrientations =  for ($i = 0; $i -lt $pieces.Count; $i++) {
        if ($pieces[$i] -ne 0) {
            $orientations[$i]
        }
    }

    $nextPiece = $availableOrientations.IndexOf($p) + 1
    $availableOrientations[$nextPiece]
}

$sw = [System.Diagnostics.Stopwatch]::new()
$sw.Start()

Get-Date; while ($shape) {
    $counter++
#    if (-not ($counter % 30)) {Read-Host 'Pausing'}
    $sequence.Add($shape) | Out-Null

    for ($i = 0; $i -lt $orientations.Count; $i++) {
        if ($shape -in $orientations[$i]) {
            $pieces[$i]--
        }
    }

    if (Test-Sequence) {
#        Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Green
        if ($sequence.Count -eq 17) {
            $solutions.Add(
                [PSCustomObject]@{
                    Sequence = $sequence -join ' '
                    Counter  = $counter
                    Date     = Get-Date
                }
            ) | Out-Null
            $solutions | Export-Csv -NoTypeInformation -Append -Encoding ASCII -Path .\solutions.csv
            Write-Host ("{0,3}{1,12}{2,4}{3,3} {4} {5}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' '), (Get-Date)) -ForegroundColor Green
            $sequence.RemoveAt($sequence.Count - 1)
        } else {
            $shape = '000'
        }
    } else {
#        Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Yellow
        $sequence.RemoveAt($sequence.Count - 1)
    }

    do {
        # Put it back
        for ($i = 0; $i -lt $orientations.Count; $i++) {
            if ($shape -in $orientations[$i]) {$pieces[$i]++}
        }
#        Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Red

        if (-not ($next = Get-NextPiece $shape)) {
            $shape = $sequence[-1]
            $sequence.RemoveAt($sequence.Count - 1)
        }
    } until ($next -or ($sequence.Count -eq 0 -and $shape -eq $orientations[-1][-1]))

    $shape = $next
}
$sw.Elapsed.TotalSeconds
