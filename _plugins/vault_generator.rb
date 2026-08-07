#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'

module Jekyll
  # ============================================================
  # VaultGenerator — 将 _vault/ 中的文章注入 Jekyll 站点
  # ============================================================
  # 功能：
  #   1. 递归扫描 _vault/ 下所有 .md 文件（排除 _index.md）
  #   2. 解析 frontmatter，published:false 的文件跳过
  #   3. 从文件路径自动推导 categories
  #   4. 动态创建 Jekyll::Document 并注入 site.posts
  #   5. 为每个分类目录生成 VaultIndexPage（面包屑 + 子分类 + 文章列表）
  # ============================================================
  class VaultGenerator < Generator
    safe true
    priority :high

    def generate(site)
      @site = site
      @vault_dir = File.join(site.source, '_vault')
      return unless Dir.exist?(@vault_dir)

      Jekyll.logger.info('VaultGenerator:', 'Scanning _vault/ ...')

      # { dir_path => { dirs: [], posts: [] } }
      @dir_map = {}

      @vault_docs = []
      @published_count = 0
      @skipped_count = 0

      scan_vault
      inject_posts
      generate_index_pages

      Jekyll.logger.info('VaultGenerator:',
                         "#{@published_count} published, #{@skipped_count} skipped")
    end

    private

    # ----------------------------------------------------------
    # 1. 递归扫描 _vault/
    # ----------------------------------------------------------
    def scan_vault
      Dir.glob(File.join(@vault_dir, '**', '*.md')).each do |filepath|
        next if File.basename(filepath) == '_index.md'

        rel_path = Pathname.new(filepath).relative_path_from(Pathname.new(@vault_dir)).to_s
        dir_key  = File.dirname(rel_path)
        dir_key  = '.' if dir_key == '.'

        content = safe_read(filepath)
        next unless content

        frontmatter = parse_frontmatter(content)
        next unless frontmatter

        # published:false → 跳过
        if frontmatter['published'] == false
          @skipped_count += 1
          next
        end

        @published_count += 1

        # 用路径自动推导 categories（若 frontmatter 未设置）
        categories = frontmatter['categories'] || derive_categories(rel_path)

        doc_data = {
          'title'      => frontmatter['title'] || basename_no_ext(filepath),
          'date'       => frontmatter['date'],
          'categories' => categories,
          'tags'       => frontmatter['tags'] || [],
          'pin'        => frontmatter['pin'] || false,
          'toc'        => frontmatter.fetch('toc', true),
          'comments'   => frontmatter.fetch('comments', true),
          'math'       => frontmatter.fetch('math', false),
          'mermaid'    => frontmatter.fetch('mermaid', true)
        }

        doc_data['author'] = frontmatter['author'] if frontmatter['author']

        body = extract_body(content)

        @vault_docs << {
          path:    filepath,
          data:    doc_data,
          content: body,
          dir_key: dir_key
        }

        # 记录到目录映射
        @dir_map[dir_key] ||= { dirs: Set.new, posts: [] }
        @dir_map[dir_key][:posts] << {
          'title' => doc_data['title'],
          'date'  => doc_data['date'],
          'url'   => nil # 注入后由 Jekyll 生成
        }
      end

      # 收集子目录关系
      @dir_map.each_key do |dir|
        parent = File.dirname(dir)
        parent = '.' if parent == '.'
        @dir_map[parent] ||= { dirs: Set.new, posts: [] }
        @dir_map[parent][:dirs] << dir if dir != '.'
      end
    end

    # ----------------------------------------------------------
    # 2. 注入 posts collection
    # ----------------------------------------------------------
    def inject_posts
      posts_collection = @site.collections['posts']

      @vault_docs.each do |vd|
        doc = Jekyll::Document.new(vd[:path], {
                                     site:       @site,
                                     collection: posts_collection
                                   })

        # 设置数据和内容（绕过 read 方法，因为文件不在 _posts/ 中）
        doc.data.merge!(vd[:data])

        # output 设置：复用 Chirpy 默认的 /posts/:title/ 格式
        doc.data['permalink'] ||= "/posts/#{Jekyll::Utils.slugify(vd[:data]['title'])}/"

        doc.content = vd[:content]

        # 触发 post_init hooks（如 posts-lastmod-hook）
        Jekyll::Hooks.trigger(:posts, :post_init, doc)

        posts_collection.docs << doc
      end

      # 按日期倒序排列
      posts_collection.docs.sort_by! { |d| d.date }.reverse!
    end

    # ----------------------------------------------------------
    # 3. 生成分类索引页
    # ----------------------------------------------------------
    def generate_index_pages
      # 每个子目录的索引页
      @dir_map.each_key do |dir|
        next if dir == '.'

        info = @dir_map[dir]
        # 提取目录名（去掉 A1- B1- C1- 等前缀作为显示名）
        display_name = dir.split('/').last.sub(/^[A-Z]\d-/, '')
        page = VaultIndexPage.new(@site, dir, display_name, info)
        @site.pages << page
      end
    end

    # ----------------------------------------------------------
    # 辅助方法
    # ----------------------------------------------------------

    def safe_read(filepath)
      File.read(filepath, encoding: 'UTF-8')
    rescue StandardError => e
      Jekyll.logger.warn('VaultGenerator:', "Failed to read #{filepath}: #{e.message}")
      nil
    end

    def parse_frontmatter(content)
      return nil unless content =~ /\A---\s*\r?\n(.*?)\r?\n---/m

      YAML.safe_load(Regexp.last_match(1), permitted_classes: [Time])
    rescue StandardError => e
      Jekyll.logger.warn('VaultGenerator:', "YAML parse error: #{e.message}")
      nil
    end

    def extract_body(content)
      # 去掉 frontmatter，返回正文
      content.sub(/\A---\s*\r?\n.*?\r?\n---\r?\n?/m, '')
    end

    def derive_categories(rel_path)
      # _vault/A4-知识库/B1-基金/C1-基金学习/xxx.md
      # => ["知识库", "基金", "基金学习"]
      dir = File.dirname(rel_path)
      return [] if dir == '.'

      dir.split('/').map { |d| d.sub(/^[A-Z]\d-/, '') }.reject(&:empty?)
    end

    def basename_no_ext(filepath)
      File.basename(filepath, File.extname(filepath))
    end
  end

  # ============================================================
  # VaultIndexPage — 分类目录索引页
  # ============================================================
  class VaultIndexPage < Page
    def initialize(site, dir_path, display_name, dir_info)
      @site = site
      @base = site.source

      # 确定 URL 路径
      if dir_path == '.'
        @dir = '/vault/'
        @name = 'index.html'
      else
        @dir = "/vault/#{dir_path}/"
        @name = 'index.html'
      end

      # 确保 _index.md 文件存在时使用文件系统写入
      # 否则使用 Page 基类的写入路径
      if dir_path == '.'
        # 顶层入口，写到 _site/vault/index.html
      end

      self.process(@name)

      # 构建子目录列表
      subdirs = (dir_info[:dirs] || []).map do |d|
        name = d.split('/').last
        display = name.sub(/^[A-Z]\d-/, '')
        {
          'name'  => display,
          'path'  => d,
          'url'   => "/vault/#{d}/",
          'count' => count_posts_in_dir(d)
        }
      end.sort_by { |s| s['name'] }

      # 文章列表（按日期倒序）
      posts = (dir_info[:posts] || []).sort_by { |p| p['date'] || Time.at(0) }.reverse

      # 面包屑
      breadcrumbs = build_breadcrumbs(dir_path)

      self.data = {
        'layout'      => 'vault_index',
        'title'       => display_name,
        'permalink'   => @dir,
        'subdirs'     => subdirs,
        'posts'       => posts,
        'breadcrumbs' => breadcrumbs,
        'dir_path'    => dir_path,
        'published'   => true
      }

      self.content = ''
    end

    private

    def count_posts_in_dir(dir)
      # 递归统计该目录及子目录中的文章数
      vault_dir = File.join(@site.source, '_vault')
      glob = File.join(vault_dir, dir, '**', '*.md')
      Dir.glob(glob).count { |f| File.basename(f) != '_index.md' }
    end

    def build_breadcrumbs(dir_path)
      crumbs = [{ 'name' => '知识库', 'url' => '/vault/' }]
      return crumbs if dir_path == '.'

      parts = dir_path.split('/')
      parts.each_with_index do |part, i|
        display = part.sub(/^[A-Z]\d-/, '')
        path   = parts[0..i].join('/')
        crumbs << { 'name' => display, 'url' => "/vault/#{path}/" }
      end

      crumbs
    end
  end
end
