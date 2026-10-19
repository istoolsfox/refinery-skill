#!/usr/bin/env bash
# ============================================================
# refinery install.sh — 多目标安装器
# 把 skills/refinery/ 安装到本机各 AI Agent 的技能目录。
#
# 用法：
#   ./install.sh              # 自动：装到所有已存在的技能目录；
#                             # 一个都没有时默认装 ~/.agents/skills/
#   ./install.sh --user       # ~/.agents/skills/（跨工具通用位置）
#   ./install.sh --claude     # ~/.claude/skills/（Claude Code）
#   ./install.sh --project    # <当前目录>/.claude/skills/（Claude Code 项目级）
#   ./install.sh --dir PATH   # 任意技能目录（其他 SKILL 兼容 Agent）
#   ./install.sh --all        # user + claude + project 全装
#
# 重复执行 = 覆盖更新（目标 refinery/ 目录整目录替换）。
# ============================================================
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/skills/refinery"
[ -f "$SRC/SKILL.md" ] || { echo "✗ 找不到 $SRC/SKILL.md，请在仓库根目录运行"; exit 1; }

TARGETS=()
MODE="auto"
while [ $# -gt 0 ]; do
  case "$1" in
    --user)    TARGETS+=("$HOME/.agents/skills"); MODE="explicit" ;;
    --claude)  TARGETS+=("$HOME/.claude/skills"); MODE="explicit" ;;
    --project) TARGETS+=("$PWD/.claude/skills");  MODE="explicit" ;;
    --dir)     shift; TARGETS+=("$1");            MODE="explicit" ;;
    --all)     TARGETS+=("$HOME/.agents/skills" "$HOME/.claude/skills" "$PWD/.claude/skills"); MODE="explicit" ;;
    *) echo "未知参数：$1（支持 --user/--claude/--project/--dir PATH/--all）"; exit 1 ;;
  esac
  shift
done

# auto 模式：只装已存在的技能目录；都不存在则落到跨工具通用位置
if [ "$MODE" = "auto" ]; then
  TARGETS=()
  for d in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
    [ -d "$d" ] && TARGETS+=("$d")
  done
  [ ${#TARGETS[@]} -eq 0 ] && TARGETS+=("$HOME/.agents/skills")
fi

install_one() {
  dest="$1/refinery"
  if [ -e "$dest" ] && [ "$dest" -ef "$SRC" ]; then
    echo "= 跳过（目标就是源仓库）：$dest"; return
  fi
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$SRC" "$dest"
  [ -f "$dest/SKILL.md" ] || { echo "✗ 安装失败：$dest/SKILL.md 缺失"; exit 1; }
  echo "✓ 已安装：$dest"
}

for d in "${TARGETS[@]}"; do
  install_one "$d"
done

cat <<'EOF'

完成。触发词：优化代码 / 清理死代码 / 代码体检 / 精炼 / refactor / clean up dead code
提示：部分 Agent 需要重启会话才会重新扫描技能目录。
EOF
