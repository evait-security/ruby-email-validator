# ruby-email-validator (v1.0)
This script will validate a file containing a list of e-mail addresses using the truemail gem. All valid emails are written to the output file as list or csv with the default gophish user groups template.

# Installation using bundler
```zsh
bundle config set --local path 'vendor/bundle'
bundle install
```
# Usage
 ```zsh
# default config (smtp validation and list output) 
bundle exec ruby verify.rb -i input_emails.txt -o verified_emails.txt
# smtp validation and csv gophish output
bundle exec ruby verify.rb -i input_emails.txt -o verified_emails.csv -f gophish
# regex validation only and csv gophish output
bundle exec ruby verify.rb -i input_emails.txt -o verified_emails.csv -f gophish -m regex
# using the pipe, no output file, only stdout
cat /tmp/mails.txt | bundle exec ruby verify.rb
```

# Additional info
More information about the validation methods can be found on https://github.com/truemail-rb/truemail#validation-features
