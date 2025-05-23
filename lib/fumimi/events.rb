require "active_support"

module Fumimi::Events
  extend ActiveSupport::Concern

  def self.respond(name, regex, &block)
    @@messages ||= []
    @@messages << { name: name, regex: regex }

    define_method(:"do_#{name}") do |event, *args|
      matches = event.text.scan(/(?<!`)#{regex}(?!`)/)

      matches.each do |match|
        instance_exec(event, match, &block)
      end

      nil
    end
  end

  respond(:post_id, /post #[0-9]+/i) do |event, text|
    post_id = text[/[0-9]+/].to_i

    post = booru.posts.show(post_id)
    post.send_embed(event.channel)
  end

  respond(:forum_id, /forum #[0-9]+/i) do |event, text|
    forum_post_id = text[/[0-9]+/].to_i

    forum_post = booru.forum_posts.show(forum_post_id)
    Fumimi::Model::ForumPost.render_forum_posts(event.channel, [forum_post])
  end

  respond(:topic_id, /topic #[0-9]+/i) do |event, text|
    topic_id = text[/[0-9]+/]

    forum_post = booru.forum_posts.search(topic_id: topic_id).to_a.last
    Fumimi::Model::ForumPost.render_forum_posts(event.channel, [forum_post])
  end

  respond(:comment_id, /comment #[0-9]+/i) do |event, text|
    id = text[/[0-9]+/]

    comment = booru.comments.show(id)
    Fumimi::Model::Comment.render_comments(event.channel, [comment])
  end

  respond(:wiki_link, /\[\[ [^\]]+ \]\]/x) do |event, text|
    title = text[/[^\[\]]+/]

    event.channel.start_typing
    Fumimi::Model::WikiPage.render_wiki_page(event.channel, title, booru)
  end

  respond(:search_link, /{{ [^\}]+ }}/x) do |event, text|
    search = text[/[^{}]+/]

    event.channel.start_typing
    posts = booru.posts.index(limit: 3, tags: search)

    posts.each do |post|
      post.send_embed(event.channel)
    end
  end

  respond(:artist_id, /artist #[0-9]+/i) do |event, text|
    id = text[/[0-9]+/]
    event << "https://danbooru.donmai.us/artists/#{id}"
  end

  respond(:note_id, /note #[0-9]+/i) do |event, text|
    id = text[/[0-9]+/]

    note = booru.notes.show(id)
    event << "https://danbooru.donmai.us/posts/#{note.post_id}#note-#{note.id}"
  end

  respond(:pixiv_id, /pixiv #[0-9]+/i) do |event, text|
    id = text[/[0-9]+/]
    event << "https://www.pixiv.net/member_illust.php?mode=medium&illust_id=#{id}"
  end

  respond(:pool_id, /pool #[0-9]+/i) do |event, text|
    id = text[/[0-9]+/]
    event << "https://danbooru.donmai.us/pools/#{id}"
  end

  respond(:user_id, /user #[0-9]+/i) do |event, text|
    id = text[/[0-9]+/]
    event << "https://danbooru.donmai.us/users/#{id}"
  end

  respond(:issue_id, /issue #[0-9]+/i) do |event, text|
    issue_id = text[/[0-9]+/]
    event.send_message "https://github.com/danbooru/danbooru/issues/#{issue_id}"
  end

  respond(:pull_id, /pull #[0-9]+/i) do |event, text|
    pull_id = text[/[0-9]+/]
    event.send_message "https://github.com/danbooru/danbooru/pull/#{pull_id}"
  end

  def do_convert_post_links(event)
    post_ids = []

    message = event.message.content.gsub(%r{\b(?!https?://\w+\.donmai\.us/posts/\d+/\w+)https?://(?!testbooru)\w+\.donmai\.us/posts/(\d+)\b[^[:space:]]*}i) do |link|
      post_ids << ::Regexp.last_match(1).to_i
      "<#{link}>"
    end

    if post_ids.present?
      event.message.delete
      event.send_message("#{event.author.display_name} posted: #{message}", false, nil, nil, false) # tts, embed, attachments, allowed_mentions

      post_ids.each do |post_id|
        post = booru.posts.show(post_id)
        post.send_embed(event.channel)
      end
    end

    nil
  end
end
