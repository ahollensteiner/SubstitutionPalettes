<#
.SYNOPSIS
    Pflegt die <ImageData>-Eintraege in SubstitutionPalettes.xml.

.DESCRIPTION
    Ablauf pro Durchlauf:

    1) BACKUP: Die Ziel-XML wird zuerst 1:1 als "<Name>_BACKUP.xml" im selben
       Ordner gesichert. Eine bereits vorhandene Sicherungskopie wird dabei
       ueberschrieben (kein Versionieren, immer nur die eine juengste Sicherung).

    2) FREISTELLEN: Von jeder PNG-Datei im Bildordner wird eine Kopie mit der
       Namenserweiterung "_FREI" erzeugt, deren (weisser) Hintergrund transparent
       gemacht wird. Diese Kopien werden im Unterordner "IMAGE_frei" abgelegt.
       Die Original-PNGs bleiben unveraendert; fuer das Einbetten in die XML
       wird weiterhin das Original-PNG verwendet, NICHT die freigestellte Kopie.

    3) PIPELINES-TEXTBILDER: Fuer alle <Class>-Elemente innerhalb von
       <BaseClass name="PipeLines"> - AUSSER den Klassen 'Jacketed',
       'NewPrimary', 'NewSecondary', 'Primary', 'Secondary' (Parameter
       -PipeLineExcluded) - wird KEIN PNG-File mehr benoetigt. Stattdessen
       erzeugt das Skript automatisch ein 90x90-Bild (Parameter -TextImageSize),
       das den Klassennamen als schwarzen Text auf weissem Grund zeigt (Muster:
       ARG, LM_ETOH), und traegt dessen Base64-Code als <ImageData> ein.

       Schriftgroessen-Regel:
         - Namen mit 1 bis 3 Zeichen erhalten ALLE dieselbe Schriftgroesse.
           Diese Basisgroesse wird einmalig so berechnet, dass ein 3-stelliger
           Referenztext (Parameter -TextImageCalibrationText, Standard "MMM")
           die verfuegbare Bildbreite (Bildgroesse minus 2x Rand) gerade noch
           ausfuellt, ohne ueberzulaufen - bewusst mit schmalem Rand fuer
           maximale Lesbarkeit.
         - Namen mit 4 bis 7 Zeichen werden mit einer fuer den jeweiligen Namen
           individuell verkleinerten Schriftgroesse gerendert, damit der Text
           trotz der zusaetzlichen Zeichen noch vollstaendig ins Bild passt.

       Die ausgeschlossenen Klassen (Jacketed usw.) werden NICHT angefasst -
       weder durch diesen Schritt noch durch Schritt 4 (falls zufaellig eine
       gleichnamige PNG-Datei existieren sollte).

    4) EINBETTEN (Datei-basiert, fuer alle UEBRIGEN BaseClasses): Fuer jede
       PNG-Datei im Bildordner wird der Dateiname (ohne Endung) als Class-Name
       interpretiert und der Base64-Code der PNG-Datei in das passende
       <Class name="..."> Element eingetragen:

         - Existiert die Class als (selbstschliessendes oder leeres) Element
           ohne <ImageData>, wird <ImageData> ergaenzt.
         - Existiert bereits ein <ImageData>-Element, wird dessen Inhalt
           aktualisiert (z.B. wenn sich das PNG geaendert hat).
         - Wird kein passendes <Class name="..."> Element gefunden, wird eine
           Warnung ausgegeben und die Datei uebersprungen.
         - Gehoert eine PNG-Datei zu einer Class innerhalb von "PipeLines",
           wird sie hier IGNORIERT (mit Hinweis), da "PipeLines" ausschliess-
           lich durch Schritt 3 verwaltet wird.

    SICHERHEITSGARANTIE: Das Skript aendert niemals den Wert eines "name"-
    Attributs in der XML. Der Name (aus Dateiname oder aus der XML selbst
    gelesen) dient ausschliesslich dazu, das passende <Class name="..."> zu
    SUCHEN (per exaktem, gross-/kleinschreibungssensitivem Textvergleich).
    Beim Einfuegen von <ImageData> wird das bereits vorhandene "name=..."-
    Attribut unveraendert aus der XML uebernommen (nicht neu zusammengebaut) -
    es wird also nie umbenannt, hinzugefuegt oder entfernt.

    Stimmt ein PNG-Dateiname (Schritt 4) mit keinem Klassennamen in der XML
    ueberein, wird eine Warnung ausgegeben und die Datei uebersprungen (es
    werden keine neuen Class-Eintraege angelegt und keine bestehenden umbe-
    nannt). Weicht nur die Gross-/Kleinschreibung ab (z.B. "arg.png" statt
    "ARG.png"), wird das explizit als Hinweis mit ausgegeben.

    DATEINAMEN-PRUEFUNG: Das Skript bricht sofort mit einer Fehlermeldung ab,
    wenn -XmlPath nicht auf eine Datei zeigt, die exakt "SubstitutionPalettes.xml"
    heisst (Gross-/Kleinschreibung wird ignoriert). Das verhindert, dass das
    Skript versehentlich auf einer falschen/fremden XML-Datei laeuft - egal ob
    ueber die Kommandozeile oder ueber das GUI-Tool (SubstitutionPalettes-GUI.ps1)
    aufgerufen.

    Freistellungs-Algorithmus (Schritt 2): einfacher, verlustfreier Chroma-Key.
    Es wird die Farbe des Eckpixels (0,0) als Hintergrundfarbe angenommen.
    Jedes Pixel, das innerhalb einer Toleranz (Parameter -Tolerance, Standard
    10) zu dieser Farbe liegt, wird vollstaendig transparent geschaltet; alle
    anderen Pixel bleiben in Farbe UND Deckkraft exakt unveraendert. Bewusst
    KEINE Alpha-Rueckrechnung/Kantengelaettung: ein Verfahren, das die Deck-
    kraft aus dem "Weissanteil" eines Pixels schaetzt, wuerde voll deckende,
    aber nicht rein weisse Flaechen (z.B. ein deckendes Grau) faelschlich in
    halbtransparente Pixel mit verschobenem Farbton verwandeln. Die hier
    gewaehlte Methode kann daher an Kanten einen minimal sichtbaren hellen
    Saum hinterlassen, veraendert aber nie eine echte, volldeckende
    Vordergrundfarbe.

    Das Einbetten in die XML (Schritte 3 und 4) ist ein reines Text-
    Ersetzungsverfahren (kein XML-DOM-Reload/Save), damit die bestehende
    Formatierung/Einrueckung der grossen XML-Datei erhalten bleibt.

.PARAMETER XmlPath
    Pfad zur SubstitutionPalettes.xml. Standard: Datei im selben Ordner wie dieses Skript.

.PARAMETER ImageDir
    Ordner mit den PNG-Bildern (fuer Schritt 2 und 4). Standard: Ordner dieses Skripts.

.PARAMETER FreiDir
    Zielordner fuer die freigestellten "_FREI"-Kopien. Standard: Unterordner
    "IMAGE_frei" innerhalb von ImageDir.

.PARAMETER SkipBackup
    Wenn gesetzt, wird kein XML-Backup erstellt.

.PARAMETER SkipFreistellen
    Wenn gesetzt, werden keine freigestellten Bildkopien erzeugt.

.PARAMETER Tolerance
    Toleranz (0-255) pro Farbkanal fuer den Chroma-Key beim Freistellen.
    Standard: 10. Hoeher = grosszuegiger (mehr Pixel werden als Hintergrund
    erkannt), aber auch groesseres Risiko, echte helle Vordergrundfarben mit
    zu entfernen.

.PARAMETER PipeLineExcluded
    Klassennamen innerhalb von BaseClass "PipeLines", die NIE angefasst werden
    (weder Textbild noch PNG-Einbettung). Standard: Jacketed, NewPrimary,
    NewSecondary, Primary, Secondary.

.PARAMETER SkipPipeLineTextImages
    Wenn gesetzt, wird Schritt 3 (PipeLines-Textbilder) uebersprungen.

.PARAMETER TextImageSize
    Kantenlaenge (Pixel) der generierten quadratischen Textbilder. Standard: 90.

.PARAMETER TextImageMarginPx
    Rand (Pixel) links/rechts, der beim Textbild von der Schrift nicht
    verwendet wird. Standard: 4.

.PARAMETER TextImageFont
    Schriftname fuer die generierten Textbilder. Standard: "Arial".

.PARAMETER TextImageFontStyle
    "Regular" oder "Bold". Standard: "Bold". Fett verbessert die Lesbarkeit
    deutlich, wenn AutoCAD Plant 3D das Bild in der Palette stark verkleinert
    anzeigt - bei "Regular" verschwimmen duenne Strichstaerken beim Verkleinern
    sichtbar staerker (per Downscale-Vergleich getestet).

.PARAMETER TextImageCalibrationText
    3-stelliger Referenztext, mit dem die einheitliche Basis-Schriftgroesse
    fuer Namen mit 1-3 Zeichen kalibriert wird (siehe Beschreibung). Standard:
    "MMM" (bewusst ein breiter Buchstabe, damit auch breite 3-stellige Namen
    nicht ueberlaufen).

.EXAMPLE
    .\Update-SubstitutionPalettes.ps1

.EXAMPLE
    .\Update-SubstitutionPalettes.ps1 -ImageDir "C:\Bilder\Neue"
#>
param(
    [string]$XmlPath = (Join-Path $PSScriptRoot "SubstitutionPalettes.xml"),
    [string]$ImageDir = $PSScriptRoot,
    [string]$FreiDir = (Join-Path $ImageDir "IMAGE_frei"),
    [switch]$SkipBackup,
    [switch]$SkipFreistellen,
    [int]$Tolerance = 10,
    [string[]]$PipeLineExcluded = @('Jacketed', 'NewPrimary', 'NewSecondary', 'Primary', 'Secondary'),
    [switch]$SkipPipeLineTextImages,
    [int]$TextImageSize = 90,
    [int]$TextImageMarginPx = 4,
    [string]$TextImageFont = "Arial",
    [ValidateSet('Regular', 'Bold')]
    [string]$TextImageFontStyle = 'Bold',
    [string]$TextImageCalibrationText = "MMM"
)

Add-Type -AssemblyName System.Drawing -ErrorAction Stop
$textImageFontStyleValue = [System.Drawing.FontStyle]::$TextImageFontStyle

if (-not (Test-Path $XmlPath)) {
    throw "XML-Datei nicht gefunden: $XmlPath"
}

# Sicherheitscheck: Das Skript darf nur auf einer Datei arbeiten, die exakt
# "SubstitutionPalettes.xml" heisst (Gross-/Kleinschreibung wird ignoriert,
# wie unter Windows ueblich) - unabhaengig davon, ob der Pfad manuell per
# Kommandozeile oder ueber das GUI-Tool uebergeben wurde.
$expectedFileName = "SubstitutionPalettes.xml"
$actualFileName = [System.IO.Path]::GetFileName($XmlPath)
if (-not [string]::Equals($actualFileName, $expectedFileName, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Ungueltiger Dateiname: '$actualFileName'. Dieses Skript darf nur mit einer Datei namens '$expectedFileName' verwendet werden."
}

# ---------------------------------------------------------------------------
# Schritt 1: Backup der XML (ueberschreibt eine vorhandene Sicherungskopie)
# ---------------------------------------------------------------------------
if (-not $SkipBackup) {
    $xmlItem = Get-Item -LiteralPath $XmlPath
    $backupPath = Join-Path $xmlItem.DirectoryName ($xmlItem.BaseName + "_BACKUP" + $xmlItem.Extension)
    Copy-Item -LiteralPath $XmlPath -Destination $backupPath -Force
    Write-Host "Backup erstellt/ueberschrieben: $backupPath"
}

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$content = [System.IO.File]::ReadAllText($XmlPath, $utf8Bom)

$images = @(Get-ChildItem -Path $ImageDir -Filter *.png -File -ErrorAction SilentlyContinue)
if (-not $images) {
    Write-Warning "Keine PNG-Dateien in '$ImageDir' gefunden (Schritt 2 und 4 werden uebersprungen)."
}

# ---------------------------------------------------------------------------
# Schritt 2: Freigestellte ("_FREI") Kopien mit transparentem Hintergrund
# ---------------------------------------------------------------------------
function ConvertTo-TransparentPng {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [int]$Tolerance
    )

    Add-Type -AssemblyName System.Drawing -ErrorAction Stop

    $src = [System.Drawing.Bitmap]::FromFile($SourcePath)
    try {
        $w = $src.Width
        $h = $src.Height
        $bg = $src.GetPixel(0, 0)

        $dst = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            for ($y = 0; $y -lt $h; $y++) {
                for ($x = 0; $x -lt $w; $x++) {
                    $p = $src.GetPixel($x, $y)
                    $dr = [Math]::Abs([int]$p.R - [int]$bg.R)
                    $dg = [Math]::Abs([int]$p.G - [int]$bg.G)
                    $db = [Math]::Abs([int]$p.B - [int]$bg.B)

                    if ($dr -le $Tolerance -and $dg -le $Tolerance -and $db -le $Tolerance) {
                        # Innerhalb der Toleranz zur Eckfarbe -> Hintergrund -> transparent.
                        $dst.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                    }
                    else {
                        # Ausserhalb der Toleranz -> echte Vordergrundfarbe -> unveraendert uebernehmen.
                        $dst.SetPixel($x, $y, $p)
                    }
                }
            }
            $dst.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $dst.Dispose()
        }
        return $bg
    }
    finally {
        $src.Dispose()
    }
}

if (-not $SkipFreistellen -and $images) {
    if (-not (Test-Path $FreiDir)) {
        New-Item -ItemType Directory -Path $FreiDir -Force | Out-Null
    }
    foreach ($img in $images) {
        $freiName = [System.IO.Path]::GetFileNameWithoutExtension($img.Name) + "_FREI.png"
        $freiPath = Join-Path $FreiDir $freiName
        $bg = ConvertTo-TransparentPng -SourcePath $img.FullName -DestPath $freiPath -Tolerance $Tolerance
        Write-Host "Freigestellt: $($img.Name) -> $freiPath (Hintergrundfarbe erkannt: R=$($bg.R) G=$($bg.G) B=$($bg.B), Toleranz=$Tolerance)"
    }
}

# ---------------------------------------------------------------------------
# Gemeinsame Hilfsfunktion (Schritt 3 + 4): <ImageData> in einem Class-Element
# setzen/aktualisieren, OHNE das "name="..."-Attribut anzufassen.
# ---------------------------------------------------------------------------
function Set-ClassImageData {
    param(
        [string]$Text,
        [string]$ClassName,
        [string]$Base64
    )

    $escaped = [regex]::Escape($ClassName)

    # Fall A: <Class name="X" ...> <ImageData>...</ImageData> </Class> bereits vorhanden.
    $withImagePattern = '(<Class name="' + $escaped + '"[^>]*>\s*<ImageData>)[^<]*(</ImageData>)'

    # Fall B: <Class name="X" .../> ODER <Class name="X" ...></Class> (leer, ohne ImageData).
    # Gruppe 2 = unveraendertes "name="...""-Attribut, Gruppe 3 = alle weiteren Attribute.
    $emptyPattern = '(?m)^([ \t]*)<Class (name="' + $escaped + '")((?:\s+[A-Za-z:_-]+="[^"]*")*)\s*(?:/>|>\s*</Class>)[ \t]*\r?$'

    if ([regex]::IsMatch($Text, $withImagePattern)) {
        $b64ForClosure = $Base64
        $newText = [regex]::Replace($Text, $withImagePattern, { param($m) $m.Groups[1].Value + $b64ForClosure + $m.Groups[2].Value }, 1)
        if ($newText -ne $Text) {
            return [PSCustomObject]@{ Text = $newText; Status = 'Updated' }
        }
        return [PSCustomObject]@{ Text = $Text; Status = 'Unchanged' }
    }
    elseif ([regex]::IsMatch($Text, $emptyPattern)) {
        $b64ForClosure = $Base64
        $newText = [regex]::Replace($Text, $emptyPattern, {
                param($m)
                $indent = $m.Groups[1].Value
                $nameAttr = $m.Groups[2].Value   # unveraendert aus der XML, z.B. name="ARG"
                $restAttrs = $m.Groups[3].Value  # unveraendert aus der XML, z.B. GraphicalStyleName="ARG"
                "$indent<Class $nameAttr$restAttrs>`r`n$indent  <ImageData>$b64ForClosure</ImageData>`r`n$indent</Class>"
            }, 1)
        return [PSCustomObject]@{ Text = $newText; Status = 'Added' }
    }
    else {
        return [PSCustomObject]@{ Text = $Text; Status = 'NotFound' }
    }
}

# ---------------------------------------------------------------------------
# Schritt 3: PipeLines-Textbilder (Klassenname als Text, kein PNG erforderlich)
# ---------------------------------------------------------------------------
function New-ClassNameImageBase64 {
    param(
        [string]$Name,
        [int]$Size,
        [int]$MarginPx,
        [string]$FontFamilyName,
        [System.Drawing.FontStyle]$FontStyle,
        [string]$CalibrationText
    )

    Add-Type -AssemblyName System.Drawing -ErrorAction Stop

    $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        # "AntiAliasGridFit" (nicht ungehintetes "AntiAlias"): GridFit rundet
        # die Glyphen-Position auf das Pixelraster, BEVOR geglaettet wird. Das
        # macht das Rendering reproduzierbar - mit ungehintetem AntiAlias hat
        # sich gezeigt, dass GDI+ je nach internem Cache-Zustand des Prozesses
        # (abhaengig davon, wie viele/welche Fonts zuvor im selben Lauf
        # gemessen/gezeichnet wurden) bei identischer Schriftgroesse ein paar
        # Kanten-Pixel ANDERS antialiast rendert - das Skript meldete dadurch
        # bei manchen Klassen faelschlich "Aktualisiert" statt "Unveraendert",
        # obwohl sich nichts inhaltlich geaendert hatte.
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $g.Clear([System.Drawing.Color]::White)

        $drawableWidth = $Size - 2 * $MarginPx

        # Basisgroesse (fuer Namen mit 1-3 Zeichen): per Bisektion so bestimmen,
        # dass CalibrationText (3 Zeichen) die verfuegbare Breite gerade noch
        # ausfuellt, ohne zu ueberlaufen.
        $lo = 1.0; $hi = 500.0
        for ($i = 0; $i -lt 40; $i++) {
            $mid = ($lo + $hi) / 2.0
            $f = New-Object System.Drawing.Font($FontFamilyName, [float]$mid, $FontStyle, [System.Drawing.GraphicsUnit]::Pixel)
            $w = $g.MeasureString($CalibrationText, $f).Width
            $f.Dispose()
            if ($w -le $drawableWidth) { $lo = $mid } else { $hi = $mid }
        }
        $baseSize = $lo

        if ($Name.Length -le 3) {
            $fontSize = $baseSize
        }
        else {
            # 4-7 Zeichen: ausgehend von der Basisgroesse individuell verkleinern,
            # bis der tatsaechliche Name in die verfuegbare Breite passt.
            $lo2 = 1.0; $hi2 = $baseSize
            for ($i = 0; $i -lt 40; $i++) {
                $mid2 = ($lo2 + $hi2) / 2.0
                $f = New-Object System.Drawing.Font($FontFamilyName, [float]$mid2, $FontStyle, [System.Drawing.GraphicsUnit]::Pixel)
                $w = $g.MeasureString($Name, $f).Width
                $f.Dispose()
                if ($w -le $drawableWidth) { $lo2 = $mid2 } else { $hi2 = $mid2 }
            }
            $fontSize = $lo2
        }

        $font = New-Object System.Drawing.Font($FontFamilyName, [float]$fontSize, $FontStyle, [System.Drawing.GraphicsUnit]::Pixel)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rect = New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)
        $g.DrawString($Name, $font, [System.Drawing.Brushes]::Black, $rect, $sf)
        $font.Dispose()
        $sf.Dispose()

        $ms = New-Object System.IO.MemoryStream
        try {
            $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            return [Convert]::ToBase64String($ms.ToArray())
        }
        finally {
            $ms.Dispose()
        }
    }
    finally {
        $g.Dispose()
        $bmp.Dispose()
    }
}

$pltAdded = 0
$pltUpdated = 0
$pltUnchanged = 0
$pipeLineClassNames = @()

$pipeLineBlockPattern = '(?s)(<BaseClass name="PipeLines">)(.*?)(</BaseClass>)'
$pipeLineBlockMatch = [regex]::Match($content, $pipeLineBlockPattern)

if (-not $pipeLineBlockMatch.Success) {
    Write-Warning "BaseClass 'PipeLines' nicht in der XML gefunden - Schritt 3 (Textbilder) uebersprungen."
}
else {
    $pipeLineClassNames = [regex]::Matches($pipeLineBlockMatch.Groups[2].Value, '<Class\s+name="([^"]+)"') |
        ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

    if (-not $SkipPipeLineTextImages) {
        $body = $pipeLineBlockMatch.Groups[2].Value
        foreach ($cn in $pipeLineClassNames) {
            if ($PipeLineExcluded -contains $cn) {
                Write-Host "PipeLines: '$cn' ist ausgeschlossen - bleibt unveraendert."
                continue
            }
            $b64 = New-ClassNameImageBase64 -Name $cn -Size $TextImageSize -MarginPx $TextImageMarginPx -FontFamilyName $TextImageFont -FontStyle $textImageFontStyleValue -CalibrationText $TextImageCalibrationText
            $result = Set-ClassImageData -Text $body -ClassName $cn -Base64 $b64
            $body = $result.Text
            switch ($result.Status) {
                'Added' { Write-Host "PipeLines-Textbild hinzugefuegt: $cn"; $pltAdded++ }
                'Updated' { Write-Host "PipeLines-Textbild aktualisiert: $cn"; $pltUpdated++ }
                'Unchanged' { Write-Host "PipeLines-Textbild unveraendert: $cn"; $pltUnchanged++ }
                'NotFound' { Write-Warning "PipeLines: Class '$cn' unerwartet nicht gefunden - uebersprungen." }
            }
        }
        $content = $content.Substring(0, $pipeLineBlockMatch.Index) +
        $pipeLineBlockMatch.Groups[1].Value + $body + $pipeLineBlockMatch.Groups[3].Value +
        $content.Substring($pipeLineBlockMatch.Index + $pipeLineBlockMatch.Length)
    }
}

# ---------------------------------------------------------------------------
# Schritt 4: Base64 aus den ORIGINAL-PNGs in die XML einbetten (alle anderen
# BaseClasses; PipeLines-Klassen werden hier bewusst ignoriert, siehe oben).
# ---------------------------------------------------------------------------

# Alle in der XML vorhandenen Klassennamen einsammeln - nur zur Diagnose
# (z.B. um bei Gross-/Kleinschreibungs-Abweichungen einen Hinweis zu geben).
# Wird NICHT zum Schreiben verwendet.
$allClassNames = [regex]::Matches($content, '<Class\s+name="([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Select-Object -Unique

$added = 0
$updated = 0
$unchanged = 0
$warnings = 0

foreach ($img in $images) {
    $expectedName = [System.IO.Path]::GetFileNameWithoutExtension($img.Name)

    if ($pipeLineClassNames -contains $expectedName) {
        Write-Host "Ignoriert: $($img.Name) (Class '$expectedName' gehoert zu PipeLines und wird ausschliesslich per Textbild verwaltet, siehe Schritt 3)"
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($img.FullName)
    $base64 = [Convert]::ToBase64String($bytes)

    $result = Set-ClassImageData -Text $content -ClassName $expectedName -Base64 $base64
    $content = $result.Text

    switch ($result.Status) {
        'Added' { Write-Host "Hinzugefuegt: $expectedName (neues ImageData eingefuegt)"; $added++ }
        'Updated' { Write-Host "Aktualisiert: $expectedName (bestehendes ImageData ersetzt)"; $updated++ }
        'Unchanged' { Write-Host "Unveraendert: $expectedName (ImageData bereits aktuell)"; $unchanged++ }
        'NotFound' {
            $ciMatch = $allClassNames | Where-Object { $_.ToLowerInvariant() -eq $expectedName.ToLowerInvariant() } | Select-Object -First 1
            if ($ciMatch) {
                Write-Warning "PNG '$($img.Name)' -> Name '$expectedName' stimmt NICHT exakt (Gross-/Kleinschreibung) mit dem XML-Klassennamen '$ciMatch' ueberein. Datei uebersprungen - Klassenname in der XML wurde NICHT geaendert. Bitte PNG oder Class-Namen angleichen."
            }
            else {
                Write-Warning "PNG '$($img.Name)' -> Kein <Class name=`"$expectedName`"> Element in der XML gefunden. Datei uebersprungen - es wurde kein neuer Eintrag angelegt und kein bestehender Name geaendert."
            }
            $warnings++
        }
    }
}

[System.IO.File]::WriteAllText($XmlPath, $content, $utf8Bom)

Write-Host ""
Write-Host "PipeLines-Textbilder: Hinzugefuegt: $pltAdded, Aktualisiert: $pltUpdated, Unveraendert: $pltUnchanged"
Write-Host "PNG-Einbettung (uebrige BaseClasses): Hinzugefuegt: $added, Aktualisiert: $updated, Unveraendert: $unchanged, Warnungen (uebersprungen): $warnings"
