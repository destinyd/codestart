module Codestart
  class RailsEngineGenerator
    def initialize(project_name)
      @gem_dir = File.join __dir__, '..'
      @templates_dir = File.join @gem_dir, 'templates'

      puts "rails engine 项目代码构建工具".shell_yellow
      @project_name = project_name
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

      puts "      #{'change'.shell_green}  #{path}"
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

      puts "      #{'change'.shell_green}  #{path}"
    end

    def add_rails_engine_file
      puts "  创建 rails engine 文件"
      path = File.join @project_name, 'lib', @project_name, 'rails.rb'

      File.open(path, 'w') do |f|
        f.write "module #{@module_name}\n"
        f.write "  class Engine < ::Rails::Engine\n"
        f.write "    isolate_namespace #{@module_name}\n"
        f.write "  end\n"
        f.write "end\n"
      end

      puts "      #{'create'.shell_green}  #{path}"
    end

    def add_module_require
      puts "  添加 module 引用"
      path = File.join @project_name, 'lib', "#{@project_name}.rb"
      
      File.open(path, 'a') do |f|
        f.write "\n"
        f.write "# 引用 rails engine\n"
        f.write "require '#{@project_name}/rails'\n"
      end

      puts "      #{'change'.shell_green}  #{path}"
    end

    def run_bundle
      FileUtils.cd @project_name do
        system "bundle"
      end
    end

    def add_controller_files
      controllers_dir = File.join File.join @project_name, 'controllers', @project_name
      appliction_controller_path = File.join controllers_dir, 'application_controller.rb'
      FileUtils.mkdir_p controllers_dir
      FileUtils.touch appliction_controller_path

      File.open appliction_controller_path, 'w' do |f|
        template_path = File.join @templates_dir, 'application_controller.rb.erb'
        content = ERB.new(File.read(template_path)).result binding
        f.write content
      end

      puts "      #{'create'.shell_green}  #{appliction_controller_path}"
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

      # 创建 controller 文件
      add_controller_files
    end

  end
end