require 'aws-sdk'
require 'yaml'

# Store mongodump objects to amazon s3. Database must be used as a replica set
#
# Amazon s3 configuration file must be named amazon_s3.yml in $HOME
# or AMAZON_S3_PATH must be set in the environment
#
BACKUP_NB = 100
MONGODUMP_OPTIONS = ARGV[0] ? ARGV[0] : ''

# String format is dump-YYYY-MM-DD.tar.gz
def get_time_object(str)
  obj = Time.new(str[5..8].to_i, str[10..11].to_i, str[13..14].to_i)
  obj
end

# Return position of the oldest archive (to delete)
def get_older_file(list)
  tmp = Time.now
  name = ''

  list.each do |elem|
    elem_to_time = get_time_object(elem)
    if elem_to_time < tmp
      tmp = elem_to_time
      name = elem
    end
  end

  list.index(name)
end

# Load configuration file
s3_path = ENV['AMAZON_S3_PATH'] || ENV['HOME'] + '/amazon_s3.yml'
S3_CONFIG = YAML.load_file(s3_path)


s3 = AWS::S3.new(
  :access_key_id => S3_CONFIG['access_key_id'],
  :secret_access_key => S3_CONFIG['secret_access_key'])


# Get s3 backup bucket and dump directory
BACKUP_BUCKET = S3_CONFIG['backup_bucket']
dump_dir = S3_CONFIG['dump_directory']

bucket = s3.buckets[BACKUP_BUCKET]

# Create dump directory
puts "MongoDB Backup started !"
puts "----> Dumping data"
puts "      Creating dump directory #{dump_dir}"
puts "      Running mongodump #{MONGODUMP_OPTIONS}"
%x[mkdir -p #{dump_dir}; cd #{dump_dir}; mongodump #{MONGODUMP_OPTIONS} >/dev/null]

# Get object list from our bucket
puts "----> Getting object list"
list = bucket.objects()
key_list = list.map { |x| x.key() }

# Delete oldest object if we have to many backups
if list.to_a.length >= BACKUP_NB
  puts "----> Deleting oldest backup"
  bucket.objects[key_list[get_older_file(key_list)]].delete()
end

# Go to the dump directory, make the tarball and upload it
Dir.chdir(dump_dir) do
  puts "----> Save backup to S3"
  tarball = "dump-#{Time.now.to_s[0..-16]}.tar.gz"
  puts "      Creating tarball `#{tarball}'"
  %x[tar -cf #{tarball} dump]
  puts "      Storing tarball to bucket `#{BACKUP_BUCKET}'"
  key = File.basename(tarball)
  bucket.objects[key].write(:file => tarball)
end

# Delete dump directory we just created
puts "----> Cleaning-up"
%x[rm -rf #{dump_dir}]
puts "Backup done !"
