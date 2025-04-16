require 'database_cleaner/active_record'

RSpec.configure do |config|
  # Sebelum suite test dijalankan
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  # Sebelum setiap test
  config.before(:each) do
    DatabaseCleaner.start
  end

  # Setelah setiap test
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
