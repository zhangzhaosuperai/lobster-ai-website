# GitHub 仓库设置指南

## 快速设置（2分钟完成）

由于安全限制，我无法直接创建 GitHub 仓库，但你可以快速完成：

### 方法一：使用 GitHub CLI（推荐）

```bash
# 登录 GitHub
gh auth login

# 创建仓库
gh repo create lobster-ai-website --public --description "Lobster AI Website"

# 推送代码
git remote add origin https://github.com/YOUR_USERNAME/lobster-ai-website.git
git branch -M main
git push -u origin main
```

### 方法二：手动创建（最简单）

1. 访问 https://github.com/new
2. 填写信息：
   - Repository name: `lobster-ai-website`
   - Description: `Lobster AI Website`
   - 选择 `Public`
3. 点击 **Create repository**
4. 在仓库页面复制以下命令并执行：

```bash
cd /root/.openclaw/workspace/lobster-ai-website
git remote add origin https://github.com/YOUR_USERNAME/lobster-ai-website.git
git branch -M main
git push -u origin main
```

## 配置 Cloudflare Pages 自动部署

1. 登录 https://dash.cloudflare.com
2. 点击 **Pages** → **Create a project**
3. 选择 **Connect to Git**
4. 选择 GitHub 账户
5. 选择 `lobster-ai-website` 仓库
6. 配置构建设置：
   - Framework preset: None
   - Build command: (留空)
   - Build output directory: `public`
7. 点击 **Save and Deploy**

完成！之后每次推送代码到 GitHub，Cloudflare Pages 会自动重新部署。

## 快速部署命令

```bash
# 修改文件后
git add .
git commit -m "Update website"
git push origin main
# Cloudflare Pages 会自动部署
```
