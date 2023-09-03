#!/usr/bin/env ruby

# Health reminders that rotate based on the current time
# Each reminder is in the format: [hour_to_start, reminder_message]

HEALTH_REMINDERS = [
  [7, '🌞 Morning!'],         # 7 AM
  [9, '🌞💧 Drink Water'],    # 9 AM
  [10, '🌞🧘🏾 Strech'],        # 10 AM
  [11, '💧 Drink Water'],     # 11 AM
  [12, '🍽️  Lunch Time'],     # 12 PM
  [14, '🥤 Energy Drink'],    # 2 PM
  [15, '💧🚶 Water/Walk'],    # 3 PM
  [16, '💧 Drink Water'],     # 4 PM
  [18, '🛑 Wind Down...']     # 6 PM
]

def get_health_reminder
  current_hour = Time.now.hour
  reminder = HEALTH_REMINDERS.reverse.find { |hour, _| current_hour >= hour }

  if reminder
    return reminder.last
  else
    return '🛑 Take Care!' # Default reminder if no match
  end
end

puts get_health_reminder
