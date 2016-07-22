class AddEnglishSiteRulesTopic < ActiveRecord::Migration
  EN_SITE_RULES_TOPIC_ID = 220_000

  def up
    return if Rails.env.test?

    Topic.create!(
      id: EN_SITE_RULES_TOPIC_ID,
      title: 'Site rules',
      user_id: 1,
      forum_id: 4,
      body: en_site_rules_topic_body,
      locale: :en
    )
  end

  def down
    return if Rails.env.test?
    Topic.find(EN_SITE_RULES_TOPIC_ID).destroy
  end

private

  def en_site_rules_topic_body
    I18n.t 'sticky_topic_view.site_rules.body', locale: :en
  end
end
