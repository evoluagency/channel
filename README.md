# EVOLU Channel

Projeto público, gratuito e não oficial de um Add-on RPG de fantasia medieval para Minecraft Bedrock.

## Estado atual

**Prévia experimental v1.1.0.** A economia básica foi migrada do protótipo antigo. O primeiro reino, Valdora, ainda não possui vilas geradas nem NPCs próprios; estes são marcos futuros.

## Funcionalidades desta prévia

- Dinheiro digital e físico, banco e conversão entre moedas.
- Comércio simples por menu, recompensas em combate e transferências entre jogadores conectados.
- Apresentação de Valdora como território inicial.

## Implantação

O GitHub guarda arquivos e versões manuais, **sem GitHub Actions, workflows, cron jobs ou migrations**. O site estático deve ser publicado manualmente na Vercel. O arquivo `Channel.mcaddon` deve ser importado no Minecraft Android e ativado em um mundo de teste.

## Proteção de mundos antigos

Os UUIDs de pacotes e IDs internos do antigo protótipo (`erpg:*`) são preservados para compatibilidade de saldos, itens e inventários. Faça backup antes de atualizar.

## Licenciamento e autoria

Projeto independente, sem vínculo com Mojang ou Microsoft. Nenhum personagem ou história de terceiros está incorporado. Direitos autorais reservados até definição de licença pública para o código e os assets.
