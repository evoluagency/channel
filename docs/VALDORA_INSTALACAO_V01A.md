# Instalação de Valdora — V-01A experimental

**Atenção:** este é um construtor de estruturas. Não é um mundo `.mcworld` e não oferece ainda NPCs programados nem missões.

1. Faça backup dos mundos existentes. Crie um **mundo NOVO, plano e descartável**, com cheats/comandos ativados.
2. Importe `Channel_Valdora_V01A.mcaddon` e ative o pacote de comportamento Channel.
3. Entre no mundo. Antes de executar, escolha área livre de **96 × 96 blocos**. Preferencialmente fique de pé no solo, **no centro dessa área**, em X0+48, Z0+48, com os arredores carregados. Não execute sobre edificações importantes.
4. Digite no chat: `/function valdora/construir_centro`. Alternativamente, no canto noroeste (X0,Z0), use `/function valdora/construir` (pode exigir maior distância de renderização).
5. O comando carrega quatro vias e quatro módulos de construção em sequência, relativos à posição atual do operador. **Não execute duas vezes** nem rode enquanto caminha.
6. Comece pela estrada leste até o Mercado, depois Praça e Quartel, e siga ao norte até o Portão. Verifique caminho, iluminação e paredes.
7. Se ocorrer algum problema, descarte o mundo de teste. Não há botão de desfazer e `/function` não cria um mundo independente.
8. Se o comando não for reconhecido, verifique se cheats estão habilitados e o behavior pack está ativo. Teste `/structure load channel:valdora/praca ~10 ~-1 ~10` em um mundo descartável.

**Importação/versão:** mantenha os UUIDs dos dois pacotes anteriores. Esta compilação atualiza as versões para 1.2.0; propriedades de economia existentes não são removidas. Não atualize um mundo importante sem backup.

**Limitações:** a capa é arte conceitual; o cenário usa blocos vanilla. Não há homologação em aparelho Android real. Algumas texturas ou blocos poderão precisar de ajuste após a inspeção no jogo.

**Sem automações:** o gerador Python roda somente localmente. Nenhum GitHub Action, workflow, migration, job, Vercel ou Supabase é necessário para jogar.