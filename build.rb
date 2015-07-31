require 'active_support'
require 'active_support/core_ext/string'

def green_str(str)
  "\e[1;32;40m#{str}\e[0m"
end

def generate
  project_name = ARGV[0]
  if project_name.blank?
    puts "请输入 ruby build.rb <gem 名称>"
    return
  end

  module_name = project_name.camelize

  if File.exist? project_name
    puts "文件目录 #{project_name} 已存在"
    return
  end

  # 创建 gem
  # ----------------------
  puts '  初始化 gem'
  system "bundle gem #{project_name}"



  # 给 gemspec 添加依赖
  # ------------------
  puts "  给 gemspec 添加依赖"

  path = "#{project_name}/#{project_name}.gemspec"
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

  puts "      #{green_str('change')}  #{path}"



  # 创建 rails engine 文件
  # -------------
  puts "  创建 rails engine 文件"
  path = File.join project_name, 'lib', project_name, 'rails.rb'
  File.open(path, 'w') do |f|
    f.write "module #{module_name}\n"
    f.write "  class Engine < ::Rails::Engine\n"
    f.write "    isolate_namespace #{module_name}\n"
    f.write "  end\n"
    f.write "end\n"
  end
  puts "      #{green_str('create')}  #{path}"



  # 添加 module 引用
  # -------------------
  puts "  添加 module 引用"
  path = File.join project_name, 'lib', "#{project_name}.rb"
  File.open(path, 'a') do |f|
    f.write "\n"
    f.write "# 引用 rails engine\n"
    f.write "require '#{project_name}/rails'\n"
  end
  puts "      #{green_str('change')}  #{path}"
end

generate
