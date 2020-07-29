class BbCodes::Tags::CommentTag
  include Singleton

  BBCODE_REGEXP = %r{
    \[comment=(?<comment_id>\d+) (?<quote>\ quote)?\]
      (?<text> .*? )
    \[/comment\]
    |
    \[comment=(?<comment_id>\d+)\]
  }mix

  COMMENT_ID_REGEXP = /\[comment=(\d+)/

  def format text
    comments = fetch_comments text

    text.gsub(BBCODE_REGEXP) do
      comment_to_html(
        $LAST_MATCH_INFO[:comment_id],
        $LAST_MATCH_INFO[:text],
        $LAST_MATCH_INFO[:quote].present?,
        comments
      )
    end
  end

private

  def comment_to_html comment_id, text, is_quoted, comments
    comment = comments[comment_id.to_i]
    user = comment&.user if is_quoted || text.blank?
    author_name = extract_author user, text, comment_id
    css_classes = [
      'bubbled',
      ('b-user16' if is_quoted)
    ].compact.join(' ')

    "[url=#{comment_url(comment_id)} #{css_classes}]" +
      author_html(is_quoted, user, author_name) +
      '[/url]'
  end

  def comment_url comment_id
    UrlGenerator.instance.comment_url comment_id
  end

  def author_html is_quoted, user, author_name
    if is_quoted
      quoteed_author_html user, author_name
    else
      "@#{author_name}"
    end
  end

  def quoteed_author_html user, author_name
    return "<span>#{author_name}</span>" unless user&.avatar&.present?

    <<-HTML.squish
      <img
        src="#{user.avatar_url 16}"
        srcset="#{user.avatar_url 32} 2x"
        alt="#{author_name}"
      /><span>#{author_name}</span>
    HTML
  end

  def extract_author user, text, comment_id
    text.presence || user&.nickname || comment_id
  end

  def fetch_comments text
    comment_ids = text.scan(COMMENT_ID_REGEXP).map { |v| v[0].to_i }

    Comment
      .where(id: comment_ids)
      .includes(:user)
      .index_by(&:id)
  end
end
