# frozen_string_literal: true

module Jobs
  module Chat
    class EmailNotifications < ::Jobs::Scheduled
      # No schedule, no execute chat email notification.
    end
  end
end
