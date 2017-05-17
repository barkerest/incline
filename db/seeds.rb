
Incline::Recaptcha::pause_for do

  Incline::User::ensure_admin_exists!

  # For development purposes, we want to add a bunch of enabled users and a handful of disabled users.
  if Rails.env.development?
    admin_user = Incline::User.where(system_admin: true, enabled: true).first
    unless Incline::User.where(enabled: true).count >= 100
      print "Creating enabled test users...\n"
      100.times do |n|
        name = Faker::Name.name
        email = "user-#{n+1}@example.com"
        password = 'password'
        Incline::User.create!(
            name: name,
            email: email,
            password: password,
            password_confirmation: password,
            activated: (n % 5 < 3),
            activated_at: (n % 5 < 3) ? Time.zone.now : nil,
            recaptcha: Incline::Recaptcha::DISABLED
        )
      end
    end
    unless Incline::User.where(enabled: false).count >= 5
      print "Creating disabled test users...\n"
      5.times do |n|
        name = Faker::Name.name
        email = "disabled-#{n+1}@example.com"
        password = 'password'
        Incline::User.create!(
            name: name,
            email: email,
            password: password,
            password_confirmation: password,
            enabled: false,
            disabled_by: admin_user.email,
            disabled_at: Time.zone.now - (n + 1).weeks,
            disabled_reason: 'For testing',
            recaptcha: Incline::Recaptcha::DISABLED
        )
      end
    end
  end

end
