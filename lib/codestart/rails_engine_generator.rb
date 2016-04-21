module Codestart
  module Output
    def file_tip(action, path)
      puts "      #{action.shell_green}  #{path}"
    end
  end

  module FileIO
    def write_lines(path, lines)
      File.open path, 'w' do |f|
        lines.each do |line|
          f.write line
        end
      end
    end

    def create_from_lines(path, lines)
      write_lines path, lines
      file_tip 'create', path
    end

    def insert_lines(lines, position, new_lines)
      part0 = lines[0...position]
      part1 = lines[position..-1]
      return part0 + new_lines + part1
    end

    def find_position(lines, query)
      position = 0
      lines.each do |line|
        break if line.index(query) == 0
        position += 1
      end
      return position
    end

    def create_from_erb(template, target_path)
      write_erb template, target_path
      file_tip 'create', target_path
    end

    def create_dir_and_file_from_erb(target_dir, template)
      FileUtils.mkdir_p target_dir
      name = template.split('/').last
      path = File.join target_dir, name.sub(/\.erb$/, '')
      create_from_erb template, path
    end

    private

      def write_erb(template, target_path)
        source = File.join @templates_dir, template
        File.open target_path, 'w' do |f|
          f.write ERB.new(File.read(source)).result binding
        end
      end
  end

  class RailsEngineGenerator
    include Output
    include FileIO

    def initialize(args)
      @args = args

      @gem_dir = File.join __dir__, '..'
      @templates_dir = File.join @gem_dir, 'templates'

      puts "rails engine 项目代码构建工具".shell_yellow
      @project_name = args[0]
      @dash_project_name = @project_name
    end

    def project_name_valid?
      if @project_name.blank?
        puts '请输入: codestart <engine_name>'.shell_red
        return false
      end
      if @project_name.include? '-'
        @project_name = @project_name.gsub('-', '_')
        puts "由于名称包含 - , 已在必要的地方替换为 #{@project_name}".shell_red
      end
      return true
    end

    def is_dir_exist?
      path = @dash_project_name

      # 删除目标目录
      if @args[1] == '-rm'
        system "rm -rf #{path}"
      end

      if File.exist? path
        puts "文件目录 #{path} 已存在".shell_red
        return true
      end
      return false
    end

    def init_gem
      puts '  初始化 gem'
      system "bundle gem #{@project_name}"
    end

    def add_dependency
      puts "  给 gemspec 添加依赖"
      path = "#{@project_name}/#{@project_name}.gemspec"

      lines = File.read(path).lines
      # 去掉 TODO
      pos0 = find_position lines, '  spec.summary'
      pos1 = find_position lines, '  spec.description'
      lines[pos0] = '  spec.summary       = ""' + "\n"
      lines[pos1] = '  spec.description   = ""' + "\n"

      # 添加依赖
      end_line_pos = find_position lines, 'end'
      output = insert_lines lines, end_line_pos, [
          "\n",
          "  # 以下为 rails engine 依赖\n",
          "  spec.add_development_dependency 'actionpack', '~> 4.2.0'\n",
          "  spec.add_development_dependency 'activesupport', '~> 4.2.0'\n\n",
          "  spec.add_development_dependency 'jquery-rails', '>= 3.1.0'\n",
          "  spec.add_development_dependency 'uglifier'\n"
        ]

      write_lines path, output
      file_tip 'modify', path
    end

    def change_gemfile_source
      puts "  修改 Gemfile source 为 ruby.taobao.org"
      path = File.join @project_name, 'Gemfile'

      lines = File.read(path).lines
      lines[0] = "source 'http://ruby.taobao.org/'\n"

      write_lines path, lines
      file_tip 'modify', path
    end

    def change_lib_module_file
      puts "  创建 #{@module_name} module"
      path = File.join @project_name, 'lib', "#{@project_name}.rb"

      lines = [
        "module #{@module_name}\n",
        "  class << self\n",
        "    def #{@project_name}_config\n",
        "      self.instance_variable_get(:@#{@project_name}_config) || {}\n",
        "    end\n",
        "\n",
        "    def set_mount_prefix(mount_prefix)\n",
        "      config = #{@module_name}.#{@project_name}_config\n",
        "      config[:mount_prefix] = mount_prefix\n",
        "      #{@module_name}.instance_variable_set(:@#{@project_name}_config, config)\n",
        "    end\n",
        "\n",
        "    def get_mount_prefix\n",
        "      #{@project_name}_config[:mount_prefix]\n",
        "    end\n",
        "  end\n",
        "end\n",
        "\n",
        "# 引用 rails engine\n",
        "require '#{@project_name}/engine'\n",
        "require '#{@project_name}/rails_routes'\n"
      ]

      write_lines path, lines
      file_tip 'modify', path
    end

    def add_rails_engine_file
      puts "  创建 rails engine 文件"
      path = File.join @project_name, 'lib', @project_name, 'engine.rb'

      create_from_erb 'engine.rb.erb', path
    end

    def add_rails_routes_rb_file
      puts "  创建 rails_routes.rb 文件"
      path = File.join @project_name, 'lib', @project_name, 'rails_routes.rb'

      create_from_erb 'rails_routes.rb.erb', path
    end

    def run_bundle
      FileUtils.cd @project_name do
        system "bundle"
      end
    end

    def add_controllers_files
      puts "  创建 controllers"

      controllers_dir = File.join @project_name, 'app/controllers', @project_name
      create_dir_and_file_from_erb controllers_dir,
        'application_controller.rb.erb'
    end

    def add_sample_views_files
      puts "  创建 sample views"

      sample_layout_dir = File.join @project_name, 'sample/app/views/layouts'

      sample_view_dir = File.join @project_name, 'sample/app/views', 'home'

      create_dir_and_file_from_erb sample_layout_dir, 'sample/application.html.haml.erb'
      create_dir_and_file_from_erb sample_view_dir, 'sample/index.html.haml.erb'
    end

    def add_routes_file
      puts "  创建 routes"

      config_dir = File.join @project_name, 'config'

      create_dir_and_file_from_erb config_dir, 'routes.rb.erb'
    end

    def add_keep_dirs
      keep_it File.join @project_name, 'app/models', @project_name
      keep_it File.join @project_name, 'app/views', @project_name
      keep_it File.join @project_name, 'app/controllers', @project_name
      keep_it File.join @project_name, 'app/assets/javascripts', @project_name
      keep_it File.join @project_name, 'app/assets/stylesheets', @project_name
    end

    def keep_it dir
      FileUtils.mkdir_p dir
      FileUtils.touch File.join dir, '.keep'
    end

    def copy_sample
      source_sample_dir = File.join @gem_dir, 'sample/'
      target_sample_dir = File.join @project_name, 'sample/'

      FileUtils.cp_r source_sample_dir, target_sample_dir
      file_tip 'create', target_sample_dir

      # 修改 Gemfile
      gemfile_path = File.join target_sample_dir, 'Gemfile'
      File.open gemfile_path, 'a' do |f|
        f.write "\n"
        f.write "gem '#{@dash_project_name}', path: '../'"
      end

      # 修改 routes.rb
      FileUtils.mkdir_p File.join target_sample_dir, 'config'
      routes_path = File.join target_sample_dir, 'config/routes.rb'
      lines = File.read(routes_path).lines
      lines[1] = "  #{@module_name}::Routing.mount '/', :as => '#{@project_name}'\n"
      write_lines routes_path, lines

      # 修改 mongoid.yml
      mongoid_yml_path = File.join target_sample_dir, 'config/mongoid.yml'
      result = ERB.new(File.read(mongoid_yml_path)).result binding
      File.open mongoid_yml_path, 'w' do |f|
        f.write result
      end
    end

    def modify_for_dash_name
      return if !@dash_project_name.include? '-'

      puts "进行必要的补充调整"

      # 修改工程名
      system "mv #{@project_name} #{@dash_project_name}"
      file_tip 'chname', "#{@project_name} -> #{@dash_project_name}"

      # 修改 gemspec 名称和内容
      p1 = "#{@dash_project_name}/#{@project_name}.gemspec"
      p2 = "#{@dash_project_name}/#{@dash_project_name}.gemspec"
      system "mv #{p1} #{p2}"
      file_tip 'chname', "#{p1} -> #{p2}"
      lines = File.read(p2).lines
      lines[6] = "  spec.name          = '#{@dash_project_name}'\n"
      write_lines p2, lines
      file_tip 'modify', p2

      # 修改 lib/ 下的 rb
      p1 = "#{@dash_project_name}/lib/#{@project_name}.rb"
      p2 = "#{@dash_project_name}/lib/#{@dash_project_name}.rb"
      system "mv #{p1} #{p2}"
      file_tip 'chname', "#{p1} -> #{p2}"

      # 修改 Gemfile
      path = "#{@dash_project_name}/Gemfile"
      lines = File.read(path).lines
      lines[2] = "# Specify your gem's dependencies in #{@dash_project_name}.gemspec\n"
      write_lines path, lines
      file_tip 'modify', path
    end

    def generate
      return if not project_name_valid?
      return if is_dir_exist?

      @module_name = @project_name.camelize

      # 创建 gem
      init_gem

      # 给 gemspec 添加依赖
      add_dependency

      # 修改 gem 的 Gemfile 更改 source
      change_gemfile_source

      # 创建 rails engine 文件
      add_rails_engine_file

      # 创建 rails_routes.rb 文件
      add_rails_routes_rb_file

      # 修改 lib/xxx.rb 文件，增加 module
      change_lib_module_file

      # bundle
      # run_bundle

      # 创建 controllers 文件
      add_controllers_files

      # 创建 routes 文件
      add_routes_file

      # 复制 sample 文件夹
      copy_sample

      # 创建 sample views 文件
      add_sample_views_files

      # 添加一些 .keep 文件
      add_keep_dirs

      # 当文件名里有 -, 进行必要的调整
      modify_for_dash_name

      FileUtils.cd @dash_project_name do
        system 'rm -rf .git'
        system 'git init'
      end
    end

  end
end
