# Eliminate Functions

###### Configuration Here ######

# Number of sequences tried
[uint64]$counter = 0

# Collection of solutions found
$solutions = [System.Collections.ArrayList]::new()

# Sequence to begin with. Start with empty string to begin at the beginning.
$startSequence = ''
#$startSequence = '421 111 142'

# Dimensions of the box
$Xsize = 5
$Ysize = 5
$Zsize = 5

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
$box = New-Object 'object[,,]' $Xsize, $Ysize, $Zsize

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

# See if the current sequence will fit in a box, starting empty
function Test-Sequence {
    # Clear the box
    for ($z = 0; $z -lt $Zsize; $z++) {
        for ($y = 0; $y -lt $Ysize; $y++) {
            for ($x = 0; $x -lt $Xsize; $x++) {
                $box[$x, $y, $z] = 0
            }
        }    
    }

    foreach ($piece in $sequence) {
        # Find an empty square
        for ($z = 0; $z -lt $Zsize; $z++) {
            for ($y = 0; $y -lt $Ysize; $y++) {
                for ($x = 0; $x -lt $Xsize; $x++) {
                    if ($box[$x, $y, $z] -eq 0) {
                        $ex, $ey, $ez = $x, $y, $z
                        $X = $Xsize
                        $y = $Ysize
                        $z = $Zsize
                    }
                }
            }
        }

        # Get the coordinates of the piece
        $px = [int][string]$piece[0]
        $py = [int][string]$piece[1]
        $pz = [int][string]$piece[2]

        # Put the piece in the box once cube at a time
        for ($z = $ez; $z -lt $ez + $pz; $z++) {
            for ($y = $ey; $y -lt $ey + $py; $y++) {
                for ($x = $ex; $x -lt $ex + $px; $x++) {
                    if ($box[$x, $y, $z] -eq 0) {
                        $box[$x, $y, $z] = 1
                    } else {
                        # It doesn't fit
                        return $false
                    }
                }
            }
        }
    }
    # All pieces fit so the sequence is valid
    return $true
}

$sw = [System.Diagnostics.Stopwatch]::new()
$sw.Start()

Get-Date; while ($shape) {
    $counter++
#    if (-not ($counter % 10)) {Read-Host 'Pausing'}
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

        [array]$availableOrientations =  for ($i = 0; $i -lt $pieces.Count; $i++) {
            if ($pieces[$i] -ne 0) {
                $orientations[$i]
            }
        }
        
        $nextPiece = $availableOrientations.IndexOf($shape) + 1
        $next = $availableOrientations[$nextPiece]

        if (-not $next) {
            $shape = $sequence[-1]
            $sequence.RemoveAt($sequence.Count - 1)
        }
    } until ($next -or ($sequence.Count -eq 0 -and $shape -eq $orientations[-1][-1]))

    $shape = $next
}
$sw.Elapsed.TotalSeconds
