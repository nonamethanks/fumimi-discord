require "danbooru/model"
require "discordrb"

class Danbooru
  class Post < Danbooru::Model
    def url
      "https://danbooru.donmai.us/posts/#{id}"
    end

    def full_large_file_url
      if has_large
        "https://danbooru.donmai.us#{large_file_url}"
      else
        full_preview_file_url
      end
    end

    def full_preview_file_url
      "https://danbooru.donmai.us#{preview_file_url}"
    end

    def shortlink
      "post ##{id}"
    end

    def embed_thumbnail(channel_name)
      if is_censored? || is_unsafe?(channel_name)
        Discordrb::Webhooks::EmbedThumbnail.new(url: "http://danbooru.donmai.us.rsz.io#{preview_file_url}?blur=30")
      else
        Discordrb::Webhooks::EmbedThumbnail.new(url: full_preview_file_url)
      end
    end

    def embed_image(channel_name)
      if is_censored? || is_unsafe?(channel_name)
        Discordrb::Webhooks::EmbedImage.new(url: "http://danbooru.donmai.us.rsz.io#{large_file_url}?blur=30")
      else
        Discordrb::Webhooks::EmbedImage.new(url: full_large_file_url)
      end
    end

    def is_unsafe?(channel_name)
      nsfw_channel = (channel_name =~ /^nsfw/i)
      rating != "s" && !nsfw_channel
    end

    def is_censored?
      tag_string.split.grep(/^(loli|shota|toddlercon|guro|scat)$/).any?
    end

    def border_color
      if is_flagged
        0xC41C19
      elsif parent_id
        0x00FF00
      elsif has_active_children
        0xC0C000
      elsif is_pending
        0x0000FF
      end
    end

    def embed_footer
      file_info = "#{image_width}x#{image_height} (#{file_size.to_s(:human_size, precision: 4)} #{file_ext})"
      timestamp = "#{created_at.strftime("%F")} at #{created_at.strftime("%l:%M %p")}"

      Discordrb::Webhooks::EmbedFooter.new({
        text: "#{file_info} | #{timestamp}"
      })
    end
  end
end