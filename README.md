# release-flow-demo

Учебный репозиторий: GitHub Flow + release-please + деплой stage/прод (симуляция).

- `.github/workflows/ci.yml` — проверки до merge (заголовок PR, тесты, заглушка AI-агентов)
- `.github/workflows/deploy-stage.yml` — после merge в main: тесты, «сборка», деплой на stage, smoke
- `.github/workflows/release.yml` — бот держит Release PR; после его merge — тег и GitHub Release
- `.github/workflows/deploy-prod.yml` — деплой на прод вручную (Run workflow с тега v*), только для разрешённых людей

Пройти сценарий: `./walkthrough.sh`
