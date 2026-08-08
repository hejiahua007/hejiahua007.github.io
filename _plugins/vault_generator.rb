#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'
require 'set'
require 'digest'
require 'date'

module Jekyll
  # ============================================================
  # VaultGenerator — 将 _vault/ 中的文章注入 Jekyll 站点
  # ============================================================
  # 功能：
  #   1. 递归扫描 _vault/ 下所有 .md 文件（排除 _index.md）
  #   2. 解析 frontmatter，只有 published:true 的文件才发布（fail closed）
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
      @registered_assets = Set.new
      @all_vault_basenames = Set.new
      @published_count = 0
      @skipped_count = 0

      scan_vault
      inject_posts
      expose_root_sections
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

        @all_vault_basenames << File.basename(filepath)

        rel_path = Pathname.new(filepath).relative_path_from(Pathname.new(@vault_dir)).to_s
        dir_key  = File.dirname(rel_path)
        dir_key  = '.' if dir_key == '.'

        content = safe_read(filepath)
        next unless content

        frontmatter = parse_frontmatter(content)
        next unless frontmatter

        # Fail closed: missing/invalid published never reaches the public site.
        unless frontmatter['published'] == true
          @skipped_count += 1
          next
        end

        unless frontmatter['title'] && frontmatter['date']
          Jekyll.logger.warn('VaultGenerator:', "Missing title/date: #{rel_path}")
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
          'mermaid'    => frontmatter.fetch('mermaid', true),
          'permalink'  => frontmatter['permalink']
        }

        doc_data['author'] = frontmatter['author'] if frontmatter['author']

        body = rewrite_local_assets(extract_body(content), filepath, rel_path)

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
          'url'   => nil,
          'source_path' => filepath
        }
      end

      build_directory_hierarchy
    end

    # ----------------------------------------------------------
    # 2. 注入 posts collection
    # ----------------------------------------------------------
    def inject_posts
      posts_collection = @site.collections['posts']

      # During the transition, prefer _vault over a legacy _posts file with
      # the same basename. This removes duplicate pages without deleting data.
      posts_collection.docs.reject! do |doc|
        doc.path.include?('_posts') && @all_vault_basenames.include?(File.basename(doc.path))
      end

      @vault_docs.each do |vd|
        doc = Jekyll::Document.new(vd[:path], {
                                     site:       @site,
                                     collection: posts_collection
                                   })

        # 设置数据和内容（绕过 read 方法，因为文件不在 _posts/ 中）
        doc.data.merge!(vd[:data])

        # Use a stable, unique URL. Chinese-only titles can slugify to an empty
        # string, so a path hash is always included.
        explicit_permalink = vd[:data]['permalink']
        doc.data['permalink'] = if explicit_permalink && !explicit_permalink.empty?
                                  explicit_permalink
                                else
                                  build_permalink(vd[:path], vd[:data]['title'])
                                end

        doc.content = vd[:content]

        # 触发 post_init hooks（如 posts-lastmod-hook）
        Jekyll::Hooks.trigger(:posts, :post_init, doc)

        posts_collection.docs << doc

        post_entry = @dir_map[vd[:dir_key]][:posts].find do |entry|
          entry['source_path'] == vd[:path]
        end
        post_entry['url'] = doc.data['permalink'] if post_entry
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
        display_name = dir.split('/').last.sub(/^[A-Z]\d+-/, '')
        page = VaultIndexPage.new(@site, dir, display_name, info)
        @site.pages << page
      end
    end

    def build_directory_hierarchy
      @dir_map.keys.dup.each do |leaf|
        current = leaf
        while current != '.'
          parent = File.dirname(current)
          parent = '.' if parent == '.'
          @dir_map[parent] ||= { dirs: Set.new, posts: [] }
          @dir_map[parent][:dirs] << current
          current = parent
        end
      end
    end

    def expose_root_sections
      descriptions = {
        'A1-回忆归档' => '过往的日记、反思和经历，按年份归档。',
        'A2-规划' => '年度计划与目标管理。',
        'A3-项目' => '个人项目、设计过程与成果记录。',
        'A4-知识库' => '技术学习、阅读笔记和可复用知识。'
      }
      root_dirs = @dir_map.fetch('.', { dirs: Set.new })[:dirs]
      @site.data['vault_sections'] = root_dirs.sort.map do |dir|
        label = File.basename(dir)
        {
          'label' => label,
          'name' => label.sub(/^[A-Z]\d+-/, ''),
          'url' => "/vault/#{dir}/",
          'description' => descriptions.fetch(label, '公开内容分类。')
        }
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

      YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time])
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

      dir.split('/').map { |d| d.sub(/^[A-Z]\d+-/, '') }.reject(&:empty?)
    end

    def basename_no_ext(filepath)
      File.basename(filepath, File.extname(filepath))
    end

    def build_permalink(filepath, title)
      rel_path = Pathname.new(filepath).relative_path_from(Pathname.new(@vault_dir)).to_s
      basename = basename_no_ext(filepath).sub(/^\d{4}-\d{2}-\d{2}-/, '')
      slug = Jekyll::Utils.slugify(basename)
      slug = Jekyll::Utils.slugify(title.to_s) if slug.empty?
      digest = Digest::SHA1.hexdigest(rel_path)[0, 10]
      slug = 'vault' if slug.empty?
      "/posts/#{slug}-#{digest}/"
    end

    def rewrite_local_assets(body, article_path, rel_path)
      rewritten = body.gsub(/(!\[[^\]]*\]\()([^)\s]+)([^)]*\))/) do
        prefix = Regexp.last_match(1)
        source = Regexp.last_match(2)
        suffix = Regexp.last_match(3)
        public_url = register_local_asset(source, article_path, rel_path)
        "#{prefix}#{public_url || source}#{suffix}"
      end

      rewritten.gsub(/(<img\b[^>]*\bsrc=["'])([^"']+)(["'])/i) do
        prefix = Regexp.last_match(1)
        source = Regexp.last_match(2)
        suffix = Regexp.last_match(3)
        public_url = register_local_asset(source, article_path, rel_path)
        "#{prefix}#{public_url || source}#{suffix}"
      end
    end

    def register_local_asset(source, article_path, rel_path)
      return nil if source =~ %r{\A(?:[a-z][a-z0-9+.-]*:|/|#)}i

      clean_source = source.sub(/\A</, '').sub(/>\z/, '').split(/[?#]/, 2).first
      asset_path = File.expand_path(clean_source, File.dirname(article_path))
      vault_prefix = File.expand_path(@vault_dir) + File::SEPARATOR
      return nil unless asset_path.start_with?(vault_prefix) && File.file?(asset_path)

      article_key = Digest::SHA1.hexdigest(rel_path)[0, 12]
      destination_dir = File.join('assets', 'vault', article_key)
      asset_key = [asset_path, destination_dir]

      unless @registered_assets.include?(asset_key)
        source_dir = Pathname.new(File.dirname(asset_path))
                             .relative_path_from(Pathname.new(@site.source)).to_s
        @site.static_files << VaultStaticFile.new(
          @site,
          @site.source,
          source_dir,
          File.basename(asset_path),
          destination_dir
        )
        @registered_assets << asset_key
      end

      "/#{destination_dir.tr('\\', '/')}/#{File.basename(asset_path)}"
    rescue StandardError => e
      Jekyll.logger.warn('VaultGenerator:', "Asset error #{source}: #{e.message}")
      nil
    end
  end

  class VaultStaticFile < StaticFile
    def initialize(site, base, source_dir, name, destination_dir)
      super(site, base, source_dir, name)
      @vault_destination_dir = destination_dir
    end

    def destination(dest)
      File.join(dest, @vault_destination_dir, @name)
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
        display = name.sub(/^[A-Z]\d+-/, '')
        {
          'name'  => display,
          'path'  => d,
          'url'   => "/vault/#{d}/",
          'count' => count_posts_in_dir(d)
        }
      end.sort_by { |s| natural_sort_key(s['path']) }

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

    def natural_sort_key(value)
      value.downcase.scan(/\d+|\D+/).map do |part|
        part.match?(/\A\d+\z/) ? [0, part.to_i] : [1, part]
      end
    end

    def count_posts_in_dir(dir)
      # Count only documents that passed the strict publication gate.
      @site.collections['posts'].docs.count do |doc|
        begin
          next false unless doc.path.include?(File.join('_vault', dir))

          rel = Pathname.new(doc.path)
                        .relative_path_from(Pathname.new(File.join(@site.source, '_vault'))).to_s
          rel.start_with?("#{dir}/")
        rescue ArgumentError
          false
        end
      end
    end

    def build_breadcrumbs(dir_path)
      crumbs = [{ 'name' => '知识库', 'url' => '/vault/' }]
      return crumbs if dir_path == '.'

      parts = dir_path.split('/')
      parts.each_with_index do |part, i|
        display = part.sub(/^[A-Z]\d+-/, '')
        path   = parts[0..i].join('/')
        crumbs << { 'name' => display, 'url' => "/vault/#{path}/" }
      end

      crumbs
    end
  end
end
