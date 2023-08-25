# frozen_string_literal: true

class ExpoPushNotificationError
  EXPO_TOKEN = 'ExponentPushToken[802DHLBCwOJkdEnRn_fuuG]'

  attr_reader :push_too_many_exp_id, :validation, :device_not_registered

  def initialize
    @push_too_many_exp_id = too_many_exp_id_error
    @validation = validation_error
    @device_not_registered = device_not_registered_error
  end

  private

  def too_many_exp_id_error
    {
      'code' => 'PUSH_TOO_MANY_EXPERIENCE_IDS',
      'message' => 'All push notification messages in the same request must be for the same project; check the details field to investigate conflicting tokens.',
      'details' => { 'test-experience-id': [EXPO_TOKEN] },
      'isTransient' => false
    }
  end

  def validation_error
    {
      'code' => 'VALIDATION_ERROR',
      'message' => '"[2].title" must be a string.',
      'isTransient' => false
    }
  end

  def device_not_registered_error
    {
      'status' => 'error',
      'message' => "\"#{EXPO_TOKEN}\" is not a registered push notification recipient",
      'details' => {
        'error' => 'DeviceNotRegistered',
        'expoPushToken' => EXPO_TOKEN
      }
    }
  end
end
