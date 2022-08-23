# ruby-email-validator (v1.0)
This script will validate a file containing a list of e-mail addresses using the truemail gem. All valid emails are written to the output file as list or csv with the default gophish user groups template.

# Installation using bundler
```zsh
bundle config set --local path 'vendor/bundle'
bundle install
```

# Usage
 ```zsh
bundle exec ruby main.rb -i input_emails.txt -o verified_emails.txt
bundle exec ruby main.rb -i input_emails.txt -o verified_emails.csv -f gophish
```