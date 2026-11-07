# Channel — Valdora V-01B: entrada no reino e distribuição Android

Versão experimental do Add-on: 1.3.0. **Um arquivo para o jogador:** `Channel.mcaddon`.

## O que foi corrigido

- No **primeiro acesso** a um mundo sem Valdora, um menu oferece **Preparar Valdora → Construir Valdora aqui**. Confirmação obrigatória para substituir blocos. O mundo deve ser **novo, plano, descartável** e com espaço de 96×96 blocos. Não existe construção automática em mundos existentes.
- São colocadas as mesmas oito estruturas da V-01A, sem novos modelos ou NPCs.
- Após a criação, o jogador é levado para uma passagem livre ao sul da Praça Central (fora da fonte e da estátua), e o local é configurado para seu próximo renascimento.
- O ponto de nascimento do mundo também é configurado via `setworldspawn` quando o comando é permitido. Na ausência de permissão, o `player.setSpawnPoint` individual ainda é solicitado.
- Novos participantes de um reino já criado são direcionados à praça uma vez. Jogadores recorrentes mantêm a posição que tinham ao sair, sem teleportes repetidos.
- A carteira Channel possui a opção **Conhecer Valdora**, que permite **retornar à praça** ou abrir novamente o fluxo de criação quando o menu inicial foi fechado.
- Evita construções duplicadas: uma propriedade persistente marca o local da cidade depois que as oito estruturas são solicitadas. Um bloqueio também impede criação concorrente por dois jogadores na mesma sessão.

## Limitações e segurança

- A implementação depende da API Script `@minecraft/server` 2.0 e da `StructureManager.place`. A colocação em blocos não carregados pode ser enfileirada até o carregamento; verifique cada edifício no Minecraft real.
- **O próprio `.mcaddon` não contém um mundo `.mcworld` completo.** Assim, no primeiro acesso o jogador aparece inicialmente na área natural do Minecraft e precisa confirmar a criação de Valdora. Após a confirmação, será enviado à praça e nascerá lá nos acessos seguintes. Para aparecer na praça *antes de qualquer confirmação*, será necessário distribuir um mundo preparado `.mcworld` com spawn gravado e o Add-on incorporado.
- Não executa modificações automáticas no terreno sem confirmação. A construção não possui desfazer; fazer backups.
- A alternativa manual `/function valdora/construir_centro` também registra o spawn e teleporta para a entrada da praça, mas não grava a propriedade de controle da interface. Use o menu de jogo para a primeira criação.
- Como nas versões anteriores, o Add-on não está homologado em dispositivos reais por esta entrega. Testes locais simulados **não** comprovam execução real.

## Como instalar e testar

1. Abra o único arquivo `Channel.mcaddon` pelo Minecraft Bedrock. No Android, o Minecraft deve estar instalado; em alguns gerenciadores (particularmente MIUI/HyperOS), o Minecraft pode não aparecer em "Abrir com" mesmo se o arquivo for válido.
2. Ative o pacote Channel no mundo **NOVO e PLANO**. Use o Add-on mais recente, cujo pacote tem versão 1.3.0.
3. Entre no mundo e aguarde o menu "Valdora | Reino inicial". Se não abrir, use a **Carteira Channel → Conhecer Valdora → Preparar Valdora**.
4. Confirme a substituição da área 96×96 em um mundo plano descartável.
5. Verifique que é teleportado à entrada sul da Praça Central e que o portão, mercado e guilda estão próximos.
6. Saia, entre novamente e confirme que retorna à **posição salva** (sem teleporte inesperado). Morra apenas num mundo de teste e confirme renascimento na praça.
7. Convide um segundo jogador e confirme chegada inicial à praça. Confira que não houve construção duplicada.

## Compatibilidade Android

- É utilizado o formato `.mcaddon` oficial, contendo ambos os pacotes.
- Não é possível forçar o Android de todos os fabricantes a oferecer o Minecraft no menu "Abrir com". Essa associação é declarada pelo aplicativo Android Minecraft, não pela página, GitHub nem conteúdo do `.mcaddon`.
- A extensão não deve ser alterada para `.apk`, `.bin`, `.zip` ou outra. **Não** distribuir instaladores APK de terceiros.
- O download deve ser oferecido com URL e filename `.mcaddon`. No site estático, cabeçalhos de `Content-Disposition: attachment; filename="Channel.mcaddon"` podem proteger o nome; isso não corrige a ausência de associação com Minecraft no Android.
- **Pendente:** confirmar importação em pelo menos um Xiaomi com Minecraft atual e num Samsung; registrar versão de Android/Minecraft, navegador e resultado.

## Não realizado

Não foram feitos deploy na Vercel, alteração de DNS, modificação no servidor Minecraft, criação de repositórios adicionais ou GitHub Actions. A versão de download atual do site não foi substituída.