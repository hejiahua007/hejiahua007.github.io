#!/usr/bin/env ruby
# frozen_string_literal: true

# Lightweight local fallback for environments where html-proofer cannot load
# libcurl. GitHub Actions still runs the full html-proofer suite.

require 'json'
require 'nokogiri'
require 'pathname'
require 'uri'

site_root = Pathname.new(ARGV[0] || '_site').expand_path
abort "Site directory not found: #{site_root}" unless site_root.directory?

html_files = Dir.glob(site_root.join('**', '*.html')).sort
errors = []
documents = {}

resolve_target = lambda do |source_file, raw_url|
  clean_url = raw_url.to_s.split(/[?#]/, 2).first
  return nil if clean_url.empty? || clean_url.match?(%r{\A(?:https?:|mailto:|tel:|javascript:|data:|//)}i)

  clean_url = URI::DEFAULT_PARSER.unescape(clean_url)
  candidate = if clean_url.start_with?('/')
                site_root.join(clean_url.delete_prefix('/'))
              else
                Pathname.new(source_file).dirname.join(clean_url).cleanpath
              end

  choices = [candidate]
  # A directory-style URL may end in a filename containing a dot (for example
  # "v2.1/"). Its final segment is not a file extension when the URL has a
  # trailing slash.
  choices << candidate.join('index.html') if clean_url.end_with?('/') || candidate.extname.empty?
  choices << Pathname.new("#{candidate}.html") if candidate.extname.empty?
  choices.find(&:file?)
rescue ArgumentError
  nil
end

html_files.each do |path|
  content = File.read(path, encoding: 'UTF-8')
  doc = Nokogiri::HTML5(content)
  documents[Pathname.new(path).expand_path.to_s] = doc

  ids = doc.css('[id]').map { |node| node['id'] }
  ids.tally.each { |id, count| errors << "#{path}: duplicate id ##{id}" if count > 1 }

  doc.css('img').each do |image|
    errors << "#{path}: image missing alt: #{image['src']}" unless image.key?('alt')
  end

  doc.css('script[type="application/ld+json"]').each do |script|
    JSON.parse(script.text)
  rescue JSON::ParserError => e
    errors << "#{path}: invalid JSON-LD: #{e.message}"
  end

  doc.css('a[href], img[src], script[src], link[href]').each do |node|
    attribute = node.key?('href') ? 'href' : 'src'
    raw_url = node[attribute]
    next if raw_url.nil? || raw_url.empty? || raw_url.start_with?('#')

    target = resolve_target.call(path, raw_url)
    next if target || raw_url.match?(%r{\A(?:https?:|mailto:|tel:|data:|//)}i)

    errors << "#{path}: missing local target #{raw_url}"
  end
end

html_files.each do |path|
  doc = documents[Pathname.new(path).expand_path.to_s]
  doc.css('a[href*="#"]').each do |link|
    raw_url = link['href']
    path_part, fragment = raw_url.split('#', 2)
    next if fragment.nil? || fragment.empty? || raw_url.match?(%r{\Ahttps?://}i)

    target_path = if path_part.empty?
                    Pathname.new(path).expand_path
                  else
                    resolve_target.call(path, path_part)
                  end
    next unless target_path

    target_doc = documents[target_path.expand_path.to_s]
    target_doc ||= Nokogiri::HTML5(File.read(target_path, encoding: 'UTF-8'))
    decoded_fragment = URI::DEFAULT_PARSER.unescape(fragment)
    fragment_exists = target_doc.css('[id]').any? { |node| node['id'] == decoded_fragment }
    errors << "#{path}: missing fragment ##{fragment} in #{raw_url}" unless fragment_exists
  rescue ArgumentError
    errors << "#{path}: invalid fragment in #{raw_url}"
  end
end

puts "Built HTML files checked: #{html_files.length}"
if errors.empty?
  puts 'Local links, fragments, image alternatives and JSON-LD are valid.'
  exit 0
end

warn errors.join("\n")
warn "Errors: #{errors.length}"
exit 1
