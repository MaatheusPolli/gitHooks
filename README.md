# 🤖 Git AI Hooks Hub - Manual Técnico de Operação

Este projeto é um ecossistema modular desenhado para automatizar e padronizar as mensagens de commit da equipe utilizando Inteligência Artificial (Gemini, Claude ou Copilot). Ele foca em senioridade técnica, produtividade e resiliência total.

---

## 📂 Estrutura do Projeto (Arquitetura Modular)

```text
<pasta-do-projeto>/gitHooks/
├── lib/            # Core: AIService, ConfigService, GitService, LogService, PathService,
│                   #       ProcessService, SecretFilter, CommitFormat (.ps1)
│   └── providers/  # GeminiProvider, ClaudeProvider (CopilotProvider está desativado)
├── prompts/        # Templates editáveis: commit-msg.txt, commit-msg-senior.txt, code-review.txt
├── actions/        # Orquestradores: GenerateCommitMsg.ps1 (commit), PerformCodeReview.ps1 (pre-push)
├── hooks/          # prepare-commit-msg (git commit) e pre-push (revisão antes do push)
├── setup/          # Setup-TortoiseGit-IA.bat, Instalar-GeminiCLI.bat, Install-All.ps1
├── diagnostics/    # Verify-Environment.ps1, Test-AllProviders.ps1, Diagnostico-Hooks-IA.bat
├── tests/          # Testes Pester (rodam no CI)
└── config/         # settings.txt (local) e settings.example.txt (modelo versionado)
```

> Os scripts resolvem a pasta pela própria localização; se preferir, defina a variável de ambiente `GITHOOKS_HOME` com o caminho do projeto.

---

## 🛡️ Filosofia Non-Blocking (Resiliência Total)

A automação foi construída para ser um **assistente invisível**. Se algo falhar, o fluxo de trabalho original do Git permanece intacto:
- **Falha Segura:** Se a IA falhar ou a chave cair, a janela de commit abre normalmente (vazia ou com o texto que você já digitou) para preenchimento manual.
- **Performance:** A chamada à IA leva alguns segundos. Cada provedor tem um timeout (60 s por padrão); ao estourar, o commit segue sem a mensagem sugerida.
- **Retorno Positivo:** O sistema sempre retorna 'sucesso' para o Git, garantindo que o processo de commit nunca seja interrompido por erros técnicos da automação.

---

## 📋 Requisitos e Tecnologias

1.  **PowerShell 5.1+:** Linguagem principal do projeto para integração nativa com o Windows (arquivos `.ps1`).
2.  **Node.js (LTS):** Necessário para rodar os CLIs de IA (Gemini-CLI).
3.  **Local do projeto:** Não é necessário unidade Z:. Basta a pasta do projeto (opcionalmente, defina `GITHOOKS_HOME`).
4.  **API Key:** Uma chave ativa do Google AI Studio (Gratuita).

---

## 🚀 1. Instalação (0 a 100%)

Para facilitar a adoção pelo time, criamos dois níveis de instalação:

### A. Setup Rápido (Apenas TortoiseGit)
Se você usa apenas a interface visual do TortoiseGit, execute:
`<pasta-do-projeto>\gitHooks\setup\Setup-TortoiseGit-IA.bat`
- Ele instala o Node.js e o Gemini-CLI.
- Orienta sobre o login na IA.
- Mostra como configurar o Hook na tela do TortoiseGit.

### B. Setup Completo (Tortoise + Terminal + CI/CD)
Se você quer que a IA funcione também ao digitar `git commit` no terminal, execute:
`powershell -File "<pasta-do-projeto>\gitHooks\setup\Install-All.ps1"`
- Realiza todo o setup básico e instala o hook nativo `prepare-commit-msg` no seu repositório local.

---

## ⚙️ 2. Configurações (settings.txt)

Edite `<pasta-do-projeto>\gitHooks\config\settings.txt` para ajustar o comportamento:

- **PROVIDER:** `Gemini` (Padrão) ou `Claude`. O `Copilot` está desativado: o `gh copilot` é interativo e não gera mensagens de commit.
- **PROMPT_FILE:** 
    - `commit-msg.txt`: Mensagem padrão, direta e concisa.
    - `commit-msg-senior.txt`: Mensagem avançada com análise de impacto e riscos para arquitetos.
- **LANGUAGE:** `PT-BR`.
- **MAX_DIFF_CHARS:** Limite total de caracteres enviados para a IA (Padrão: 80.000). Evita lentidão em commits gigantes.
- **IGNORED_EXTENSIONS:** Lista de extensões que a IA deve ignorar no diff detalhado (ex: `.map, .bin`).
- **INCLUDE_UNTRACKED/INCLUDE_UNSTAGED:** Define se a IA deve "olhar" para arquivos que você ainda não deu `git add`. **Recomendado: FALSE.** O modelo `settings.example.txt` já vem assim; se o seu `settings.txt` local estiver `TRUE`, volte para `FALSE` para não enviar arquivos não versionados à IA.
- **CODE_REVIEW_ENABLED:** `TRUE` ativa a revisão automática antes do `git push` (hook `pre-push`), que envia o diff à IA. Padrão: `FALSE`.
- **PRIORITY_EXTENSIONS / DIFF_CONTEXT_LINES / CLEAR_LOG:** Extensões com mais espaço no diff, linhas de contexto (padrão 1) e limpeza do log a cada execução.
- **LOG_PATH:** Local do log (Default: `C:\LOG-GitHooks\debug.log`).

---

## 🚀 3. Otimização Inteligente (Smart Diff)

Para garantir que a IA seja rápida e precisa, o sistema utiliza uma técnica de **Smart Diff**:
1.  **Sumário de Escopo:** Antes do código, a IA recebe uma lista de *todos* os arquivos alterados.
2.  **Filtragem de Ruído e Espaços:** Arquivos irrelevantes são ignorados e mudanças de indentação/espaços são removidas do diff (`-w`) para focar na lógica.
3.  **Contexto técnico reduzido:** O sistema envia apenas o contexto estritamente necessário (`-U1`) ao redor das mudanças, reduzindo drasticamente o volume de texto sem perder a compreensão técnica.
4.  **Prioridade por Extensão:** Arquivos críticos como `.pas`, `.js` e `.xml` têm prioridade de espaço, enquanto arquivos de configuração são resumidos primeiro.
5.  **Truncamento Estratégico:** Arquivos excessivamente grandes são resumidos para que a IA foque apenas nos blocos de mudança essenciais.

## 🛠️ 4. Configuração Passo a Passo no TortoiseGit

Para que a IA preencha automaticamente sua mensagem de commit na interface visual, siga exatamente estas etapas:

1.  **Acesse as Configurações**: Clique com o botão direito em qualquer pasta do seu repositório -> **TortoiseGit** -> **Settings**.
2.  **Selecione Hook Scripts**: No menu à esquerda, navegue até a seção **Hook Scripts**.
3.  **Adicione um Novo Hook**: Clique no botão **Add...** à direita.
4.  **Configure assim**:
    - **Hook Type**: Selecione `Start Commit Hook`.
    - **Run when working tree path is under**: Coloque um asterisco `*` (ou o caminho do seu projeto).
    - **Command Line To Execute**: 
      `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<pasta-do-projeto>\gitHooks\actions\GenerateCommitMsg.ps1"`
    - **Wait for the script to finish**: **MARCADA** (Obrigatório).
    - **Hide the script while running**: **MARCADA** (Recomendado).
5.  **Salve**: Clique em **OK** e pronto!

**COMO TESTAR:** Abra a tela de commit do TortoiseGit (com arquivos já marcados para commit). A mensagem aparecerá automaticamente em poucos segundos.

---

## 🔒 Segurança do envio à IA

Antes de qualquer diff sair da sua máquina:
- Arquivos sensíveis (`.env*`, `*.pem`, `*.pfx`, `*.key`, `appsettings*.json`, `web.config`, `credentials.json` e outros) são omitidos; só o nome aparece no sumário.
- Chaves e credenciais conhecidas (Google, OpenAI, GitHub, AWS, Slack, JWT, blocos PEM e atribuições como `password=`) são mascaradas com `[REDACTED]`.
- O Claude roda com as ferramentas desativadas (`--tools=""`): o modelo só recebe o diff e não lê arquivos do repositório por conta própria.

---

## 🎨 5. Customização de Prompts

Você pode criar seus próprios templates na pasta `prompts/`. O sistema substitui automaticamente:
- `{{DIFF}}`: O código alterado.
- `{{BRANCH}}`: O nome da branch atual (ex: 12345).
- `{{AI_CLI}}`: O motor utilizado.

O formato da primeira linha do commit deve seguir Conventional Commits (`tipo(escopo): descrição`). Se a IA fugir do formato, o texto bruto é mantido e o log registra o aviso.

---

## 🔍 Resolução de Problemas (Troubleshooting)

- **A mensagem não aparece:** Use o script `<pasta-do-projeto>\gitHooks\diagnostics\Verify-Environment.ps1` para validar a conexão.
- **A IA falhou:** Se o CLI sair com erro (cota do Gemini, sessão expirada, login pendente) ou estourar o timeout, o log registra o motivo (início do stderr do CLI) e você preenche a mensagem manualmente.
- **Verificar Logs:** Consulte o log em `C:\LOG-GitHooks\debug.log` para ver o rastro técnico da execução.

## Licença

Este projeto usa **licença dupla**. O texto completo está em [LICENSE](LICENSE).

- **Uso pessoal, educacional e não comercial:** livre, nos termos da licença MIT (mantenha o aviso de copyright).
- **Uso comercial:** exige licença comercial. Isso inclui usar em produto ou serviço comercial, vender acesso ou derivados, usar em atividades com fins lucrativos e implantar em empresas.

Contato para licença comercial: ma.polli@hotmail.com
