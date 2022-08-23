require 'optparse'
require 'truemail'
require 'colorize'
require 'debug'
require 'csv'

options = {}

ARGV << '-h' if ARGV.empty? # set -h if program is called without arguments

# parsing option with gem

OptionParser.new do |opts|
  opts.banner = "E-Mail list validator written in ruby using truemail gem"
  opts.separator ''
  opts.separator 'Usage: main.rb [options]'
  opts.separator 'Example: bundle exec ruby main.rb -i /tmp/input_list.txt -o /tmp/output_list.txt'
  opts.separator 'Example (gophish csv): bundle exec ruby main.rb -i /tmp/input_list.txt -f gophish -o /tmp/output_list.csv'
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
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = true
  end
end.parse!

# check if options are set (maybe there is a smoother solution with optionsparser but it will do the job)
begin
  unless options[:input_file]
    puts '[!] missing input file'.red
    exit(1)
  end
  unless options[:output_file]
    puts '[!] missing output file'.red
    exit(1)
  end
rescue => exception
  puts '[!] error while parsing options'.red
  exit(1)
end

# reading the input file and split line by line
begin
  input_data = File.read(options[:input_file]).split
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
  config.default_validation_type = :smtp
  config.smtp_fail_fast = true
  config.smtp_safe_check = false
end

# validating the emails line by line
begin
  output_data = []
  input_data.each do |input_email|
    truemail_return = Truemail.validate(input_email,  with: :smtp)
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