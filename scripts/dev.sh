#!/usr/bin/env bash
#------------------------------------------------------------------------------
# DevFlow·AI Hugo 开发服务器脚本
# 功能：
# - 检查并安装依赖
# - 启动 Hugo 开发服务器
# - 自动打开浏览器
#------------------------------------------------------------------------------
set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 打印带颜色的消息
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${NC}"
}

# 检查命令是否存在
check_command() {
  if ! command -v "$1" &>/dev/null; then
    return 1
  fi
  return 0
}

# 检查 Hugo
check_hugo() {
  print_msg "$BLUE" "🔍 检查 Hugo 安装..."
  
  if ! check_command "hugo"; then
    print_msg "$RED" "❌ Hugo 未安装"
    print_msg "$YELLOW" "📦 请安装 Hugo Extended v0.148+:"
    
    # 根据系统提供安装建议
    if [[ "$OSTYPE" == "darwin"* ]]; then
      print_msg "$YELLOW" "   brew install hugo"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      print_msg "$YELLOW" "   使用 build.sh 脚本自动下载，或："
      print_msg "$YELLOW" "   snap install hugo --channel=extended"
    fi
    
    print_msg "$YELLOW" "   或访问: https://gohugo.io/installation/"
    return 1
  fi
  
  # 检查版本
  local hugo_version=$(hugo version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  print_msg "$GREEN" "✅ Hugo 已安装 (v${hugo_version})"
  
  # 检查是否为 Extended 版本
  if ! hugo version | grep -q "extended"; then
    print_msg "$YELLOW" "⚠️  建议使用 Hugo Extended 版本以支持 SCSS/SASS"
  fi
  
  return 0
}

# 检查并安装 Hugo 模块依赖
check_dependencies() {
  print_msg "$BLUE" "📦 检查项目依赖..."
  
  # 检查 go.mod 是否存在
  if [[ -f "go.mod" ]]; then
    print_msg "$BLUE" "   下载 Hugo 模块..."
    hugo mod tidy
    print_msg "$GREEN" "✅ 依赖安装完成"
  fi
}

# 打开浏览器
open_browser() {
  local url=$1
  
  # 延迟一秒后打开浏览器
  (sleep 1 && {
    if [[ "$OSTYPE" == "darwin"* ]]; then
      open "$url"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        # WSL 环境
        cmd.exe /c start "$url" 2>/dev/null || true
      else
        # 原生 Linux
        xdg-open "$url" 2>/dev/null || true
      fi
    fi
  }) &
}

# 启动 Hugo 服务器
start_hugo_server() {
  local port=${PORT:-1313}
  local environment=${HUGO_ENV:-development}
  
  print_msg "$BLUE" "🚀 启动 Hugo 开发服务器..."
  print_msg "$YELLOW" "   环境: $environment"
  print_msg "$YELLOW" "   端口: $port"
  print_msg "$YELLOW" "   地址: http://localhost:$port/"
  
  # 打开浏览器
  open_browser "http://localhost:$port/"
  
  # 启动 Hugo，使用开发环境配置
  exec hugo server \
    --environment "$environment" \
    --port "$port" \
    --buildDrafts \
    --buildFuture \
    --gc \
    --disableFastRender \
    --navigateToChanged
}

# 主函数
main() {
  print_msg "$GREEN" "======================================"
  print_msg "$GREEN" "   DevFlow·AI 开发环境启动"
  print_msg "$GREEN" "======================================"
  
  # 检查 Hugo
  if ! check_hugo; then
    exit 1
  fi
  
  # 检查依赖
  check_dependencies
  
  # 启动服务器
  start_hugo_server
}

# 执行主函数
main "$@"