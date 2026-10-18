# Calendário: movimento e cadência de revisão

Registro: **16/10/2026**, FE-031/FE-032. Somente estudo local de planejamento;
**não apresentado e não aprovado**, sem mudança no aplicativo Flutter.

O usuário relatou que o calendário simplesmente aparece. Nos testes locais,
a fonte anterior tinha entrada de 180 ms, opacidade inicial .55 e deslocamento
8 px. Não foi reproduzida a ausência total no ambiente do usuário; não atribuir
causa comprovada à acessibilidade ou ao iPhone.

Um novo estudo local, concluído antes da orientação FE-032, usa entrada de
240 ms, opacidade 0→1, deslocamento 12→0 e escala .98→1, com fundo escurecendo
em 180 ms. Preserva abertura direta em movimento reduzido, inclusive quando
o sistema solicita redução. Aplica espaço 20, campos 24 e painéis/calendário 32,
conforme FE-028/FE-030. Os novos tempos e efeitos são propostas do assistente.

O teste conferiu quadros intermediários e estado final, abertura repetida,
interrupção, seleção de data, retorno de foco, redução local e do sistema e
sua mudança durante a entrada. Passou em Edge e WebKit no Windows, com seis
combinações de largura/tema por motor, sem erros JavaScript observados. Também
conferiu saldo parcial e revisão. A alteração da preferência usou o helper
original com provedor de anotações simulado; não automatizou o painel nativo.
Não comprova UIKit/iPhone, Android, leitor de tela ou desempenho nativo.

Fontes, script, relatórios e quatro capturas estão
[preservados nesta pasta](referencias_frontend/rodada-calendario-movimento-2026-10-16/README.md).

**Orientação vigente FE-032:** o usuário dispensou a prévia desta rodada e pediu
evitar uma geração a cada ajuste simples por preocupação com consumo. Depois
dessa mensagem, apenas registros e preservação foram concluídos. Não apresentar
agora, não iniciar outros testes e não tratar o estudo salvo como aceitação.
Registrar ajustes simples e reuni-los para uma próxima revisão visual.
