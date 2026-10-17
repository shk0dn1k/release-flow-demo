#!/usr/bin/env bash
# Пошаговая прогулка по флоу. Запускать из папки release-flow-demo.
# Нужны: git, gh (GitHub CLI), выполненный `gh auth login`.
set -euo pipefail

REPO_NAME="${REPO_NAME:-release-flow-demo}"

bold()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
say()   { printf '%s\n' "$*"; }
pause() { printf '\n\033[2m[Enter — дальше]\033[0m '; read -r _; }

wait_checks() {
  local pr="$1"
  say "Жду запуска проверок..."
  sleep 15
  gh pr checks "$pr" --watch --interval 5 || true
}

wait_release_pr() {
  say "Жду, пока бот создаст/обновит Release PR (обычно до минуты)..."
  for _ in $(seq 1 30); do
    RELEASE_PR=$(gh pr list --label "autorelease: pending" --json number --jq '.[0].number' 2>/dev/null || true)
    [[ -n "${RELEASE_PR:-}" ]] && { say "Release PR: #$RELEASE_PR"; return; }
    sleep 6
  done
  say "Release PR пока не появился — проверь вкладку Actions, workflow «release»."
}

make_pr() {
  local branch="$1" title="$2"
  git add -A
  git commit -q -m "$title"
  git push -q -u origin "$branch"
  gh pr create --title "$title" --body "Демо: $title" --head "$branch" --base main >/dev/null
  gh pr view "$branch" --json number --jq .number
}

# ---------- Шаг 0. Создание репозитория ----------
command -v gh >/dev/null || { echo "Установи GitHub CLI: https://cli.github.com"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Сначала выполни: gh auth login"; exit 1; }

OWNER=$(gh api user --jq .login)
USER_ID=$(gh api user --jq .id)
FULL="$OWNER/$REPO_NAME"

bold "Шаг 0. Создаю публичный репозиторий $FULL"
say "Публичный — потому что апрувы деплоя (environments) на бесплатном плане работают только в публичных репо."
say "Секретов в нём нет, всё — симуляция."
pause

gh repo create "$FULL" --public --description "Демо флоу: PR → stage → Release PR → прод" >/dev/null

say "Разрешаю Actions создавать PR (нужно боту release-please)..."
gh api -X PUT "repos/$FULL/actions/permissions/workflow" \
  -f default_workflow_permissions=write -F can_approve_pull_request_reviews=true >/dev/null

say "Создаю окружения: stage (без апрува) и production (апрув — ты)..."
gh api -X PUT "repos/$FULL/environments/stage" >/dev/null
printf '{"reviewers":[{"type":"User","id":%s}]}' "$USER_ID" \
  | gh api -X PUT "repos/$FULL/environments/production" --input - >/dev/null

git init -q -b main
chmod +x src/*.sh tests/*.sh walkthrough.sh
git add -A
git commit -q -m "chore: начальная структура"
git remote add origin "https://github.com/$FULL.git"
git push -q -u origin main

say "Отмечаю стартовую версию v1.0.0..."
gh release create v1.0.0 --title "v1.0.0" --notes "Стартовая версия" >/dev/null

bold "Готово: https://github.com/$FULL"
say "Открой вкладку Actions — там уже бежит deploy-stage для первого коммита."
say "Settings → Environments — видно stage и production с тобой в Required reviewers."
pause

# ---------- Шаг 1. Фича ----------
bold "Шаг 1. Разработчик делает фичу: ручная корректировка баланса"
git checkout -q -b feat/adjust
cat > src/adjust.sh <<'X'
#!/usr/bin/env bash
# Использование: adjust.sh <баланс> <изменение> <причина>
set -euo pipefail
[[ $# -eq 3 && -n "$3" ]] || { echo "нужна причина" >&2; exit 1; }
bash "$(dirname "$0")/balance.sh" "$1" "$2"
X
cat > tests/adjust.test.sh <<'X'
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
check "корректировка с причиной" "90" "$(bash src/adjust.sh 100 -10 'ошибка оператора')"
check "без причины — отказ" "fail" "$(bash src/adjust.sh 100 -10 '' 2>/dev/null || echo fail)"
exit $FAILED
X
PR1=$(make_pr feat/adjust "feat: ручная корректировка баланса с причиной")
say "Открыт PR #$PR1: https://github.com/$FULL/pull/$PR1"
say "Смотри внизу PR блок Checks: заголовок, тесты, AI-агенты."
wait_checks "$PR1"
pause

bold "Merge PR #$PR1 (squash) → main"
gh pr merge "$PR1" --squash --delete-branch >/dev/null
git checkout -q main && git pull -q
say "Сейчас в Actions запустились два workflow:"
say "  deploy-stage — тесты на main, «сборка», деплой на stage, smoke"
say "  release      — бот создаёт Release PR"
wait_release_pr
say "Открой Release PR: https://github.com/$FULL/pull/${RELEASE_PR:-}"
say "Посмотри вкладку Files changed: version.txt → 1.1.0 и CHANGELOG.md с пунктом «Новое»."
pause

# ---------- Шаг 2. Исправление ----------
bold "Шаг 2. Другой разработчик чинит баг: понятная ошибка при пустых аргументах"
git checkout -q -b fix/args
cat > src/balance.sh <<'X'
#!/usr/bin/env bash
# Использование: balance.sh <текущий баланс> <изменение>
set -euo pipefail
[[ $# -eq 2 ]] || { echo "использование: balance.sh <баланс> <изменение>" >&2; exit 1; }
current="$1"
delta="$2"
echo $(( current + delta ))
X
PR2=$(make_pr fix/args "fix: понятная ошибка при неверных аргументах")
say "PR #$PR2: https://github.com/$FULL/pull/$PR2"
wait_checks "$PR2"
gh pr merge "$PR2" --squash --delete-branch >/dev/null
git checkout -q main && git pull -q
say "Смержено. Release PR обновится сам — в changelog появится раздел «Исправления»."
say "Версия останется 1.1.0: есть feat, значит минорная."
sleep 30
pause

# ---------- Шаг 3. Неправильный заголовок ----------
bold "Шаг 3. Кто-то открыл PR с заголовком не по формату"
git checkout -q -b chore/readme
echo "" >> README.md && echo "Демо-изменение." >> README.md
PR3=$(make_pr chore/readme "поправил ридми")
say "PR #$PR3: https://github.com/$FULL/pull/$PR3"
say "Проверка «Формат заголовка PR» упадёт."
wait_checks "$PR3"
say "Исправляю заголовок на «docs: уточнил README» — проверка перезапустится сама."
gh pr edit "$PR3" --title "docs: уточнил README" >/dev/null
wait_checks "$PR3"
gh pr merge "$PR3" --squash --delete-branch >/dev/null
git checkout -q main && git pull -q
say "docs скрыт в changelog — в Release PR ничего не добавится, но версия не сломается."
pause

# ---------- Шаг 4. Сломанный тест ----------
bold "Шаг 4. PR, который ломает расчёт баланса"
git checkout -q -b fix/broken
sed -i.bak 's/current + delta/current - delta/' src/balance.sh && rm -f src/balance.sh.bak
PR4=$(make_pr fix/broken "fix: пересчёт баланса")
say "PR #$PR4: https://github.com/$FULL/pull/$PR4"
say "Тесты упадут — в логе job «Тесты» видно, какие именно."
wait_checks "$PR4"
say "В реальной схеме merge будет заблокирован. Закрываю PR."
gh pr close "$PR4" --delete-branch >/dev/null
git checkout -q main && git branch -q -D fix/broken
pause

# ---------- Шаг 5. Релиз ----------
wait_release_pr
bold "Шаг 5. День релиза: тех лид открывает Release PR #${RELEASE_PR:-}"
say "https://github.com/$FULL/pull/${RELEASE_PR:-}"
say "Changelog = список того, что едет на прод. Тех лид сверяет его с QA."
pause

bold "Merge Release PR"
gh pr merge "$RELEASE_PR" --squash >/dev/null
git pull -q
say "Бот создаст тег v1.1.0 и GitHub Release, затем job deploy-prod остановится на апруве."
say ""
say "Открой: https://github.com/$FULL/actions/workflows/release.yml"
say "В последнем запуске будет «Waiting for review» → Review deployments → production → Approve."
say "Это тот самый момент, где в реальной схеме апрувит тех лид или ты (если деньги)."
pause

bold "Что посмотреть в итоге"
say "  Releases:      https://github.com/$FULL/releases — v1.1.0 с changelog"
say "  Tags:          https://github.com/$FULL/tags"
say "  Deployments:   https://github.com/$FULL/deployments — история stage и production"
say "  CHANGELOG.md:  в main"
say ""
say "Удалить демо: gh repo delete $FULL --yes"
