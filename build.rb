require 'active_support'
require 'active_support/core_ext/string'

class String
  def shell_green
    "\e[1;32;40m#{self}\e[0m"
  end

  def shell_red
    "\e[1;31;40m#{self}\e[0m"
  end
end

class Generator
  def initialize(project_name)
    @project_name = project_name
  end

  def project_name_valid?
    if @project_name.blank?
      puts "请输入 ruby build.rb <gem 名称>".shell_red
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

  def generate
    return if not project_name_valid?
    return if is_dir_exist?

    @module_name = @project_name.camelize

    # 创建 gem
    init_gem

    # 给 gemspec 添加依赖
    add_dependency

    # 创建 rails engine 文件
    add_rails_engine_file

    # 添加 module 引用
    add_module_require
  end

end

Generator.new(ARGV[0]).generate
