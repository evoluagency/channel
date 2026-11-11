# EVOLU Channel

Add-on RPG independente para Minecraft Bedrock (Android/PC), com economia e o primeiro núcleo construído de Valdora.

## Um único download para testar

**Versão experimental V-01B (pacotes 1.3.0)**

[**Baixar Channel.mcaddon**](experimental/Channel.mcaddon)

O único arquivo reúne pacote de comportamento e pacote de recursos. Não é APK nem instalador independente: o Minecraft precisa estar instalado para importar o arquivo.

## Como entrar em Valdora

1. Importe `Channel.mcaddon` no Minecraft.
2. Crie um **mundo plano novo e descartável**, com o pacote Channel ativo.
3. Ao entrar, use o menu **Preparar Valdora → Construir Valdora aqui** e confirme a alteração do terreno.
4. O jogador será enviado à entrada segura da Praça Central. O ponto de renascimento ficará registrado ali.
5. Se o menu não aparecer, use o item **Carteira Channel → Conhecer Valdora**.

**Atenção:** a construção substitui blocos em uma área de aproximadamente 96×96; não use em mundos existentes ou importantes. O primeiro nascimento de um mundo totalmente novo ocorre naturalmente, antes da confirmação e construção do reino. Para já nascer dentro de uma cidade pré-construída, precisaremos de um mundo distribuído em formato `.mcworld`.

## O que já existe

- Oito estruturas de Valdora: praça, mercado, guilda/quartel, portão e quatro trechos de vias.
- Carteira digital, banco, dinheiro físico, compras, vendas, recompensas em combate e transferências.
- Entrada guiada e renascimento perto da praça após o reino ser criado.
- Versão experimental não homologada em Minecraft real nesta entrega; testes simulados de economia e nascimento aprovados.

## Compatibilidade Android

O Android decide quais aplicativos aparecem em **Abrir com**. Embora Samsung já tenha reconhecido o arquivo em teste, **não é possível garantir a associação ao Minecraft em todo Android** apenas pelo conteúdo do `.mcaddon` ou pelo site. Não renomeie para `.apk`; se Minecraft não aparecer, consulte [o diagnóstico Android](docs/VALDORA_ANDROID_E_SPAWN_V01B.md).

## Documentos e código

- [Documento técnico Valdora](docs/VALDORA_CADERNO_TECNICO_V01.md)
- [Correção V-01B (Android e spawn)](docs/VALDORA_ANDROID_E_SPAWN_V01B.md)
- [Código e scripts de teste](addon/Channel_BP/scripts/main.js)
- [Estruturas da cidade](addon/Channel_BP/structures/channel/valdora/)
- [Validação simulada de spawn](docs/tests/test_valdora_spawn.cjs)

## Engenharia e direitos

O addon Minecraft não usa GitHub Actions, workflows, cron jobs, banco externo nem deploy automático. O jogo Valdora (`game/`) tem workflows de validação e release, todos de disparo manual ou restritos a branches históricas; veja `game/docs/ESTADO_DO_PROJETO.md`. A Vercel e o DNS são geridos separadamente pelo proprietário.

UUIDs e IDs internos `erpg:*` são preservados para compatibilidade; faça backup dos mundos antes de atualizar.

Projeto independente, não oficial da Mojang/Microsoft. Direitos reservados até a definição da licença pública do código e dos assets.
