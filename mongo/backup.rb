require 'aws/s3'
require 'yaml'

BACKUP_NUMBER=300

def run_recursively(dir, base)
  Dir.foreach(dir) do |entry|
    if entry[0] != '.' && File.directory?(entry)
      run_recursively(dir + '/' + entry, base + '/' + entry)
    else
      file = base + '/' + entry
      S3Object.store(file, open(file), backup_bucket)
    end
  end
end

# Load configuration file
S3_CONFIG = YAML.load_file(ENV['HOME'] + '/amazon_s3.yml')

backup_bucket = S3_CONFIG['backup_bucket']
dump_dir = S3_CONFIG['dump_directory']
base_dir = dump_dir.split('/')[-1]

if !dump_dir
  dump_dir = 'dump-tmp'
end

%x[mkdir -p #{dump_dir}; cd #{dump_dir}; mongodump]

AWS::S3::Base.establish_connection!(
    :access_key_id     => S3_CONFIG['access_key_id'],
    :secret_access_key => S3_CONFIG['secret_access_key']
  )

Dir.chdir(dump_dir) do
  run_recursively(Dir.pwd, base_dir)
end

%x[rm -rf #{dump_dir}]
