# New Next Piece

###### Configuration Here ######

# Number of sequences tried
[uint64]$counter = 0

# Collection of solutions found
$solutions = [System.Collections.ArrayList]::new()

# Sequence to begin with. Start with empty string to begin at the beginning.
$startSequence = ''
$startSequence = '2-421 0-111 2-142'

# Dimensions of the box
$boxXSize = 5
$boxYSize = 5
$boxZSize = 5

# The counts of each piece
$pieces = @(5, 6, 6)

# The possible orientations for each piece. Must be in the same order as $pieces
$orientations = @('0-111', '1-223', '1-232', '1-322', '2-124', '2-142', '2-214', '2-241', '2-412', '2-421')
###### End Configuration ######

# Build the box
$box = New-Object 'object[,,]' $boxXSize, $boxYSize, $boxZSize

# Build the current sequence by adding the start pieces
$sequence = [System.Collections.ArrayList]::new()

$startPieces = $startSequence.Split(' ')
if ($startPieces) {
    foreach ($startPiece in $startPieces) {
        $pieces[[int][string]$startPiece[0]]--
        $sequence.Add($startPiece) | Out-Null
    }
}

# Shape to start with.
if ($sequence) {
    $shape = $sequence[-1]
    $sequence.RemoveAt($sequence.Count - 1)

    # Put it back
    $pieces[[int][string]$shape[0]]++
} else {
    $shape = $orientations[0]
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
            $(for ($x = 0; $x -lt $boxXSize; $x++) {
                $box[$x, $y, $z]
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
                if ($box[$x, $y, $z] -eq 0) {
                    return $x, $y, $z
                }
            }
        }
    }
}

# Try and add a piece to the current box.
function Place-Piece ([string]$p) {
    $ex, $ey, $ez = Get-NextEmptyCoordinates
    $px = [int]$p.Substring(2, 1)
    $py = [int]$p.Substring(3, 1)
    $pz = [int]$p.Substring(4, 1)

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

# See if the current sequence will fit in a box, starting empty
function Test-Sequence {
    Clear-Box
    foreach ($piece in $sequence) {
        if (-not (Place-Piece $piece)) {
            return $false
        }
    }
    return $true
}

function Get-NextPiece ($p) {
    $nextIndex = $orientations.IndexOf($p) + 1
    for ($i = $nextIndex; $i -lt $orientations.Length; $i++) {
        $shape = $orientations[$i]
        if ($pieces[[int][string]$shape[0]]) { return $shape }
    }
}

$sw = [System.Diagnostics.Stopwatch]::new()
$sw.Start()

Get-Date; while ($shape) {
    $counter++
#    if (-not ($counter % 10)) {Read-Host 'Pausing'}
    $sequence.Add($shape) | Out-Null

    # Take the piece
    $pieces[[int][string]$shape[0]]--

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
            $solutions | Export-Csv -NoTypeInformation -Append -Encoding ASCII -Path .\solutions_new_next.csv
            Write-Host ("{0,3}{1,12}{2,4}{3,3} {4} {5}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' '), (Get-Date)) -ForegroundColor Green
            $sequence.RemoveAt($sequence.Count - 1)
        } else {
            $shape = '00000'
        }
    } else {
#        Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Yellow
        $sequence.RemoveAt($sequence.Count - 1)
    }

    do {
        # Put it back
        if ($shape -ne '00000') {
            $pieces[[int][string]$shape[0]]++
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
