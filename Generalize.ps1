###### Configuration Here ######

# Dimensions of the box
$Xsize = 5
$Ysize = 5
$Zsize = 5

# The counts and shapes of each piece. They need to be in the same order.
$pieces = @(3, 1, 1, 13)
$shapes = @('113', '122', '222', '124')

# Sequence to begin with. Start with empty string to begin at the beginning.
$startSequence = ''

# Number of sequences tried
[uint64]$counter = 0

###### End Configuration ######

# Collection of solutions found
$solutions = [System.Collections.ArrayList]::new()

$totalPieces = ($pieces | Measure -Sum).Sum

# Build the box
$box = New-Object 'object[,,]' $Xsize, $Ysize, $Zsize

function Get-Permutations {
    param(
        [string]$String
    )

    if ($String.Length -le 1) {
        return ,$String
    }

    $permutations = @()
    for ($i = 0; $i -lt $String.Length; $i++) {
        # Pick one character
        $char = $String[$i]

        # Form the remainder of the string without that character
        $rest = $String.Substring(0, $i) + $String.Substring($i + 1)

        # Recurse to get all permutations of the remainder
        foreach ($perm in Get-Permutations -String $rest) {
            $permutations += ($char + $perm)
        }
    }

    return $permutations
}

# Find all possible orientations of the pieces
$orientations = @()
foreach ($shape in $shapes) {
    $permutations = ,(Get-Permutations $shape | Sort-Object -Unique)
    $orientations += $permutations
}

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

        # Get the dimensions of the piece
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
    [void]$sequence.Add($shape) #| Out-Null

    for ($i = 0; $i -lt $orientations.Count; $i++) {
        if ($shape -in $orientations[$i]) {
            $pieces[$i]--
        }
    }

    if (Test-Sequence) {
#        Write-Host ("{0,7}{1,12}{2,$($pieces.Count + 1)}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Green
        if ($sequence.Count -eq $totalPieces) {
            $solution = [PSCustomObject]@{
                Sequence = $sequence -join ' '
                Counter  = $counter
                Date     = Get-Date
            }
            $solutions.Add($solution) | Out-Null
            $solution | Export-Csv -NoTypeInformation -Append -Encoding ASCII -Path .\solutions.csv
            Write-Host ("{0,7}{1,12}{2,$($pieces.Count + 1)}{3,3} {4} {5}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' '), (Get-Date)) -ForegroundColor Green
            $sequence.RemoveAt($sequence.Count - 1)
        } else {
            $shape = '000'
        }
    } else {
#        Write-Host ("{0,7}{1,12}{2,$($pieces.Count + 1)}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Yellow
        $sequence.RemoveAt($sequence.Count - 1)
    }
    do {
        # Put it back
        for ($i = 0; $i -lt $orientations.Count; $i++) {
            if ($shape -in $orientations[$i]) {$pieces[$i]++}
        }
#        Write-Host ("{0,7}{1,12}{2,$($pieces.Count + 1)}{3,3} {4}" -f $solutions.Count, $counter, ($pieces -join ''), $sequence.count, ($sequence -join ' ')) -ForegroundColor Red

        [array]$availableOrientations = for ($i = 0; $i -lt $pieces.Count; $i++) {
            if ($pieces[$i]) {
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
