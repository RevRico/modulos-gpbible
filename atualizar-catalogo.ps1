# Atualiza o catalog.json e o CONTROLE_MODULOS.md a partir dos .zip desta pasta.
#
# Como usar (depois de colocar/trocar/apagar .zip aqui):
#   clique com o botão direito neste arquivo > "Executar com o PowerShell"
#   ou, num terminal dentro da pasta:  powershell -ExecutionPolicy Bypass -File .\atualizar-catalogo.ps1
#
# - Módulos que já estão no catalog.json (mesmo caminho) mantêm o nome.
# - Módulos novos entram com o nome do arquivo; edite o "name" depois, se quiser.
# - A categoria vem da subpasta: bibles, commentaries, dictionary, subheadings,
#   devotions, hymnals.
# - Zips que não existem mais na pasta saem do catálogo.
# - Avisa de zips quebrados (< 100 bytes) e de arquivos grandes demais para o GitHub.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$pasta = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseUrl = 'https://raw.githubusercontent.com/RevRico/modulos-gpbible/main'
$catalogo = Join-Path $pasta 'catalog.json'
$controle = Join-Path $pasta 'CONTROLE_MODULOS.md'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$limiteGitHub = 100MB   # acima disso o "git push" é recusado
$avisoGitHub = 50MB

$categorias = [ordered]@{
    'bibles'       = 'Bíblias'
    'commentaries' = 'Comentários'
    'dictionary'   = 'Dicionários'
    'subheadings'  = 'Subtítulos'
    'devotions'    = 'Devocionais'
    'hymnals'      = 'Hinários'
}

# Catálogo atual (para preservar os nomes).
$antigos = @{}
if (Test-Path $catalogo) {
    $json = [IO.File]::ReadAllText($catalogo, $utf8)
    foreach ($m in ($json | ConvertFrom-Json)) {
        $chave = if ($m.path) { $m.path } else { $m.fileName }
        $antigos[$chave] = $m
    }
}

function Get-Categoria($relativo) {
    $primeira = $relativo.Split('/')[0].ToLower()
    if ($categorias.Contains($primeira)) { return $categorias[$primeira] }
    $n = $relativo.ToLower()
    if ($n -match 'subheading|subtitles') { return 'Subtítulos' }
    if ($n -match '\.commentaries\.') { return 'Comentários' }
    if ($n -match '\.dictionary\.') { return 'Dicionários' }
    if ($n -match '\.devotions\.') { return 'Devocionais' }
    return 'Bíblias'
}

function Get-UrlCodificada($relativo) {
    $partes = $relativo.Split('/') | ForEach-Object { [uri]::EscapeDataString($_) }
    return "$baseUrl/" + ($partes -join '/')
}

$itens = @()
$linhas = @()
$grandes = @()
foreach ($zip in (Get-ChildItem -Path $pasta -Filter '*.zip' -Recurse | Sort-Object FullName)) {
    $relativo = $zip.FullName.Substring($pasta.Length).TrimStart('\', '/') -replace '\\', '/'
    if ($zip.Length -lt 100) {
        Write-Warning "${relativo}: arquivo quebrado ($($zip.Length) bytes), ignorado. Envie o zip de novo."
        continue
    }
    if ($zip.Length -ge $limiteGitHub) {
        Write-Warning "${relativo}: $([math]::Round($zip.Length / 1MB, 1)) MB. O GitHub RECUSA arquivos de 100 MB ou mais; divida ou remova este zip antes do push."
        $grandes += $relativo
    } elseif ($zip.Length -ge $avisoGitHub) {
        Write-Warning "${relativo}: $([math]::Round($zip.Length / 1MB, 1)) MB (o GitHub avisa acima de 50 MB, mas aceita)."
    }

    $arquivo = $null
    try {
        $arquivo = [IO.Compression.ZipFile]::OpenRead($zip.FullName)
        $dentro = @($arquivo.Entries | Where-Object { $_.Name -match '\.sqlite3$' } | ForEach-Object { $_.Name })
    } catch {
        Write-Warning "${relativo}: não é um zip válido, ignorado."
        continue
    } finally {
        if ($arquivo) { $arquivo.Dispose() }
    }

    if ($dentro.Count -eq 0) {
        Write-Warning "${relativo}: não tem nenhum .sqlite3 dentro, ignorado."
        continue
    }

    $antigo = $antigos[$relativo]
    if (-not $antigo) { $antigo = $antigos[$zip.Name] }
    $nome = if ($antigo) { $antigo.name } else { [IO.Path]::GetFileNameWithoutExtension($zip.Name) }
    $categoria = Get-Categoria $relativo
    $tamanho = if ($zip.Length -ge 1MB) { ('{0:N1} MB' -f ($zip.Length / 1MB)) -replace ',', '.' } else { '{0} KB' -f [math]::Round($zip.Length / 1KB) }

    $itens += [ordered]@{
        name     = $nome
        fileName = $zip.Name
        path     = $relativo
        category = $categoria
        size     = $tamanho
        url      = Get-UrlCodificada $relativo
    }
    $linhas += "| $nome | $categoria | ``$relativo`` | $tamanho | $($dentro -join '<br>') |"
}

# Ordem estável: categoria (na ordem das pastas) e depois nome.
$ordem = @($categorias.Values)
$itens = $itens | Sort-Object { $ordem.IndexOf($_.category) }, { $_.name.ToLower() }

$saida = ConvertTo-Json -InputObject @($itens) -Depth 4
$saida = $saida -replace '\\u0027', "'"
[IO.File]::WriteAllText($catalogo, $saida + "`n", $utf8)

$md = @()
$md += '# Controle de módulos'
$md += ''
$md += "Gerado por ``atualizar-catalogo.ps1`` em $(Get-Date -Format 'dd/MM/yyyy HH:mm'). Não edite à mão: rode o script de novo."
$md += ''
$md += "Total: **$($itens.Count)** pacotes."
$md += ''
foreach ($c in $ordem) {
    $n = @($itens | Where-Object { $_.category -eq $c }).Count
    if ($n -gt 0) { $md += "- ${c}: $n" }
}
if ($grandes.Count -gt 0) {
    $md += ''
    $md += '## Atenção: arquivos grandes demais para o GitHub (100 MB)'
    foreach ($g in $grandes) { $md += "- ``$g``" }
}
$md += ''
$md += '| Nome | Categoria | Arquivo | Tamanho | Módulos dentro do zip |'
$md += '|---|---|---|---|---|'
$md += $linhas
$md += ''
$md += '## Como publicar uma atualização de módulos'
$md += ''
$md += '1. Coloque (ou troque) o `.zip` na subpasta do tipo. O `.zip` deve ter os arquivos `.SQLite3` direto dentro.'
$md += '2. Rode `atualizar-catalogo.ps1`. Ele reescreve `catalog.json` e este arquivo.'
$md += '3. Envie para https://github.com/RevRico/modulos-gpbible pelo Git (ou GitHub Desktop), com as subpastas.'
$md += '4. No app: Menu > Baixar Módulos > botão de atualizar. Os itens novos aparecem.'
$md += ''
$md += 'Tipo do módulo pelo nome do arquivo `.SQLite3` dentro do zip: `.commentaries.` = comentário, `.dictionary.` = dicionário, `.subheadings.` = subtítulos, `.devotions.` = devocional, sem nenhum desses = Bíblia (ou hinário, se estiver na pasta `hymnals`).'
[IO.File]::WriteAllText($controle, ($md -join "`n") + "`n", $utf8)

Write-Host "Pronto: $($itens.Count) pacotes em catalog.json e CONTROLE_MODULOS.md."
if ($grandes.Count -gt 0) { Write-Host "ATENÇÃO: $($grandes.Count) arquivo(s) acima do limite do GitHub (veja os avisos)." -ForegroundColor Yellow }
