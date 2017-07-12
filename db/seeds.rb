require 'securerandom'

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
        r = SecureRandom.random_number
        activated = (r < 0.8) ? (5 + (r * 25).to_i).days.ago : nil
        created = (activated ? activated : (5 + (r * 25).to_i).days.ago) - 1.hour

        u = Incline::User.create!(
            name: name,
            email: email,
            password: password,
            password_confirmation: password,
            activated: !!activated,
            activated_at: activated,
            created_at: created,
            recaptcha: 'na'
        )
        if activated
          hist =
              if SecureRandom.random_number < 0.25
                :fail
              elsif SecureRandom.random_number < 0.5
                :mix
              else
                :success
              end

          r += 0.2 if r < 0.2
          while activated < Time.now

            success,message = if hist == :fail
                                [ false, 'Invalid email or password.' ]
                              elsif hist == :success
                                [ true, 'User logged in successfully.' ]
                              elsif SecureRandom.random_number <= 0.5
                                [ false, 'Invalid email or password.' ]
                              else
                                [ true, 'User logged in successfully.' ]
                              end

            u.login_histories.create!(ip_address: '127.0.0.1', successful: success, message: message, created_at: activated)

            activated += r.days
          end
        end
      end
    end
    unless Incline::User.where(enabled: false).count >= 5
      print "Creating disabled test users...\n"
      5.times do |n|
        name = Faker::Name.name
        email = "disabled-#{n+1}@example.com"
        password = 'password'
        u = Incline::User.create!(
            name: name,
            email: email,
            password: password,
            password_confirmation: password,
            enabled: false,
            disabled_by: admin_user.email,
            disabled_at: ((n * 2.5).to_i + 1).days.ago,
            disabled_reason: 'For testing',
            recaptcha: 'na'
        )
      end
    end
  end

end
