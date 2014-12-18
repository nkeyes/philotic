desc "initialize named durable queues"
namespace :philotic do
  task :init_queues, :filename do |t, args|
    raise "You must specify a file name for #{t.name}: rake #{t.name}[FILENAME] #yes, you need the brackets, no space." if !args[:filename]

    require 'philotic'

    # philotic.config.initialize_named_queues must be truthy to run Philotic.initialize_named_queue!
    Philotic.config.initialize_named_queues = true


    @filename = args[:filename]
    queues    = YAML.load_file(@filename)
    queues.each_pair do |queue_name, queue_options|
      Philotic.initialize_named_queue!(queue_name, queue_options)
    end
  end
end
