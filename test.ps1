function Uninstall-MyService {
    param ([string]$serviceName)

    $service = $config.serviceInstallation | Where-Object { $_.serviceName -eq $serviceName }

    if ($null -ne $service) {
        $scriptFullPath = Join-Path -Path $PSScriptRoot -ChildPath ($service.folder + "\" + $service.scriptPath)
        # Wechsle in das Verzeichnis, in dem das Deinstallations-Skript liegt
        Set-Location -Path $scriptFullPath

        # Test: Der Deinstallationsbefehl wird mit dem &-Operator ausgeführt, 
        # der es ermöglicht, Befehle oder Skripte aus einer Zeichenkette zu starten
        Write-Host "Executing: $service.removeCommand"
        & $service.removeCommand
    } else {
        Write-Host "Service '$serviceName' wurde nicht gefunden."
    }
}

function Stop-MyProcess {
    param([string]$processName)
    Stop-Process -Name $processName -Force
}

#Nur mit Adminrechten
function Stop-MyService {
    param([string]$serviceName)
    Stop-Service -Name $serviceName -Force
}

function Start-MyProcess {
    param([string]$processName)
    Start-Process $processName
}

function Copy-MyFolder {
    param([string]$source, [string]$destination)
    Copy-Item -Path $source -Destination $destination -Recurse
}

function Add-XmlSnippet {
    param([string]$xmlPath, [string]$xpath, [string]$snippetContent)
    $xml = [xml](Get-Content $xmlPath)
    $newElement = $xml.CreateElement("newElement")
    $newElement.InnerXml = $snippetContent
    $node = $xml.SelectSingleNode($xpath)
    $node.AppendChild($newElement)
    $xml.Save($xmlPath)
}

function Edit-TextFile {
    param([string]$filePath, [string]$searchText, [string]$replaceText)
    (Get-Content $filePath) | ForEach-Object {
        $_ -replace $searchText, $replaceText
    } | Set-Content $filePath
}

function Stop-Elasticsearch {
    $service = $config.services | Where-Object { $_.name -contains "elasticsearch-service" }
    if ($null -ne $service) {
        Stop-MyService -serviceName $service.name
    }
}

function Start-AllServices {
    foreach ($process in $config.services) {
        if ($process.action -eq "start") {
            Start-MyProcess -serviceName $process.name
        }
    }
}

function Expand-AllFiles {
    $sourceFolder = Join-Path -Path $PSScriptRoot -ChildPath $config.source
    $destination = Join-Path -Path $PSScriptRoot -ChildPath $config.destination
    
    Get-ChildItem -Path $sourceFolder -Filter *.zip | ForEach-Object {
        Expand-Archive -Path $_.FullName -DestinationPath $destination -Force
    }
}

function Copy-ElasticsearchConfig {
    # Aus der Konfigurationsdatei die Informationen zum Elasticsearch-Service auslesen
    $targetServiceName = "elasticsearch-service-x64"
    $service = $config.serviceInstallation | Where-Object { $_.serviceName -eq $targetServiceName }
    $scriptRoot= $PSScriptRoot # Root
    $sourceRoot = $config.source # Quellverzeichnis
    $destinationRoot = $config.destination # Zielverzeichnis

    $sourceFolderConfigFile = Join-Path -Path $scriptRoot -ChildPath ($sourceRoot + "\" + $service.sourceFolderConfigFile)
    $destinationPath = Join-Path -Path $scriptRoot -ChildPath ($destinationRoot + "\" + $service.folder + "\" + $service.configFullPath)

    Copy-Item -Path $sourceFolderConfigFile -Destination $destinationPath -Force


}

function Show-MainMenu {
    Clear-Host
    Write-Host "=== Menü ==="
    Write-Host "1. Elasticsearch stoppen & deinstallieren"
    Write-Host "2. Zip Files in den Zielordner entpacken"
    Write-Host "3. Elasticsearch Config kopieren"
    Write-Host "4. XML-Datei erweitern"
    Write-Host "5. Textdatei bearbeiten"
    Write-Host "6. Alle Aufgaben aus config.json ausführen"
    Write-Host "7. Beenden"
    Write-Host ""
}



# Lesen der Konfigurationsdatei
$currentPath = $PSScriptRoot # extra stehen lassen
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configFilePath | ConvertFrom-Json

do {
    Show-MainMenu
    $choice = Read-Host "Wählen Sie eine Option (1-7)"

    switch ($choice) {
        '1' {
            #Stop-Elasticsearch
            #Uninstall-Elasticsearch
        }
        '2' {
            Expand-AllFiles
        }
        '3' {
            Copy-ElasticsearchConfig
        }
        '4' {
            foreach ($xmlOp in $config.xmlOperations) {
                Add-XmlSnippet -xmlPath $xmlOp.filePath -xpath $xmlOp.xpath -snippetContent $xmlOp.snippetContent
            }
        }
        '5' {
            $filePath = Read-Host "Pfad zur Textdatei"
            $searchText = Read-Host "Zu suchender Text"
            $replaceText = Read-Host "Ersetzungstext"
            Edit-TextFile -filePath $filePath -searchText $searchText -replaceText $replaceText
        }
        '6' {

            #Expand-AllFiles
            #Copy-ElasticsearchConfig
            #usw..
        }
        '7' {
            Write-Host "Programm wird beendet."
            return
        }
        default {
            Write-Host "Ungültige Auswahl. Noch ein Versuch."
        }
    }

    Write-Host ""
    Read-Host "Drücken Sie Enter, um fortzufahren"

} while ($true)