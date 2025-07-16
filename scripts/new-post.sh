#!/usr/bin/env bash
#------------------------------------------------------------------------------
# DevFlow·AI 交互式文章创建脚本
# 参考现代 CLI 工具的最佳实践，提供优雅的交互体验
#------------------------------------------------------------------------------
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POSTS_DIR="${PROJECT_ROOT}/content/posts"

# 默认值
DEFAULT_AUTHOR="${POST_AUTHOR:-DevFlow}"
DEFAULT_SHOW_TOC="true"
DEFAULT_DRAFT="false"

# 打印带颜色的消息
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${NC}"
}

# 打印标题
print_header() {
  echo
  print_msg "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print_msg "$CYAN" "     📝 DevFlow·AI 新文章创建向导"
  print_msg "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
}

# 带默认值的输入提示
prompt_with_default() {
  local prompt=$1
  local default=$2
  local var_name=$3
  
  if [[ -n "$default" ]]; then
    printf "${BOLD}${prompt}${NC} ${DIM}(${default})${NC}: "
  else
    printf "${BOLD}${prompt}${NC}: "
  fi
  
  read -r input
  
  if [[ -z "$input" && -n "$default" ]]; then
    eval "$var_name='$default'"
  else
    eval "$var_name='$input'"
  fi
}

# 多选输入（用于标签）
prompt_tags() {
  print_msg "$BOLD" "📌 标签 (用空格分隔，直接回车跳过):"
  print_msg "$DIM" "   常用: frontend ai javascript typescript react vue css hugo"
  printf "   > "
  read -r tags_input
  
  if [[ -n "$tags_input" ]]; then
    # 将空格分隔的标签转换为 YAML 数组格式
    IFS=' ' read -ra TAGS_ARRAY <<< "$tags_input"
    TAGS="["
    for i in "${!TAGS_ARRAY[@]}"; do
      if [[ $i -gt 0 ]]; then
        TAGS+=", "
      fi
      TAGS+="\"${TAGS_ARRAY[$i]}\""
    done
    TAGS+="]"
  else
    TAGS=""
  fi
}

# 多作者输入
prompt_authors() {
  print_msg "$BOLD" "👥 作者 (用逗号分隔，直接回车使用默认):"
  printf "   > "
  read -r authors_input
  
  if [[ -z "$authors_input" ]]; then
    AUTHORS="\"$DEFAULT_AUTHOR\""
  else
    # 将逗号分隔的作者转换为 YAML 数组格式
    IFS=',' read -ra AUTHORS_ARRAY <<< "$authors_input"
    AUTHORS="["
    for i in "${!AUTHORS_ARRAY[@]}"; do
      if [[ $i -gt 0 ]]; then
        AUTHORS+=", "
      fi
      # 去除前后空格
      author=$(echo "${AUTHORS_ARRAY[$i]}" | xargs)
      AUTHORS+="\"$author\""
    done
    AUTHORS+="]"
  fi
}

# 是/否选择
prompt_yes_no() {
  local prompt=$1
  local default=$2
  local var_name=$3
  
  local options
  if [[ "$default" == "true" ]]; then
    options="Y/n"
    default_val="Y"
  else
    options="y/N"
    default_val="N"
  fi
  
  printf "${BOLD}${prompt}${NC} ${DIM}(${options})${NC}: "
  read -r input
  
  # 如果没有输入，使用默认值
  if [[ -z "$input" ]]; then
    input=$default_val
  fi
  
  # 转换为小写
  input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
  
  if [[ "$input" == "y" || "$input" == "yes" ]]; then
    eval "$var_name='true'"
  else
    eval "$var_name='false'"
  fi
}

# 生成文件名
generate_filename() {
  local title=$1
  # 转换为小写，替换空格为短横线，移除特殊字符
  local filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]/-/g' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g')
  echo "$filename"
}

# 创建文章
create_post() {
  local title=$1
  local filename=$2
  local description=$3
  local authors=$4
  local tags=$5
  local show_toc=$6
  local draft=$7
  
  # 获取当前日期
  local date=$(date +%Y-%m-%d)
  
  # 构建 front matter
  local front_matter="---
title: \"$title\"
date: \"$date\"
draft: $draft"
  
  # 添加可选字段
  if [[ -n "$description" ]]; then
    front_matter+="\ndescription: \"$description\""
  fi
  
  if [[ -n "$authors" && "$authors" != "[\"\"]" ]]; then
    front_matter+="\nauthor: $authors"
  fi
  
  if [[ -n "$tags" && "$tags" != "[]" ]]; then
    front_matter+="\ntags: $tags"
  fi
  
  if [[ "$show_toc" == "true" ]]; then
    front_matter+="\nShowToc: true
TocOpen: true"
  fi
  
  front_matter+="\n---\n\n"
  
  # 创建文件路径
  local filepath="${POSTS_DIR}/${filename}.md"
  
  # 检查文件是否已存在
  if [[ -f "$filepath" ]]; then
    print_msg "$YELLOW" "⚠️  文件已存在: $filepath"
    prompt_yes_no "是否覆盖?" "false" "overwrite"
    if [[ "$overwrite" != "true" ]]; then
      print_msg "$RED" "❌ 取消创建"
      return 1
    fi
  fi
  
  # 创建目录（如果不存在）
  mkdir -p "$POSTS_DIR"
  
  # 写入文件
  echo -e "$front_matter" > "$filepath"
  
  # 添加初始内容模板
  cat >> "$filepath" << 'EOF'
<!-- 在这里开始写你的文章 -->

## 引言

在这里介绍文章的背景和目的...

## 主要内容

### 子标题 1

内容...

### 子标题 2

内容...

## 总结

总结文章的主要观点...

## 参考资料

- [参考链接 1](https://example.com)
- [参考链接 2](https://example.com)
EOF
  
  print_msg "$GREEN" "\n✅ 文章创建成功！"
  print_msg "$CYAN" "📄 文件位置: $filepath"
  
  # 询问是否立即编辑
  echo
  prompt_yes_no "是否立即编辑?" "true" "edit_now"
  if [[ "$edit_now" == "true" ]]; then
    # 检查常用编辑器
    if command -v code &>/dev/null; then
      code "$filepath"
    elif command -v vim &>/dev/null; then
      vim "$filepath"
    elif command -v nano &>/dev/null; then
      nano "$filepath"
    else
      print_msg "$YELLOW" "未找到编辑器，请手动打开文件"
    fi
  fi
  
  # 询问是否启动开发服务器
  echo
  prompt_yes_no "是否启动开发服务器?" "true" "start_server"
  if [[ "$start_server" == "true" ]]; then
    print_msg "$CYAN" "\n🚀 启动开发服务器..."
    cd "$PROJECT_ROOT"
    exec ./dev
  fi
}

# 快速模式（通过命令行参数）
quick_mode() {
  local title=$1
  shift
  
  # 解析命令行参数
  local description=""
  local authors="$DEFAULT_AUTHOR"
  local tags=""
  local show_toc="true"
  local draft="false"
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--description)
        description="$2"
        shift 2
        ;;
      -a|--author|--authors)
        authors="$2"
        shift 2
        ;;
      -t|--tags)
        tags="$2"
        shift 2
        ;;
      --no-toc)
        show_toc="false"
        shift
        ;;
      --draft)
        draft="true"
        shift
        ;;
      *)
        print_msg "$RED" "未知参数: $1"
        exit 1
        ;;
    esac
  done
  
  # 生成文件名
  local filename=$(generate_filename "$title")
  
  # 处理标签格式
  if [[ -n "$tags" ]]; then
    IFS=',' read -ra TAGS_ARRAY <<< "$tags"
    tags="["
    for i in "${!TAGS_ARRAY[@]}"; do
      if [[ $i -gt 0 ]]; then
        tags+=", "
      fi
      tag=$(echo "${TAGS_ARRAY[$i]}" | xargs)
      tags+="\"$tag\""
    done
    tags+="]"
  fi
  
  # 处理作者格式
  if [[ -n "$authors" && "$authors" != "$DEFAULT_AUTHOR" ]]; then
    IFS=',' read -ra AUTHORS_ARRAY <<< "$authors"
    authors="["
    for i in "${!AUTHORS_ARRAY[@]}"; do
      if [[ $i -gt 0 ]]; then
        authors+=", "
      fi
      author=$(echo "${AUTHORS_ARRAY[$i]}" | xargs)
      authors+="\"$author\""
    done
    authors+="]"
  else
    authors="\"$authors\""
  fi
  
  create_post "$title" "$filename" "$description" "$authors" "$tags" "$show_toc" "$draft"
}

# 显示帮助信息
show_help() {
  cat << EOF
${BOLD}用法:${NC}
  ./new                     交互式创建新文章
  ./new "文章标题" [选项]   快速创建模式

${BOLD}选项:${NC}
  -d, --description <描述>   文章描述
  -a, --authors <作者>       作者（逗号分隔）
  -t, --tags <标签>          标签（逗号分隔）
  --no-toc                   不显示目录
  --draft                    创建草稿

${BOLD}示例:${NC}
  ./new
  ./new "我的新文章"
  ./new "Hugo 教程" -d "Hugo 静态网站生成器入门" -t "hugo,tutorial"
  ./new "技术分享" --authors "张三,李四" --draft

${BOLD}环境变量:${NC}
  POST_AUTHOR               默认作者名（默认: DevFlow）
EOF
}

# 主函数
main() {
  # 检查参数
  if [[ $# -eq 0 ]]; then
    # 交互模式
    print_header
    
    # 收集信息
    prompt_with_default "📖 文章标题" "" "TITLE"
    if [[ -z "$TITLE" ]]; then
      print_msg "$RED" "❌ 标题不能为空"
      exit 1
    fi
    
    # 生成文件名
    FILENAME=$(generate_filename "$TITLE")
    print_msg "$DIM" "   文件名: ${FILENAME}.md"
    echo
    
    prompt_with_default "📝 文章描述 (可选)" "" "DESCRIPTION"
    echo
    
    prompt_authors
    echo
    
    prompt_tags
    echo
    
    prompt_yes_no "📑 显示目录 (TOC)?" "$DEFAULT_SHOW_TOC" "SHOW_TOC"
    echo
    
    prompt_yes_no "📝 创建为草稿?" "$DEFAULT_DRAFT" "DRAFT"
    echo
    
    # 显示摘要
    print_msg "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_msg "$BOLD" "📋 文章信息摘要:"
    print_msg "$NC" "   标题: $TITLE"
    print_msg "$NC" "   文件: ${FILENAME}.md"
    [[ -n "$DESCRIPTION" ]] && print_msg "$NC" "   描述: $DESCRIPTION"
    print_msg "$NC" "   作者: $AUTHORS"
    [[ -n "$TAGS" ]] && print_msg "$NC" "   标签: $TAGS"
    print_msg "$NC" "   显示目录: $SHOW_TOC"
    print_msg "$NC" "   草稿: $DRAFT"
    print_msg "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    prompt_yes_no "确认创建?" "true" "CONFIRM"
    if [[ "$CONFIRM" != "true" ]]; then
      print_msg "$YELLOW" "❌ 取消创建"
      exit 0
    fi
    
    create_post "$TITLE" "$FILENAME" "$DESCRIPTION" "$AUTHORS" "$TAGS" "$SHOW_TOC" "$DRAFT"
    
  elif [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    show_help
  else
    # 快速模式
    quick_mode "$@"
  fi
}

# 执行主函数
main "$@"