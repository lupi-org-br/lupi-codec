# lupi-codec

Processa uma pasta de jogo (sprites, mapas, scripts) e gera um release otimizado com manifesto, paleta de cores e arquivos convertidos para o formato do motor Lupi.

## Requisitos

- Lua 5.3 ou superior
- ImageMagick (`magick` disponivel no PATH)

## Uso

```bash
lua run.lua <pasta_entrada> <pasta_saida>
```

### Exemplo

```bash
lua run.lua ../meu-jogo /tmp/meu-jogo-release
```

## O que acontece

1. Copia todos os arquivos do projeto para `<pasta_saida>/releases/<timestamp>/`
2. Processa imagens PNG:
   - Extrai cores e converte para BGR555
   - Detecta tiles automaticamente
   - Remove os PNGs originais
3. Converte mapas Tiled (`.json`) para scripts Lua
4. Ignora arquivos desnecessarios
5. Gera `palette.lua` e `master_palette.json`
6. Gera `lupi_manifest.txt` com metadados de cada arquivo
7. Cria o link simbolico `current` apontando para o release

## Estrutura de saida

```
<pasta_saida>/
  current/ -> releases/<timestamp>/
  master_palette.json
  releases/
    <timestamp>/
      lupi_manifest.txt
      palette.lua
      ... (arquivos processados)
```

## Arquivos

- `run.lua` — orquestra o processamento
- `manifest.lua` — gera o manifesto
- `pipeline.lua` — aplica os codecs nos arquivos
- `codecs.lua` — escolhe o codec por extensao
- `image_codec.lua` — converte PNG para bitmap indexado
- `tiled_codec.lua` — converte mapas Tiled JSON para Lua
- `pass_through_codec.lua` — mantem arquivos Lua como estao
- `ignore_codec.lua` — remove arquivos ignorados
- `colors_manager.lua` — gerencia a paleta de cores
- `dkjson.lua` — biblioteca JSON pura Lua
