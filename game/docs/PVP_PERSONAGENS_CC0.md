# Valdora PvP — personagens no estilo da arte conceitual (levantamento, 16/11/2026)

O acabamento de desenho animado dos heróis da arte (Nilo, Mara, Otto) **não sai por código**:
precisa de modelo 3D esculpido, com rig e animação. O código só monta cenário. Os caminhos
gratuitos estão abaixo. Nenhum envolve gasto, e nada foi baixado ainda.

## 1. Modelos prontos com licença CC0 (sem atribuição, uso comercial)

| Pacote | O que tem | Formato | Encaixe no Valdora |
|---|---|---|---|
| KayKit Adventurers (Kay Lousberg) | humanoides cartoon com rig, 75 animações, 25+ acessórios | glTF e FBX | melhor encaixe de proporção "chibi" cartoon; tem pacote de animações compatível; já existe no Asset Library do Godot |
| KayKit Character Animations | animações extras para todos os personagens KayKit | glTF e FBX | corrida, tiro, agachar para o FPS em terceira pessoa |
| Quaternius Universal Base Characters | corpos base masculino e feminino com rig | glTF e FBX | base mais realista; cabeça e roupa trocáveis |
| Quaternius Universal Animation Library 1 e 2 | biblioteca de animações CC0 | glTF e FBX | animações para os corpos acima |
| Kenney (personagens animados) | personagens em bloco, alegres | glTF e FBX | estilo mais simples que a arte |

Cuidados:

- nenhum pacote CC0 tem um "soldado" pronto no estilo da arte. O caminho é adaptar um humanoide
  KayKit ou Quaternius: colete, cachecol, óculos, arma com as cores do Valdora (creme, verde-azulado,
  laranja);
- conferir o arquivo de licença dentro de cada download antes de versionar. Um guia de terceiros
  diverge do CC0 nas páginas da Quaternius.

## 2. Imagem para 3D por IA, rodando localmente (código aberto)

| Modelo | Licença (conferir o LICENSE no repositório) | Observação |
|---|---|---|
| TripoSR (Stability AI e Tripo) | MIT, permite uso comercial | rascunho de malha em segundos; precisa de retopologia, rig e textura |
| TRELLIS e TRELLIS.2 (Microsoft) | MIT | o pipeline oficial usa o RMBG-2.0 para remover o fundo, que é CC BY-NC (não comercial). Trocar esse passo por outro removedor |
| Hunyuan3D 2.x (Tencent) | licença comunitária própria | não vale na UE, no Reino Unido nem na Coreia do Sul; licença à parte acima de 1 milhão de usuários por mês. Evitar |

Limite prático: esses modelos pedem GPU. O contêiner das sessões não tem GPU, e rodar na nuvem
seria gasto. Dá para rodar no computador do dono se ele tiver placa de vídeo, ou nos espaços
gratuitos do Hugging Face (com fila). O resultado sai sem rig. O rig automático gratuito é o
Mixamo, da Adobe: é grátis, mas não é CC0, então conferir os termos.

## 3. Recomendação

1. Personagem jogável e inimigos: **KayKit Adventurers + Character Animations (CC0)**, recoloridos
   na paleta do Valdora, com acessórios modelados por nós. É o caminho mais rápido, sem custo e sem risco de licença.
2. Heróis de vitrine dos menus (Nilo, Mara, Otto, a partir da arte do dono): imagem para 3D com
   **TripoSR ou TRELLIS** no computador do dono, retopologia no Blender (gratuito) e rig no
   Mixamo. Fica para uma sessão própria, com o dono rodando a geração.
3. Não usar modelos de outros jogos nem "inspirados" em personagens conhecidos.

Fontes: [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers),
[KayKit Character Animations](https://kaylousberg.itch.io/kaykit-character-animations),
[KayKit no Asset Library do Godot](https://godotengine.org/asset-library/asset/2129),
[Quaternius Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html),
[Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html),
[guia de personagens com rig gratuitos](https://app.cinevva.com/guides/free-rigged-3d-character-models),
[TripoSR](https://stability.ai/news/triposr-3d-generation),
[estado da geração 3D por IA em 2026](https://3daistudio.com/state-of-ai-3d-generation-2026),
[licença do Hunyuan3D](https://github.com/Tencent-Hunyuan/Hunyuan3D-2/issues/6),
[uso comercial do TRELLIS](https://huggingface.co/spaces/trellis-community/TRELLIS/discussions/8).
