// Deployment procfile for Aptible
cmd: bundle exec rails s -b 0.0.0.0 -p 3000
worker: bundle exec rails jobs:work
cron: exec supercronic /app/crontab
release: bin/rails heroku:release
web: bundle exec rails server
