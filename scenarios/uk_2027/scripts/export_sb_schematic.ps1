param([string]$Root = (Split-Path $PSScriptRoot -Parent))
# Export the user's authoritative schematic without changing the PowerPoint.
$source = Join-Path $Root 'outputs\uk_upscaling_method_SB.pptx'
$ppt = New-Object -ComObject PowerPoint.Application
try {
    $deck = $ppt.Presentations.Open($source, -1, 0, 0)
    $width = [int]([double]$deck.PageSetup.SlideWidth / 72 * 600)
    $height = [int]([double]$deck.PageSetup.SlideHeight / 72 * 600)
    $deck.Slides.Item(1).Export((Join-Path $Root 'figures\uk_scenarios_method_schematic.png'),'PNG',$width,$height)
    $deck.SaveAs((Join-Path $Root 'figures\uk_scenarios_method_schematic.pdf'),32)
    $deck.Close()
} finally { $ppt.Quit() }
