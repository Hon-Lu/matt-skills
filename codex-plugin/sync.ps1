param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$codexRoot = Split-Path -Parent $PSCommandPath
$repositoryRoot = Split-Path -Parent $codexRoot
$claudeManifestPath = Join-Path $repositoryRoot '.claude-plugin\plugin.json'
$marketplaceRelativePath = '.agents\plugins\marketplace.json'
$pluginName = 'mattpocock-skills'

function Write-JsonFile {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [object]$Value
    )

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $content = $Value | ConvertTo-Json -Depth 20
    $content = [regex]::Replace($content, "`r?`n", "`r`n") + "`r`n"
    [System.IO.File]::WriteAllText($Path, $content, [System.Text.UTF8Encoding]::new($false))
}

function Get-PromotedSkills {
    param([Parameter(Mandatory)] [object]$ClaudeManifest)

    if ($null -eq $ClaudeManifest.skills -or $ClaudeManifest.skills.Count -eq 0) {
        throw '.claude-plugin/plugin.json must contain a non-empty skills array.'
    }

    $skills = foreach ($rawPath in $ClaudeManifest.skills) {
        if ($rawPath -notmatch '^\./skills/(engineering|productivity)/[^/]+$') {
            throw "Unsupported promoted skill path: $rawPath"
        }

        $source = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $rawPath))
        $name = Split-Path -Leaf $source
        if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
            throw "Promoted skill is missing SKILL.md: $rawPath"
        }

        [pscustomobject]@{ Name = $name; Source = $source }
    }

    $duplicates = $skills | Group-Object Name | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name
    if ($duplicates) {
        throw "Codex requires unique flat skill names: $($duplicates -join ', ')"
    }

    return @($skills)
}

function New-PluginManifest {
    param([Parameter(Mandatory)] [object]$ClaudeManifest)

    return [ordered]@{
        name = $ClaudeManifest.name
        version = $ClaudeManifest.version
        description = $ClaudeManifest.description
        author = $ClaudeManifest.author
        homepage = $ClaudeManifest.homepage
        repository = 'https://github.com/asd880921/matt-skills'
        license = $ClaudeManifest.license
        keywords = $ClaudeManifest.keywords
        skills = './skills/'
        interface = [ordered]@{
            displayName = 'Matt Pocock Skills'
            shortDescription = 'Engineering and productivity skills for Codex.'
            longDescription = "Matt Pocock's promoted engineering and productivity skills, packaged as a native Codex plugin."
            developerName = 'Matt Pocock'
            category = 'Engineering'
            capabilities = @('Engineering', 'Productivity')
            defaultPrompt = @(
                'Ask Matt which workflow fits this task.'
                'Turn this idea into an implementation-ready spec.'
                'Review this code change and identify the highest-risk issues.'
            )
        }
    }
}

function New-MarketplaceManifest {
    param([Parameter(Mandatory)] [string]$Name)

    return [ordered]@{
        name = 'matt-skills'
        interface = [ordered]@{ displayName = 'Matt Skills' }
        plugins = @(
            [ordered]@{
                name = $Name
                source = [ordered]@{
                    source = 'local'
                    path = './plugins/mattpocock-skills'
                }
                policy = [ordered]@{
                    installation = 'AVAILABLE'
                    authentication = 'ON_INSTALL'
                }
                category = 'Engineering'
            }
        )
    }
}

function Build-CodexPlugin {
    param(
        [Parameter(Mandatory)] [string]$OutputRoot,
        [Parameter(Mandatory)] [object]$ClaudeManifest,
        [Parameter(Mandatory)] [array]$Skills
    )

    $outputPluginRoot = Join-Path $OutputRoot "plugins\$pluginName"
    $expectedRoot = [System.IO.Path]::GetFullPath((Join-Path $OutputRoot 'plugins'))
    $resolvedTarget = [System.IO.Path]::GetFullPath($outputPluginRoot)
    if (-not $resolvedTarget.StartsWith($expectedRoot + [System.IO.Path]::DirectorySeparatorChar)) {
        throw "Refusing to replace unexpected path: $resolvedTarget"
    }
    if (Test-Path -LiteralPath $outputPluginRoot) {
        Remove-Item -LiteralPath $outputPluginRoot -Recurse -Force
    }

    $outputSkillsRoot = Join-Path $outputPluginRoot 'skills'
    New-Item -ItemType Directory -Path $outputSkillsRoot -Force | Out-Null
    foreach ($skill in $Skills) {
        $destination = Join-Path $outputSkillsRoot $skill.Name
        Copy-Item -LiteralPath $skill.Source -Destination $destination -Recurse

        # Claude reads this frontmatter key; Codex preserves the same user-only
        # behavior through agents/openai.yaml and rejects a true value here.
        $skillManifestPath = Join-Path $destination 'SKILL.md'
        $skillManifest = [System.IO.File]::ReadAllText($skillManifestPath)
        $normalizedManifest = [regex]::Replace(
            $skillManifest,
            '(?m)^disable-model-invocation:\s*true\r?\n',
            ''
        )
        if ($normalizedManifest -ne $skillManifest) {
            [System.IO.File]::WriteAllText(
                $skillManifestPath,
                $normalizedManifest,
                [System.Text.UTF8Encoding]::new($false)
            )
        }
    }

    Write-JsonFile -Path (Join-Path $outputPluginRoot '.codex-plugin\plugin.json') -Value (New-PluginManifest $ClaudeManifest)
    Write-JsonFile -Path (Join-Path $OutputRoot $marketplaceRelativePath) -Value (New-MarketplaceManifest $ClaudeManifest.name)
}

function Assert-SameTree {
    param(
        [Parameter(Mandatory)] [string]$ExpectedRoot,
        [Parameter(Mandatory)] [string]$ActualRoot
    )

    if (-not (Test-Path -LiteralPath $ActualRoot -PathType Container)) {
        throw "Codex plugin is stale; missing directory: $ActualRoot"
    }

    $expectedFiles = @(Get-ChildItem -LiteralPath $ExpectedRoot -File -Recurse | ForEach-Object {
        $_.FullName.Substring($ExpectedRoot.Length).TrimStart('\', '/')
    } | Sort-Object)
    $actualFiles = @(Get-ChildItem -LiteralPath $ActualRoot -File -Recurse | ForEach-Object {
        $_.FullName.Substring($ActualRoot.Length).TrimStart('\', '/')
    } | Sort-Object)

    if (($expectedFiles -join "`n") -ne ($actualFiles -join "`n")) {
        throw 'Codex plugin file list is stale. Run: .\codex-plugin\sync.ps1'
    }

    foreach ($file in $expectedFiles) {
        $expectedHash = (Get-FileHash -LiteralPath (Join-Path $ExpectedRoot $file) -Algorithm SHA256).Hash
        $actualHash = (Get-FileHash -LiteralPath (Join-Path $ActualRoot $file) -Algorithm SHA256).Hash
        if ($expectedHash -ne $actualHash) {
            throw "Codex plugin file is stale: $file. Run: .\codex-plugin\sync.ps1"
        }
    }
}

$claudeManifest = Get-Content -Raw -LiteralPath $claudeManifestPath | ConvertFrom-Json
$skills = Get-PromotedSkills $claudeManifest

if ($Check) {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("matt-skills-codex-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    try {
        Build-CodexPlugin -OutputRoot $temporaryRoot -ClaudeManifest $claudeManifest -Skills $skills
        Assert-SameTree -ExpectedRoot (Join-Path $temporaryRoot 'plugins') -ActualRoot (Join-Path $repositoryRoot 'plugins')

        $expectedMarketplaceHash = (Get-FileHash -LiteralPath (Join-Path $temporaryRoot $marketplaceRelativePath) -Algorithm SHA256).Hash
        $actualMarketplaceHash = (Get-FileHash -LiteralPath (Join-Path $repositoryRoot $marketplaceRelativePath) -Algorithm SHA256).Hash
        if ($expectedMarketplaceHash -ne $actualMarketplaceHash) {
            throw 'Codex marketplace manifest is stale. Run: .\codex-plugin\sync.ps1'
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }

    Write-Host "Codex plugin is in sync ($($skills.Count) skills)."
}
else {
    Build-CodexPlugin -OutputRoot $repositoryRoot -ClaudeManifest $claudeManifest -Skills $skills
    Write-Host "Synced Codex plugin from Claude manifest ($($skills.Count) skills)."
}
