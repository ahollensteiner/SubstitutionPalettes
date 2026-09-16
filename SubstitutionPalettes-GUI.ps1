<#
.SYNOPSIS
    Einfaches Fenster-Tool (ohne Kommandozeile) zum Aktualisieren von
    SubstitutionPalettes.xml - fuer Anwender, die das Skript nicht ueber
    PowerShell-Parameter bedienen moechten.

.DESCRIPTION
    Zeigt ein Fenster mit:
      1) einem Button zum Auswaehlen der SubstitutionPalettes.xml (Windows-
         Datei-Dialog). Es wird geprueft, dass die gewaehlte Datei EXAKT
         "SubstitutionPalettes.xml" heisst (Gross-/Kleinschreibung egal) -
         bei jedem anderen Dateinamen erscheint eine Fehlermeldung und die
         Auswahl wird verworfen.
      2) einem "Start"-Button, der die eigentliche Verarbeitung anstoesst.
         Verzeichnis fuer PNG-Bilder, Freistellungs-Kopien ("IMAGE_frei")
         UND die Backup-Datei ("..._BACKUP.xml") ist automatisch der Ordner,
         in dem die gewaehlte SubstitutionPalettes.xml liegt.
      3) einem Log-Fenster, das die Meldungen des eigentlichen Skripts
         (Update-SubstitutionPalettes.ps1, im selben Ordner wie dieses
         GUI-Skript) anzeigt.

    Dieses GUI-Skript enthaelt selbst KEINE Verarbeitungslogik - es ruft
    lediglich Update-SubstitutionPalettes.ps1 mit den passenden Parametern
    auf. Alle Sicherheitsregeln (Backup, Namensschutz, Dateinamen-Pruefung
    usw.) gelten dadurch unveraendert; siehe die Kommentare dort.

    Fuer erfahrene Anwender, die einzelne Optionen (Toleranz, Schriftart,
    ausgeschlossene PipeLines-Klassen usw.) anpassen wollen, bleibt
    Update-SubstitutionPalettes.ps1 direkt per Kommandozeile mit allen
    Parametern nutzbar - dieses GUI deckt bewusst nur den Standardfall ab.

.EXAMPLE
    .\SubstitutionPalettes-GUI.ps1
    (Doppelklick im Explorer funktioniert ebenfalls, siehe Hinweis in der
    Projekt-Dokumentation zur PowerShell-Ausfuehrungsrichtlinie.)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ExpectedFileName = "SubstitutionPalettes.xml"
$EnginePath = Join-Path $PSScriptRoot "Update-SubstitutionPalettes.ps1"

# ---------------------------------------------------------------------------
# Fenster und Steuerelemente aufbauen
# ---------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "SubstitutionPalettes - Bilder aktualisieren"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(700, 560)
$form.MinimumSize = New-Object System.Drawing.Size(560, 400)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$lblStep1 = New-Object System.Windows.Forms.Label
$lblStep1.Text = "1. SubstitutionPalettes.xml auswaehlen:"
$lblStep1.Location = New-Object System.Drawing.Point(15, 15)
$lblStep1.AutoSize = $true
$lblStep1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(15, 40)
$txtPath.Size = New-Object System.Drawing.Size(540, 24)
$txtPath.ReadOnly = $true
$txtPath.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Durchsuchen..."
$btnBrowse.Location = New-Object System.Drawing.Point(565, 38)
$btnBrowse.Size = New-Object System.Drawing.Size(110, 28)
$btnBrowse.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$lblFolderInfo = New-Object System.Windows.Forms.Label
$lblFolderInfo.Text = "Es wurde noch keine Datei ausgewaehlt."
$lblFolderInfo.Location = New-Object System.Drawing.Point(15, 70)
$lblFolderInfo.AutoSize = $true
$lblFolderInfo.ForeColor = [System.Drawing.Color]::DimGray
$lblFolderInfo.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$lblStep2 = New-Object System.Windows.Forms.Label
$lblStep2.Text = "2. Verarbeitung starten:"
$lblStep2.Location = New-Object System.Drawing.Point(15, 105)
$lblStep2.AutoSize = $true
$lblStep2.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start"
$btnStart.Location = New-Object System.Drawing.Point(15, 130)
$btnStart.Size = New-Object System.Drawing.Size(160, 36)
$btnStart.Enabled = $false
$btnStart.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Bereit."
$lblStatus.Location = New-Object System.Drawing.Point(190, 138)
$lblStatus.AutoSize = $true
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Protokoll:"
$lblLog.Location = New-Object System.Drawing.Point(15, 178)
$lblLog.AutoSize = $true
$lblLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(15, 202)
$txtLog.Size = New-Object System.Drawing.Size(660, 300)
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Schliessen"
$btnClose.Location = New-Object System.Drawing.Point(565, 510)
$btnClose.Size = New-Object System.Drawing.Size(110, 30)
$btnClose.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

$form.Controls.AddRange(@($lblStep1, $txtPath, $btnBrowse, $lblFolderInfo, $lblStep2, $btnStart, $lblStatus, $lblLog, $txtLog, $btnClose))

# ---------------------------------------------------------------------------
# Logik
# ---------------------------------------------------------------------------
$script:SelectedXmlPath = $null

$btnBrowse.Add_Click({
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title = "SubstitutionPalettes.xml auswaehlen"
        $dlg.Filter = "SubstitutionPalettes.xml|SubstitutionPalettes.xml|Alle XML-Dateien (*.xml)|*.xml|Alle Dateien (*.*)|*.*"
        $dlg.FileName = $ExpectedFileName
        $dlg.CheckFileExists = $true
        if (Test-Path $PSScriptRoot) { $dlg.InitialDirectory = $PSScriptRoot }

        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $chosenName = [System.IO.Path]::GetFileName($dlg.FileName)
            if (-not [string]::Equals($chosenName, $ExpectedFileName, [System.StringComparison]::OrdinalIgnoreCase)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Die gewaehlte Datei heisst '$chosenName'.`n`nDieses Tool funktioniert ausschliesslich mit einer Datei namens '$ExpectedFileName'. Bitte waehlen Sie die richtige Konfigurationsdatei aus.",
                    "Falscher Dateiname",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }

            $script:SelectedXmlPath = $dlg.FileName
            $txtPath.Text = $dlg.FileName
            $lblFolderInfo.Text = "Ordner (hier werden auch Backup, PNG-Bilder und IMAGE_frei erwartet/abgelegt): " + (Split-Path $dlg.FileName -Parent)
            $btnStart.Enabled = $true
            $lblStatus.Text = "Bereit."
            $lblStatus.ForeColor = [System.Drawing.Color]::Black
        }
    })

$btnStart.Add_Click({
        if (-not $script:SelectedXmlPath) { return }

        if (-not (Test-Path $EnginePath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Die Datei 'Update-SubstitutionPalettes.ps1' wurde nicht im selben Ordner wie dieses Tool gefunden:`n$EnginePath",
                "Skript nicht gefunden",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return
        }

        $btnStart.Enabled = $false
        $btnBrowse.Enabled = $false
        $txtLog.Clear()
        $lblStatus.Text = "Laeuft..."
        $lblStatus.ForeColor = [System.Drawing.Color]::DarkOrange
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        [System.Windows.Forms.Application]::DoEvents()

        $imageDir = Split-Path $script:SelectedXmlPath -Parent

        try {
            $output = & $EnginePath -XmlPath $script:SelectedXmlPath -ImageDir $imageDir *>&1
            foreach ($line in $output) {
                $txtLog.AppendText("$line`r`n")
            }
            $lblStatus.Text = "Fertig."
            $lblStatus.ForeColor = [System.Drawing.Color]::ForestGreen
            [System.Windows.Forms.MessageBox]::Show(
                "Verarbeitung abgeschlossen. Details siehe Protokoll.",
                "Fertig",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        }
        catch {
            $txtLog.AppendText("FEHLER: $($_.Exception.Message)`r`n")
            $lblStatus.Text = "Fehler."
            $lblStatus.ForeColor = [System.Drawing.Color]::Red
            [System.Windows.Forms.MessageBox]::Show(
                $_.Exception.Message,
                "Fehler bei der Verarbeitung",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
        finally {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            $btnStart.Enabled = $true
            $btnBrowse.Enabled = $true
        }
    })

$btnClose.Add_Click({ $form.Close() })

[System.Windows.Forms.Application]::Run($form)
