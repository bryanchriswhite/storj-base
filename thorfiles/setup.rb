class Setup < ThorBase
  desc 'submodule <repo name> [version]', 'setup using git submodules (for dev)'

  def submodule(repo_name, version = 'latest')
    submodules.each &method(:git_init_and_update)
    run 'thor docker:build thor'
    run 'thor docker:build node-no-conflict'
    run "thor docker:build_submodule #{repo_name}"
  end

  desc 'npm_install_storj', 'npm installs storj modules'

  def npm_install_storj
    get_non_conflicting = -> (key) {
      # p "reduce_on called with key: #{key}"
      result = submodules.reduce({}) do |acc, submodule|
        # p "reducer called with submodule: #{submodule}"
        package_json = parse_package_json submodule
        # print "package_json:\n#{package_json}\n"
        # p "key: #{key}"
        target = package_json[key]

        next acc unless target

        non_conflicting = target.keys.to_set ^ acc.keys
        # p "acc class: #{acc.class}"
        # p "selected_target class: #{acc.class}"
        next acc.merge(target.select do |key, value|
          non_conflicting.include? key
        end)
      end
      # print "result:\n-------\n#{result}\n"
      result
    }

    non_conflicting_deps = get_non_conflicting.call :dependencies
    non_conflicting_dev_deps = get_non_conflicting.call :devDependencies
    # print "deps:\n-----\n#{non_conflicting_deps}\n"
    # print "devDeps:\n--------\n#{non_conflicting_dev_deps}\n"

    storj_no_conflict = {
        name: 'storj-no-conflict',
        description: 'non-conflicting deps and devDeps of storj modules',
        dependencies: non_conflicting_deps,
        devDependencies: non_conflicting_dev_deps
    }

    # p "PACKAGE"
    # p "PACKAGE"
    # p "PACKAGE"
    # p "PACKAGE"
    # p "PACKAGE"
    # print JSON.dump(storj_no_conflict) + "\n"
    File.open('package.json', 'w') do |file|
      file.write JSON.dump(storj_no_conflict)
    end

    run 'npm install'
  end

  desc 'npm_link_storj', 'npm links storj modules'

  def npm_link_storj
    submodules.each do |submodule|
      run "cd #{submodule} && npm link"
      package = parse_package_json submodule
      package.each do |name, version|
        # TODO: this isn't the best way to test if a module shoould be linked
        if /^storj-/.match name
          run "npm link #{name}"
        end
      end
    end
  end

  desc 'npm_install_node_no_conflict', 'installs npm base modules for storj'

  def npm_install_node_no_conflict
    p "npm install submodule deps: #{submodules}"
    git_init_and_update_submodules
    npm_install_storj
    # submodules.each do |submodule|
    #   p "module: #{submodule}"
    #   package = parse_package_json submodule
    #   run "rm -rf #{WORKDIR}/node_modules/#{package['name']}"
    # end
  end

  private

  def git_init_and_update_submodules
    submodules.each do |submodule|
      git_init_and_update submodule
    end
  end

  def parse_package_json(path)
    JSON.parse(File.open("#{WORKDIR}/#{path ? path + '/' : ''}package.json").read, { symbolize_names: true })
  end

  def git_init_and_update(repo_name)
    run "git submodule init #{repo_name}"
    run "git submodule update #{repo_name}"
  end
end
