# Working on improving indexing

###### Configureation Here ######

# Number of sequences tried
[uint64]$counter = 0

# Collection of solutions found
$solutions = [System.Collections.ArrayList]::new()

# Sequence to begin with. Start with empty string to begin at the beginning.
$startSequence = ''
#$startSequence = '241 223 124 322 111 412 232 124 111 111 232 223 412 322 111 111'
#$startSequence = '241 223 142 223 214 111 111 111 241 111 214 223 111 232'
#$startSequence = '111 111 111 111 111'
#$startSequence = '111 421 142'
#$startSequence = '111 412 241 322 223 124 124 111 232 223 232 111 322'
#$startSequence = '111 421 142 232 223 214 214 322 111 223 111 322 232 142 111'
#$startSequence = '111 421 142 232 223 214 214 322 111 223 111 322 232 142 111 421 111'
#$startSequence = '111 421'
#$startSequence = '111 421 142 223 223'
#$startSequence = '421 111 142 223 232 214 322 214 111 223'

# Dimensions of the box
$boxXSize = 5
$boxYSize = 5
$boxZSize = 5

# The counts of each piece
$pieces = @(5, 6, 6)

# The possible orientations for each piece. Must be in the same order as $pieces
$orientations = @(
    ,@('00111')
    ,@('10223', '11232', '12322')
    ,@('20124', '21142', '22214', '23241', '24412', '25421')
)
###### End Configuration ######

# Build the box
$box = New-Object 'object[,,]' $boxXSize, $boxYSize, $boxZSize

# Build the current sequence by adding the start pieces
$sequence = [System.Collections.ArrayList]::new()

$startPieces = $startSequence.Split(' ')
if ($startPieces) {
    foreach ($startPiece in $startPieces) {
        $pieces[[convert]::ToInt16($startPiece[0].ToString())]--
        $sequence.Add($startPiece) | Out-Null
    }
}

# Shape to start with.
if ($sequence) {
    $shape = $sequence[-1]
    $sequence.RemoveAt($sequence.Count - 1)

    # Put it back
    $pieces[[convert]::ToInt16($shape[0].ToString())]++
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

# See if the current sequece will fit in a box, starting empty
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
    [array]$availableOrientations = for ($i = 0; $i -lt $pieces.Count; $i++) {
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

    # Take the piece
    $pieces[([convert]::ToInt16($shape[0].ToString()))]--

    if (Test-Sequence) {
        Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Green
        if ($sequence.Count -eq 17) {
            $solutions.Add(
                [PSCustomObject]@{
                    Sequence = $sequence -join ' '
                    Counter  = $counter
                    Date     = Get-Date
                }
            ) | Out-Null
            $solutions | Export-Csv -NoTypeInformation -Append -Encoding ASCII -Path .\solutions.csv
            Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}{5}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' '), (Get-Date)) -ForegroundColor Green
            $sequence.RemoveAt($sequence.Count - 1)
        } else {
            $shape = '00000'
        }
    } else {
        Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Yellow
        $sequence.RemoveAt($sequence.Count - 1)
    }

    do {
        # Put it back
        $pieces[[convert]::ToInt16($shape[0].ToString())]++
        Write-Host ("{0,3}{1,12}{2,4}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Red

        if (-not ($next = Get-NextPiece $shape)) {
            $shape = $sequence[-1]
            $sequence.RemoveAt($sequence.Count - 1)
        }
    } until ($next -or ($sequence.Count -eq 0 -and $shape -eq $orientations[-1][-1]))

    $shape = $next
}
$sw.Elapsed.TotalSeconds
