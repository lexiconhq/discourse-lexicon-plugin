# frozen_string_literal: true

require 'rails_helper'

describe 'notification_content' do
  let(:notification_type_mention) { Notification.types[:mentioned] }
  let(:sender) { 'Adam' }
  let(:topic_title) { 'Test Topic' }
  let(:excerpt) { 'This is the notification for test' }

  let(:notification_type_message) { Notification.types[:private_message] }
  

  it 'should generate content and title' do
    expected_title_mention = 'Adam mentioned you - Test Topic'
    expected_body = 'This is the notification for test'

    excerpt_message = 'This is the message for test' 
    expected_title_message = 'Adam sent you a message - Test Topic'

    result_mention = NotificationContent.generate_notification_content(notification_type_mention, sender, topic_title, excerpt)
    expect(result_mention[:title]).to eq(expected_title_mention)
    expect(result_mention[:body]).to eq(expected_body)

    result_message = NotificationContent.generate_notification_content(notification_type_message, sender, topic_title, excerpt_message)
    expect(result_message[:title]).to eq(expected_title_message)
    expect(result_message[:body]).to eq(excerpt_message)
  end

  it 'should generate content and title with other type' do
    notification_type_other = "0"
    excerpt_other = "other notification content"

    expected_title = 'Test Topic'
    expected_other_body = 'Adam: other notification content'

    result_other = NotificationContent.generate_notification_content(notification_type_other, sender, topic_title, excerpt_other)
    expect(result_other[:title]).to eq(expected_title)
    expect(result_other[:body]).to eq(expected_other_body)

  end

  it 'should handle notification type "posted" correctly' do
    notification_type_posted = Notification.types[:posted]
    expected_title_posted = 'Adam posted in - Test Topic'
    excerpt_post = 'This is the posted for test' 

    result_posted = NotificationContent.generate_notification_content(notification_type_posted, sender, topic_title, excerpt_post)
    expect(result_posted[:title]).to eq(expected_title_posted)
    expect(result_posted[:body]).to eq(excerpt_post)
  end

  it 'should handle notification type "linked" correctly' do
    notification_type_linked = Notification.types[:linked]
    expected_title_linked = 'Adam linked to your post - Test Topic'
    expected_linked = 'This is the linked for test'

    result_linked = NotificationContent.generate_notification_content(notification_type_linked, sender, topic_title, expected_linked)
    expect(result_linked[:title]).to eq(expected_title_linked)
    expect(result_linked[:body]).to eq(expected_linked)
  end
end
