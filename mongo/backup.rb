require 'aws/s3'
require 'yaml'

# Store mongodump objects to amazon s3
#
# Amazon s3 configuration file must be named amazon_s3.yml in $HOME
# or AMAZON_S3_PATH must be set in the environment

def run_recursively(list, key_list, dir, base)
  Dir.foreach(dir) do |entry|
    if entry.length > 1 && entry[0] != '.'
      if File.directory?(dir + '/' + entry)
        run_recursively(list, key_list, dir + '/' + entry, base + '/' + entry)
      else
        file = base + '/' + entry
        count = key_list.count(file)
        puts "Storing file #{file}... (#{count} already)"
        AWS::S3::S3Object.store(file + '-' + Time.now.to_s[0..-7], open(dir + '/' + entry), BACKUP_BUCKET)
      end
    end
  end
end

# Load configuration file
s3_path = ENV['AMAZON_S3_PATH'] || ENV['HOME'] + '/amazon_s3.yml'
S3_CONFIG = YAML.load_file(s3_path)

BACKUP_BUCKET = S3_CONFIG['backup_bucket']

dump_dir = S3_CONFIG['dump_directory']

%x[mkdir -p #{dump_dir}; cd #{dump_dir}; mongodump]

# Fix to make aws/s3 works with european buckets
AWS::S3::DEFAULT_HOST.replace "s3-eu-west-1.amazonaws.com"
AWS::S3::Base.establish_connection!(
    :access_key_id     => S3_CONFIG['access_key_id'],
    :secret_access_key => S3_CONFIG['secret_access_key']
  )

list = AWS::S3::Bucket.objects(BACKUP_BUCKET)
key_list = list.map { |x| x.key().split('-')[0] }

Dir.chdir(dump_dir + '/dump') do
  run_recursively(list, key_list, Dir.pwd, Dir.pwd.split('/')[-1])
  puts "Upload done !"
end

%x[rm -rf #{dump_dir}]
