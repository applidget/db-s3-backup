require 'aws/s3'
require 'yaml'

# Get latest backup stored on amazon s3
#
# Used when creating a new server, so when we add it to the replica set it can
# catch up the other databases in the set
#
# Amazon s3 configuration file must be named amazon_s3.yml in $HOME
# or AMAZON_S3_PATH must be set in the environment
#

# String format is dump-YYYY-MM-DD.tar.gz
def get_time_object(str)
  obj = Time.new(str[5..8].to_i, str[10..11].to_i, str[13..14].to_i)
  obj
end

# Return position of the latest archive
def get_latest_file(list)
  tmp = get_time_object(list[0])
  name = ''

  list.each do |elem|
    elem_to_time = get_time_object(elem)
    if elem_to_time > tmp
      tmp = elem_to_time
      name = elem
    end
  end

  list.index(name)
end

# Load configuration file
s3_path = ENV['AMAZON_S3_PATH'] || ENV['HOME'] + '/amazon_s3.yml'
S3_CONFIG = YAML.load_file(s3_path)

# Fix to make aws/s3 works with european buckets
AWS::S3::DEFAULT_HOST.replace "s3-eu-west-1.amazonaws.com"
AWS::S3::Base.establish_connection!(
    :access_key_id     => S3_CONFIG['access_key_id'],
    :secret_access_key => S3_CONFIG['secret_access_key']
  )

# Get s3 backup bucket
BACKUP_BUCKET = S3_CONFIG['backup_bucket']

puts "Extracting MongoDB Backup started !"

# Get object list from our bucket
puts "----> Getting object list"
list = AWS::S3::Bucket.objects(BACKUP_BUCKET)
if list.length == 0
  puts "Bucket is empty. Exiting..."
  exit 0
end
key_list = list.map { |x| x.key() }

puts "----> Searching latest backup"
tarball = key_list[get_latest_file(key_list)]
puts "      Latest is #{tarball}"

puts "----> Downloading backup"
arch = AWS::S3::S3Object.find(tarball, BACKUP_BUCKET)
puts "      Found archive to download"
arch_size = arch.about['content-length']
puts "      Size is #{arch_size.to_i / 1000000} MB"

puts "      Receiving backup..."
open(tarball, 'w') do |file|
  AWS::S3::S3Object.stream(tarball, BACKUP_BUCKET) do |chunk|
    file.write chunk
  end
end
puts "      File received !"

puts "----> Extracting file"
%x[ mkdir latest-backup &>/dev/null; tar -xf #{tarball} -C latest-backup ]
puts "      Extracted file to latest-backup/"

puts "----> Cleaning-up"
%x[ rm -f #{tarball} ]

puts "Finished getting latest backup !"
