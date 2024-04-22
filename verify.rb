require 'optparse'
require 'truemail'
require 'colorize'
require 'debug'
require 'csv'
require 'mail'

options = {}

# parsing option with gem

op = OptionParser.new do |opts|
  opts.banner = "E-Mail list validator written in ruby using truemail gem"
  opts.separator ''
  opts.separator 'Usage: verify.rb [options]'
  opts.separator 'Example: bundle exec ruby verify.rb -i /tmp/input_list.txt -o /tmp/output_list.txt'
  opts.separator 'Example (gophish csv and regex only): bundle exec ruby verify.rb -i /tmp/input_list.txt -f gophish -o /tmp/output_list.csv -m regex'
  opts.separator 'Example (using the pipe, no outfile): cat /tmp/mails.txt | bundle exec ruby verify.rb'
  opts.separator ''
  opts.on("-i", "--input INPUT", "Input file (list) of unverified emails") do |input_file|
    options[:input_file] = input_file
  end
  opts.on("-o", "--output OUTPUT", "Output file (list) of verified emails") do |output_file|
    options[:output_file] = output_file
  end
  opts.on("-f", "--format FORMAT", "Select output format: gophish (csv),list (default)") do |output_format|
    options[:format] = output_format
  end
  opts.on("-m", "--method METHOD", "Select the validation method: regex (RFC 5322), mx, smtp (default)") do |method|
    options[:method] = method
  end
  opts.on("-d", "--disable-wildcard", "Disable wildcard detection") do |v|
    options[:disable_wildcard_detection] = true
  end
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = true
  end
end

op.parse!

# check if options are set (maybe there is a smoother solution with optionsparser but it will do the job)
unless options[:method]
  options[:method] = "smtp" # set smtp as the default option if not set
end


# reading the input file and split line by line
begin
  unless options[:input_file]
    unless STDIN.tty? # check if pipe is present
      input_data = ARGF.read.split
    end
    unless input_data
      puts op.help
      exit(0)
    end
  else
    input_data = File.read(options[:input_file]).split
  end
rescue => exception
  puts '[!] error while reading input'.red
  puts exception
  exit(1)
end

# configure truemail
Truemail.configure do |config|
  # Required parameter. Must be an existing email on behalf of which verification will be performed
  config.verifier_email = 'verifier@example.com'
  config.verifier_domain = 'example.com'
  config.connection_attempts = 2
  case options[:method]
  when "smtp"
    config.default_validation_type = :smtp
  when "mx"
    config.default_validation_type = :mx
  when "regex"
    config.default_validation_type = :regex
  else # fallback if wrong method selected
    config.default_validation_type = :smtp
  end
  config.smtp_fail_fast = true
  config.smtp_safe_check = false
end

# validating the emails line by line
begin
  unless options[:disable_wildcard_detection]
    # collect all email domains of input_data
    input_domains = []
    input_data.each do |input_email|
      input_domains << Mail::Address.new(input_email).domain
    end
    input_domains.uniq.each do |input_domain|
      truemail_return = Truemail.validate("dlfAxs7TGR91OhmWCbDiqtpcwEEARRJf@#{input_domain}")
      if options[:verbose]
        puts "[*] Checking for wildcard on domain: #{input_domain}"
        puts Hash[truemail_return.result.each_pair.to_a]
      end
      if truemail_return.result.success
        puts "[!] Wildcard on domain #{input_domain} detected".red
      end
    end
  end
  output_data = []
  input_data.each do |input_email|
    truemail_return = Truemail.validate(input_email)
    if truemail_return.result.success
      output_data << truemail_return.result.email
      puts "[+] #{truemail_return.result.email}".green
      puts Hash[truemail_return.result.each_pair.to_a] if options[:verbose]
    else
      puts "[-] #{truemail_return.result.email}".red
      puts Hash[truemail_return.result.each_pair.to_a] if options[:verbose]
    end
  end
rescue => exception
  puts '[!] error while validating the input emails'.red
  puts exception
  exit(1)
end

# writing data to output file
if options[:output_file]
  begin
    case options[:format]
    when "gophish"
      CSV.open(options[:output_file], "w") do |csv|
        # writing the gophish default csv group template header
        csv << ["First Name", "Last Name", "Email", "Position"]
        output_data.each do |email|
          csv << [nil,nil,email,nil]
        end
      end
      puts "[*] #{output_data.size} valid emails out of #{input_data.size} input emails were written to file: #{options[:output_file]} as gophish csv".white
    else
      File.open(options[:output_file], 'w') {|f|f.write output_data.join("\n")}
      puts "[*] #{output_data.size} valid emails out of #{input_data.size} input emails were written to file: #{options[:output_file]} as list".white
    end
  rescue => exception
    puts '[!] error while writing to output file'.red
    puts exception
    exit(1)
  end
end