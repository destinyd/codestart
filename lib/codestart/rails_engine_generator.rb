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
      path = File.join target_dir, template.sub(/\.erb$/, '')
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
      @gem_dir = File.join __dir__, '..'
      @templates_dir = File.join @gem_dir, 'templates'

      puts "rails engine 项目代码构建工具".shell_yellow
      @project_name = args[0]

      # 删除目标目录
      if args[1] == '-rm'
        system "rm -rf #{@project_name}"
      end
    end

    def project_name_valid?
      if @project_name.blank?
        puts "请输入: bundle exec codestart <engine_name>".shell_red
        return false
      end
      return true
    end

    def is_dir_exist?
      path = @project_name
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

    def add_rails_engine_file
      puts "  创建 rails engine 文件"
      path = File.join @project_name, 'lib', @project_name, 'engine.rb'

      create_from_lines path, [
          "module #{@module_name}\n",
          "  class Engine < ::Rails::Engine\n",
          "    isolate_namespace #{@module_name}\n",
          "  end\n",
          "end\n",
        ]
    end

    def add_module_require
      puts "  添加 module 引用"
      path = File.join @project_name, 'lib', "#{@project_name}.rb"
      
      create_from_lines path, [
          "\n",
          "# 引用 rails engine\n",
          "require '#{@project_name}/engine'\n",
        ]
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
      create_dir_and_file_from_erb controllers_dir,
        'home_controller.rb.erb'
    end

    def add_views_files
      puts "  创建 views"

      layout_dir = File.join @project_name, 'app/views/layouts', @project_name
      layout_path = File.join layout_dir, 'application.html.haml'

      view_dir = File.join @project_name, 'app/views', @project_name, 'home'
      view_path = File.join view_dir, 'index.html.haml'

      FileUtils.mkdir_p layout_dir
      FileUtils.mkdir_p view_dir

      create_from_erb 'application.html.haml.erb', layout_path
      create_from_erb 'index.html.haml.erb', view_path
    end

    def add_assets_files
      puts "  创建 assets"

      js_dir = File.join @project_name, 'app/assets/javascripts', @project_name
      js_path = File.join js_dir, 'application.js'
      css_dir = File.join @project_name, 'app/assets/stylesheets', @project_name
      css_path = File.join css_dir, 'application.css'
      ui_scss_path = File.join css_dir, 'ui.scss'

      FileUtils.mkdir_p js_dir
      FileUtils.mkdir_p css_dir

      create_from_erb 'application.js.erb', js_path
      create_from_erb 'application.css.erb', css_path
      create_from_erb 'ui.scss.erb', ui_scss_path
    end

    def add_routes_file
      puts "  创建 routes"

      config_dir = File.join @project_name, 'config'
      routes_path = File.join config_dir, 'routes.rb'
      FileUtils.mkdir_p config_dir
      FileUtils.touch routes_path

      create_from_erb 'routes.rb.erb', routes_path
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
        f.write "gem '#{@project_name}', path: '../'"
      end

      # 修改 routes.rb
      routes_path = File.join target_sample_dir, 'config/routes.rb'
      lines = File.read(routes_path).lines
      lines[1] = "mount #{@module_name}::Engine => '/', :as => '#{@project_name}'"
      write_lines routes_path, lines
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

      # 添加 module 引用
      add_module_require

      # bundle
      # run_bundle

      # 创建 controllers 文件
      add_controllers_files

      # 创建 views 文件
      add_views_files

      # 创建 assets 文件
      add_assets_files

      # 创建 routes 文件
      add_routes_file

      # 复制 sample 文件夹
      copy_sample

      FileUtils.cd @project_name do
        system 'rm -rf .git'
        system 'git init'
      end
    end

  end
end