$imagesPath = "images"
$htmlFile = "index.html"

Write-Output "=== Pre-commit: Update Alt Art numbers ==="

# Get staged files only
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

$newNumbers = @()
foreach ($file in $stagedFiles) {
    if ($file -match "^$imagesPath/(\d+)a\.png$") {
        $newNumbers += [int]$matches[1]
    }
}

if ($newNumbers.Count -eq 0) {
    Write-Output "No new matching images staged."
    exit 0
}

$html = Get-Content $htmlFile -Raw

# Multiline-safe regex pattern
# Pattern to match the entire array, including any whitespace/newlines
$pattern = "const\s+alts\s*=\s*\[(.*?)\]"

# Use Singleline mode so . matches newlines
$match = [regex]::Match($html, $pattern, "Singleline")

if ($match.Success) {
    
    $existingString = $match.Groups[1].Value

    # Remove trailing commas, split on comma, trim whitespace
    $existingNumbers = $existingString -split "," | ForEach-Object {
        $num = $_.Trim()
        if ($num -match "^\d+$") { [int]$num }
    } | Where-Object { $_ -ne $null }

} else {
    Write-Output "ERROR: Could not find 'const alts = [...]' in HTML."

    exit 1
}

# Merge new numbers and remove duplicates
$allNumbers = ($existingNumbers + $newNumbers) | Sort-Object -Unique
$arrayString = ($allNumbers -join ", ")

# Replace array in HTML
$html = [regex]::Replace($html, $pattern, "const alts = [$arrayString];", [System.Text.RegularExpressions.RegexOptions]::Singleline)

# Save and re-stage
Set-Content $htmlFile $html
git add $htmlFile

Write-Output "=== Pre-commit: Alt art numbers updated ==="
