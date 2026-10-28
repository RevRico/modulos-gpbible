# Pasta `github/`

Esta pasta é o que vai para o repositório de módulos
https://github.com/RevRico/modulos-gpbible, de onde o app **Bible Pro** baixa os módulos.
O app não lê esta pasta do computador; ele lê o que está publicado no GitHub.

## Estrutura

```
github/
  bibles/          Bíblias (.zip)
  commentaries/    Comentários (.zip)
  dictionary/      Dicionários (.zip)
  subheadings/     Subtítulos (.zip)
  devotions/       Devocionais (.zip)
  hymnals/         Hinários (.zip)
  catalog.json            Lista que o app lê (gerado)
  CONTROLE_MODULOS.md     Resumo de tudo que está publicado (gerado)
  atualizar-catalogo.ps1  Script que gera os dois arquivos acima
  LEIA-ME.md              Este arquivo
```

A pasta onde o `.zip` está define o tipo no app. Os arquivos `catalog.json`,
`CONTROLE_MODULOS.md`, `atualizar-catalogo.ps1` e `LEIA-ME.md` podem ir para o
repositório junto: o app só considera `.zip` e `catalog.json`.

## Fluxo para publicar uma atualização de módulos

1. Coloque o `.zip` na subpasta certa (os `.SQLite3` ficam direto dentro do zip).
2. Rode `atualizar-catalogo.ps1` (botão direito > Executar com o PowerShell).
   Ele atualiza `catalog.json` e `CONTROLE_MODULOS.md` e avisa de zip quebrado
   ou grande demais.
3. Envie para o GitHub pelo Git ou GitHub Desktop, mantendo as subpastas.
4. No app: Menu > Baixar Módulos > botão de atualizar.

Zips novos que ficarem de fora do `catalog.json` aparecem no app mesmo assim
(com o nome do arquivo). O `catalog.json` serve para dar nome bonito a cada um.

## Limites do GitHub (importante)

- **100 MB por arquivo é o máximo**: se um único arquivo passar disso, o
  `git push` inteiro é recusado. Hoje `bibles/TR_ACF.zip` (102,5 MB) passa do
  limite e precisa ser dividido ou removido. `commentaries/Bible Pic.commentaries.zip`
  tem 99,9 MB, por muito pouco abaixo do limite.
- Acima de 50 MB o GitHub só avisa.
- O repositório todo deve ficar abaixo de ~1 GB para o GitHub não reclamar.
  A pasta tem cerca de 1,2 GB.
- Não use Git LFS: o app baixa pelo endereço `raw.githubusercontent.com`, que
  não entrega arquivos do LFS.

## Não renomeie nem mova zips pela página do GitHub

Renomear/mover um arquivo binário pelo site do GitHub **corrompe o arquivo** (ele
fica com 2 bytes). Foi o que aconteceu com `Almeida1911.zip`, `Thompson.zip` e
`ProVer.zip` em 27/10/2026. Para reorganizar, mova os arquivos aqui na pasta e
envie com o Git. O app ignora arquivos com menos de 100 bytes e o script avisa.

## Atualização do aplicativo (versão)

O histórico de versões do app fica em `../CHANGELOG.md` e a versão atual em
`../pubspec.yaml` (linha `version:`). Cada atualização do app sobe a versão e ganha
uma entrada no CHANGELOG, que aparece em Menu > Sobre.
