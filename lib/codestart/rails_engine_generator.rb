module Codestart
  module Output
    def file_tip(action, path)
      puts "      #{'action'.shell_green}  #{path}"
    end
  end

  class RailsEngineGenerator
    include Output

    def initialize(project_name)
      @gem_dir = File.join __dir__, '..'
      @templates_dir = File.join @gem_dir, 'templates'

      puts "rails engine 项目代码构建工具".shell_yellow
      @project_name = project_name
    end

    def write_erb(template, target)
      source = File.join @templates_dir, template
      File.open target, 'w' do |f|
        f.write ERB.new(File.read(source)).result binding
      end
    end

    def project_name_valid?
      if @project_name.blank?
        puts "请输入: bundle exec codestart <子模块名>".shell_red
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
      end_line = 0
      lines.each do |line|
        break if line.index("end") == 0
        end_line += 1
      end
      part0 = lines[0...end_line]
      part1 = lines[(end_line)..-1]

      output = (part0 + [
          "\n",
          "  # 以下为 rails engine 依赖\n",
          "  spec.add_development_dependency 'actionpack', '~> 4.2.0'\n", 
          "  spec.add_development_dependency 'activesupport', '~> 4.2.0'\n\n",
          "  spec.add_development_dependency 'jquery-rails', '>= 3.1.0'\n",
          "  spec.add_development_dependency 'uglifier'\n"
        ] + part1).join

      File.open(path, 'w') do |f|
        f.write output
      end

      file_tip 'change', path
    end

    def change_gemfile_source
      puts "  修改 Gemfile source 为 ruby.taobao.org"
      path = File.join @project_name, 'Gemfile'

      lines = File.read(path).lines
      lines[0] = "source 'http://ruby.taobao.org/'\n"

      File.open(path, 'w') do |f|
        lines.each do |line|
          f.write line
        end
      end

      file_tip 'change', path
    end

    def add_rails_engine_file
      puts "  创建 rails engine 文件"
      path = File.join @project_name, 'lib', @project_name, 'engine.rb'

      File.open(path, 'w') do |f|
        f.write "module #{@module_name}\n"
        f.write "  class Engine < ::Rails::Engine\n"
        f.write "    isolate_namespace #{@module_name}\n"
        f.write "  end\n"
        f.write "end\n"
      end

      file_tip 'create', path
    end

    def add_module_require
      puts "  添加 module 引用"
      path = File.join @project_name, 'lib', "#{@project_name}.rb"
      
      File.open(path, 'a') do |f|
        f.write "\n"
        f.write "# 引用 rails engine\n"
        f.write "require '#{@project_name}/engine'\n"
      end

      file_tip 'change', path
    end

    def run_bundle
      FileUtils.cd @project_name do
        system "bundle"
      end
    end

    def add_controllers_files
      puts "  创建 controllers"

      controllers_dir = File.join @project_name, 'app/controllers', @project_name
      appliction_controller_path = File.join controllers_dir, 'application_controller.rb'
      home_controller_path = File.join controllers_dir, 'home_controller.rb'

      FileUtils.mkdir_p controllers_dir
      FileUtils.touch appliction_controller_path

      write_erb 'application_controller.rb.erb', appliction_controller_path
      write_erb 'home_controller.rb.erb', home_controller_path

      file_tip 'create', appliction_controller_path
      file_tip 'create', home_controller_path
    end

    def add_views_files
      puts "  创建 views"

      layout_dir = File.join @project_name, 'app/views/layouts', @project_name
      layout_path = File.join layout_dir, 'application.html.haml'

      view_dir = File.join @project_name, 'app/views', @project_name, 'home'
      view_path = File.join view_dir, 'index.html.haml'

      FileUtils.mkdir_p layout_dir
      FileUtils.mkdir_p view_dir

      write_erb 'application.html.haml.erb', layout_path
      write_erb 'index.html.haml.erb', view_path

      file_tip 'create', layout_path
      file_tip 'create', view_path
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

      write_erb 'application.js.erb', js_path
      write_erb 'application.css.erb', css_path
      write_erb 'ui.scss.erb', ui_scss_path

      file_tip 'create', js_path
      file_tip 'create', css_path
    end

    def add_routes_file
      puts "  创建 routes"

      config_dir = File.join @project_name, 'config'
      routes_path = File.join config_dir, 'routes.rb'
      FileUtils.mkdir_p config_dir
      FileUtils.touch routes_path

      File.open routes_path, 'w' do |f|
        template_path = File.join @templates_dir, 'routes.rb.erb'
        content = ERB.new(File.read(template_path)).result binding
        f.write content
      end

      file_tip 'create', routes_path
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
    end

  end
end