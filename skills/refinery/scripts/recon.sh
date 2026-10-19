#!/usr/bin/env bash
# refinery recon.sh — 机械侦察：项目身份 / git 状态 / 哲学文件 / 技术栈 / 测试命令探测
# 用法：cd <项目根> && bash <refinery 目录>/scripts/recon.sh
# 输出：人类可读摘要。只读，不改任何文件。
#
# 自有账号判定（用于区分"自有项目/上游贡献"模式）：
#   依次取 REFINERY_OWN_USER 环境变量 → git config --get github.user
#   都没有时输出"待判定"，refinery 按上游贡献模式保守处理。

set -u

say() { printf '%s\n' "$*"; }
sec() { say ""; say "== $* =="; }

sec "1. git 身份与状态"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  say "repo: yes  branch: ${branch}"
  if [ -n "$(git status --porcelain 2>/dev/null | head -50)" ]; then
    say "worktree: DIRTY（有未提交改动 → 优化前必须先处理）"
    git status --porcelain | head -10 | sed 's/^/  /'
    n=$(git status --porcelain | wc -l | tr -d ' ')
    [ "$n" -gt 10 ] && say "  … 共 ${n} 项"
  else
    say "worktree: clean"
  fi
  OWN_USER="${REFINERY_OWN_USER:-$(git config --get github.user 2>/dev/null || true)}"
  while IFS= read -r r; do
    url=$(git remote get-url "$r" 2>/dev/null || echo "?")
    owner=$(printf '%s' "$url" | sed 's/\.git$//' | awk -F'[:/]' '{print $(NF-1)}')
    if [ -z "$OWN_USER" ]; then
      tag="  ← 待判定（设 REFINERY_OWN_USER=<你的GitHub用户名> 可自动判）"
    elif [ "$owner" = "$OWN_USER" ]; then
      tag="  ← 自有仓库（候选：自有项目模式）"
    else
      tag="  ← 他人仓库（候选：上游贡献模式）"
    fi
    say "remote ${r}: ${url}${tag}"
  done < <(git remote)
  [ -z "$(git remote)" ] && say "remote: none（本地项目 → 自有项目模式）"
else
  say "repo: no（非 git 目录 → 自有项目模式；强烈建议先 git init 再优化）"
fi

sec "2. 哲学与约定文件"
for f in PHILOSOPHY.md AGENTS.md CLAUDE.md CONTRIBUTING.md CONSTRAINTS.md README.md; do
  [ -f "$f" ] && say "found: ${f}" || say "  --  : ${f}"
done
if [ -d docs/adr ]; then
  n=$(ls docs/adr 2>/dev/null | wc -l | tr -d ' ')
  say "docs/adr/: ${n} 条决策记录"
fi

sec "3. 技术栈与候选命令（探测到才列；执行前先看对应文档确认）"
found=0
check() { # $1=标记文件 $2=说明 $3...=候选命令
  local marker="$1" desc="$2"; shift 2
  if [ -e "$marker" ]; then
    found=1
    say "[${desc}] 标记: ${marker}"
    for c in "$@"; do say "    cmd? ${c}"; done
  fi
}
check pubspec.yaml                "Dart/Flutter"  "dart analyze" "dart format --output=none --set-exit-code ." "flutter test" "./scripts/check.sh"
check package.json                "Node/JS/TS"    "npm run lint --if-present" "npx tsc --noEmit" "npm test --if-present"
check pnpm-lock.yaml              "Node(pnpm)"    "pnpm lint" "pnpm test"
check pyproject.toml              "Python"        "ruff check ." "mypy ." "pytest"
check setup.py                    "Python"        "ruff check ." "pytest"
check requirements.txt            "Python"        "ruff check ." "pytest"
check Cargo.toml                  "Rust"          "cargo fmt --check" "cargo clippy" "cargo test"
check go.mod                      "Go"            "go vet ./..." "go test ./..."
check Makefile                    "Make"          "make test" "make lint"
check scripts/check.sh            "全量门禁脚本"  "./scripts/check.sh"
[ "$found" = "0" ] && say "未识别到常见技术栈标记，需人工判断"

sec "4. 测试资产"
for d in test tests __tests__ spec integration_test; do
  [ -d "$d" ] && say "dir: ${d}/ ($(find "$d" -name '*test*' -o -name '*spec*' 2>/dev/null | wc -l | tr -d ' ') 个测试文件)"
done

sec "5. 规模感"
say "源码文件数（常见后缀）：$(find . -path ./node_modules -prune -o -path ./.git -prune -o -path ./build -prune -o -path ./.venv -prune -o -path ./venv -prune -o -path ./dist -prune -o -type f \( -name '*.py' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.dart' -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o -name '*.swift' -o -name '*.kt' \) -print 2>/dev/null | wc -l | tr -d ' ')"

say ""
say "侦察完毕。下一步：人工读 §2 找到的哲学/约定文件，然后按 SKILL.md 第 1 步定档。"
