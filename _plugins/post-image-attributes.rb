# frozen_string_literal: true

# Markdown articles can contain many screenshots. Defer images below the fold
# without changing the source notes or the Vault asset routing rules.
Jekyll::Hooks.register :posts, :post_render do |post|
  next unless post.output_ext == '.html'

  post.output = post.output.gsub(/<img(?![^>]*\bloading=)([^>]*)>/i) do
    %(<img loading="lazy" decoding="async"#{Regexp.last_match(1)}>)
  end
end
