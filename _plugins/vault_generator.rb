#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'
require 'set'
require 'digest'
require 'date'
require 'time'
require 'uri'

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
      prepare_urls
      inject_posts
      expose_root_sections
      expose_projects
      expose_tree
      expose_tags
      expose_archives
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

        rel_path = Pathname.new(filepath)
                           .relative_path_from(Pathname.new(@vault_dir)).to_s.tr('\\', '/')
        dir_key  = File.dirname(rel_path).tr('\\', '/')
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

        # Vault 文件夹是唯一公开层级。主题自带 categories 仅保留给旧文章，
        # 避免同一篇 Vault 文章同时出现两套互相冲突的导航。
        vault_categories = derive_categories(rel_path)

        doc_data = {
          'title'      => frontmatter['title'] || basename_no_ext(filepath),
          'date'       => frontmatter['date'],
          'categories' => [],
          'vault_categories' => vault_categories,
          'tags'       => frontmatter['tags'] || [],
          'pin'        => frontmatter['pin'] || false,
          'toc'        => frontmatter.fetch('toc', true),
          'comments'   => frontmatter.fetch('comments', true),
          'math'       => frontmatter.fetch('math', false),
          'mermaid'    => frontmatter.fetch('mermaid', true),
          'permalink'  => frontmatter['permalink'],
          'project_card' => frontmatter['project_card'] == true,
          'summary'    => frontmatter['summary'],
          'stack'      => frontmatter['stack'] || [],
          'status'     => frontmatter['status'],
          'featured'   => frontmatter['featured'] == true
        }
        # Vault notes often contain code examples such as {{value}}. They are
        # content, not Liquid templates, so render Markdown without Liquid.
        doc_data['render_with_liquid'] = false

        doc_data['author'] = frontmatter['author'] if frontmatter['author']

        @vault_docs << {
          path:    filepath,
          data:    doc_data,
          content: extract_body(content),
          rel_path: rel_path,
          dir_key: dir_key
        }

        # 记录到目录映射
        @dir_map[dir_key] ||= { dirs: Set.new, posts: [] }
        @dir_map[dir_key][:posts] << {
          'title' => doc_data['title'],
          'date'  => doc_data['date'],
          'filename' => File.basename(filepath),
          'url'   => nil,
          'source_path' => filepath
        }
      end

      build_directory_hierarchy
    end

    # ----------------------------------------------------------
    # 2. 注入 posts collection
    # ----------------------------------------------------------
    def prepare_urls
      @published_path_urls = {}
      basename_candidates = Hash.new { |hash, key| hash[key] = [] }
      @vault_docs.each do |vd|
        explicit_permalink = vd[:data]['permalink']
        permalink = if explicit_permalink && !explicit_permalink.empty?
                      explicit_permalink
                    else
                      build_permalink(vd[:path], vd[:data]['title'])
                    end
        vd[:data]['permalink'] = permalink
        @published_path_urls[File.expand_path(vd[:path])] = permalink
        basename_candidates[File.basename(vd[:path]).downcase] << permalink
      end
      @published_basename_urls = basename_candidates.filter_map do |basename, urls|
        [basename, urls.first] if urls.length == 1
      end.to_h
    end

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
        doc.data['permalink'] = vd[:data]['permalink']
        doc.data['layout'] = 'vault_post'
        doc.data['vault_breadcrumbs'] = build_vault_breadcrumbs(vd[:dir_key])
        doc.data['vault_dir_path'] = vd[:dir_key]
        doc.data['vault_dir_url'] = vd[:dir_key] == '.' ? '/vault/' : "/vault/#{vd[:dir_key]}/"
        doc.data['vault_dir_name'] = if vd[:dir_key] == '.'
                                      '资料库'
                                    else
                                      clean_folder_name(File.basename(vd[:dir_key]))
                                    end

        body = rewrite_local_assets(vd[:content], vd[:path], vd[:rel_path])
        doc.content = rewrite_local_links(body, vd[:path])

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
        'A1-回忆归档' => '走过的日子、当时的心情，以及多年后仍想记得的片段。',
        'A2-规划' => '曾经想去的方向、做过的选择，以及计划怎样随生活变化。',
        'A3-项目' => '出于需要或兴趣做出的东西，连同过程、失误和下一次尝试。',
        'A4-知识库' => '读过的书、学过的方法，以及未来还可能重新用到的理解。'
      }
      root_dirs = @dir_map.fetch('.', { dirs: Set.new })[:dirs]
      @site.data['vault_sections'] = root_dirs.sort.map do |dir|
        label = File.basename(dir)
        {
          'label' => label,
          'code' => folder_code(label),
          'name' => clean_folder_name(label),
          'url' => "/vault/#{dir}/",
          'description' => descriptions.fetch(label, '公开内容分类。'),
          'count' => count_vault_docs(dir)
        }
      end
    end

    def expose_projects
      projects = @vault_docs.filter_map do |vd|
        next unless vd[:data]['project_card']
        next unless vd[:dir_key].match?(%r{\AA3-项目/[^/]+\z})

        entry = @dir_map[vd[:dir_key]][:posts].find do |candidate|
          candidate['source_path'] == vd[:path]
        end
        next unless entry && entry['url']

        label = File.basename(vd[:dir_key])
        {
          'code' => folder_code(label),
          'name' => clean_folder_name(label),
          'title' => vd[:data]['title'],
          'summary' => vd[:data]['summary'] || '查看项目背景、实现过程与相关文档。',
          'stack' => vd[:data]['stack'],
          'status' => vd[:data]['status'] || '持续整理',
          'featured' => vd[:data]['featured'],
          'docs_url' => "/vault/#{vd[:dir_key]}/",
          'intro_url' => entry['url'],
          'count' => count_vault_docs(vd[:dir_key])
        }
      end

      @site.data['vault_projects'] = projects.sort_by do |project|
        natural_sort_key(project['code'])
      end
    end

    def expose_tree
      @site.data['vault_tree'] = tree_nodes_for('.')
    end

    def tree_nodes_for(parent)
      info = @dir_map.fetch(parent, { dirs: Set.new, posts: [] })
      info[:dirs].sort_by { |path| natural_sort_key(path) }.map do |path|
        label = File.basename(path)
        direct_posts = @dir_map.fetch(path, { posts: [] })[:posts]
                               .sort_by { |post| [post['date'] || Time.at(0), post['title'].to_s] }
                               .reverse
                               .map do |post|
          {
            'title' => post['title'],
            'date' => post['date'],
            'filename' => post['filename'],
            'url' => post['url']
          }
        end

        {
          'label' => label,
          'code' => folder_code(label),
          'name' => clean_folder_name(label),
          'path' => path,
          'url' => "/vault/#{path}/",
          'count' => count_vault_docs(path),
          'children' => tree_nodes_for(path),
          'posts' => direct_posts
        }
      end
    end

    def expose_tags
      groups = Hash.new { |hash, key| hash[key] = [] }
      @vault_docs.each do |vd|
        entry = @dir_map[vd[:dir_key]][:posts].find { |item| item['source_path'] == vd[:path] }
        next unless entry && entry['url']

        Array(vd[:data]['tags']).each do |tag|
          name = tag.to_s.strip
          next if name.empty?

          groups[name] << {
            'title' => vd[:data]['title'],
            'date' => vd[:data]['date'],
            'url' => entry['url'],
            'section' => vd[:data]['vault_categories'].first || '资料库'
          }
        end
      end

      @site.data['vault_tags'] = groups.map do |name, posts|
        {
          'name' => name,
          'id' => "tag-#{Digest::SHA1.hexdigest(name)[0, 10]}",
          'count' => posts.length,
          'posts' => posts.sort_by { |post| post['date'] || Time.at(0) }.reverse
        }
      end.sort_by { |group| [-group['count'], group['name']] }
    end

    def expose_archives
      by_year = Hash.new { |hash, key| hash[key] = Hash.new { |months, month| months[month] = [] } }
      @vault_docs.each do |vd|
        date = vd[:data]['date']
        date = Time.parse(date.to_s) unless date.respond_to?(:year)
        entry = @dir_map[vd[:dir_key]][:posts].find { |item| item['source_path'] == vd[:path] }
        next unless entry && entry['url']

        by_year[date.year][date.month] << {
          'title' => vd[:data]['title'],
          'date' => date,
          'day' => format('%02d', date.day),
          'url' => entry['url'],
          'section' => vd[:data]['vault_categories'].first || '资料库'
        }
      rescue ArgumentError
        next
      end

      @site.data['vault_archives'] = by_year.keys.sort.reverse.map do |year|
        months = by_year[year].keys.sort.reverse.map do |month|
          posts = by_year[year][month].sort_by { |post| post['date'] }.reverse
          {
            'month' => month,
            'label' => "#{month} 月",
            'count' => posts.length,
            'posts' => posts
          }
        end
        {
          'year' => year,
          'count' => months.sum { |month| month['count'] },
          'months' => months
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

    def build_vault_breadcrumbs(dir_path)
      crumbs = [{ 'code' => '', 'name' => '资料库', 'url' => '/vault/' }]
      return crumbs if dir_path == '.'

      parts = dir_path.split('/')
      parts.each_with_index do |part, index|
        crumbs << {
          'code' => folder_code(part),
          'name' => clean_folder_name(part),
          'url' => "/vault/#{parts[0..index].join('/')}/"
        }
      end
      crumbs
    end

    def folder_code(value)
      value[/\A[A-Z]\d+/] || ''
    end

    def clean_folder_name(value)
      value.sub(/^[A-Z]\d+-/, '')
    end

    def count_vault_docs(dir)
      @vault_docs.count do |doc|
        doc[:dir_key] == dir || doc[:dir_key].start_with?("#{dir}/")
      end
    end

    def natural_sort_key(value)
      value.downcase.scan(/\d+|\D+/).map do |part|
        part.match?(/\A\d+\z/) ? [0, part.to_i] : [1, part]
      end
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

    def rewrite_local_links(body, article_path)
      rewritten = body.gsub(/(?<!!)\[([^\]]+)\]\(([^)\s]+)([^)]*)\)/) do
        label = Regexp.last_match(1)
        source = Regexp.last_match(2)
        suffix = Regexp.last_match(3)
        target = resolve_markdown_link(source, article_path)
        target == :private ? label : "[#{label}](#{target || source}#{suffix})"
      end

      rewritten.gsub(/(<a\b[^>]*\bhref=["'])([^"']+)(["'])/i) do
        prefix = Regexp.last_match(1)
        source = Regexp.last_match(2)
        suffix = Regexp.last_match(3)
        target = resolve_markdown_link(source, article_path)
        target == :private ? "#{prefix}##{suffix}" : "#{prefix}#{target || source}#{suffix}"
      end
    end

    def resolve_markdown_link(source, article_path)
      return nil if source.start_with?('#')

      if source =~ %r{\Ahttps?://}i
        uri = URI.parse(source)
        site_host = URI.parse(@site.config['url'].to_s).host
        return nil unless uri.host == site_host && File.extname(uri.path).downcase == '.md'

        return @published_basename_urls[File.basename(uri.path).downcase]
      end
      return nil if source =~ %r{\A(?:[a-z][a-z0-9+.-]*:|/)}i

      path_part, fragment = source.split('#', 2)
      return nil unless File.extname(path_part).downcase == '.md'

      target_path = File.expand_path(path_part, File.dirname(article_path))
      target_url = @published_path_urls[target_path] || @published_basename_urls[File.basename(path_part).downcase]
      return :private unless target_url

      fragment && !fragment.empty? ? "#{target_url}##{fragment}" : target_url
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
          'label' => name,
          'code'  => name[/\A[A-Z]\d+/] || '',
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
        'folder_label' => File.basename(dir_path),
        'folder_code' => File.basename(dir_path)[/\A[A-Z]\d+/] || '',
        'description' => "当前层有 #{subdirs.count} 个子文件夹、#{posts.count} 篇文章；共收录 #{count_posts_in_dir(dir_path)} 篇公开内容。",
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
          normalized_path = doc.path.tr('\\', '/')
          next false unless normalized_path.include?("_vault/#{dir}")

          rel = Pathname.new(doc.path)
                        .relative_path_from(Pathname.new(File.join(@site.source, '_vault')))
                        .to_s.tr('\\', '/')
          rel.start_with?("#{dir}/")
        rescue ArgumentError
          false
        end
      end
    end

    def build_breadcrumbs(dir_path)
      crumbs = [{ 'code' => '', 'name' => '资料库', 'url' => '/vault/' }]
      return crumbs if dir_path == '.'

      parts = dir_path.split('/')
      parts.each_with_index do |part, i|
        display = part.sub(/^[A-Z]\d+-/, '')
        path   = parts[0..i].join('/')
        crumbs << {
          'code' => part[/\A[A-Z]\d+/] || '',
          'name' => display,
          'url' => "/vault/#{path}/"
        }
      end

      crumbs
    end
  end
end
