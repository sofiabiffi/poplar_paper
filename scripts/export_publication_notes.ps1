$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    foreach ($stem in @('01_tree_growth','02_weather_and_PAIC','03_cropping_treatment_and_legacy','04_soil_carbon_stocks','06_soc_sequestration')) {
        $source = Join-Path $taskRoot "manuscript/analysis_notes/$stem.docx"
        $output = Join-Path $taskRoot "manuscript/analysis_notes/_qa/publication/$stem"
        New-Item -ItemType Directory -Force -Path $output | Out-Null
        $doc = $word.Documents.Open($source,$false,$true)
        try {
            $doc.ExportAsFixedFormat((Join-Path $output "$stem.pdf"),17)
        } finally { $doc.Close(0) }
        Write-Output "Exported $stem"
    }
} finally { $word.Quit() }
