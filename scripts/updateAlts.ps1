$imagesPath = "images"
$htmlFile = "index.html"

# Get staged files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

# Filter only images like "images/12a.png"
$newNumbers = @()

foreach ($file in $stagedFiles) {
    if ($file -match "^$imagesPath/(\d+)a\.png$") {
        $newNumbers += [int]$matches[1]
    }
}

# If nothing new, exit early
if ($newNumbers.Count -eq 0) {
    Write-Output "No new matching images staged."
    exit 0
}

# Read HTML
$html = Get-Content $htmlFile -Raw

# Extract existing array
if ($html -match "const imageNumbers = \[(.*?)\];") {
    $existingString = $matches[1]

    if ($existingString.Trim() -eq "") {
        $existingNumbers = @()
    } else {
        $existingNumbers = $existingString -split "," | ForEach-Object {
            [int]($_.Trim())
        }
    }
} else {
    Write-Error "Could not find imageNumbers array in HTML"
    exit 1
}

# Merge + remove duplicates
$allNumbers = ($existingNumbers + $newNumbers) | Sort-Object -Unique

# Convert back to string
$arrayString = ($allNumbers -join ", ")

# Replace in HTML
$html = $html -replace "const imageNumbers = \[.*?\];", "const imageNumbers = [$arrayString];"

# Save
Set-Content $htmlFile $html

# Re-stage updated HTML
git add $htmlFile

Write-Output "Updated imageNumbers: $arrayString"