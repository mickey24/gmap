require 'rake'
require 'spec/rake/spectask'

task :default => [:spec]

desc "Run all specs"
task :spec do
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['--options', 'spec/spec.opts']
  end
end
