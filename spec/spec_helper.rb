require "yaml"
require "gmap"

def sample_config
  config = YAML.load(<<EOM)
ruby_path      : /path/to/ruby
qsub_path      : /path/to/qsub

tophat_path    : /path/to/tophat
bowtie_path    : /path/to/bowtie
soap2_path     : /path/to/soap2

jobname_prefix : m
queue          : node.q
threads        : 2
output_dir     : /path/to/output_dir

genome_config:
 mouse:
  genome_path : /path/to/genome/mouse/%s
  chrnum      : 1-19,X,Y

project_config:
 default:
  tophat : "--solexa-quals -r 200 --mate-std-dev 50"
  bowtie : "-X 250 -I 150"
  soap2  : "-x 250 -m 150"
 SRP000198:
  tophat : "--solexa-quals -r 200 --mate-std-dev 50"
  bowtie : "-X 250 -I 150"
  soap2  : "-x 250 -m 150"
EOM
  option = {
    "tool"         => "tophat",
    "genome_index" => "mouse",
    "input_files"  => ["/path/to/SRP000198"],
  }

  config.merge(option)
end
