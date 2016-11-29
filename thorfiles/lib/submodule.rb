class Submodule < ThorBase
  desc 'add <repo name> [git remote url]', 'Add a new git submodule'

  method_option :branch, aliases: :b, type: :string

  def add(repo_name, git_remote_url = 'https://github.com/Storj/%{repo_name}.git')
    # update .gitmodules
    append_dot_gitmodules
    # *update .git/index

  end

  desc 'build <submodule name> [service name]', 'Builds docker image (and optionally dep images) for given submodule'

  method_option :deps, aliases: :d, default: false, type: :boolean
  method_option :env, aliases: :e, default: :development, type: :string

  def build(submodule, service = '')
    @env = options[:env]

    gemfile_lock_path = "#{WORKDIR}/Gemfile.lock"
    File.delete gemfile_lock_path if File.file? gemfile_lock_path

    if options[:deps]
      # invoke 'docker:build', ['thor']
      # invoke 'docker:build', ['node-storj']
      ::Docker.new.build 'thor' #, options
      ::Docker.new.build 'node-storj' #, options
    end

    git_init_and_update submodule

    composition_yml_path = "#{WORKDIR}/#{submodule}/dockerfiles/#{submodule}-#{@env}.yml"
    docker_compose :build, service, file: composition_yml_path
  end

  desc 'update', 'Init and update all git submodules given current .git/index and .gitmodules files'

  # method_option :force, aliases: :f, default: false, type: :boolean

  def update
    deinit
    submodules.each &method(:git_init_and_update)
  end

  desc 'deinit', 'Deinit all git submodules'

  method_option :force, aliases: :f, default: false, type: :boolean

  def deinit
    force = options[:force] ? '--force' : ''

    submodules.each do |submodule|
      run "git submodule deinit #{force} #{submodule}"
    end
  end

  desc 'up <submodule name> [service name]', '"Up" a docker composition (or a specific service) for the given submodule'

  method_option :env, default: :development, aliases: :e

  def up(submodule, service = '')
    @env = options[:env]
    composition_yml = "#{WORKDIR}/submodule/dockerfiles/#{submodule}-#{@env}.yml"
    docker_compose composition_yml, 'up', service: service
  end

  desc 'run <submodule name> <service name> [command]', 'Run a one-off command in the specified service for the given submodule\'s composition'

  method_option :env, default: :development, aliases: :e

  def command(submodule, service, command = '')
    @env = options[:env]
    composition_yml = "#{WORKDIR}/submodule/dockerfiles/#{submodule}-#{@env}.yml"
    docker_compose composition_yml, 'run', service: service, command: command
  end
end
