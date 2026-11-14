# Roteiro: medir a cidade 3D no aparelho (M8)

Escrito na sessão 1.6 (14/11/2026). Objetivo: confirmar **30 FPS** da cidade cheia no nível 30 num Samsung e num Xiaomi. Nada aqui foi executado: **gerar o APK de teste depende do OK do dono**.

## 1. O que é instalado

- Um app de teste separado, **"MUNDO arte3d"**, feito do projeto `tools/arte3d/` (cena `cidade.tscn`, que abre direto no celular).
- Pacote próprio, sugerido `ink.evolu.mundo.teste3d`, assinado com a chave de depuração do Godot. **Não substitui nem toca o Valdora 0.4.1** (`ink.evolu.valdora`) nem o OTA rev 10; dá para instalar os dois lado a lado e desinstalar o teste depois.
- Tamanho esperado: 30 a 40 MB (motor + fonte; sem modelos externos).

## 2. Gerar o APK (escolher uma opção; precisa de OK)

| Opção | Custo | O que precisa |
|---|---|---|
| **A. No computador do dono** (recomendada) | nenhum | Godot 4.7.2 oficial, modelos de exportação 4.7.2 (gratuitos), JDK 17 e Android SDK; o Godot cria a chave de depuração |
| B. GitHub Actions | nenhum (repositório público: runner padrão não consome franquia); cerca de 15 min de execução | um workflow novo só para o teste; disparo manual; artefato baixado pelo dono |

Passos da opção A:

1. Abrir `tools/arte3d/project.godot` no Godot 4.7.2.
2. Projeto → Exportar → Adicionar → Android. Preencher: nome "MUNDO arte3d", pacote `ink.evolu.mundo.teste3d`, arquitetura arm64-v8a, orientação retrato (já está no projeto), "Usar build Gradle" desligado.
3. Exportar projeto → modo de depuração ligado → salvar o `.apk`.
4. Copiar para o celular e instalar (permitir fontes desconhecidas só para esse arquivo).

O `export_presets.cfg` não fica no repositório (contém caminhos da máquina).

## 3. Medir

O app abre na cidade cheia, no zoom padrão. No topo, o painel mostra **FPS, milissegundos por quadro, chamadas de desenho, triângulos, LOD e largura visível**. Embaixo, três botões:

- **Cenário**: alterna `cheia` (80 lotes no nível 30, pior caso), `n30` (só o que a regra permite no nível 30) e `misto` (faixas sorteadas). Recarrega a cena.
- **Sombra**: liga e desliga a sombra do sol. Recarrega a cena.
- **Medir**: cerca de 30 s. Passa por quatro zooms (perto, padrão, médio e longe), 120 quadros em cada, e mostra a média, o pior quadro, as chamadas e os triângulos. O arquivo fica na pasta do app.

Em cada aparelho:

1. Celular carregado acima de 50%, modo de economia de bateria desligado, brilho médio, sem outros apps abertos.
2. Abrir o app e esperar 10 s.
3. Cenário `cheia`, sombra sim: tocar **Medir** e **fotografar a tela** do resultado.
4. Repetir com sombra não.
5. Cenário `misto`, sombra sim: **Medir** e fotografar.
6. Arrastar e pinçar livremente por 1 min. Anotar se travou ou piscou, se o zoom parou nos limites e se o toque nos botões funcionou.
7. Esperar 5 min com o app aberto e repetir o passo 3 (aquecimento do aparelho).

Mandar as fotos com o **modelo exato** do aparelho e a versão do Android (Configurações → Sobre o telefone).

## 4. Critério

| Resultado | Leitura |
|---|---|
| Média ≤ 33 ms e pior ≤ 50 ms nos quatro zooms, `cheia`, com sombra | M8 aprovado no aparelho |
| Só passa sem sombra | sombra fica só no zoom de perto ou sai do celular fraco (opção na tela de ajustes) |
| Não passa nem sem sombra | próximos cortes, nesta ordem: LOD 1 mais cedo (largura 18), MSAA desligado, resolução 3D a 75%, menos prédios por bloco |

No PC de desenvolvimento a medição não serve como referência de tempo: sem placa de vídeo, o Godot desenha por software. As contagens (chamadas e triângulos) valem e estão em `game/docs/logs/cidade3d/`.
