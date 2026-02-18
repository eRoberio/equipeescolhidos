<p align="center">
	<img src="assets/thechosen.png" alt="Equipe Escolhidos" height="96" />
</p>

# Equipe Escolhidos — The Chosen Ranking

Aplicativo Flutter da Equipe Escolhidos para acompanhamento de rankings, pontos e vendas, com gráficos dinâmicos, relatórios e integração com Firebase. Compatível com Android, iOS, Web e Desktop.

## Visão Geral
- Gestão de lançamentos e pontuações dos colportores.
- Gráficos em pizza (fl_chart) para visualizar participação de cada colportor.
- Ranking de Vendas (R$) e Ranking Geral (Pontos).
- Autenticação e fluxo de login/logout.
- Relatórios diários e painel de metas.

## Principais Funcionalidades
- Ranking de Vendas (R$) e de Pontos.
- Visualização por gráficos: [lib/charts_page.dart](lib/charts_page.dart).
- Dashboard de metas: [lib/goal_dashboard.dart](lib/goal_dashboard.dart) e [lib/goal_widgets.dart](lib/goal_widgets.dart).
- Relatórios e lançamentos: [lib/daily_report_page.dart](lib/daily_report_page.dart), [lib/lancamentos_page.dart](lib/lancamentos_page.dart), [lib/lancamento_colportor_page.dart](lib/lancamento_colportor_page.dart).
- Login e navegação: [lib/login_page.dart](lib/login_page.dart), [lib/main.dart](lib/main.dart).

## Tecnologias
- Flutter (UI multi-plataforma).
- Firebase (Firestore, Auth). Arquivos já presentes como [android/app/google-services.json](android/app/google-services.json) e configurações em iOS/web.
- `fl_chart` para visualização dos dados.

## Como Executar
Pré-requisitos:
- Flutter SDK (instalação oficial: https://docs.flutter.dev/get-started/install)
- Ambiente com pelo menos um dispositivo/alvo (Chrome, Android, iOS, Windows, etc.)

Instalação de dependências:
```bash
flutter pub get
```

Rodar em diferentes plataformas (exemplos):
```bash
# Web (Chrome)
flutter run -d chrome

# Android (emulador ou device)
flutter run -d android

# Windows Desktop
flutter run -d windows
```

## Configuração do Firebase
- Android: já configurado via `google-services.json` em [android/app/google-services.json](android/app/google-services.json).
- iOS: arquivos de configuração presentes em [ios/Runner](ios/Runner) e [ios/Flutter](ios/Flutter).
- Web: arquivo [firebase.json](firebase.json) e artefatos em [build/web](build/web). Caso use seu próprio projeto Firebase, atualize os arquivos de configuração e regras do Firestore conforme sua necessidade.

## Estrutura do Projeto
- Código principal: [lib](lib)
	- Ponto de entrada: [lib/main.dart](lib/main.dart)
	- Páginas de gráficos: [lib/charts_page.dart](lib/charts_page.dart)
	- Ranking: [lib/ranking_page.dart](lib/ranking_page.dart), [lib/ranking_geral_page.dart](lib/ranking_geral_page.dart)
- Ativos: [assets](assets) (inclui `thechosen.png`)
- Web build: [build/web](build/web)

## Contribuição
Contribuições são bem-vindas! Abra um issue com sugestões/bugs e envie PRs com melhorias. Agradecimentos à comunidade e à Equipe Escolhidos pelo apoio.

## Créditos
Feito com carinho pela Equipe Escolhidos. 💙

<img width="528" height="599" alt="image" src="https://github.com/user-attachments/assets/0b6df10a-96cf-4873-bf61-2fb644e1f881" />

<img width="861" height="823" alt="image" src="https://github.com/user-attachments/assets/78bc146f-bef9-4fd6-811a-1e301142fb81" />

<img width="861" height="823" alt="image" src="https://github.com/user-attachments/assets/ab7bf73b-171c-4b6c-8db6-afb84bbc7610" />

<img width="1911" height="339" alt="image" src="https://github.com/user-attachments/assets/038627bf-6d82-4361-b281-108ee77abfcf" />

<img width="795" height="363" alt="image" src="https://github.com/user-attachments/assets/fac52369-eb67-4907-8c63-984066b21bd3" />

<img width="1121" height="300" alt="image" src="https://github.com/user-attachments/assets/34386826-9dae-4204-bdc9-c0aab5625277" />


